#!/bin/bash
source ~/ldsc_project/config.sh

echo "================================================================"
echo "STEP 4: EXTRACT RESULTS TO CSV (FIXED)"
echo "================================================================"

mkdir -p $OUTPUT_DIR/results

#############################################
# 4A. ESTRAI h²
#############################################
echo "--- Extracting h² results ---"

H2_CSV="$OUTPUT_DIR/results/h2_results.csv"
echo "IDP,h2,h2_se,h2_z,h2_pval,lambda_gc" > "$H2_CSV"

for f in $OUTPUT_DIR/h2/*.log; do
    # Skip se è un _run.log
    [[ "$f" == *"_run.log" ]] && continue
    
    idp=$(basename "$f" .log)
    
    # Estrai valori (parsing corretto)
    h2=$(grep "Total Observed scale h2:" "$f" | awk '{print $5}')
    se=$(grep "Total Observed scale h2:" "$f" | awk '{print $7}' | tr -d '()')
    z=$(grep "Total Observed scale h2:" "$f" | awk '{print $9}' | tr -d '()')
    pval=$(grep "Total Observed scale h2:" "$f" | awk '{print $11}' | tr -d '()')
    lambda=$(grep "Lambda GC:" "$f" | awk '{print $3}')
    
    echo "$idp,$h2,$se,$z,$pval,$lambda" >> "$H2_CSV"
done

# Rimuovi righe vuote
sed -i '/,,,,/d' "$H2_CSV"

echo "✓ h² results: $H2_CSV"
wc -l "$H2_CSV"
echo ""

#############################################
# 4B. ESTRAI rg (se esistono)
#############################################
echo "--- Extracting rg results ---"

RG_CSV="$OUTPUT_DIR/results/rg_results.csv"
echo "IDP,rg,rg_se,rg_z,rg_pval" > "$RG_CSV"

if ls $OUTPUT_DIR/rg/*_x_EA845.log 1> /dev/null 2>&1; then
    for f in $OUTPUT_DIR/rg/*_x_EA845.log; do
        [[ "$f" == *"_run.log" ]] && continue
        
        idp=$(basename "$f" _x_EA845.log)
        
        # Parsing tabella rg (riga con p1 p2)
        line=$(grep -A1 "p1.*p2" "$f" | tail -1)
        
        if [ -n "$line" ]; then
            rg=$(echo "$line" | awk '{print $3}')
            se=$(echo "$line" | awk '{print $4}')
            z=$(echo "$line" | awk '{print $5}')
            pval=$(echo "$line" | awk '{print $6}')
            
            echo "$idp,$rg,$se,$z,$pval" >> "$RG_CSV"
        fi
    done
    
    sed -i '/,,,/d' "$RG_CSV"
    echo "✓ rg results: $RG_CSV"
    wc -l "$RG_CSV"
else
    echo "⚠ No rg results found (run Step 3 first)"
fi

echo ""
echo "================================================================"
echo "STEP 4 COMPLETED"
echo "Results:"
echo "  - h²: $H2_CSV ($(wc -l < $H2_CSV) rows)"
if [ -f "$RG_CSV" ]; then
    echo "  - rg: $RG_CSV ($(wc -l < $RG_CSV) rows)"
fi
echo "================================================================"
