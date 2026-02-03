#!/bin/bash
set -e
source ~/ldsc_project/config.sh

echo "=== DOWNLOAD BIG40 (CURL) ==="

IDP_LIST=$FILTERS_DIR/idp_lists/big40_ids_ALL.txt
TOTAL=$(wc -l < $IDP_LIST)
echo "IDP: $TOTAL"
echo ""

BASE_URL="https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k"
i=0
SUCCESS=0
FAILED=0

while IFS= read -r id; do
    ((i++))
    FILE="${id}.txt.gz"
    DEST="$SUMSTATS_DIR/big40_33k/$FILE"
    
    if [ -f "$DEST" ]; then
        echo "[$i/$TOTAL] Skip: $FILE"
        ((SUCCESS++))
        continue
    fi
    
    echo -n "[$i/$TOTAL] $FILE ... "
    
    if curl -f -s -m 120 -o "$DEST" "$BASE_URL/$FILE" 2>/dev/null; then
        SIZE=$(du -h "$DEST" | cut -f1)
        
        if gzip -t "$DEST" 2>/dev/null; then
            echo "OK ($SIZE)"
            ((SUCCESS++))
        else
            echo "CORROTTO"
            rm -f "$DEST"
            ((FAILED++))
        fi
    else
        echo "FAILED"
        rm -f "$DEST"
        ((FAILED++))
    fi
    
    sleep 0.5
done < "$IDP_LIST"

echo ""
echo "Completato: $SUCCESS/$TOTAL | Falliti: $FAILED"
