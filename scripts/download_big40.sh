#!/bin/bash
source ~/ldsc_project/config.sh

IDP_LIST=$FILTERS_DIR/idp_lists/big40_ids_ALL.txt
TOTAL=$(wc -l < $IDP_LIST)
BASE_URL="https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k"

echo "Download $TOTAL file..."

i=0
while read id; do
    ((i++))
    FILE="${id}.txt.gz"
    DEST="$SUMSTATS_DIR/big40_33k/$FILE"
    
    if [ -f "$DEST" ]; then
        echo "[$i/$TOTAL] Skip $FILE"
        continue
    fi
    
    echo -n "[$i/$TOTAL] $FILE ... "
    curl -f -s -m 120 -o "$DEST" "$BASE_URL/$FILE" && echo "OK" || echo "FAIL"
    sleep 0.5
done < "$IDP_LIST"

echo "DONE!"
