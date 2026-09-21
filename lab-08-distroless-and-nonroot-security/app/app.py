from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import time

class SecureHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            # Güvenli geçici alana (/tmp) veri yazmayı dene
            try:
                with open('/tmp/last_access.log', 'w') as f:
                    f.write(f"Access time: {time.time()}\n")
                tmp_writable = True
            except Exception:
                tmp_writable = False

            # Salt okunur kök dizine (/root_test.txt) dosya yazmayı dene (Engellenmeli!)
            try:
                with open('/root_test.txt', 'w') as f:
                    f.write("Hacked!\n")
                root_writable = True
            except Exception:
                root_writable = False

            response = {
                "service": "Hardened Secure Container",
                "running_uid": os.getuid(),
                "running_gid": os.getgid(),
                "is_root": os.getuid() == 0,
                "read_only_rootfs_active": not root_writable,
                "tmp_writable": tmp_writable,
                "security_status": "CIS Benchmark Compliant"
            }
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response, indent=2).encode())
        else:
            self.send_response(404)
            self.end_headers()

def run():
    # 8080 portunu dinle (Non-root kullanıcılar 1024 üzeri portları varsayılan olarak dinleyebilir)
    server = HTTPServer(('0.0.0.0', 8080), SecureHandler)
    print("🔒 Güvenli Hardened Sunucu 8080 portunda çalışıyor...")
    server.serve_forever()

if __name__ == '__main__':
    run()
