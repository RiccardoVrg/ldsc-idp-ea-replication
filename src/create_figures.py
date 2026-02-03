import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os

# Carica risultati
rg_data = pd.read_csv('data/rg_ALL_163_IDPs_FINAL.csv')
h2_data = pd.read_csv('data/h2_ALL_173_IDPs_FINAL.csv')

# Fix: converti IDP in string
rg_data['IDP'] = rg_data['IDP'].astype(str)
h2_data['IDP'] = h2_data['IDP'].astype(str)

# Merge
data = pd.merge(rg_data, h2_data[['IDP', 'h2']], on='IDP', how='left')
print(f"Loaded {len(data)} IDPs")

# Crea directory results se non esiste
os.makedirs('results', exist_ok=True)

# FIGURE 1: Scatterplot
fig, ax = plt.subplots(figsize=(8, 6))
colors = ['red' if p < 0.01 else 'orange' if p < 0.05 else 'gray' for p in data['rg_p']]
ax.scatter(data['h2'], data['rg'], c=colors, alpha=0.6, s=50)
ax.axhline(0, color='black', linestyle='--', linewidth=0.5)
ax.set_xlabel('SNP-heritability (h²)', fontsize=12)
ax.set_ylabel('Genetic correlation with EA (rg)', fontsize=12)
ax.set_title('Genetic Correlations: Brain IDPs and Educational Attainment', fontsize=14, fontweight='bold')
from matplotlib.patches import Patch
legend_elements = [Patch(facecolor='red', label='p < 0.01'), Patch(facecolor='orange', label='p < 0.05'), Patch(facecolor='gray', label='n.s.')]
ax.legend(handles=legend_elements, loc='best')
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('results/Figure1_rg_scatterplot.png', dpi=300, bbox_inches='tight')
print("✓ Figure 1 saved")
plt.close()

# FIGURE 2: Distribution
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))
ax1.hist(data['rg'], bins=30, color='steelblue', edgecolor='black', alpha=0.7)
ax1.axvline(0, color='red', linestyle='--', linewidth=2)
ax1.set_xlabel('Genetic correlation (rg)', fontsize=12)
ax1.set_ylabel('Frequency', fontsize=12)
ax1.set_title('Distribution of rg values', fontsize=13, fontweight='bold')
sig = data[data['rg_p'] < 0.05]
nonsig = data[data['rg_p'] >= 0.05]
ax2.violinplot([nonsig['rg'], sig['rg']], positions=[1, 2], widths=0.7, showmeans=True)
ax2.scatter([1]*len(nonsig), nonsig['rg'], alpha=0.3, s=20, color='gray')
ax2.scatter([2]*len(sig), sig['rg'], alpha=0.5, s=30, color='red')
ax2.axhline(0, color='black', linestyle='--', linewidth=0.5)
ax2.set_xticks([1, 2])
ax2.set_xticklabels(['Non-sig.', 'Significant\n(p<0.05)'])
ax2.set_ylabel('Genetic correlation (rg)', fontsize=12)
ax2.set_title('rg by significance', fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('results/Figure2_rg_distribution.png', dpi=300, bbox_inches='tight')
print("✓ Figure 2 saved")
plt.close()

# FIGURE 3: Top 20
top20 = data.nsmallest(20, 'rg_p').sort_values('rg')
fig, ax = plt.subplots(figsize=(10, 8))
colors_bar = ['red' if p < 0.01 else 'orange' for p in top20['rg_p']]
ax.barh(range(len(top20)), top20['rg'], color=colors_bar, alpha=0.7)
ax.set_yticks(range(len(top20)))
ax.set_yticklabels(top20['IDP'], fontsize=9)
ax.set_xlabel('Genetic correlation (rg)', fontsize=12)
ax.set_title('Top 20 IDPs by significance', fontsize=14, fontweight='bold')
ax.axvline(0, color='black', linestyle='--', linewidth=1)
ax.grid(True, alpha=0.3, axis='x')
plt.tight_layout()
plt.savefig('results/Figure3_top20_barplot.png', dpi=300, bbox_inches='tight')
print("✓ Figure 3 saved")
plt.close()

print("\nAll figures created successfully!")
print("Results saved in: results/")
