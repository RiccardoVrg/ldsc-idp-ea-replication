#!/bin/bash
source ~/ldsc_project/config.sh

echo "=== DOWNLOAD BIG40 (FIXED) ==="

IDP_LIST=$FILTERS_DIR/idp_lists/big40_ids_ALL.txt
TOTAL=$(wc -l < $IDP_LIST)
BASE_URL="https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k"

i=0
SUCCESS=0
FAILED=0

while read id; do
    ((i++))
    FILE="${id}.txt.gz"
    DEST="$SUMSTATS_DIR/big40_33k/$FILE"
    
    echo -n "[$i/$TOTAL] $FILE ... "
    
    # RIMUOVI -f, AGGIUNGI -L
    if curl -L -s -m 180 -o "$DEST" "$BASE_URL/$FILE" 2>/dev/null && \
       [ -f "$DEST" ] && gzip -t "$DEST" 2>/dev/null; then
        SIZE=$(du -h "$DEST" | cut -f1)
        echo "✓ ($SIZE)"
        ((SUCCESS++))
    else
        rm -f "$DEST"
        echo "❌"
        ((FAILED++))
    fi
    
    sleep 0.3
done < "$IDP_LIST"

echo ""
echo "Download: $SUCCESS/$TOTAL | Falliti: $FAILED/$TOTAL"
