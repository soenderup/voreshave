#!/usr/bin/env python3
"""Lokal dev-server uden caching.

Sender Cache-Control: no-store på alle svar, så browseren aldrig cacher
localhost-ressourcer. Hvert projekt har sin egen unikke port (= egen origin),
men no-store er stadig et bælte-og-seler-værn mod at browseren serverer en
forældet udgave af en netop redigeret fil.

Serverer fra current working directory - dev-start.sh cd'er til projektmappen
før start. Brug: devserver.py [PORT]
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
