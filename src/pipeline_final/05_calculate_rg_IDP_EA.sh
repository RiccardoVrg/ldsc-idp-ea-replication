#!/bin/bash
set -e

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc

cd ~/ldsc_project
mkdir -p out/rg/logs

EA_FILE="munge/neale/845_FINAL_SIMPLE.sumstats.gz"

if [ ! -f "$EA_FILE" ]; then
    echo "ERROR: $EA_FILE not found. Run 04_prepare_EA_sumstats.sh first"
    exit 1
fi

TOTAL=$(ls munge/big40_final/*.sumstats.gz | grep -v TEST | grep -v CHECK | grep -v FIXED | wc -l)
echo "Starting rg for $TOTAL IDPs with EA"

i=0
for sumstats in munge/big40_final/*.sumstats.gz; do
    idp=$(basename $sumstats .sumstats.gz)
    if [[ $idp == *"TEST"* ]] || [[ $idp == *"CHECK"* ]] || [[ $idp == *"FIXED"* ]]; then
        continue
    fi
    
    i=$((i+1))
    echo "[$i/$TOTAL] rg($idp, EA)..."
    
    ldsc.py \
        --rg $sumstats,$EA_FILE \
        --ref-ld-chr ref/eur_w_ld_chr/ \
        --w-ld-chr ref/eur_w_ld_chr/ \
        --no-check-alleles \
        --out out/rg/${idp}_EA \
        > out/rg/logs/${idp}_EA.log 2>&1
    
    echo "  Done"
done

echo "COMPLETED: $TOTAL rg calculations"
