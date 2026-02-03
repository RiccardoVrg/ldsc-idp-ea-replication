#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc
source ~/ldsc_project/config.sh

echo "================================================================"
echo "STEP 2: SNP HERITABILITY (h²) - FIXED"
echo "================================================================"

# Path CORRETTI (con prefisso file)
LD_PREFIX="$REF_DIR/eur_w_ld_chr_FIXED/"
W_PREFIX="$REF_DIR/weights_hm3_no_hla_FIXED/"

# Verifica che esistano
if [ ! -f "${LD_PREFIX}.1.l2.ldscore.gz" ]; then
    echo "ERROR: LD file not found: ${LD_PREFIX}.1.l2.ldscore.gz"
    exit 1
fi

echo "LD prefix: $LD_PREFIX"
echo "W prefix: $W_PREFIX"
echo ""

mkdir -p $OUTPUT_DIR/h2

H2_DONE=0
FAILED=0
TOTAL=$(ls $MUNGE_DIR/big40_final/*.sumstats.gz | wc -l)

for f in $MUNGE_DIR/big40_final/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/h2/$base
    
    # Skip se già completato con successo
    if [ -f "${out}.log" ] && grep -q "Total Observed scale h2:" "${out}.log" 2>/dev/null; then
        ((H2_DONE++))
        continue
    fi
    
    echo "[$((H2_DONE+FAILED+1))/$TOTAL] Computing h² for $base"
    
    # Cancella log vecchi falliti
    rm -f "${out}.log" "${out}_run.log"
    
    ldsc.py \
        --h2 "$f" \
        --ref-ld-chr "$LD_PREFIX" \
        --w-ld-chr "$W_PREFIX" \
        --out "$out" 2>&1 | tee "${out}_run.log"
    
    # Verifica successo
    if grep -q "Total Observed scale h2:" "${out}.log" 2>/dev/null; then
        h2=$(grep "Total Observed scale h2:" "${out}.log" | awk '{print $5}')
        echo "  ✓ h² = $h2"
        ((H2_DONE++))
    else
        echo "  ✗ FAILED"
        ((FAILED++))
    fi
done

echo ""
echo "================================================================"
echo "STEP 2 COMPLETED"
echo "  ✓ Success: $H2_DONE/$TOTAL"
echo "  ✗ Failed: $FAILED/$TOTAL"
echo "Output: out/h2/*.log"
echo "================================================================"
