#!/bin/bash
set -e

# Attiva ambiente (necessario per script nohup)
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc

source ~/ldsc_project/config.sh

LOG=$LOGS_DIR/ldsc_continue.log
echo "=== PIPELINE (da STEP 2) ===" | tee $LOG
echo "Start: $(date)" | tee -a $LOG

HM3=$(find $REF_DIR -name "w_hm3.snplist" -type f | head -1)
LD=$(find $REF_DIR/eur_w_ld_chr -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')
W=$(find $REF_DIR/weights_hm3_no_hla -name "*.l2.ldscore.gz" | head -1 | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')

echo "Riferimenti:" | tee -a $LOG
echo "  HM3: $HM3" | tee -a $LOG
echo "  LD: $LD" | tee -a $LOG
echo "  W: $W" | tee -a $LOG

TOTAL=$(ls $MUNGE_DIR/big40_prepped/*.tsv.gz 2>/dev/null | wc -l)
echo "File da processare: $TOTAL" | tee -a $LOG
echo ""

echo "=== STEP 2: MUNGE BIG40 ===" | tee -a $LOG
mkdir -p $MUNGE_DIR/big40_33k
MUNGED=0
for f in $MUNGE_DIR/big40_prepped/*.tsv.gz; do
    base=$(basename $f .tsv.gz)
    out=$MUNGE_DIR/big40_33k/$base
    
    if [ -f "${out}.sumstats.gz" ]; then
        ((MUNGED++))
        continue
    fi
    
    echo "Munge [$((MUNGED+1))/$TOTAL]: $base" | tee -a $LOG
    
    if munge_sumstats.py --sumstats "$f" --out "$out" --merge-alleles "$HM3" \
        --snp rsid --a1 a1 --a2 a2 --beta beta --se se --p P --N 33000 >> $LOG 2>&1; then
        ((MUNGED++))
    else
        echo "  ❌ FAILED: $base" | tee -a $LOG
    fi
done
echo "✓ Munge BIG40: $MUNGED/$TOTAL" | tee -a $LOG

echo ""
echo "=== STEP 3: MUNGE NEALE ===" | tee -a $LOG
mkdir -p $MUNGE_DIR/neale
EA_OUT="$MUNGE_DIR/neale/845"

if [ ! -f "${EA_OUT}.sumstats.gz" ]; then
    echo "Munge EA 845..." | tee -a $LOG
    munge_sumstats.py --sumstats "$SUMSTATS_DIR/neale/845.gwas.imputed_v3.both_sexes.tsv.bgz" \
        --out "$EA_OUT" --merge-alleles "$HM3" \
        --p pval --snp variant --a1 minor_allele --signed-sumstats beta,0 --N 361194 >> $LOG 2>&1
    echo "✓ EA 845 munged" | tee -a $LOG
else
    echo "✓ EA 845 già munged" | tee -a $LOG
fi

echo ""
echo "=== STEP 4: h² ===" | tee -a $LOG
mkdir -p $OUTPUT_DIR/h2
H2_DONE=0
SUMSTATS_TOTAL=$(ls $MUNGE_DIR/big40_33k/*.sumstats.gz 2>/dev/null | wc -l)

for f in $MUNGE_DIR/big40_33k/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/h2/$base
    
    if [ -f "${out}.log" ]; then
        ((H2_DONE++))
        continue
    fi
    
    echo "h² [$((H2_DONE+1))/$SUMSTATS_TOTAL]: $base" | tee -a $LOG
    
    if ldsc.py --h2 "$f" --ref-ld-chr "$LD" --w-ld-chr "$W" --out "$out" >> $LOG 2>&1; then
        ((H2_DONE++))
    else
        echo "  ❌ FAILED: $base" | tee -a $LOG
    fi
done
echo "✓ h²: $H2_DONE/$SUMSTATS_TOTAL" | tee -a $LOG

echo ""
echo "=== STEP 5: rg ===" | tee -a $LOG
mkdir -p $OUTPUT_DIR/rg
RG_DONE=0
EA_SS="$MUNGE_DIR/neale/845.sumstats.gz"

for f in $MUNGE_DIR/big40_33k/*.sumstats.gz; do
    base=$(basename $f .sumstats.gz)
    out=$OUTPUT_DIR/rg/${base}_x_EA845
    
    if [ -f "${out}.log" ]; then
        ((RG_DONE++))
        continue
    fi
    
    echo "rg [$((RG_DONE+1))/$SUMSTATS_TOTAL]: $base" | tee -a $LOG
    
    if ldsc.py --rg "$f","$EA_SS" --ref-ld-chr "$LD" --w-ld-chr "$W" --out "$out" >> $LOG 2>&1; then
        ((RG_DONE++))
    else
        echo "  ❌ FAILED: $base" | tee -a $LOG
    fi
done
echo "✓ rg: $RG_DONE/$SUMSTATS_TOTAL" | tee -a $LOG

echo ""
echo "==============================================================================="
echo "                      PIPELINE COMPLETATA"
echo "==============================================================================="
echo "Fine: $(date)"
echo "Munged: $MUNGED/$TOTAL"
echo "h²: $H2_DONE/$SUMSTATS_TOTAL"
echo "rg: $RG_DONE/$SUMSTATS_TOTAL"
