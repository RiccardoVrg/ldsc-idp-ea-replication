#!/bin/bash
set -e
source ~/ldsc_project/config.sh

LOG_FILE=$LOGS_DIR/big40_download.log
echo "=== DOWNLOAD BIG40 IDP ===" | tee $LOG_FILE
echo "Data: $(date)" | tee -a $LOG_FILE
echo ""

# Scarica tabella IDP HTML
IDP_HTML=$FILTERS_DIR/idp_lists/BIG40-IDPs_v4.html
IDP_URL="https://open.win.ox.ac.uk/ukbiobank/big40/BIG40-IDPs_v4/IDPs.html"

if [ ! -f "$IDP_HTML" ]; then
    echo "Download tabella IDP..." | tee -a $LOG_FILE
    wget -q -O "$IDP_HTML" "$IDP_URL"
    echo "✓ Tabella scaricata" | tee -a $LOG_FILE
else
    echo "✓ Tabella già presente" | tee -a $LOG_FILE
fi

# Estrai IDP IDs con Python3
echo "Estrazione IDP IDs..." | tee -a $LOG_FILE

python3 << 'PYCODE' > $FILTERS_DIR/idp_lists/big40_ids_ALL.txt
import re
import sys

html_path = "$FILTERS_DIR/idp_lists/BIG40-IDPs_v4.html".replace("$FILTERS_DIR", "/home/vergnano/ldsc_project/filters")

with open(html_path, 'r') as f:
    html = f.read()

# Pattern di filtro
patterns = [
    r'aparc-Desikan_(?:rh|lh)_area',
    r'aseg_(?:rh|lh|global)_volume',
    r'IDP_dMRI_TBSS_FA'
]

ids = set()
cortical = set()
subcortical = set()
dmri = set()

# Estrai righe tabella
for row in re.findall(r'<tr[^>]*>(.*?)</tr>', html, re.DOTALL):
    tds = re.findall(r'<td[^>]*>(.*?)</td>', row, re.DOTALL)
    
    if len(tds) >= 3:
        # Estrai ID (prima colonna)
        id_raw = re.sub(r'<.*?>', '', tds[0])
        id4 = re.sub(r'[^\d]', '', id_raw).strip()
        
        # Estrai short name (terza colonna)
        short = re.sub(r'<.*?>', '', tds[2]).strip()
        
        if len(id4) == 4 and short:
            # Controlla pattern
            if re.search(patterns[0], short):
                cortical.add(id4)
                ids.add(id4)
            elif re.search(patterns[1], short):
                subcortical.add(id4)
                ids.add(id4)
            elif re.search(patterns[2], short):
                dmri.add(id4)
                ids.add(id4)

# Output lista completa ordinata
for id in sorted(ids):
    print(id)

# Log su stderr
print(f"Cortical: {len(cortical)}", file=sys.stderr)
print(f"Subcortical: {len(subcortical)}", file=sys.stderr)
print(f"dMRI: {len(dmri)}", file=sys.stderr)
print(f"TOTALE: {len(ids)}", file=sys.stderr)
PYCODE

# Conta IDP selezionati
TOTAL_IDP=$(wc -l < $FILTERS_DIR/idp_lists/big40_ids_ALL.txt)
echo "✓ IDP selezionati: $TOTAL_IDP" | tee -a $LOG_FILE
echo ""

# Download summary statistics
echo "Download summary statistics..." | tee -a $LOG_FILE
BASE_URL="https://open.win.ox.ac.uk/ukbiobank/big40/release2/stats33k"

i=0
SUCCESS=0
FAILED=0

while read id; do
    ((i++))
    FILE="${id}.txt.gz"
    DEST="$SUMSTATS_DIR/big40_33k/$FILE"
    
    # Skip se già presente
    if [ -f "$DEST" ]; then
        echo "[$i/$TOTAL_IDP] ✓ Skip: $FILE" | tee -a $LOG_FILE
        ((SUCCESS++))
        continue
    fi
    
    echo -n "[$i/$TOTAL_IDP] Download: $FILE " | tee -a $LOG_FILE
    
    # Download con retry (max 3 tentativi)
    DOWNLOAD_OK=0
    for attempt in {1..3}; do
        if wget -q -T 30 -t 1 -O "$DEST" "$BASE_URL/$FILE" 2>/dev/null; then
            DOWNLOAD_OK=1
            break
        else
            sleep $((2**attempt))
        fi
    done
    
    if [ $DOWNLOAD_OK -eq 1 ]; then
        SIZE=$(du -h "$DEST" | cut -f1)
        echo "✓ ($SIZE)" | tee -a $LOG_FILE
        ((SUCCESS++))
    else
        echo "❌ FAILED" | tee -a $LOG_FILE
        rm -f "$DEST"
        ((FAILED++))
    fi
    
    # Rate limiting
    sleep 0.3
done < $FILTERS_DIR/idp_lists/big40_ids_ALL.txt

# Summary
echo "" | tee -a $LOG_FILE
echo "=== DOWNLOAD COMPLETATO ===" | tee -a $LOG_FILE
echo "Successo: $SUCCESS/$TOTAL_IDP" | tee -a $LOG_FILE
echo "Falliti: $FAILED/$TOTAL_IDP" | tee -a $LOG_FILE

if [ $FAILED -eq 0 ]; then
    echo "✅ Tutti i file scaricati!" | tee -a $LOG_FILE
    echo "Prossimo: bash 03_download_neale.sh" | tee -a $LOG_FILE
else
    echo "⚠️ Alcuni download falliti" | tee -a $LOG_FILE
fi
