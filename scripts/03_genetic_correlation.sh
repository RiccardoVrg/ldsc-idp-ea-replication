#!/bin/bash
#############################################
# STEP 3: GENETIC CORRELATION (rg)
# Calcola correlazione genetica tra IDP e EA
# Input: munge/big40_final/*.sumstats.gz + munge/neale/845.sumstats.gz
# Output: out/rg/*_x_EA845.log (172 files)
# Tempo: ~2-3 ore
#############################################

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc
source ~/ldsc_project/config.sh

echo "================================================================"
echo "STEP 3: GENETIC CORRELATION (rg)"
echo "================================================================"

# Trova riferimenti
LD=$(find $REF_DIR/eur_w_ld_chr -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')
W=$(find $REF_DIR/weights_hm3_no_hla -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')

EA_SS="$MUNGE_DIR/neale/845.sumstats.gz"

# Verifica che EA esista
if [ ! -f "$EA_SS" ]; then
    echo "ERROR: EA sumstats not found at $EA_SS"
    echo "Run 01_munge_all.sh first!"
    exit 1
fi

# Crea cartella output
mkdir -p $OUTPUT_DIR/rg

RG_DONE=0
TOTAL=$(ls $MUNGE_DIR/big40_final/*.sumstats.gz | wc -l)

for f in $MUNGE_DIR/big40_final/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/rg/${base}_x_EA845
    
    # Skip se già fatto
    if [ -f "${out}.log" ]; then
        ((RG_DONE++))
        continue
    fi
    
    echo "[$((RG_DONE+1))/$TOTAL] Computing rg: $base × EA"
    
    ldsc.py \
        --rg "$f","$EA_SS" \
        --ref-ld-chr "$LD" \
        --w-ld-chr "$W" \
        --out "$out" \
        > "${out}_run.log" 2>&1
    
    # Mostra risultato
    if [ -f "${out}.log" ]; then
        grep "Genetic Correlation:" "${out}.log" | head -1
        ((RG_DONE++))
    fi
done

echo ""
echo "================================================================"
echo "STEP 3 COMPLETED"
echo "rg computed: $RG_DONE/$TOTAL"
echo "Output: out/rg/*.log"
echo "================================================================"