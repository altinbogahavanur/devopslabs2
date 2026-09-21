import time
import sys

print("🔥 Bellek tüketim simülasyonu başlatıldı...", flush=True)
data = []
step = 1

while True:
    try:
        print(f"[{step}. sn] 25 MB bellek tahsis ediliyor...", flush=True)
        # 25 MB'lık bayt dizisi tahsis et ve referansı sakla (GC temizlemesin)
        data.append(bytearray(25 * 1024 * 1024))
        step += 1
        time.sleep(1)
    except MemoryError:
        print("Bellek hatası alındı!", flush=True)
        sys.exit(1)
