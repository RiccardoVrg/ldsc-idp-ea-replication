#!/bin/bash
# FIX CRITICAL: I file .M da Zenodo erano sbagliati (10M invece di 1.2M SNPs)
# Questo causava h² > 1 (impossibile!)

cd ~/ldsc_project/ref/eur_w_ld_chr

echo "Ricalcolo file .M corretti..."
for i in {1..22}; do
    count=$(zcat ${i}.l2.ldscore.gz | tail -n +2 | wc -l)
    echo "$count" > ${i}.l2.M
    echo "Chr $i: $count SNPs"
done

echo "Verifica totale:"
cat *.l2.M | awk '{sum+=$1} END {print "Total M:", sum}'
