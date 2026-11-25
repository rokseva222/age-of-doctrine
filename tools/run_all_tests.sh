#!/bin/bash
# Tüm *_test.gd dosyalarını headless çalıştırır; her biri için HATA/SCRIPT ERROR sayısını /tmp/aod_tests/summary.txt'ye yazar.
cd "$(dirname "$0")/.."
mkdir -p /tmp/aod_tests; [ -n "${RESUME:-}" ] || : > /tmp/aod_tests/summary.txt; touch /tmp/aod_tests/summary.txt
for f in tools/*_test.gd; do
  n=$(basename "$f" .gd)
  grep -q "^$n rc=" /tmp/aod_tests/summary.txt && continue
  case " ${SKIP_TESTS:-} " in *" $n "*) continue;; esac
  timeout ${TEST_TIMEOUT:-180} godot --headless --path . -s "$f" > /tmp/aod_tests/$n.log 2>&1
  rc=$?
  bad=$(grep -v "HATA SAYISI=0" "/tmp/aod_tests/$n.log" | grep -c -E "^HATA|SCRIPT ERROR|Parse Error" )
  echo "$n rc=$rc hata=$bad" >> /tmp/aod_tests/summary.txt
done
echo BITTI >> /tmp/aod_tests/summary.txt
