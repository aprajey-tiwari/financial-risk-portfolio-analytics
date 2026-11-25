
/*
PROJECT:
Financial Risk Data Quality & Portfolio Monitoring Analytics Lab

ANALYSIS:
Account Status Distribution

BUSINESS OBJECTIVE:
Understand the distribution of loan accounts and
sanctioned amounts across current account statuses.

SOURCE TABLE:
portfolio_final.loan_accounts

REPORTING CUTOFF:
31 October 2026 (disbursement cutoff)

METRICS:
1. Loan accounts by account status
2. Total sanctioned amount
3. Average sanctioned amount
4. Account count share (%)
5. Sanctioned amount share (%)

IMPORTANT:
account_status represents the status currently
stored in the dataset. It is NOT a historical
status snapshot as of 31 October 2026.

Sanctioned amount is not outstanding exposure.
*/

WITH portfolio_base AS (
    SELECT
        account_id,
        account_status,
        sanction_amount
    FROM portfolio_final.loan_accounts
    WHERE disbursement_date <= DATE '2026-10-31'
),

status_summary AS (
    SELECT
        account_status,

        COUNT(DISTINCT account_id) AS total_loan_accounts,

        SUM(sanction_amount) AS total_sanctioned_amount,

        AVG(sanction_amount) AS average_sanctioned_amount

    FROM portfolio_base
    GROUP BY account_status
)

SELECT
    account_status,

    total_loan_accounts,

    ROUND(total_sanctioned_amount, 2)
        AS total_sanctioned_amount,

    ROUND(average_sanctioned_amount, 2)
        AS average_sanctioned_amount,

    ROUND(
        total_loan_accounts * 100.0
        / NULLIF(SUM(total_loan_accounts) OVER (), 0),
        2
    ) AS account_share_pct,

    ROUND(
        total_sanctioned_amount * 100.0
        / NULLIF(SUM(total_sanctioned_amount) OVER (), 0),
        2
    ) AS sanctioned_amount_share_pct

FROM status_summary

ORDER BY total_loan_accounts DESC;
