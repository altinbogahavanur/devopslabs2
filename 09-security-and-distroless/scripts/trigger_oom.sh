#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "=========================================================="
echo "💥 DOCKER CGROUPS VE OOMKILLED (EXIT CODE 137) TESTİ 💥"
echo "=========================================================="

echo -e "\n[1/4] Stres Testi İmajı Derleniyor..."
docker build -t memory-stress:v1 ./stress-app > /dev/null

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
OOM_STATUS=$(docker inspect oom-victim --format '{{.State.OOMKilled}}')
echo "State.OOMKilled: $OOM_STATUS"

echo -e "\n[4/4] Konteyner Temizleniyor..."
docker rm -f oom-victim > /dev/null
echo "Tamamlandı!"
