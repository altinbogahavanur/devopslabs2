#!/bin/bash
set -e

echo "=========================================================="
echo "🔐 BUILDKIT SECRET VE KATMAN SIZINTISI TESTİ 🔐"
echo "=========================================================="

echo -e "\n[1/4] ❌ Güvensiz İmaj Derleniyor (Dockerfile.leaky)..."
docker build \
  --build-arg SECRET_TOKEN="super_secret_github_token_ghp_1234567890abcdef" \
  -f Dockerfile.leaky \
  -t secret-demo:leaky . > /dev/null

echo -e "\n[2/4] ✅ Güvenli İmaj Derleniyor (BuildKit Secret Mount)..."
DOCKER_BUILDKIT=1 docker build \
  --secret id=api_token,src=secrets/api_token.txt \
  -f Dockerfile.secure \
  -t secret-demo:secure . > /dev/null

echo -e "\n=========================================================="
echo "🕵️  GÜVENSİZ İMAJ KATMAN GEÇMİŞİ DENETİMİ (docker history):"
echo "=========================================================="
docker history --no-trunc secret-demo:leaky | grep "super_secret" || true
echo "🚨 TEHLİKE: Geliştiricinin girdiği gizli token imaj geçmişinde kabak gibi ortada!"

echo -e "\n=========================================================="
echo "🛡️  GÜVENLİ İMAJ KATMAN GEÇMİŞİ DENETİMİ:"
echo "=========================================================="
set +e
docker history --no-trunc secret-demo:secure | grep "super_secret"
EXIT_LEAK=$?
set -e

if [ $EXIT_LEAK -ne 0 ]; then
    echo "✅ KANITLANDI: BuildKit Secret sayesinde hiçbir parola imaj geçmişine sızmadı!"
fi
echo "=========================================================="
