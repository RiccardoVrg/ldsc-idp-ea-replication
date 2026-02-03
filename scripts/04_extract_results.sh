#!/bin/bash
#############################################
# STEP 4: EXTRACT RESULTS
# Estrae risultati da file .log in CSV
# Input: out/h2/*.log + out/rg/*.log
# Output: results/h2_results.csv + results/rg_results.csv
#############################################

source ~/ldsc_project/config.sh

echo "================================================================"
echo "STEP 4: EXTRACT RESULTS TO CSV"
echo "================================================================"

mkdir -p $OUTPUT_DIR/results

#############################################
# 4A. ESTRAI h²
#############################################
echo "--- Extracting h² results ---"

H2_CSV="$OUTPUT_DIR/results/h2_results.csv"
echo "IDP,h2,h2_se,h2_pval" > "$H2_CSV"

for f in $OUTPUT_DIR/h2/*.log; do
    idp=$(basename $f .log)
    
    # Estrai h², SE, p-value
    h2=$(grep "Total Observed scale h2:" "$f" | awk '{print $5}')
    se=$(grep "Total Observed scale h2:" "$f" | awk '{print $7}' | tr -d '()')
    pval=$(grep "Lambda GC:" "$f" | awk '{print $3}')
    
    echo "$idp,$h2,$se,$pval" >> "$H2_CSV"
done

echo "✓ h² results: $H2_CSV"
echo ""

#############################################
# 4B. ESTRAI rg
#############################################
echo "--- Extracting rg results ---"

RG_CSV="$OUTPUT_DIR/results/rg_results.csv"
echo "IDP,rg,rg_se,rg_pval,rg_z" > "$RG_CSV"

for f in $OUTPUT_DIR/rg/*_x_EA845.log; do
    idp=$(basename $f _x_EA845.log)
    
    # Estrai rg, SE, Z, p-value
    line=$(grep -A1 "p1.*p2" "$f" | tail -1)
    rg=$(echo "$line" | awk '{print $3}')
    se=$(echo "$line" | awk '{print $4}')
    z=$(echo "$line" | awk '{print $5}')
    pval=$(echo "$line" | awk '{print $6}')
    
    echo "$idp,$rg,$se,$pval,$z" >> "$RG_CSV"
done

echo "✓ rg results: $RG_CSV"
echo ""

echo "================================================================"
echo "STEP 4 COMPLETED"
echo "Results:"
echo "  - h²: $H2_CSV"
echo "  - rg: $RG_CSV"
echo "================================================================"