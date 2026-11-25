"""Reconcile the latest portfolio snapshot to account_summary.csv.

Run from the repository root:
    python python/reconciliation.py

This script compares overdue accounts only because account_summary.csv contains
the overdue-account population. It does not compare sanctioned amount to exposure.
"""
from pathlib import Path
import pandas as pd
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "processed"
OUT = ROOT / "reports"
OUT.mkdir(exist_ok=True)

snap = pd.read_csv(DATA / "portfolio_snapshots.csv", parse_dates=["reporting_date"])
summary = pd.read_csv(DATA / "account_summary.csv")

latest_date = snap["reporting_date"].max()
latest = snap.loc[snap["reporting_date"].eq(latest_date)].copy()
overdue = latest.loc[latest["dpd"].gt(0)].copy()

# Inspect source columns and compare common financial fields only.
key = "account_id"
if key not in summary.columns or key not in overdue.columns:
    raise ValueError("Both source files must contain account_id.")

comparison = overdue.merge(summary, on=key, how="outer", suffixes=("_snapshot", "_summary"), indicator=True)
missing_from_summary = int(comparison["_merge"].eq("left_only").sum())
missing_from_snapshot = int(comparison["_merge"].eq("right_only").sum())

financial_pairs = []
for col in ("overdue_exposure", "overdue_instalments", "dpd"):
    left, right = f"{col}_snapshot", f"{col}_summary"
    if left in comparison.columns and right in comparison.columns:
        financial_pairs.append((left, right, col))

mismatch_mask = pd.Series(False, index=comparison.index)
for left, right, _ in financial_pairs:
    a, b = comparison[left], comparison[right]
    if pd.api.types.is_numeric_dtype(a) and pd.api.types.is_numeric_dtype(b):
        equal = pd.Series(
            np.isclose(a.astype(float), b.astype(float), rtol=1e-10, atol=1e-8, equal_nan=True),
            index=comparison.index,
        )
    else:
        equal = a.fillna("__NULL__").eq(b.fillna("__NULL__"))
    mismatch_mask |= ~equal

matched = comparison.loc[comparison["_merge"].eq("both")]
result = pd.DataFrame([{
    "reporting_date": latest_date.date().isoformat(),
    "snapshot_overdue_accounts": int(overdue[key].nunique()),
    "summary_accounts": int(summary[key].nunique()),
    "missing_from_summary": missing_from_summary,
    "missing_from_snapshot": missing_from_snapshot,
    "financial_mismatches": int(mismatch_mask.sum()),
    "matched_accounts": int(matched[key].nunique()),
    "compared_fields": ", ".join(x[2] for x in financial_pairs) if financial_pairs else "account_id only",
}])
result.to_csv(OUT / "portfolio_reconciliation_script_output.csv", index=False)
print(result.to_string(index=False))
