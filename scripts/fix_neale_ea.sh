#!/bin/bash
# Pre-processa file Neale per LDSC
# Aggiunge colonna major_allele

INPUT="$HOME/ldsc_project/sumstats/neale/845.gwas.imputed_v3.both_sexes.tsv.bgz"
OUTPUT="$HOME/ldsc_project/sumstats/neale/845_fixed.tsv.gz"

echo "Pre-processing Neale EA file..."

zcat "$INPUT" | awk '
BEGIN {OFS="\t"}
NR==1 {
    # Header: aggiungi major_allele dopo minor_allele
    for(i=1; i<=NF; i++) {
        printf "%s%s", $i, (i<NF ? OFS : "")
        if($i == "minor_allele") printf "%smajor_allele", OFS
    }
    print ""
    next
}
{
    # Data: estrai alleli da variant (formato chr:pos:ref:alt)
    split($1, v, ":")
    ref = v[3]
    alt = v[4]
    minor = $2
    major = (minor == ref) ? alt : ref
    
    # Output con major_allele
    for(i=1; i<=NF; i++) {
        printf "%s%s", $i, (i<NF ? OFS : "")
        if(i == 2) printf "%s%s", major, OFS  # Dopo minor_allele
    }
    print ""
}
' | gzip > "$OUTPUT"

echo "✓ Fixed file: $OUTPUT"
