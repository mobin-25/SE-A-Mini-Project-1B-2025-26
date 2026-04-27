import asyncio
import csv
import hashlib
import io
import json
import os
import random
import time
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Dict, List

import uvicorn
from fastapi import (FastAPI, WebSocket, WebSocketDisconnect,
                     HTTPException, UploadFile, File, Depends)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt

import database as db
import wireshark

SECRET    = "uniaccess_secret_2024"
SERVER_IP = "192.168.0.104"
UPLOADS   = "uploads"
os.makedirs(UPLOADS, exist_ok=True)

# ── State ──────────────────────────────────────────────────────────────────
client_sockets:  Dict[str, WebSocket] = {}
admin_sockets:   List[WebSocket]      = []
blocked_set:     set                  = set()
latency_history: List[float]          = []

mem_packets: Dict[str, int]  = {}
mem_files:   Dict[str, int]  = {}
mem_ping:    Dict[str, int]  = {}
mem_ip:      Dict[str, str]  = {}
mem_flooder: Dict[str, bool] = {}
flood_msgs:  Dict[str, int]  = {}

FLOOD_THRESHOLD      = 500
FLOOD_WINDOW         = 2
AUTO_BLOCK_THRESHOLD = 5000
_pkt_snap:   Dict[str, int] = {}
_strike:     Dict[str, int] = {}

# ── Auth ───────────────────────────────────────────────────────────────────
def hash_pw(pw: str) -> str:
    return hashlib.sha256(pw.encode()).hexdigest()

def make_token(u: str, admin: bool) -> str:
    return jwt.encode({"sub": u, "admin": admin, "iat": int(time.time())},
                      SECRET, algorithm="HS256")

def verify_token(t: str) -> dict:
    return jwt.decode(t, SECRET, algorithms=["HS256"])

security = HTTPBearer()

def get_user(creds: HTTPAuthorizationCredentials = Depends(security)):
    try: return verify_token(creds.credentials)
    except Exception: raise HTTPException(401, "Invalid token")

def get_admin(u=Depends(get_user)):
    if not u.get("admin"): raise HTTPException(403, "Admin only")
    return u

# ── Broadcast ──────────────────────────────────────────────────────────────
async def push_admins(msg: dict):
    dead = []
    for ws in list(admin_sockets):
        try: await ws.send_json(msg)
        except Exception: dead.append(ws)
    for d in dead:
        if d in admin_sockets: admin_sockets.remove(d)

async def push_client(uname: str, msg: dict) -> bool:
    ws = client_sockets.get(uname)
    if not ws: return False
    try: await ws.send_json(msg); return True
    except Exception: client_sockets.pop(uname, None); return False

async def broadcast():
    try:
        clients = []
        for u in list(client_sockets.keys()):
            clients.append({
                "username":   u,
                "ip":         mem_ip.get(u, ""),
                "files_sent": mem_files.get(u, 0),
                "packets":    mem_packets.get(u, 0),
                "ping":       mem_ping.get(u, 0),
                "is_blocked": u in blocked_set,
                "is_flooder": mem_flooder.get(u, False),
                "online":     True,
            })
        try:
            rows   = await db.get_all_clients()
            online = set(client_sockets.keys())
            for c in rows:
                if c["username"] not in online:
                    clients.append({
                        "username":   c["username"],
                        "ip":         c["ip"]         or "",
                        "files_sent": c["files_sent"] or 0,
                        "packets":    c["packets"]    or 0,
                        "ping":       0,
                        "is_blocked": c["is_blocked"] or False,
                        "is_flooder": c["is_flooder"] or False,
                        "online":     False,
                    })
        except Exception:
            pass

        flood_on = any(cl["is_flooder"] and not cl["is_blocked"] and cl["online"]
                       for cl in clients)
        load = round(0.70 + random.random() * 0.25, 2) if flood_on \
               else round(0.05 + random.random() * 0.15, 2)

        await push_admins({
            "type":    "clients",
            "clients": clients,
            "load":    min(load, 1.0),
            "latency": latency_history[-40:],
            "net":     {"recv_ps": 0, "sent_ps": 0,
                        "pkt_recv_ps": 0, "pkt_sent_ps": 0},
        })

        for u, ws in list(client_sockets.items()):
            try:
                await ws.send_json({"type": "stats", "data": {
                    "username":   u,
                    "ip":         mem_ip.get(u, ""),
                    "files_sent": mem_files.get(u, 0),
                    "packets":    mem_packets.get(u, 0),
                    "ping":       mem_ping.get(u, 0),
                    "is_blocked": u in blocked_set,
                    "is_flooder": mem_flooder.get(u, False),
                }})
            except Exception:
                pass
    except Exception as e:
        print(f"[broadcast error] {e}")

async def detect_floods():
    for u in list(client_sockets.keys()):
        curr = mem_packets.get(u, 0)
        last = _pkt_snap.get(u, curr)
        rate = curr - last
        _pkt_snap[u] = curr

        if rate <= FLOOD_THRESHOLD:
            _strike[u] = 0
            continue

        # Auto-block: extreme rate
        if rate >= AUTO_BLOCK_THRESHOLD and u not in blocked_set:
            print(f"[AUTO-BLOCK] {u} blocked at {rate} pkt/s")
            await db.set_client_blocked(u, True)
            blocked_set.add(u)
            await push_client(u, {
                "type":    "blocked",
                "message": f"Auto-blocked: {rate} pkt/s exceeded {AUTO_BLOCK_THRESHOLD} limit.",
            })
            client_sockets.pop(u, None)
            try:
                await db.insert_log(mem_ip.get(u, ""), "SYSTEM", 0,
                    f"🔴 AUTO-BLOCKED: {u} at {rate} pkt/s", u)
            except Exception:
                pass
            await push_admins({"type": "packet", "packet": {
                "time": datetime.now().strftime("%H:%M:%S"),
                "src_ip": mem_ip.get(u, ""), "dst_ip": SERVER_IP,
                "protocol": "SYSTEM", "length": 0,
                "info": f"🔴 AUTO-BLOCKED: {u} — {rate} pkt/s",
            }})
            await push_admins({
                "type": "notification", "level": "critical",
                "title": "🔴 Auto-Blocked",
                "message": f"{u} was AUTO-BLOCKED ({rate} pkt/s > {AUTO_BLOCK_THRESHOLD})",
                "username": u, "rate": rate,
            })
            continue

        # Flag as flooder
        _strike[u] = _strike.get(u, 0) + 1
        if _strike[u] >= FLOOD_WINDOW and not mem_flooder.get(u, False):
            print(f"[DETECT] {u} flooder at {rate} pkt/s")
            mem_flooder[u] = True
            try: await db.update_flooder_flag(u, True)
            except Exception: pass
            await push_admins({"type": "packet", "packet": {
                "time": datetime.now().strftime("%H:%M:%S"),
                "src_ip": mem_ip.get(u, ""), "dst_ip": SERVER_IP,
                "protocol": "SYSTEM", "length": 0,
                "info": f"🚨 AUTO-DETECTED: {u} at {rate} pkt/s",
            }})
            await push_admins({
                "type": "notification", "level": "warning",
                "title": "⚠️ Flood Detected",
                "message": f"{u} is flooding at {rate} pkt/s",
                "username": u, "rate": rate,
            })

# ── Lifespan ───────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    await db.init_db()
    rows = await db.get_all_clients()
    for c in rows:
        if c["is_blocked"]: blocked_set.add(c["username"])
        mem_packets[c["username"]] = c["packets"]    or 0
        mem_files[c["username"]]   = c["files_sent"] or 0
        mem_ping[c["username"]]    = c["ping"]       or 0
        mem_ip[c["username"]]      = c["ip"]         or ""
        mem_flooder[c["username"]] = c["is_flooder"] or False
    wireshark.set_callback(on_packet)
    asyncio.create_task(wireshark.start_capture(on_packet))
    asyncio.create_task(_ping_loop())
    asyncio.create_task(_db_sync())
    print("✅ UniAccess ready on http://0.0.0.0:8000")
    yield
    await db.close_db()

app = FastAPI(lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])

async def _ping_loop():
    while True:
        try:
            await asyncio.sleep(1)
            await detect_floods()
            flood_on = any(mem_flooder.get(u, False) and u not in blocked_set
                           for u in client_sockets)
            total, count = 0, 0
            for u in list(client_sockets.keys()):
                if mem_flooder.get(u, False) and u not in blocked_set:
                    ping = random.randint(80, 150)
                elif flood_on:
                    ping = random.randint(90, 200)
                else:
                    ping = random.randint(10, 50)
                mem_ping[u] = ping
                total += ping; count += 1
            val = round(total / count, 1) if count > 0 else round(random.randint(5, 15), 1)
            latency_history.append(val)
            if len(latency_history) > 80: latency_history.pop(0)
            await broadcast()
        except Exception as e:
            print(f"[ping_loop error] {e}")

async def _db_sync():
    while True:
        try:
            await asyncio.sleep(5)
            for u in list(client_sockets.keys()):
                try:
                    await db.update_client_full(u, mem_files.get(u,0),
                                                mem_packets.get(u,0), mem_ping.get(u,0))
                except Exception:
                    pass
        except Exception as e:
            print(f"[db_sync error] {e}")

async def on_packet(pkt: dict):
    try:
        await db.insert_log(pkt.get("src_ip",""), pkt.get("protocol",""),
                            pkt.get("length",0), pkt.get("info",""))
        await push_admins({"type": "packet", "packet": pkt})
    except Exception:
        pass

# ── REST ───────────────────────────────────────────────────────────────────
class AuthReq(BaseModel):
    username: str
    password: str

@app.post("/auth/login")
async def login(req: AuthReq):
    user = await db.get_user(req.username)
    if not user or user["password"] != hash_pw(req.password):
        raise HTTPException(401, "Invalid credentials")
    if not user["is_admin"]:
        c = await db.get_client(req.username)
        if c and c["is_blocked"]: raise HTTPException(403, "BLOCKED")
    return {"token": make_token(req.username, user["is_admin"]),
            "username": req.username, "is_admin": user["is_admin"]}

@app.post("/auth/register")
async def register(req: AuthReq):
    if len(req.username) < 3: raise HTTPException(400, "Username too short")
    if len(req.password) < 4: raise HTTPException(400, "Password too short")
    if not await db.create_user(req.username, hash_pw(req.password)):
        raise HTTPException(409, "Username already taken")
    return {"message": "Registered"}

@app.post("/client/upload")
async def upload(file: UploadFile = File(...), user=Depends(get_user)):
    u = user["sub"]
    if u in blocked_set: raise HTTPException(403, "BLOCKED")
    data = await file.read()
    with open(os.path.join(UPLOADS, f"{u}_{file.filename}"), "wb") as f:
        f.write(data)
    mb = len(data) / (1024 * 1024)
    mem_packets[u] = mem_packets.get(u,0) + max(int(mb*10)+random.randint(2,8), 5)
    mem_files[u]   = mem_files.get(u,0) + 1
    await db.update_client_full(u, mem_files[u], mem_packets[u], mem_ping.get(u,30))
    await db.insert_log(mem_ip.get(u,""), "TCP", len(data),
                        f"File Upload: {file.filename} ({mb:.1f} MB)", u)
    await broadcast()
    return {"message": "uploaded", "size_mb": round(mb, 2)}

@app.post("/admin/block/{username}")
async def block(username: str, user=Depends(get_admin)):
    await db.set_client_blocked(username, True)
    blocked_set.add(username)
    sent = await push_client(username, {
        "type": "blocked", "message": "You have been blocked by the administrator."})
    client_sockets.pop(username, None)
    try:
        await db.insert_log(mem_ip.get(username,""), "SYSTEM", 0,
                            f"🚫 Admin BLOCKED: {username}", username)
    except Exception:
        pass
    await broadcast()
    print(f"[BLOCK] {username} ws={sent}")
    return {"ok": True}

@app.post("/admin/unblock/{username}")
async def unblock(username: str, user=Depends(get_admin)):
    await db.set_client_blocked(username, False)
    blocked_set.discard(username)
    await broadcast()
    return {"ok": True}

# ── Downloads ──────────────────────────────────────────────────────────────
KEY = "admin123"
def _chk(k):
    if k != KEY: raise HTTPException(401, "Wrong key. Add ?key=admin123")
def _t(t):
    if not t: return ""
    try: return f"{t.hour:02d}:{t.minute:02d}:{t.second:02d}"
    except: return str(t)
def _csv(rows):
    b = io.StringIO(); w = csv.writer(b)
    w.writerow(["#","Time","Src IP","Dst IP","Protocol","Length","Info","Username"])
    for i,r in enumerate(rows,1):
        w.writerow([i,_t(r["time"]),r["source_ip"] or "",r["dest_ip"] or "SERVER",
                    r["protocol"] or "",r["length"] or 0,r["info"] or "",r["username"] or ""])
    return b.getvalue()

def _sr(data, fname):
    return StreamingResponse(iter([data]), media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={fname}"})

@app.get("/admin/logs/download/all")
async def dl_all(key: str = ""):
    _chk(key)
    return _sr(_csv(await db.get_all_logs()),
               f"all_logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")

@app.get("/admin/logs/download/flooder")
async def dl_flood(key: str = ""):
    _chk(key)
    rows = [r for r in await db.get_all_logs()
            if r["info"] and any(x in r["info"].lower()
                                 for x in ["⚠️","flood","syn","detected","blocked"])]
    return _sr(_csv(rows), f"flooder_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")

@app.get("/admin/logs/download/clients")
async def dl_clients(key: str = ""):
    _chk(key)
    rows = [r for r in await db.get_all_logs()
            if r["info"] and not any(x in r["info"].lower()
                                     for x in ["⚠️","flood","syn","detected"])]
    return _sr(_csv(rows), f"clients_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")

@app.get("/admin/stats/summary")
async def dl_summary(key: str = ""):
    _chk(key)
    rows = await db.get_all_clients()
    b = io.StringIO(); w = csv.writer(b)
    w.writerow(["Username","IP","Files","Packets","Ping","Flooder","Blocked","Online","Last Seen"])
    for c in rows:
        u = c["username"]; on = u in client_sockets
        w.writerow([u, c["ip"] or "",
                    mem_files.get(u,c["files_sent"] or 0) if on else c["files_sent"] or 0,
                    mem_packets.get(u,c["packets"] or 0)  if on else c["packets"] or 0,
                    mem_ping.get(u,c["ping"] or 0)        if on else c["ping"] or 0,
                    "YES" if c["is_flooder"] else "NO",
                    "YES" if c["is_blocked"] else "NO",
                    "YES" if on else "NO",
                    str(c["last_seen"]) if c["last_seen"] else ""])
    return _sr(b.getvalue(), f"summary_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")

@app.get("/admin/dataset/download")
async def dl_dataset(key: str = "", label_mode: str = "all"):
    _chk(key)
    rows = await db.get_all_logs()
    clients = await db.get_all_clients()
    ip_map = {c["ip"]: c["is_flooder"] for c in clients if c["ip"]}
    def lbl(r):
        ip=r["source_ip"] or ""; inf=r["info"] or ""
        if ip in ip_map and ip_map[ip]: return 1
        if any(x in inf.lower() for x in ["flood","⚠️","detected"]): return 1
        return 0
    b = io.StringIO(); w = csv.writer(b)
    w.writerow(["row","timestamp","hour","min","sec","src_ip","dst_ip","protocol",
                "length","info","username","src_local","dst_local",
                "is_tcp","is_udp","is_icmp","is_http","is_dns",
                "is_flood","has_warning","direction","event","label"])
    for i,r in enumerate(rows,1):
        l=lbl(r)
        if label_mode=="flooder" and l!=1: continue
        if label_mode=="client"  and l!=0: continue
        t=r["time"]; src=r["source_ip"] or ""; dst=r["dest_ip"] or SERVER_IP
        pr=(r["protocol"] or "").upper(); inf=r["info"] or ""
        loc=lambda ip: 1 if ip.startswith(("192.168.","10.","172.")) else 0
        def ev(inf,pr):
            i=inf.lower()
            if "upload"  in i: return "UPLOAD"
            if "connect" in i: return "CONNECT"
            if "blocked" in i: return "BLOCK"
            if "flood" in i or "⚠️" in inf: return "FLOOD"
            return "OTHER"
        w.writerow([i, t.strftime("%Y-%m-%d %H:%M:%S") if t else "",
                    t.hour if t else "",t.minute if t else "",t.second if t else "",
                    src,dst,r["protocol"] or "",r["length"] or 0,inf,r["username"] or "",
                    loc(src),loc(dst),
                    1 if pr=="TCP" else 0, 1 if pr=="UDP" else 0, 1 if pr=="ICMP" else 0,
                    1 if pr in("HTTP","HTTPS") else 0, 1 if pr=="DNS" else 0,
                    1 if any(x in inf.lower() for x in ["flood","syn","malformed"]) else 0,
                    1 if "⚠️" in inf else 0,
                    "INBOUND" if dst==SERVER_IP else "OUTBOUND", ev(inf,pr), l])
    return _sr(b.getvalue(),
               f"dataset_{label_mode}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")

@app.get("/")
async def root():
    return {"status": "UniAccess ✅", "online": list(client_sockets.keys())}

# ── WebSocket Client ───────────────────────────────────────────────────────
FPROTO = ["UDP","TCP","ICMP","HTTP","DNS","TLS"]
FINFO  = ["Fragmented IP datagram","SYN flood attempt","UDP flood burst",
          "ICMP echo request flood","HTTP GET flood","Malformed packet",
          "Port scan detected","DNS amplification attack",
          "Large UDP payload","Repeated SYN packets"]

@app.websocket("/ws/client/{username}")
async def ws_client(ws: WebSocket, username: str, token: str = ""):
    if not token: token = ws.query_params.get("token", "")
    try:
        p = verify_token(token)
        if p["sub"] != username: await ws.close(code=4001); return
    except Exception: await ws.close(code=4001); return

    if username in blocked_set:
        await ws.accept()
        await ws.send_json({"type":"blocked","message":"You are blocked."})
        await ws.close(); return

    await ws.accept()
    ip = ws.client.host if ws.client else "unknown"
    print(f"[WS] ✅ {username}  ip={ip}")

    await db.upsert_client(username, ip, False)
    c = await db.get_client(username)
    if c:
        mem_packets[username] = c["packets"]    or 0
        mem_files[username]   = c["files_sent"] or 0
        mem_ping[username]    = c["ping"]       or 0
    mem_ip[username]=ip; mem_flooder[username]=False
    flood_msgs[username]=0; _pkt_snap[username]=mem_packets.get(username,0)
    _strike[username]=0; client_sockets[username]=ws
    await broadcast()
    try: await db.insert_log(ip,"TCP",0,f"Connected: {username}",username)
    except Exception: pass
    await ws.send_json({"type":"stats","data":{
        "username":username,"ip":ip,
        "files_sent":mem_files.get(username,0),
        "packets":mem_packets.get(username,0),
        "ping":mem_ping.get(username,0),
        "is_blocked":False,"is_flooder":False}})

    try:
        while True:
            try: raw = await ws.receive_text()
            except WebSocketDisconnect: print(f"[WS] 🔴 {username}"); break
            except Exception as e: print(f"[WS] {username}: {e}"); break
            try: msg = json.loads(raw)
            except Exception: continue
            t = msg.get("type","")
            if t == "ping":
                try: await ws.send_json({"type":"pong"})
                except Exception: break
            elif t == "flood":
                if username in blocked_set:
                    try: await ws.send_json({"type":"blocked","message":"You have been blocked."})
                    except Exception: pass
                    break
                pkts = random.randint(800,1500)
                mem_packets[username] = mem_packets.get(username,0) + pkts
                mem_ping[username]    = random.randint(80,150)
                flood_msgs[username]  = flood_msgs.get(username,0) + 1
                if flood_msgs[username] % 8 == 0:
                    mem_files[username] = mem_files.get(username,0) + 1
                proto=random.choice(FPROTO); info=random.choice(FINFO)
                length=random.randint(64,1500)
                await push_admins({"type":"packet","packet":{
                    "time":datetime.now().strftime("%H:%M:%S"),
                    "src_ip":ip,"dst_ip":SERVER_IP,
                    "protocol":proto,"length":length,"info":f"⚠️ {info}"}})
                if flood_msgs[username] % 3 == 0:
                    try: await db.insert_log(ip,proto,length,f"⚠️ {info}",username)
                    except Exception: pass
                if flood_msgs[username] % 5 == 0:
                    await broadcast()
    finally:
        try: await db.update_client_full(username,
            mem_files.get(username,0),mem_packets.get(username,0),mem_ping.get(username,0))
        except Exception: pass
        for d in [client_sockets,flood_msgs,_strike,_pkt_snap]:
            d.pop(username,None)
        print(f"[WS] 🔴 {username} done")
        try: await broadcast()
        except Exception: pass

# ── WebSocket Admin ────────────────────────────────────────────────────────
@app.websocket("/ws/admin")
async def ws_admin(ws: WebSocket):
    token = ws.query_params.get("token","")
    try:
        p = verify_token(token)
        if not p.get("admin"): await ws.close(code=4003); return
    except Exception: await ws.close(code=4001); return
    await ws.accept(); admin_sockets.append(ws)
    print("[WS] ✅ ADMIN")
    try:
        await broadcast()
        rows = await db.get_recent_logs(100)
        await ws.send_json({"type":"logs","logs":[{
            "time":_t(r["time"]),"src_ip":r["source_ip"] or "",
            "dst_ip":r["dest_ip"] or "SERVER","protocol":r["protocol"] or "",
            "length":r["length"] or 0,"info":r["info"] or ""} for r in rows]})
        while True:
            try: await ws.receive_text()
            except (WebSocketDisconnect,RuntimeError): break
            except Exception: break
    finally:
        if ws in admin_sockets: admin_sockets.remove(ws)
        print("[WS] 🔴 ADMIN done")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)