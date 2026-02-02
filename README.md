# LDSC Replication: Brain MRI IDPs and Educational Attainment

Replication of genetic correlation analysis from **Satizabal et al. (2019)** using UK Biobank data.

## Results
- **163/172 IDPs** successfully analyzed
- Mean genetic correlation: **rg = 0.041** (range: -0.11 to +0.19)
- **37 significant** correlations (p<0.05, 22.7%)
- Top hit: **Pars orbitalis (L)** - rg=0.194, p=0.0001

## Files
- `h2_ALL_173_IDPs_FINAL.csv` - Heritability estimates
- `rg_ALL_163_IDPs_FINAL.csv` - Genetic correlations
- `RESULTS_SUMMARY.txt` - Full summary report
- `pipeline_final/` - Complete reproducible pipeline

## Validation
✅ Consistent with Satizabal 2019  
✅ Same brain regions (frontal, cingulate, parietal)  
✅ Similar effect sizes

See `pipeline_final/README.md` for full documentation.
