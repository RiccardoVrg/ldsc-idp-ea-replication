#!/bin/bash
set -e

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc

cd ~/ldsc_project

TOTAL=$(ls ~/ldsc_project/munge/big40_final/*.sumstats.gz | wc -l)
echo "Starting h2 calculation for $TOTAL IDPs"

i=0
for sumstats in ~/ldsc_project/munge/big40_final/*.sumstats.gz; do
    i=$((i+1))
    idp=$(basename $sumstats .sumstats.gz)
    
    echo "[$i/$TOTAL] Processing $idp..."
    
    ldsc.py \
        --h2 $sumstats \
        --ref-ld-chr ~/ldsc_project/ref/eur_w_ld_chr/ \
        --w-ld-chr ~/ldsc_project/ref/eur_w_ld_chr/ \
        --out ~/ldsc_project/out/h2/${idp} \
        > ~/ldsc_project/out/h2/logs/${idp}.log 2>&1
    
    echo "  Done"
done

echo "COMPLETED: $TOTAL IDPs"
