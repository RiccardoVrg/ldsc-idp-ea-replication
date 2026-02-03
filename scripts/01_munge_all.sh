#!/bin/bash
#############################################
# STEP 1: MUNGE SUMSTATS
# Converte sumstats in formato LDSC standard
# Input: munge/big40_prepped/*.tsv.gz + neale/845.tsv.bgz
# Output: munge/big40_final/*.sumstats.gz + neale/845.sumstats.gz
# Tempo: ~2-3 ore
#############################################

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc
source ~/ldsc_project/config.sh

echo "================================================================"
echo "STEP 1: MUNGE SUMMARY STATISTICS"
echo "================================================================"

# Trova riferimenti LD scores e weights
LD=$(find $REF_DIR/eur_w_ld_chr -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')
W=$(find $REF_DIR/weights_hm3_no_hla -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')

echo "LD scores: $LD"
echo "Weights: $W"
echo ""

# Crea cartelle output
mkdir -p $MUNGE_DIR/big40_final
mkdir -p $MUNGE_DIR/neale

#############################################
# 1A. MUNGE BIG40 (172 IDP)
#############################################
echo "--- MUNGE BIG40 IDP ---"
MUNGED=0
FAILED=0
TOTAL=$(ls $MUNGE_DIR/big40_prepped/*.tsv.gz | wc -l)

for f in $MUNGE_DIR/big40_prepped/*.tsv.gz; do
    base=$(basename $f .tsv.gz)
    out=$MUNGE_DIR/big40_final/$base
    
    # Skip se già fatto
    if [ -f "${out}.sumstats.gz" ]; then
        ((MUNGED++))
        continue
    fi
    
    echo -n "[$(( MUNGED + FAILED + 1 ))/$TOTAL] Munge $base ... "
    
    # Munge
    if munge_sumstats.py \
        --sumstats "$f" \
        --out "$out" \
        --snp rsid \
        --a1 a1 \
        --a2 a2 \
        --p P \
        --signed-sumstats beta,0 \
        --N 33000 \
        > /dev/null 2>&1; then
        echo "✓"
        ((MUNGED++))
    else
        echo "✗ FAILED"
        ((FAILED++))
    fi
done

echo ""
echo "BIG40 Summary:"
echo "  ✓ Munged: $MUNGED/$TOTAL"
echo "  ✗ Failed: $FAILED/$TOTAL"
echo ""

#############################################
# 1B. MUNGE NEALE EA (845)
#############################################
echo "--- MUNGE NEALE EA ---"
EA_OUT="$MUNGE_DIR/neale/845"

if [ -f "${EA_OUT}.sumstats.gz" ]; then
    echo "✓ EA already munged"
else
    echo -n "Munge EA (phenotype 845) ... "
    
    if munge_sumstats.py \
        --sumstats "$SUMSTATS_DIR/neale/845.gwas.imputed_v3.both_sexes.tsv.bgz" \
        --out "$EA_OUT" \
        --p pval \
        --snp variant \
        --a1 minor_allele \
        --signed-sumstats beta,0 \
        --N 361194 \
        > /dev/null 2>&1; then
        echo "✓"
    else
        echo "✗ FAILED"
    fi
fi

echo ""
echo "================================================================"
echo "STEP 1 COMPLETED"
echo "Output: munge/big40_final/*.sumstats.gz (172 files)"
echo "        munge/neale/845.sumstats.gz"
echo "================================================================"