# LDSC Replication: Brain MRI IDPs and Educational Attainment

Replication of genetic correlation analysis from Satizabal et al. (2019) using UK Biobank data.

## Repository Structure
```
├── data/                          # Results data
│   ├── h2_ALL_173_IDPs_FINAL.csv # Heritability estimates
│   └── rg_ALL_163_IDPs_FINAL.csv # Genetic correlations
├── results/                       # Figures and summary
│   ├── Figure1_rg_scatterplot.png
│   ├── Figure2_rg_distribution.png
│   ├── Figure3_top20_barplot.png
│   └── RESULTS_SUMMARY.txt
└── src/                          # Source code
    ├── create_figures.py         # Generate result figures
    └── pipeline_final/           # LDSC analysis pipeline
        ├── README.md             # Detailed documentation
        └── *.sh                  # Analysis scripts
```

## Quick Results

- **163 IDPs** analyzed
- Mean genetic correlation: **rg = 0.041** (range: -0.11 to +0.19)
- **37 significant** correlations (p<0.05, 22.7%)
- **Top hit**: Pars orbitalis (L) - rg=0.194, p=0.0001

## Reproduce Analysis

### Prerequisites
```bash
# Install LDSC
conda create -n ldsc python=2.7
conda activate ldsc
git clone https://github.com/bulik/ldsc.git
cd ldsc && pip install -r requirements.txt

# Install plotting libraries
pip install matplotlib seaborn pandas numpy
```

### Run Pipeline
```bash
# Clone repository
git clone https://github.com/RiccardoVrg/ldsc-idp-ea-replication.git
cd ldsc-idp-ea-replication

# Execute analysis (requires LDSC data - see src/pipeline_final/README.md)
cd src/pipeline_final
./02_fix_reference_M_files.sh      # Fix reference panel
./03_calculate_h2_all_IDPs.sh      # Calculate heritability
./04_prepare_EA_sumstats.sh        # Prepare EA sumstats
./05_calculate_rg_IDP_EA.sh        # Calculate genetic correlations
./06_extract_h2_results.sh         # Extract h² results
./07_extract_rg_results.sh         # Extract rg results
```

### Generate Figures
```bash
# From repository root
python src/create_figures.py
```

This will create:
- `results/Figure1_rg_scatterplot.png` - rg vs h² scatterplot
- `results/Figure2_rg_distribution.png` - Distribution plots
- `results/Figure3_top20_barplot.png` - Top 20 significant IDPs

## Results Summary

### Heritability (h²)
- 173 IDPs: mean h²=0.20, range=[-0.006, 0.36]
- Distribution: 90% between 0.10-0.30
- EA: h²=0.097 ± 0.005

### Genetic Correlations (rg)
| Metric | Value |
|--------|-------|
| Total analyzed | 163 IDPs |
| Mean rg | 0.041 |
| Range | -0.11 to +0.19 |
| Significant (p<0.05) | 37 (22.7%) |
| Highly significant (p<0.01) | 14 (8.6%) |

### Top Hits (p<0.001)
1. **IDP 0666** (Pars orbitalis L): rg=0.194, p=0.0001
2. **IDP 0684** (Caudal ant. cingulate R): rg=0.187, p=0.0006
3. **IDP 0689** (Inferior parietal R): rg=0.153, p=0.0002
## Data Sources

- **IDP**: UK Biobank BIG40 (N=33k) - [Download](https://open.win.ox.ac.uk/ukbiobank/big40/)
- **EA**: Neale Lab phenotype 845 (N=240k) - [Download](https://www.nealelab.is/uk-biobank)
- **Reference**: 1000 Genomes Phase 3 EUR LD scores

## Citation

If you use this code or data, please cite:
- Satizabal et al. (2019) - Original study
- Elliott et al. (2018) - UK Biobank BIG40 data
- Bulik-Sullivan et al. (2015) - LDSC method

## Documentation

See `src/pipeline_final/README.md` for detailed pipeline documentation and `results/RESULTS_SUMMARY.txt` for full analysis summary.
