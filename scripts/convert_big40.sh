#!/bin/bash
source ~/ldsc_project/config.sh

echo "=== CONVERSIONE BIG40 OTTIMIZZATA ==="

mkdir -p $MUNGE_DIR/big40_prepped

TOTAL=$(ls $SUMSTATS_DIR/big40_33k/*.txt.gz | wc -l)
i=0

for infile in $SUMSTATS_DIR/big40_33k/*.txt.gz; do
    ((i++))
    base=$(basename $infile .txt.gz)
    outfile=$MUNGE_DIR/big40_prepped/${base}.tsv.gz
    
    if [ -f "$outfile" ]; then
        echo "[$i/$TOTAL] Skip: $base"
        continue
    fi
    
    echo -n "[$i/$TOTAL] Convert: $base ... "
    
    # Usa Python invece di awk (più efficiente per file grandi)
    python3 << PYEND | gzip > "$outfile"
import sys
import gzip

with gzip.open("$infile", "rt") as f:
    # Header
    print("chr\trsid\tpos\ta1\ta2\tbeta\tse\tP")
    
    # Skip header
    next(f)
    
    # Process lines
    for line in f:
        fields = line.strip().split()
        if len(fields) >= 8:
            chr, rsid, pos, a1, a2, beta, se, logp = fields[:8]
            try:
                p = 10 ** (-float(logp))
                print(f"{chr}\t{rsid}\t{pos}\t{a1}\t{a2}\t{beta}\t{se}\t{p}")
            except:
                continue
PYEND
    
    if [ -f "$outfile" ]; then
        echo "OK"
    else
        echo "FAIL"
    fi
done

echo ""
echo "Conversioni completate: $(ls $MUNGE_DIR/big40_prepped/*.tsv.gz | wc -l)/$TOTAL"
