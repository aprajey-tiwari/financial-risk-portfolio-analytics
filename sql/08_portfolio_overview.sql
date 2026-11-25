
/*
PROJECT:
Financial Risk Data Quality & Portfolio Monitoring Analytics Lab

ANALYSIS:
Overall Loan Portfolio Overview

BUSINESS OBJECTIVE:
Measure the size and sanctioned lending value
of the loan portfolio up to the reporting date.

SOURCE TABLE:
portfolio_final.loan_accounts

REPORTING CUTOFF:
31 October 2026

METRICS:
1. Total loan records
2. Unique loan accounts
3. Total sanctioned amount
4. Average sanctioned amount

FILTER:
Disbursement date on or before reporting cutoff.

IMPORTANT:
Sanctioned amount is not current outstanding exposure.
This query does not reconstruct historical account status.
*/

WITH portfolio_base AS (
    SELECT
        account_id,
        sanction_amount,
        disbursement_date
    FROM portfolio_final.loan_accounts
    WHERE disbursement_date <= DATE '2026-10-31'
)

SELECT
    COUNT(*) AS total_loan_records,

    COUNT(DISTINCT account_id) AS unique_loan_accounts,

    ROUND(
        SUM(sanction_amount),
        2
    ) AS total_sanctioned_amount,

    ROUND(
        AVG(sanction_amount),
        2
    ) AS average_sanctioned_amount

FROM portfolio_base;
