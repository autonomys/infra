"""Serves a Subspace chain's slot and block times, read over its public RPC, for vmagent.

Every minute it reads the best block and the block WINDOW below it: each one's
slot from its pre-runtime digest and its time from Timestamp::Now. Proof of time
sets how long a slot lasts, so a timekeeper falling out of step shows here as
slots taking longer.

CHAIN_PROBE_TARGETS lists the chains as space-separated name=url pairs; the name
becomes the network label.
"""

import json
import os
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TARGETS = dict(pair.split("=", 1) for pair in os.environ["CHAIN_PROBE_TARGETS"].split())
PORT = int(os.environ.get("CHAIN_PROBE_PORT", "9180"))
WINDOW = 200
INTERVAL_SECONDS = 60

# twox128("Timestamp") ++ twox128("Now"), the storage key of pallet_timestamp's Now
TIMESTAMP_NOW_KEY = "0xf0c365c3cf59d671eb72da0e7a4113c49f1f0515f462cdcf84e0f1d6045dfcbb"

METRICS = {
    "subspace_chain_slot_seconds": f"Seconds per slot over the last {WINDOW} blocks",
    "subspace_chain_block_seconds": f"Seconds per block over the last {WINDOW} blocks",
    "subspace_chain_best_block": "Number of the best block",
    "subspace_chain_best_slot": "Slot of the best block",
    "subspace_chain_probe_success": "Whether the last read of the chain succeeded",
}

lock = threading.Lock()
latest = {name: {"subspace_chain_probe_success": 0} for name in TARGETS}


def rpc(url, method, params):
    # Cloudflare refuses Python's default User-Agent
    request = urllib.request.Request(
        url,
        data=json.dumps({"id": 1, "jsonrpc": "2.0", "method": method, "params": params}).encode(),
        headers={"Content-Type": "application/json", "User-Agent": "chain-probe"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        answer = json.load(response)
    if "error" in answer:
        raise RuntimeError(f"{method}: {answer['error']}")
    return answer["result"]


def slot_of(header):
    """The slot in the header's Subspace pre-runtime digest: a PreRuntime item (6)
    for engine SUB_, whose SCALE-encoded data is PreDigest variant 0 followed by
    the slot as a little-endian u64."""
    for log in header["digest"]["logs"]:
        item = bytes.fromhex(log[2:])
        if item[0] == 6 and item[1:5] == b"SUB_":
            data = 5 + {0: 1, 1: 2, 2: 4}[item[5] & 3]
            if item[data] != 0:
                raise ValueError(f"unknown PreDigest variant {item[data]}")
            return int.from_bytes(item[data + 1 : data + 9], "little")
    raise ValueError("no Subspace pre-runtime digest")


def block_at(url, number):
    block_hash = rpc(url, "chain_getBlockHash", [number])
    header = rpc(url, "chain_getHeader", [block_hash])
    millis = int.from_bytes(bytes.fromhex(rpc(url, "state_getStorage", [TIMESTAMP_NOW_KEY, block_hash])[2:]), "little")
    return slot_of(header), millis / 1000


def read(url):
    best = int(rpc(url, "chain_getHeader", [])["number"], 16)
    best_slot, best_time = block_at(url, best)
    old_slot, old_time = block_at(url, best - WINDOW)
    return {
        "subspace_chain_slot_seconds": (best_time - old_time) / (best_slot - old_slot),
        "subspace_chain_block_seconds": (best_time - old_time) / WINDOW,
        "subspace_chain_best_block": best,
        "subspace_chain_best_slot": best_slot,
        "subspace_chain_probe_success": 1,
    }


def poll():
    while True:
        for name, url in TARGETS.items():
            try:
                values = read(url)
            except Exception as error:
                print(f"{name}: {error}", flush=True)
                values = {"subspace_chain_probe_success": 0}
            with lock:
                latest[name] = values
        time.sleep(INTERVAL_SECONDS)


def render():
    lines = []
    with lock:
        for metric, help_text in METRICS.items():
            lines += [f"# HELP {metric} {help_text}", f"# TYPE {metric} gauge"]
            for name, values in latest.items():
                if metric in values:
                    lines.append(f'{metric}{{network="{name}"}} {values[metric]}')
    return ("\n".join(lines) + "\n").encode()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_error(404)
            return
        body = render()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    threading.Thread(target=poll, daemon=True).start()
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
