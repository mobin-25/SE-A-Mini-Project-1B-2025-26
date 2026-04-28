
import asyncio
import aiohttp
import argparse
import json
import random
import urllib.parse
from datetime import datetime

PROTOCOLS = ["UDP","TCP","ICMP","HTTP","DNS"]
TYPES = [
    "SYN flood burst","UDP flood packet","ICMP echo flood",
    "HTTP GET flood","DNS amplification","Fragmented packet",
    "Port scan sweep","Malformed TCP segment",
]

async def run(server: str, port: int, username: str, password: str):
    http = f"http://{server}:{port}"
    ws   = f"ws://{server}:{port}"

    print(f"\n{'='*55}")
    print(f"  UniAccess Flood Simulator")
    print(f"  Target  : {http}")
    print(f"  Flooder : {username}")
    print(f"{'='*55}\n")

    async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=15)) as s:
        # Register
        print("📝 Registering...")
        try:
            async with s.post(f"{http}/auth/register",
                    json={"username": username, "password": password}) as r:
                if r.status == 200:   print("   ✅ Registered")
                elif r.status == 409: print("   ℹ️  Already exists")
                else: print(f"   ⚠️  {r.status}")
        except aiohttp.ClientConnectorError:
            print(f"❌ Cannot reach {http}"); return

        # Login
        print("🔐 Logging in...")
        token = None
        async with s.post(f"{http}/auth/login",
                json={"username": username, "password": password}) as r:
            if r.status == 200:
                token = (await r.json())["token"]
                print("   ✅ Logged in")
            elif r.status == 403:
                print("   🚫 BLOCKED"); return
            else:
                print(f"   ❌ {r.status}"); return

        # WebSocket
        enc    = urllib.parse.quote(token, safe="")
        ws_url = f"{ws}/ws/client/{username}?token={enc}"
        print(f"\n🔌 Connecting WebSocket...")

        total = 0; burst = 0; blocked = False

        async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=None, connect=10)) as ws_s:
            try:
                async with ws_s.ws_connect(ws_url, heartbeat=20) as sock:
                    print("   ✅ Connected!\n")
                    print(f"   {'TIME':<10} {'BURST':<8} {'PROTO':<8} {'TYPE':<30} TOTAL")
                    print(f"   {'-'*65}")

                    while True:
                        try:
                            msg = await asyncio.wait_for(sock.receive(), timeout=0.05)
                            if msg.type == aiohttp.WSMsgType.TEXT:
                                d = json.loads(msg.data)
                                if d.get("type") == "blocked":
                                    print(f"\n{'='*55}")
                                    print("🚫  BLOCKED BY ADMINISTRATOR")
                                    print(f"    {d.get('message','')}")
                                    print(f"{'='*55}")
                                    blocked = True
                                    break
                            elif msg.type in (aiohttp.WSMsgType.CLOSED,
                                              aiohttp.WSMsgType.ERROR):
                                print("\n⚠️  Connection closed.")
                                break
                        except asyncio.TimeoutError:
                            pass

                        proto = random.choice(PROTOCOLS)
                        ftype = random.choice(TYPES)
                        pkts  = random.randint(50, 200)
                        await sock.send_json({"type": "flood", "packets": pkts})
                        total += pkts; burst += 1
                        print(f"   {datetime.now().strftime('%H:%M:%S'):<10}"
                              f" #{burst:<6} {proto:<8} {ftype:<30} {total:,}",
                              flush=True)
                        await asyncio.sleep(random.uniform(0.1, 0.5))

            except aiohttp.WSServerHandshakeError as e:
                print(f"❌ Handshake failed: {e.status}")
            except aiohttp.ClientConnectorError as e:
                print(f"❌ Cannot connect: {e}")
            except Exception as e:
                if not blocked:
                    print(f"\n❌ {type(e).__name__}: {e}")

    print(f"\n{'✅' if blocked else '⛔'} Stopped. Total packets: {total:,}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--server",   default="192.168.0.104")
    p.add_argument("--port",     default=8000, type=int)
    p.add_argument("--username", default="flooder1")
    p.add_argument("--password", default="flood123")
    a = p.parse_args()
    try:
        asyncio.run(run(a.server, a.port, a.username, a.password))
    except KeyboardInterrupt:
        print("\n\n⛔ Stopped.")