#!/bin/bash
# EA sumstats preparation with allele alignment fix

set -e
source ~/miniconda3/etc/profile.d/conda.sh
conda activate ldsc

cd ~/ldsc_project/sumstats/neale

echo "Step 1: Preprocess EA (extract A1/A2 from variant ID)"
python << 'PYEOF'
import gzip
count = 0
with gzip.open('845.gwas.imputed_v3.both_sexes.tsv.bgz', 'rt') as fin:
    with gzip.open('845_preprocessed.tsv.gz', 'wt') as fout:
        header = next(fin).strip().split('\t')
        fout.write('SNP\tA1\tA2\tbeta\tse\tpval\tN\n')
        for line in fin:
            fields = line.strip().split('\t')
            variant = fields[0]
            minor_allele = fields[1]
            beta, se, pval, n = fields[8], fields[9], fields[11], fields[5]
            if ':' in variant and len(variant.split(':')) == 4:
                parts = variant.split(':')
                a1_var, a2_var = parts[2], parts[3]
                a1 = a1_var if minor_allele == a1_var else a2_var
                a2 = a2_var if minor_allele == a1_var else a1_var
                fout.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (variant, a1, a2, beta, se, pval, n))
                count += 1
print("Processed %d variants" % count)
PYEOF

echo "Step 2: Munge (filters INDEL automatically)"
munge_sumstats.py \
    --sumstats 845_preprocessed.tsv.gz \
    --out ~/ldsc_project/munge/neale/845_SIMPLE \
    --p pval --snp SNP --a1 A1 --a2 A2 \
    --signed-sumstats beta,0 --N-col N

echo "Step 3: Convert to rsID"
cd ~/ldsc_project/munge/neale
python << 'PYEOF'
import gzip
mapping = {}
with gzip.open('/home/vergnano/ldsc_project/munge/big40_prepped_OLD/0165.tsv.gz', 'rt') as f:
    next(f)
    for line in f:
        try:
            fields = line.strip().split('\t')
            if len(fields) >= 5:
                chr, rsid, pos, a1, a2 = fields[:5]
                key = "%s:%s:%s:%s" % (chr.lstrip('0'), pos, a1, a2)
                mapping[key] = rsid
        except: pass
converted = failed = 0
with gzip.open('845_SIMPLE.sumstats.gz', 'rt') as fin:
    with gzip.open('845_FINAL_SIMPLE.sumstats.gz', 'wt') as fout:
        header = next(fin)
        fout.write(header)
        for line in fin:
            fields = line.strip().split('\t')
            if fields[0] in mapping:
                fields[0] = mapping[fields[0]]
                fout.write('\t'.join(fields) + '\n')
                converted += 1
            else: failed += 1
print("Converted: %d (%.1f%%)" % (converted, 100.0*converted/(converted+failed)))
PYEOF

echo "EA preparation complete: munge/neale/845_FINAL_SIMPLE.sumstats.gz"
