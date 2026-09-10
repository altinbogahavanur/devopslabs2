import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

PORT = int(os.environ.get("PORT", 8000))
APP_ENV = os.environ.get("APP_ENV", "production")

class SimpleApiHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health" or self.path == "/api/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {"status": "healthy", "service": "python-api", "env": APP_ENV}
            self.wfile.write(json.dumps(response).encode("utf-8"))
        elif self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            response = {
                "message": "Python DevOps API Basariyla Calisiyor!",
                "python_version": sys.version.split()[0],
                "port": PORT
            }
            self.wfile.write(json.dumps(response).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # stdout format
        sys.stdout.write(f"[{self.log_date_time_string()}] {format%args}\n")
        sys.stdout.flush()

if __name__ == "__main__":
    server_address = ("0.0.0.0", PORT)
    httpd = HTTPServer(server_address, SimpleApiHandler)
    print(f"🚀 Python HTTP Server baslatildi. Dinlenen port: {PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nSunucu kapatiliyor...")
        httpd.server_close()
