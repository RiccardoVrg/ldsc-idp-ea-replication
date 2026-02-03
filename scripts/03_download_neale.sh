#!/bin/bash
set -e
source ~/ldsc_project/config.sh

echo "=== DOWNLOAD NEALE EA 845 ==="
echo ""

EA845="$SUMSTATS_DIR/neale/845.gwas.imputed_v3.both_sexes.tsv.bgz"

if [ -f "$EA845" ]; then
    echo "✓ EA 845 già presente"
    SIZE=$(du -h "$EA845" | cut -f1)
    echo "  Dimensione: $SIZE"
else
    echo "Download EA 845..."
    wget -q --show-progress -O "$EA845" \
        https://broad-ukb-sumstats-us-east-1.s3.amazonaws.com/round2/additive-tsvs/845.gwas.imputed_v3.both_sexes.tsv.bgz
    
    if [ -f "$EA845" ]; then
        SIZE=$(du -h "$EA845" | cut -f1)
        echo "✓ Download completato: $SIZE"
    else
        echo "❌ Download fallito!"
        exit 1
    fi
fi

echo ""
echo "Verifica file (prime 3 righe):"
zcat "$EA845" | head -3

echo ""
echo "✅ Neale EA 845 pronto!"
echo "Prossimo: bash 04_ldsc_pipeline.sh"
