#!/bin/bash
source ~/ldsc_project/config.sh

echo "=== CONVERSIONE BIG40 FIXED ==="
# Rimuovi conversioni precedenti

mkdir -p $MUNGE_DIR/big40_prepped
TOTAL=$(ls $SUMSTATS_DIR/big40_33k/*.txt.gz | wc -l)
i=0

for infile in $SUMSTATS_DIR/big40_33k/*.txt.gz; do
    ((i++))
    base=$(basename $infile .txt.gz)
    outfile=$MUNGE_DIR/big40_prepped/${base}.tsv.gz
    
    echo -n "[$i/$TOTAL] $base ... "
    
    # USA LC_NUMERIC=C per forzare punto decimale
    LC_NUMERIC=C python3 << PYEND | gzip > "$outfile"
import sys
import gzip
import locale

# Forza locale USA per numeri
locale.setlocale(locale.LC_NUMERIC, 'C')

with gzip.open("$infile", "rt") as f:
    # Header
    print("chr\trsid\tpos\ta1\ta2\tbeta\tse\tP")
    
    # Skip header
    next(f)
    
    # Process
    for line in f:
        fields = line.strip().split()
        if len(fields) >= 8:
            chr, rsid, pos, a1, a2, beta, se, logp = fields[:8]
            try:
                p = 10 ** (-float(logp))
                # FORZA formato con punto
                print(f"{chr}\t{rsid}\t{pos}\t{a1}\t{a2}\t{beta}\t{se}\t{p:.10e}")
            except:
                continue
PYEND
    
    echo "OK"
done

echo "Conversioni: $(ls $MUNGE_DIR/big40_prepped/*.tsv.gz | wc -l)/$TOTAL"
