import asyncio
import subprocess
import os
import random
from datetime import datetime
from typing import Callable

INTERFACE = os.getenv("WIRESHARK_IFACE", "")
_cb: Callable = None

def set_callback(cb: Callable):
    global _cb
    _cb = cb

def _find_iface():
    if INTERFACE:
        return INTERFACE
    try:
        r = subprocess.run(["tshark", "-D"], capture_output=True, text=True, timeout=5)
        for line in r.stdout.strip().split("\n"):
            if any(x in line.lower() for x in ["wi-fi","wlan","wireless","wifi"]):
                return line.strip().split(" ")[0].rstrip(".")
        for line in r.stdout.strip().split("\n"):
            if any(x in line.lower() for x in ["ethernet","eth"]):
                return line.strip().split(" ")[0].rstrip(".")
        lines = r.stdout.strip().split("\n")
        if lines:
            return lines[0].strip().split(" ")[0].rstrip(".")
    except Exception:
        pass
    return None

async def start_capture(broadcast_fn: Callable):
    try:
        r = subprocess.run(["tshark","--version"], capture_output=True, timeout=5)
        if r.returncode != 0:
            raise Exception("bad")
    except Exception:
        print("⚠️  tshark not found — using simulation")
        await _simulate(broadcast_fn)
        return

    iface = _find_iface()
    if not iface:
        print("⚠️  No interface — using simulation")
        await _simulate(broadcast_fn)
        return

    print(f"🦈 Capturing on: {iface}")
    while True:
        try:
            proc = await asyncio.create_subprocess_exec(
                "tshark", "-i", iface,
                "-T", "fields",
                "-e", "ip.src", "-e", "ip.dst",
                "-e", "_ws.col.Protocol",
                "-e", "frame.len",
                "-e", "_ws.col.Info",
                "-l",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.DEVNULL)
            async for line in proc.stdout:
                raw = line.decode("utf-8", errors="ignore").strip()
                if not raw:
                    continue
                parts = raw.split("\t")
                if len(parts) < 4:
                    continue
                try:
                    await broadcast_fn({
                        "time":     datetime.now().strftime("%H:%M:%S"),
                        "src_ip":   parts[0] or "?.?.?.?",
                        "dst_ip":   parts[1] or "SERVER",
                        "protocol": parts[2] or "TCP",
                        "length":   int(parts[3]) if parts[3].isdigit() else 0,
                        "info":     parts[4][:100] if len(parts) > 4 else "",
                    })
                except Exception:
                    continue
        except Exception as e:
            print(f"[tshark] {e} — restarting in 3s")
            await asyncio.sleep(3)

async def _simulate(broadcast_fn: Callable):
    protocols = ["TCP","UDP","HTTP","DNS","TLS","ICMP"]
    infos = [
        "GET /api/status HTTP/1.1",
        "Standard query A google.com",
        "Client Hello TLS 1.3",
        "ACK Seq=1 Ack=2",
        "POST /upload HTTP/1.1",
        "200 OK",
        "TCP Keep-Alive",
    ]
    ips = ["192.168.0.10","192.168.0.11","192.168.0.12"]
    while True:
        await asyncio.sleep(0.5)
        try:
            await broadcast_fn({
                "time":     datetime.now().strftime("%H:%M:%S"),
                "src_ip":   random.choice(ips),
                "dst_ip":   "192.168.0.104",
                "protocol": random.choice(protocols),
                "length":   random.randint(60, 1500),
                "info":     random.choice(infos),
            })
        except Exception:
            pass