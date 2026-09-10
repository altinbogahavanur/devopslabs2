from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os

class ProfileHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        response = {
            "service": "Profile Demo Service",
            "environment": os.getenv("APP_ENV", "development"),
            "debug_mode": os.getenv("DEBUG", "false"),
            "message": "Compose Profiles & Overrides Başarıyla Çalışıyor"
        }
        self.wfile.write(json.dumps(response, indent=2).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), ProfileHandler)
    print("🚀 Server 8080 portunda dinliyor...")
    server.serve_forever()
