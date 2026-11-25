
from pathlib import Path
import pandas as pd

# Locate the project directory
project_dir = Path(__file__).resolve().parent.parent

# Locate the portfolio snapshot dataset
file_path = project_dir / "data" / "processed" / "portfolio_snapshots.csv"

# Load the dataset
df = pd.read_csv(file_path)

# Display basic information
print("Dataset loaded successfully!")
print("Shape:", df.shape)

print("\nColumn names:")
print(df.columns.tolist())

print("\nFirst 5 records:")
print(df.head())

print("\nReporting date range:")
print(df["reporting_date"].min())
print(df["reporting_date"].max())

print("\nUnique loan accounts:")
print(df["account_id"].nunique())

print("\nMissing values:")
print(df.isnull().sum())

# 1. Check duplicate account-month records

duplicate_records = df.duplicated(
    subset=["account_id", "reporting_date"]
).sum()

print("\nDuplicate account-month records:")
print(duplicate_records)


# 2. Check monthly record counts

monthly_records = (
    df.groupby("reporting_date")
    .size()
    .sort_index()
)

print("\nMonthly record counts:")
print(monthly_records)


# 3. Check negative values

print("\nNegative value checks:")

print("Negative DPD:", (df["dpd"] < 0).sum())

print(
    "Negative overdue exposure:",
    (df["overdue_exposure"] < 0).sum()
)

print(
    "Negative overdue instalments:",
    (df["overdue_instalments"] < 0).sum()
)
# Cross-field consistency investigation

print("\nCross-field consistency checks:")

print(
    "DPD > 0 but overdue exposure = 0:",
    (
        (df["dpd"] > 0) &
        (df["overdue_exposure"] == 0)
    ).sum()
)

print(
    "DPD = 0 but overdue exposure > 0:",
    (
        (df["dpd"] == 0) &
        (df["overdue_exposure"] > 0)
    ).sum()
)

print(
    "Overdue instalments = 0 but overdue exposure > 0:",
    (
        (df["overdue_instalments"] == 0) &
        (df["overdue_exposure"] > 0)
    ).sum()
)

print(
    "Overdue instalments > 0 but overdue exposure = 0:",
    (
        (df["overdue_instalments"] > 0) &
        (df["overdue_exposure"] == 0)
    ).sum()
)


# =====================================================
# CONSOLIDATED PORTFOLIO DELINQUENCY ANALYSIS
# =====================================================

# 1. Identify the latest reporting month
latest_date = df["reporting_date"].max()

latest_snapshot = df[
    df["reporting_date"] == latest_date
].copy()

# 2. Classify accounts into DPD buckets
latest_snapshot["dpd_bucket"] = pd.cut(
    latest_snapshot["dpd"],
    bins=[-1, 0, 30, 60, 89, float("inf")],
    labels=[
        "Current",
        "1-30 DPD",
        "31-60 DPD",
        "61-89 DPD",
        "90+ DPD"
    ]
)

# 3. Calculate bucket-level portfolio metrics
bucket_summary = (
    latest_snapshot
    .groupby("dpd_bucket", observed=False)
    .agg(
        account_count=("account_id", "nunique"),
        overdue_exposure=("overdue_exposure", "sum")
    )
    .reset_index()
)

# 4. Calculate portfolio totals
total_accounts = latest_snapshot["account_id"].nunique()
total_overdue_exposure = latest_snapshot["overdue_exposure"].sum()

# 5. Calculate distribution percentages
bucket_summary["account_percentage"] = (
    bucket_summary["account_count"] / total_accounts * 100
).round(2)

bucket_summary["exposure_percentage"] = (
    bucket_summary["overdue_exposure"] /
    total_overdue_exposure * 100
).round(2) if total_overdue_exposure != 0 else 0

# 6. Display results
print("\n====================================")
print("PORTFOLIO DELINQUENCY ANALYSIS")
print("====================================")

print("Reporting date:", latest_date)
print("Total accounts:", total_accounts)
print("Total overdue exposure:", round(total_overdue_exposure, 2))

print("\nDPD BUCKET SUMMARY:")
print(bucket_summary.to_string(index=False))

# 7. Reconciliation checks
print("\n====================================")
print("RECONCILIATION CHECKS")
print("====================================")

print(
    "Account count reconciliation:",
    bucket_summary["account_count"].sum(),
    "vs",
    total_accounts
)

print(
    "Account count reconciled:",
    bucket_summary["account_count"].sum() == total_accounts
)

print(
    "Exposure reconciliation:",
    round(bucket_summary["overdue_exposure"].sum(), 2),
    "vs",
    round(total_overdue_exposure, 2)
)

print(
    "Exposure reconciled:",
    round(bucket_summary["overdue_exposure"].sum(), 2)
    == round(total_overdue_exposure, 2)
)
