#!/usr/bin/env bash

if [ -s /tmp/perm-test/app.log ]; then
  echo "✅ TEBRİKLER! Konteyner host klasörüne başarıyla yazabildi! (/tmp/perm-test/app.log mevcut ve veri içeriyor)."
  exit 0
else
  echo "❌ HATA: /tmp/perm-test/app.log dosyası oluşturulamadı veya boş!"
  echo "   İpucu: Host üzerindeki /tmp/perm-test dizin izinlerini ve sahipliğini kontrol edin (ls -ld /tmp/perm-test)."
  exit 1
fi
