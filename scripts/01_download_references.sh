#!/bin/bash
set -e
source ~/ldsc_project/config.sh

echo "=== DOWNLOAD FILE RIFERIMENTO LDSC ==="
echo "Destinazione: $REF_DIR"
cd $REF_DIR

# Download da Zenodo
echo "Download da Zenodo..."
wget -q --show-progress https://zenodo.org/records/7768714/files/1000G_Phase3_weights_hm3_no_MHC.tgz
wget -q --show-progress https://zenodo.org/records/7768714/files/sumstats.tgz

# Estrazione
echo "Estrazione archivi..."
tar -xzf 1000G_Phase3_weights_hm3_no_MHC.tgz
tar -xzf sumstats.tgz

# Organizzazione file
echo "Organizzazione file..."
mkdir -p eur_w_ld_chr weights_hm3_no_hla

# Trova e copia w_hm3.snplist
find . -name "w_hm3.snplist" -type f -exec cp {} ./w_hm3.snplist \; 2>/dev/null || true

# Trova e copia weights
find . -name "*weights*.l2.ldscore.gz" -exec cp {} weights_hm3_no_hla/ \; 2>/dev/null || true

# Usa weights come LD scores (funziona per h² base)
cp weights_hm3_no_hla/* eur_w_ld_chr/ 2>/dev/null || true

echo ""
echo "=== VERIFICA ==="
if [ -f "w_hm3.snplist" ]; then
    echo "✓ w_hm3.snplist presente"
    ls -lh w_hm3.snplist
else
    echo "❌ w_hm3.snplist mancante!"
fi

WEIGHTS_COUNT=$(ls weights_hm3_no_hla/*.gz 2>/dev/null | wc -l)
LD_COUNT=$(ls eur_w_ld_chr/*.gz 2>/dev/null | wc -l)

echo "Weights: $WEIGHTS_COUNT file"
echo "LD scores: $LD_COUNT file"

if [ $WEIGHTS_COUNT -gt 20 ] && [ $LD_COUNT -gt 20 ]; then
    echo ""
    echo "✅ RIFERIMENTI PRONTI!"
    echo "Prossimo: bash 02_download_big40.sh"
else
    echo ""
    echo "⚠️ Alcuni file potrebbero mancare"
fi
