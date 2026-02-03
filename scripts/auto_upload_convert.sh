#!/bin/bash
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc
source ~/ldsc_project/config.sh

echo "=== AUTO UPLOAD + CONVERT ==="

BATCH_SIZE=25
PC_USER="root"
PC_HOST="10.187.143.48"  # Cambia con IP del tuo PC se diverso
PC_PATH="~/backup_big40/big40_33k"

while true; do
    # Conta file già convertiti
    CONVERTED=$(ls $MUNGE_DIR/big40_prepped/*.tsv.gz 2>/dev/null | wc -l)
    echo "File convertiti: $CONVERTED/120"
    
    [ $CONVERTED -ge 120 ] && { echo "✅ COMPLETATO!"; break; }
    
    # Spazio disponibile (in GB)
    AVAIL=$(df -BG ~ | tail -1 | awk '{print $4}' | sed 's/G//')
    echo "Spazio disponibile: ${AVAIL}GB"
    
    [ $AVAIL -lt 10 ] && { echo "⚠️ Spazio insufficiente"; break; }
    
    # Calcola quanti file caricare
    FILES_TO_LOAD=$((AVAIL / 1))  # ~1GB per file
    [ $FILES_TO_LOAD -gt $BATCH_SIZE ] && FILES_TO_LOAD=$BATCH_SIZE
    
    echo "Carico prossimi $FILES_TO_LOAD file..."
    
    # Lista IDP già convertiti
    ls $MUNGE_DIR/big40_prepped/*.tsv.gz 2>/dev/null | sed 's|.*/||; s/.tsv.gz//' | sort > /tmp/converted.txt
    
    # Richiedi password una volta
    echo "Inserisci password PC per rsync:"
    read -s PC_PASSWORD
    
    # Trova e carica file mancanti
    LOADED=0
    for id in $(cat $FILTERS_DIR/idp_lists/big40_ids_ALL.txt | head -120); do
        grep -q "^${id}$" /tmp/converted.txt && continue
        [ -f "$SUMSTATS_DIR/big40_33k/${id}.txt.gz" ] && continue
        
        echo "Download: ${id}.txt.gz"
        sshpass -p "$PC_PASSWORD" rsync -az ${PC_USER}@${PC_HOST}:${PC_PATH}/${id}.txt.gz $SUMSTATS_DIR/big40_33k/ 2>/dev/null
        
        ((LOADED++))
        [ $LOADED -ge $FILES_TO_LOAD ] && break
    done
    
    echo "Caricati: $LOADED file"
    
    # Converti
    echo "Conversione..."
    bash convert_big40_FIXED.sh
    
    # Cancella originali
    rm -f $SUMSTATS_DIR/big40_33k/*.txt.gz
    
    echo "Batch completato. Spazio: $(df -h ~ | tail -1 | awk '{print $4}')"
    echo ""
done

echo "=== FINE ==="
