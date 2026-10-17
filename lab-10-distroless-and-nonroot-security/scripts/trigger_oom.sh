#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB10_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STRESS_DIR="${LAB10_DIR}/../lab-11-cgroups-resource-limits-and-oom/stress-app"

echo "=========================================================="
echo "💥 DOCKER CGROUPS VE OOMKILLED (EXIT CODE 137) TESTİ 💥"
echo "=========================================================="

echo -e "\n[1/4] Stres Testi İmajı Derleniyor..."
docker rm -f oom-victim 2>/dev/null || true

if [ -d "${STRESS_DIR}" ]; then
    docker build -t memory-stress:v1 "${STRESS_DIR}" > /dev/null
else
    docker build -t memory-stress:v1 - <<'EOF' > /dev/null
FROM python:3.12-alpine
WORKDIR /app
RUN echo -e 'import time, sys\ndata = []\nstep = 1\nwhile True:\n    try:\n        print(f"[{step}. sn] 25 MB tahsis ediliyor...", flush=True)\n        data.append(bytearray(25 * 1024 * 1024))\n        step += 1\n        time.sleep(1)\n    except MemoryError:\n        sys.exit(1)' > stress.py
CMD ["python", "-u", "stress.py"]
EOF
fi

echo -e "\n[2/4] Konteyner 80MB BELLEK SINIRI ile Başlatılıyor..."
echo "Konteyner her saniye 25MB tüketecek ve ~4. saniyede OOMKiller tarafından vurulacak!"

set +e
docker run --name oom-victim --memory=80m memory-stress:v1
EXIT_CODE=$?
set -e

echo -e "\n=========================================================="
echo "📊 KONTEYNER ÇIKIŞ ANALİZİ:"
echo "Terminal Çıkış Kodu (Exit Code): $EXIT_CODE"
echo "=========================================================="

if [ $EXIT_CODE -eq 137 ]; then
    echo "🎯 KANITLANDI: Çıkış Kodu 137 = 128 + 9 (SIGKILL)!"
    echo "Linux Çekirdeği Cgroups bellek sınırını aşan konteyneri zorla sonlandırdı."
fi

echo -e "\n[3/4] Docker Inspect ile OOMKilled Bayrağı Sorgulanıyor:"
OOM_STATUS=$(docker inspect oom-victim --format '{{.State.OOMKilled}}' 2>/dev/null || echo "bilinmiyor")
echo "State.OOMKilled: $OOM_STATUS"

echo -e "\n[4/4] Konteyner Temizleniyor..."
docker rm -f oom-victim > /dev/null 2>&1 || true
echo "Tamamlandı!"
