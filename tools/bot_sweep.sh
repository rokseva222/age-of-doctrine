#!/bin/bash
# Tüm çağ ve senaryolarda oyuncu gibi oynayan botlar: her biri birkaç strateji, her turda invaryant denetimi.
# Kullanım: bash tools/bot_sweep.sh [tur=50]   Çıktı: /tmp/aod_sweep/summary.txt (sorunlu koşular "ISSUE" satırlarıyla)
cd "$(dirname "$0")/.."
TURNS=${1:-50}
OUT=/tmp/aod_sweep; mkdir -p $OUT; touch $OUT/summary.txt $OUT/issues.txt   # kaldığı yerden devam eder (yeniden başlatmaya dayanıklı)
STRATS=(conquer fuzz bloc)
run() {  # tür id ülke strateji seed
  grep -q "^$1 $2 $3 $4 rc=" $OUT/summary.txt && return
  local log=$OUT/$1_$2_$3_$4.log
  timeout ${RUN_TIMEOUT:-240} godot --headless --path . -s tools/agentB_play.gd -- $1 $2 "$3" $4 $TURNS $5 > $log 2>&1
  local rc=$?
  local err=$(grep -c -E "SCRIPT ERROR|Parse Error" $log)
  local iss=$(grep -c "^ISSUE" $log)
  echo "$1 $2 $3 $4 rc=$rc script_err=$err issue=$iss" >> $OUT/summary.txt
  if [ "$err" != "0" ] || [ "$iss" != "0" ] || [ "$rc" = "124" ]; then
    echo "== $1 $2 $3 $4 rc=$rc" >> $OUT/issues.txt
    grep -E "SCRIPT ERROR|^ISSUE" $log | sort | uniq -c | head -6 >> $OUT/issues.txt
  fi
}
# çağlar: önerilen ilk iki ülke × stratejiler
for id in $(python3 - <<'PY'
import json
print(' '.join(['ww1','ww2']+json.load(open('data/eras/index.json'))))
PY
); do
  for c in $(python3 - "$id" <<'PY'
import json,sys,re
i=sys.argv[1]
try:
    d=json.load(open('data/eras/%s.json'%i)); print(' '.join(x.replace(' ','_') for x in d.get('suggest',[])[:2]))
except Exception:
    print('Germany United_Kingdom' if i=='ww1' else 'Germany United_States')
PY
  ); do
    for s in "${STRATS[@]}"; do run era $id "${c//_/ }" $s 11; done
  done
done
# modern senaryolar
for sc in ukr twn irn ind kor cau kara reich balt napol siber; do
  for c in $(python3 - "$sc" <<'PY'
import sys
m={'ukr':'Ukraine Russia','twn':'Taiwan China','irn':'Iran Israel','ind':'India Pakistan','kor':'South_Korea North_Korea','cau':'Armenia Azerbaijan','kara':'Turkey Greece','reich':'Germany France','balt':'Poland Russia','napol':'France United_Kingdom','siber':'Russia China'}
print(m.get(sys.argv[1],'Turkey'))
PY
  ); do
    for s in "${STRATS[@]}"; do run scn $sc "${c//_/ }" $s 7; done
  done
done
echo BITTI >> $OUT/summary.txt
