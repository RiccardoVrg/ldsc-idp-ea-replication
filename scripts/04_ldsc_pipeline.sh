#!/bin/bash
set -e
source ~/ldsc_project/config.sh

LOG=$LOGS_DIR/ldsc_pipeline.log

echo "==============================================================================="
echo "                         LDSC PIPELINE - FULL RUN"
echo "==============================================================================="
echo "Start: $(date)" | tee $LOG
echo ""

# Trova file di riferimento
echo "Ricerca file di riferimento..." | tee -a $LOG
HM3=$(find $REF_DIR -name "w_hm3.snplist" -type f 2>/dev/null | head -1)
LD_FILE=$(find $REF_DIR/eur_w_ld_chr -name "*.l2.ldscore.gz" 2>/dev/null | head -1)
W_FILE=$(find $REF_DIR/weights_hm3_no_hla -name "*.l2.ldscore.gz" 2>/dev/null | head -1)

if [ -z "$HM3" ]; then
    echo "❌ ERRORE: w_hm3.snplist non trovato!" | tee -a $LOG
    exit 1
fi

if [ -z "$LD_FILE" ]; then
    echo "❌ ERRORE: LD scores non trovati!" | tee -a $LOG
    exit 1
fi

# Estrai prefix (rimuovi .N.l2.ldscore.gz)
LD_PREFIX=$(echo "$LD_FILE" | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')
W_PREFIX=$(echo "$W_FILE" | sed 's/\.[0-9]*\.l2\.ldscore\.gz$//')

echo "File di riferimento:" | tee -a $LOG
echo "  HM3: $HM3" | tee -a $LOG
echo "  LD prefix: $LD_PREFIX" | tee -a $LOG
echo "  W prefix: $W_PREFIX" | tee -a $LOG
echo ""

# Conta file da processare
TOTAL_FILES=$(ls $SUMSTATS_DIR/big40_33k/*.txt.gz 2>/dev/null | wc -l)
echo "File BIG40 da processare: $TOTAL_FILES" | tee -a $LOG
echo ""

# ===========================================================================
# STEP 1: Conversione BIG40 (log10P -> P)
# ===========================================================================
echo "=== STEP 1/5: CONVERSIONE BIG40 ===" | tee -a $LOG
mkdir -p $MUNGE_DIR/big40_prepped

CONVERTED=0
SKIPPED=0

for infile in $SUMSTATS_DIR/big40_33k/*.txt.gz; do
    base=$(basename $infile .txt.gz)
    outfile=$MUNGE_DIR/big40_prepped/${base}.tsv.gz
    
    if [ -f "$outfile" ]; then
        ((SKIPPED++))
        continue
    fi
    
    # Conversione con awk
    zcat "$infile" | awk '
    BEGIN {
        OFS="\t"
        print "chr", "rsid", "pos", "a1", "a2", "beta", "se", "P"
    }
    NR > 1 {
        logp = $8
        p = 10^(-logp)
        print $1, $2, $3, $4, $5, $6, $7, p
    }
    ' | gzip > "$outfile"
    
    ((CONVERTED++))
    
    if [ $((CONVERTED % 10)) -eq 0 ]; then
        echo "  Convertiti: $CONVERTED/$TOTAL_FILES" | tee -a $LOG
    fi
done

echo "✓ Conversione completata: $CONVERTED convertiti, $SKIPPED già presenti" | tee -a $LOG
echo ""

# ===========================================================================
# STEP 2: Munge BIG40
# ===========================================================================
echo "=== STEP 2/5: MUNGE BIG40 ===" | tee -a $LOG
mkdir -p $MUNGE_DIR/big40_33k

MUNGED=0
SKIPPED=0
FAILED=0

for infile in $MUNGE_DIR/big40_prepped/*.tsv.gz; do
    base=$(basename $infile .tsv.gz)
    outprefix=$MUNGE_DIR/big40_33k/$base
    
    if [ -f "${outprefix}.sumstats.gz" ]; then
        ((SKIPPED++))
        continue
    fi
    
    echo "Munge: $base" | tee -a $LOG
    
    if munge_sumstats.py \
        --sumstats "$infile" \
        --out "$outprefix" \
        --merge-alleles "$HM3" \
        --snp rsid \
        --a1 a1 \
        --a2 a2 \
        --beta beta \
        --se se \
        --p P \
        --N 33000 \
        >> $LOG 2>&1; then
        
        ((MUNGED++))
        if [ $((MUNGED % 10)) -eq 0 ]; then
            echo "  Munged: $MUNGED/$TOTAL_FILES" | tee -a $LOG
        fi
    else
        echo "  ❌ FAILED: $base" | tee -a $LOG
        ((FAILED++))
    fi
done

echo "✓ Munge BIG40 completato: $MUNGED munged, $SKIPPED già presenti, $FAILED falliti" | tee -a $LOG
echo ""

# ===========================================================================
# STEP 3: Munge Neale EA 845
# ===========================================================================
echo "=== STEP 3/5: MUNGE NEALE EA 845 ===" | tee -a $LOG
mkdir -p $MUNGE_DIR/neale

EA845_RAW="$SUMSTATS_DIR/neale/845.gwas.imputed_v3.both_sexes.tsv.bgz"
EA845_OUT="$MUNGE_DIR/neale/845"

if [ ! -f "$EA845_RAW" ]; then
    echo "❌ ERRORE: File EA 845 non trovato: $EA845_RAW" | tee -a $LOG
    exit 1
fi

if [ -f "${EA845_OUT}.sumstats.gz" ]; then
    echo "✓ EA 845 già munged, skip" | tee -a $LOG
else
    echo "Munge EA 845..." | tee -a $LOG
    
    munge_sumstats.py \
        --sumstats "$EA845_RAW" \
        --out "$EA845_OUT" \
        --merge-alleles "$HM3" \
        --p pval \
        --snp variant \
        --a1 minor_allele \
        --signed-sumstats beta,0 \
        --N 361194 \
        | tee -a $LOG
    
    if [ -f "${EA845_OUT}.sumstats.gz" ]; then
        echo "✓ EA 845 munged" | tee -a $LOG
    else
        echo "❌ ERRORE: Munge EA 845 fallito" | tee -a $LOG
        exit 1
    fi
fi

echo ""

# ===========================================================================
# STEP 4: Calcolo h² per tutti IDP
# ===========================================================================
echo "=== STEP 4/5: CALCOLO h² ===" | tee -a $LOG
mkdir -p $OUTPUT_DIR/h2

SUMSTATS_COUNT=$(ls $MUNGE_DIR/big40_33k/*.sumstats.gz 2>/dev/null | wc -l)
echo "IDP da analizzare: $SUMSTATS_COUNT" | tee -a $LOG

H2_DONE=0
H2_SKIPPED=0
H2_FAILED=0

for sumstat in $MUNGE_DIR/big40_33k/*.sumstats.gz; do
    base=$(basename $sumstat .sumstats.gz)
    outprefix=$OUTPUT_DIR/h2/$base
    
    if [ -f "${outprefix}.log" ]; then
        ((H2_SKIPPED++))
        continue
    fi
    
    echo "h²: $base" | tee -a $LOG
    
    if ldsc.py \
        --h2 "$sumstat" \
        --ref-ld-chr "$LD_PREFIX" \
        --w-ld-chr "$W_PREFIX" \
        --out "$outprefix" \
        >> $LOG 2>&1; then
        
        ((H2_DONE++))
        
        if [ $((H2_DONE % 10)) -eq 0 ]; then
            echo "  Completati: $H2_DONE/$SUMSTATS_COUNT" | tee -a $LOG
        fi
    else
        echo "  ❌ FAILED: $base" | tee -a $LOG
        ((H2_FAILED++))
    fi
done

echo "✓ h² completato: $H2_DONE calcolati, $H2_SKIPPED già presenti, $H2_FAILED falliti" | tee -a $LOG
echo ""

# ===========================================================================
# STEP 5: Calcolo rg (IDP × EA 845)
# ===========================================================================
echo "=== STEP 5/5: CALCOLO rg (IDP × EA 845) ===" | tee -a $LOG
mkdir -p $OUTPUT_DIR/rg

EA845_SUMSTATS="$MUNGE_DIR/neale/845.sumstats.gz"

if [ ! -f "$EA845_SUMSTATS" ]; then
    echo "❌ ERRORE: EA 845 sumstats non trovato" | tee -a $LOG
    exit 1
fi

RG_DONE=0
RG_SKIPPED=0
RG_FAILED=0

for sumstat in $MUNGE_DIR/big40_33k/*.sumstats.gz; do
    base=$(basename $sumstat .sumstats.gz)
    outprefix=$OUTPUT_DIR/rg/${base}_x_EA845
    
    if [ -f "${outprefix}.log" ]; then
        ((RG_SKIPPED++))
        continue
    fi
    
    echo "rg: $base × EA845" | tee -a $LOG
    
    if ldsc.py \
        --rg "$sumstat","$EA845_SUMSTATS" \
        --ref-ld-chr "$LD_PREFIX" \
        --w-ld-chr "$W_PREFIX" \
        --out "$outprefix" \
        >> $LOG 2>&1; then
        
        ((RG_DONE++))
        
        if [ $((RG_DONE % 10)) -eq 0 ]; then
            echo "  Completati: $RG_DONE/$SUMSTATS_COUNT" | tee -a $LOG
        fi
    else
        echo "  ❌ FAILED: $base" | tee -a $LOG
        ((RG_FAILED++))
    fi
done

echo "✓ rg completato: $RG_DONE calcolati, $RG_SKIPPED già presenti, $RG_FAILED falliti" | tee -a $LOG
echo ""

# ===========================================================================
# SUMMARY FINALE
# ===========================================================================
echo "==============================================================================="
echo "                           PIPELINE COMPLETATA"
echo "==============================================================================="
echo "Fine: $(date)"
echo ""
echo "SUMMARY:"
echo "  BIG40 convertiti: $CONVERTED"
echo "  BIG40 munged: $MUNGED"
echo "  EA 845 munged: ✓"
echo "  h² calcolati: $H2_DONE"
echo "  rg calcolati: $RG_DONE"
echo ""
echo "OUTPUT:"
echo "  h² results: $OUTPUT_DIR/h2/"
echo "  rg results: $OUTPUT_DIR/rg/"
echo "  Log completo: $LOG"
echo "==============================================================================="
