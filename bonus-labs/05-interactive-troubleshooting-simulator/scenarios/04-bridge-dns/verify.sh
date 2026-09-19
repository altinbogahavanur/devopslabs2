#!/usr/bin/env bash

PING_OUT=$(docker exec srv-app ping -c 1 -W 2 srv-db 2>&1 || true)

if echo "$PING_OUT" | grep -q "1 packets transmitted, 1 packets received"; then
  echo "✅ TEBRİKLER! srv-app ve srv-db konteynerleri birbirini isimle çözümledi ve ping başarılı oldu!"
  exit 0
else
  echo "❌ HATA: srv-app 'srv-db' ismini çözümleyemiyor veya ping yanıt vermiyor!"
  echo "   Çıktı: $PING_OUT"
  echo "   İpucu: Varsayılan bridge ağı Dahili DNS sunmaz. Kullanıcı tanımlı özel bir bridge ağı oluşturup bağlayın."
  exit 1
fi
