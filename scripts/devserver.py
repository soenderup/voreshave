#!/usr/bin/env python3
"""Lokal dev-server uden caching.

Sender Cache-Control: no-store på alle svar, så browseren aldrig cacher
localhost-ressourcer. Det forhindrer at projekter der deler samme faste
port (8080) viser hinandens cachede filer (logo, CSS, JS m.m.).

Serverer fra current working directory - dev-start.sh cd'er til projektmappen
før start, præcis som 'python3 -m http.server' gjorde.

Brug: devserver.py [PORT]   (default 8080)
"""
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    HTTPServer(('', port), NoCacheHandler).serve_forever()
