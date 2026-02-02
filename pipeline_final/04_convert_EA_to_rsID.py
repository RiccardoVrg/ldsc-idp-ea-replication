#!/usr/bin/env python
import gzip

# Crea mapping chr:pos:a1:a2 -> rsID da file BIG40
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
        except:
            pass

print("Mapping: %d variants" % len(mapping))

# Converti EA da chr:pos a rsID
converted = 0
failed = 0
with gzip.open('/home/vergnano/ldsc_project/munge/neale/845.sumstats.gz', 'rt') as fin:
    with gzip.open('/home/vergnano/ldsc_project/munge/neale/845_rsid.sumstats.gz', 'wt') as fout:
        header = next(fin)
        fout.write(header)
        
        for line in fin:
            fields = line.strip().split('\t')
            snp = fields[0]
            if snp in mapping:
                fields[0] = mapping[snp]
                fout.write('\t'.join(fields) + '\n')
                converted += 1
            else:
                failed += 1

print("Converted: %d (%.1f%%)" % (converted, 100.0*converted/(converted+failed)))
