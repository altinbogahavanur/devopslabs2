#!/usr/bin/env bash

RUNNING=$(docker inspect -f '{{.State.Running}}' memory-crasher 2>/dev/null || echo "false")
OOM=$(docker inspect -f '{{.State.OOMKilled}}' memory-crasher 2>/dev/null || echo "false")
EXITCODE=$(docker inspect -f '{{.State.ExitCode}}' memory-crasher 2>/dev/null || echo "-1")

if [ "$RUNNING" = "true" ] && [ "$OOM" = "false" ]; then
  echo "✅ TEBRİKLER! memory-crasher konteynerinin bellek sınırı artırıldı, OOMKilled olmadan çalışmaya devam ediyor!"
  exit 0
else
  echo "❌ HATA: memory-crasher hala sağlıklı çalışmıyor!"
  echo "   Çalışıyor mu: $RUNNING | OOMKilled: $OOM | ExitCode: $EXITCODE"
  echo "   İpucu: Bellek sınırını en az 256m seviyesine yükseltin."
  exit 1
fi
