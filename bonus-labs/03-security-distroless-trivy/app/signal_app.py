import time
import signal
import sys
import os

print(f"🚀 Servis başlatıldı. PID: {os.getpid()}", flush=True)

if os.environ.get("HANDLE_SIGTERM") == "true":
    def on_sigterm(signum, frame):
        print("\n🛑 SIGTERM sinyali yakalandı! Veritabanı ve açık soketler kapatılıyor...", flush=True)
        print("💾 Bellekteki veriler diske kaydedildi.", flush=True)
        print("✅ Graceful shutdown başarıyla tamamlandı (Exit 0).", flush=True)
        sys.exit(0)
    signal.signal(signal.SIGTERM, on_sigterm)

while True:
    time.sleep(1)
