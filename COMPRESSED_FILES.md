# Compressed data files

On 2026-10-03, to save disk space, these untracked data files were gzipped (lossless). Scripts that load them by their original name need them restored first:

```bash
gunzip -k "data/pu2024.csv.gz"
gunzip -k "data/p22i6.dta.gz"
```

R (`data.table::fread`, `readr`) and pandas can also read the `.gz` files directly. Stata needs them unzipped.
