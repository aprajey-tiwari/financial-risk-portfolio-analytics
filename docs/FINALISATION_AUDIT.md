# Finalisation audit note

This note records changes made during repository preparation from the uploaded ZIP.

## Completed in this package
- Normalised the repository root folder name.
- Corrected DPD bucket boundaries in `sql/11_delinquency_analysis.sql` and `sql/16_product_wise_risk_segmentation.sql` to 61–89 and 90+.
- Added `python/reconciliation.py` as a reusable latest-snapshot versus account-summary comparison.
- Added project README, data README, requirements and `.gitignore`.
- Recalculated `reports/product_wise_risk_segmentation_corrected.csv` directly from the supplied processed CSVs, with exactly 90 DPD included in 90+.

## Verified from supplied files
- Latest snapshot date: 31 October 2026.
- Latest snapshot population: 5,000 accounts.
- Exactly 90 DPD accounts: 7.
- 61–89 DPD accounts: 96.
- 90+ DPD accounts: 3,764.
- Overdue accounts (DPD > 0): 4,178.
- Existing Power BI report definition contains four pages: Portfolio Overview, Product Risk Analysis, Delinquency Analysis, and Portfolio Trends & Risk Movement.

## Verification performed on the supplied files
- `python/data_quality_checks.py` executed successfully: 230,000 rows, 46 monthly snapshots, 5,000 accounts per month, no missing values, duplicate account-month records, negative values or cross-field exceptions; account count and overdue exposure reconciled.
- `python/reconciliation.py` executed successfully after applying a floating-point tolerance: 4,178 overdue accounts matched, zero missing accounts on either side and zero financial mismatches.

## Still requires verification in your local applications
- Execute the corrected SQL scripts against the intended PostgreSQL database.
- Open and refresh the PBIX in Power BI Desktop; confirm its data source paths and validate the visuals against the corrected report outputs.
- Review the generated Git diff before publishing.

No claim is made here that PostgreSQL queries were executed or the PBIX was refreshed.
