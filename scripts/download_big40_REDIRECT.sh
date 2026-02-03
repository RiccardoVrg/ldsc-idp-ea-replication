#!/bin/bash
source ~/ldsc_project/config.sh

echo "=== DOWNLOAD BIG40 (con redirect) ==="

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
    
    # CURL CON -L (segui redirect)
    for attempt in {1..3}; do
        curl -L -f -s -m 180 -o "$DEST" "$BASE_URL/$FILE" 2>/dev/null
        
        # Verifica gzip valido
        if [ -f "$DEST" ] && gzip -t "$DEST" 2>/dev/null; then
            SIZE=$(du -h "$DEST" | cut -f1)
            echo "✓ ($SIZE)"
            ((SUCCESS++))
            break
        else
            rm -f "$DEST"
            if [ $attempt -eq 3 ]; then
                echo "❌ FAIL"
                ((FAILED++))
            fi
        fi
    done
    
    sleep 0.3
done < "$IDP_LIST"

echo ""
echo "Successo: $SUCCESS/$TOTAL | Falliti: $FAILED/$TOTAL"
