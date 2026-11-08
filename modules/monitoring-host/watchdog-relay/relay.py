# Alertmanager's webhook only sends POST, and Uptime Kuma 1.x's push route only
# accepts GET. Each Watchdog notification from Alertmanager becomes one GET to
# the push URL, and a failed push is answered with 502 so Alertmanager counts it.

import http.server
import urllib.request

PUSH_URL_FILE = "/run/secrets/watchdog_push_url"


class Relay(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            # Read on every request, so a changed URL needs no restart
            with open(PUSH_URL_FILE) as f:
                push_url = f.read().strip()
            # Cloudflare's browser integrity check refuses Python's default
            # user agent with a 403 (error 1010) before Uptime Kuma sees it
            request = urllib.request.Request(
                push_url, headers={"User-Agent": "monitoring-loki-watchdog-relay"}
            )
            with urllib.request.urlopen(request, timeout=10):
                pushed = True
        except Exception as e:
            pushed = False
            # The type only: the message could include the URL, which is a secret
            print(f"push to Uptime Kuma failed: {type(e).__name__}", flush=True)
        self.send_response(204 if pushed else 502)
        self.end_headers()

    def log_message(self, *args):
        pass


http.server.HTTPServer(("0.0.0.0", 8080), Relay).serve_forever()
