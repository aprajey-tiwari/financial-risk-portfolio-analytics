# Data dictionary and usage

All files in this project contain synthetic records.

## Raw data
- `customer_details.csv` — synthetic customer-level attributes.
- `loan_accounts.csv` — synthetic loan/account attributes and product identifiers.

## Processed data
- `customer_details.csv` — prepared customer dimension.
- `loan_accounts.csv` — prepared loan/account dimension.
- `product_reference.csv` — product identifiers and interest rates.
- `repayment_schedule.csv` — scheduled instalment-level records.
- `payment_records.csv` — payment-level records and payment status.
- `account_summary.csv` — account-level summary for the overdue population.
- `portfolio_snapshots.csv` — monthly account-level portfolio snapshots, including reporting date, overdue instalments, overdue exposure and DPD.

`portfolio_snapshots.csv` contains one row per account per reporting month. The latest reporting date in the supplied dataset is 31 October 2026.

Do not interpret `overdue_exposure` as total outstanding principal. Null payment dates for unpaid records are expected and must be interpreted alongside payment status.
