#!/bin/bash
#############################################
# STEP 2: HERITABILITY (h²)
# Calcola SNP heritability per ogni IDP
# Input: munge/big40_final/*.sumstats.gz
# Output: out/h2/*.log (172 files)
# Tempo: ~1-2 ore
#############################################

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc
source ~/ldsc_project/config.sh

echo "================================================================"
echo "STEP 2: SNP HERITABILITY (h²)"
echo "================================================================"

# Trova riferimenti
LD=$(find $REF_DIR/eur_w_ld_chr -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')
W=$(find $REF_DIR/weights_hm3_no_hla -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')

# Crea cartella output
mkdir -p $OUTPUT_DIR/h2

H2_DONE=0
TOTAL=$(ls $MUNGE_DIR/big40_final/*.sumstats.gz | wc -l)

for f in $MUNGE_DIR/big40_final/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/h2/$base
    
    # Skip se già fatto
    if [ -f "${out}.log" ]; then
        ((H2_DONE++))
        continue
    fi
    
    echo "[$((H2_DONE+1))/$TOTAL] Computing h² for $base"
    
    ldsc.py \
        --h2 "$f" \
        --ref-ld-chr "$LD" \
        --w-ld-chr "$W" \
        --out "$out" \
        > "${out}_run.log" 2>&1
    
    # Mostra risultato
    if [ -f "${out}.log" ]; then
        grep "Total Observed scale h2" "${out}.log" | tail -1
        ((H2_DONE++))
    fi
done

echo ""
echo "================================================================"
echo "STEP 2 COMPLETED"
echo "h² computed: $H2_DONE/$TOTAL"
echo "Output: out/h2/*.log"
echo "================================================================"