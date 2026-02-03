#!/bin/bash
set -e
source ~/ldsc_project/config.sh

LOG=$LOGS_DIR/big40_download.log
echo "=== DOWNLOAD BIG40 (FIXED) ===" | tee $LOG

# Usa lista già creata
IDP_LIST=$FILTERS_DIR/idp_lists/big40_ids_ALL.txt

if [ ! -f "$IDP_LIST" ]; then
    echo "❌ Lista IDP non trovata: $IDP_LIST"
    exit 1
fi

TOTAL=$(wc -l < $IDP_LIST)
echo "IDP da scaricare: $TOTAL" | tee -a $LOG

BASE_URL="https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k"
SUCCESS=0
FAILED=0

while IFS= read -r id; do
    FILE="${id}.txt.gz"
    DEST="$SUMSTATS_DIR/big40_33k/$FILE"
    
    if [ -f "$DEST" ]; then
        echo "Skip: $FILE (già presente)" | tee -a $LOG
        ((SUCCESS++))
        continue
    fi
    
    echo -n "[$((SUCCESS+FAILED+1))/$TOTAL] Download: $FILE ... " | tee -a $LOG
    
    if wget -q -T 30 -O "$DEST" "$BASE_URL/$FILE" 2>>$LOG; then
        SIZE=$(du -h "$DEST" | cut -f1)
        echo "✓ ($SIZE)" | tee -a $LOG
        ((SUCCESS++))
    else
        echo "❌ FAILED" | tee -a $LOG
        rm -f "$DEST"
        ((FAILED++))
    fi
    
    sleep 0.3
done < "$IDP_LIST"

echo "" | tee -a $LOG
echo "=== COMPLETATO ===" | tee -a $LOG
echo "Successo: $SUCCESS/$TOTAL" | tee -a $LOG
echo "Falliti: $FAILED/$TOTAL" | tee -a $LOG
