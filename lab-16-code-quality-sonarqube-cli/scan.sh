#!/bin/bash
set -e

SONAR_HOST="${SONAR_HOST:-http://127.0.0.1:19000/sonar}"
SONAR_TOKEN="${SONAR_TOKEN:-}"

# OS Kontrolü (Linux/Ubuntu için native host network, macOS için host.docker.internal)
if [ "$(uname)" = "Darwin" ]; then
  NETWORK_ARGS="--add-host=host.docker.internal:host-gateway"
  SONAR_CONTAINER_HOST=$(echo "$SONAR_HOST" | sed -E 's/127\.0\.0\.1|localhost/host.docker.internal/')
else
  NETWORK_ARGS="--network host"
  SONAR_CONTAINER_HOST="$SONAR_HOST"
fi

echo "=========================================================="
echo "SONARQUBE DOCKER CLI ILE STATIK KOD TARAMASI (SAST)"
echo "=========================================================="
echo "SonarQube URL: ${SONAR_HOST}"

if [ -z "${SONAR_TOKEN}" ]; then
  echo -e "\n[UYARI] SONAR_TOKEN belirtilmedi. Eger SonarQube'da authentication aktifse token gereklidir."
  echo "Ornek Kullanim: export SONAR_TOKEN='squ_xxx' && ./scan.sh"
fi

echo -e "\nDocker Scanner Konteyneri Calistiriliyor..."
docker run --rm \
  ${NETWORK_ARGS} \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.host.url="${SONAR_CONTAINER_HOST}" \
  -Dsonar.token="${SONAR_TOKEN}"

echo -e "\n=========================================================="
echo "TARAMA TAMAMLANDI! Sonucu tarayicinizdan inceleyin:"
echo "Adres: ${SONAR_HOST}"
echo "=========================================================="
