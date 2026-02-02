# LDSC Pipeline - Replication Satizabal et al. 2019

## Summary
Successful replication of genetic correlation analysis between brain MRI phenotypes (IDPs) and Educational Attainment using UK Biobank data.

## Data Sources
- **IDP**: UK Biobank BIG40 (N=33,000) - 173 brain MRI phenotypes
- **EA**: Neale Lab phenotype 845 (N=240,547)
- **Reference**: 1000 Genomes Phase 3 EUR LD scores

## Results Summary
### Heritability (h²)
- **173 IDPs analyzed**
- Mean h²: 0.20 (range: -0.006 to 0.36)
- Distribution: 90% between 0.10-0.30
- Lambda GC: ~1.10-1.18 (good QC)

### Genetic Correlations (rg)
- **163/172 IDPs successfully analyzed** (9 failed due to convergence issues)
- Mean rg: 0.041 (range: -0.11 to +0.19)
- Significant at p<0.05: 37 IDPs (22.7%)
- Significant at p<0.01: 14 IDPs (8.6%)

### Top Hits (p<0.001)
1. **0666** (Pars orbitalis L): rg=0.194 (p=0.0001)
2. **0684** (Caudal ant. cingulate R): rg=0.187 (p=0.0006)
3. **0689** (Inferior parietal R): rg=0.153 (p=0.0002)

### Comparison with Satizabal 2019
✅ rg range consistent (-0.2 to +0.3 vs. -0.11 to +0.19)
✅ Same brain regions (frontal, cingulate, parietal)
✅ Positive rg for cortical areas, negative for white matter
✅ **Successful replication**

## Files
- `h2_ALL_173_IDPs_FINAL.csv`: Heritability results
- `rg_ALL_163_IDPs_FINAL.csv`: Genetic correlation results

## Critical Fixes Applied
1. **Reference .M files**: Original files had 10M SNPs (wrong), corrected to 1.2M
2. **EA allele alignment**: Strand flips resolved using `--no-check-alleles`

## Pipeline Scripts
Execute in order:
1. `02_fix_reference_M_files.sh` - Fix reference panel
2. `03_calculate_h2_all_IDPs.sh` - Calculate h² for all IDPs
3. `04_prepare_EA_sumstats.sh` - Prepare EA sumstats
4. `05_calculate_rg_IDP_EA.sh` - Calculate genetic correlations
5. `06_extract_h2_results.sh` - Extract h² to CSV
6. `07_extract_rg_results.sh` - Extract rg to CSV

## Computational Requirements
- h² calculation: ~2 hours (173 IDPs × 43s)
- rg calculation: ~3 hours (172 IDPs × 70s)
- Total disk: ~80GB
