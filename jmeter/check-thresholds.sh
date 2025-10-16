#!/bin/bash
# check-thresholds.sh – validación simple de SLA/SLO globales
# dar permisos de ejecución chmod +x check-thresholds.sh


RESULTS_FILE=$1
P95_THRESHOLD=500
ERROR_THRESHOLD=1.0

if [ -z "$RESULTS_FILE" ]; then
  echo "❌ Uso: $0 <archivo_results.jtl>"
  exit 1
fi

if [ ! -f "$RESULTS_FILE" ]; then
  echo "❌ No existe el archivo $RESULTS_FILE"
  exit 1
fi

echo "=== Validando SLA/SLO ==="
# Contar total y errores
TOTAL=$(awk -F',' 'NR>1{t++} END{print t}' "$RESULTS_FILE")
ERRORS=$(awk -F',' 'NR>1{if($8!="true") e++} END{print e+0}' "$RESULTS_FILE")
ERROR_RATE=$(awk "BEGIN {if ($TOTAL>0) print ($ERRORS/$TOTAL)*100; else print 0}")

# Calcular P95 (columna 2 = elapsed)
P95=$(awk -F',' 'NR>1{a[NR]=$2} END{n=asort(a); idx=int(n*0.95); print a[idx]}' "$RESULTS_FILE")

printf "➡️  Total samples: %s | Errors: %s (%.2f%%)\n" "$TOTAL" "$ERRORS" "$ERROR_RATE"
printf "➡️  P95: %.0f ms | Threshold: %d ms\n" "$P95" "$P95_THRESHOLD"

# Evaluar umbrales
FAIL=0
if (( $(echo "$P95 > $P95_THRESHOLD" | bc -l) )); then
  echo "⚠️  P95 supera el umbral permitido ($P95 ms > $P95_THRESHOLD ms)"
  FAIL=1
fi
if (( $(echo "$ERROR_RATE > $ERROR_THRESHOLD" | bc -l) )); then
  echo "⚠️  Error Rate supera el umbral ($ERROR_RATE % > $ERROR_THRESHOLD %)"
  FAIL=1
fi

if [ $FAIL -eq 1 ]; then
  echo "❌  No cumple SLA/SLO → fallar pipeline"
  exit 1
else
  echo "✅  Cumple con los SLA/SLO definidos"
  exit 0
fi