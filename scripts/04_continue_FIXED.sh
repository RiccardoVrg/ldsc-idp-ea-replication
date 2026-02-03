#!/bin/bash
set -e

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc
source ~/ldsc_project/config.sh

LOG=$LOGS_DIR/ldsc_fixed.log
echo "=== PIPELINE FIXED ===" | tee $LOG

HM3=$(find $REF_DIR -name "w_hm3.snplist" -type f | head -1)
LD=$(find $REF_DIR/eur_w_ld_chr -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')
W=$(find $REF_DIR/weights_hm3_no_hla -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')

echo "STEP 2: MUNGE BIG40" | tee -a $LOG
MUNGED=0
TOTAL=$(ls $MUNGE_DIR/big40_prepped/*.tsv.gz | wc -l)

for f in $MUNGE_DIR/big40_prepped/*.tsv.gz; do
    base=$(basename $f .tsv.gz)
    out=$MUNGE_DIR/big40_33k/$base
    
    [ -f "${out}.sumstats.gz" ] && { ((MUNGED++)); continue; }
    
    echo "Munge [$((MUNGED+1))/$TOTAL]: $base" | tee -a $LOG
    
    # USA signed-sumstats invece di --beta --se
    if munge_sumstats.py \
        --sumstats "$f" \
        --out "$out" \
        --merge-alleles "$HM3" \
        --snp rsid \
        --a1 a1 \
        --a2 a2 \
        --p P \
        --signed-sumstats beta,0 \
        --N 33000 >> $LOG 2>&1; then
        ((MUNGED++))
    else
        echo "  ❌ FAILED" | tee -a $LOG
    fi
done

echo "✓ Munged: $MUNGED/$TOTAL" | tee -a $LOG

echo "STEP 3: MUNGE NEALE" | tee -a $LOG
EA_OUT="$MUNGE_DIR/neale/845"
[ ! -f "${EA_OUT}.sumstats.gz" ] && \
    munge_sumstats.py --sumstats "$SUMSTATS_DIR/neale/845.gwas.imputed_v3.both_sexes.tsv.bgz" \
        --out "$EA_OUT" --merge-alleles "$HM3" \
        --p pval --snp variant --a1 minor_allele --signed-sumstats beta,0 --N 361194 >> $LOG 2>&1

echo "STEP 4: h²" | tee -a $LOG
H2_DONE=0
for f in $MUNGE_DIR/big40_33k/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/h2/$base
    [ -f "${out}.log" ] && { ((H2_DONE++)); continue; }
    echo "h² [$((H2_DONE+1))]: $base" | tee -a $LOG
    ldsc.py --h2 "$f" --ref-ld-chr "$LD" --w-ld-chr "$W" --out "$out" >> $LOG 2>&1 && ((H2_DONE++))
done

echo "STEP 5: rg" | tee -a $LOG
RG_DONE=0
EA_SS="$MUNGE_DIR/neale/845.sumstats.gz"
for f in $MUNGE_DIR/big40_33k/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/rg/${base}_x_EA845
    [ -f "${out}.log" ] && { ((RG_DONE++)); continue; }
    echo "rg [$((RG_DONE+1))]: $base" | tee -a $LOG
    ldsc.py --rg "$f","$EA_SS" --ref-ld-chr "$LD" --w-ld-chr "$W" --out "$out" >> $LOG 2>&1 && ((RG_DONE++))
done

echo "COMPLETATO! Munged:$MUNGED h²:$H2_DONE rg:$RG_DONE" | tee -a $LOG
