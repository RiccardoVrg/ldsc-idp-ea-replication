#!/bin/bash
source ~/ldsc_project/config.sh

echo "=== DOWNLOAD BIG40 (metodo ufficiale) ==="

IDP_LIST=$FILTERS_DIR/idp_lists/big40_ids_ALL.txt
TOTAL=$(wc -l < $IDP_LIST)
BASE_URL="https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k"

cd $SUMSTATS_DIR/big40_33k

i=0
while read id; do
    ((i++))
    FILE="${id}.txt.gz"
    
    if [ -f "$FILE" ] && gzip -t "$FILE" 2>/dev/null; then
        echo "[$i/$TOTAL] Skip: $FILE"
        continue
    fi
    
    echo -n "[$i/$TOTAL] $FILE ... "
    
    # USA IL COMANDO ESATTO DEL SITO
    if curl -O -L -C - "$BASE_URL/$FILE" 2>/dev/null && gzip -t "$FILE" 2>/dev/null; then
        echo "✓"
    else
        echo "❌"
        rm -f "$FILE"
    fi
    
    sleep 0.5
done < "$IDP_LIST"

echo "Completato: $(ls *.txt.gz | wc -l)/$TOTAL"
