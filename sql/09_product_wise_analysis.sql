
/*
PROJECT:
Financial Risk Data Quality & Portfolio Monitoring Analytics Lab

ANALYSIS:
Product-wise Portfolio Analysis

BUSINESS OBJECTIVE:
Analyse loan account distribution and sanctioned
lending concentration across different products.

SOURCE TABLES:
portfolio_final.loan_accounts
portfolio_final.product_reference

REPORTING CUTOFF:
31 October 2026

METRICS:
1. Loan accounts per product
2. Total sanctioned amount
3. Average sanctioned amount
4. Share of total sanctioned amount (%)
5. Product interest rate

IMPORTANT:
Sanctioned amount is not current outstanding exposure.
The reporting population includes loans disbursed
on or before the reporting cutoff.
*/

WITH portfolio_base AS (
    SELECT
        la.account_id,
        la.product_id,
        la.sanction_amount,
        pr.interest_rate
    FROM portfolio_final.loan_accounts la

    INNER JOIN portfolio_final.product_reference pr
        ON la.product_id = pr.product_id

    WHERE la.disbursement_date <= DATE '2026-10-31'
),

product_summary AS (
    SELECT
        product_id,
        interest_rate,

        COUNT(DISTINCT account_id) AS total_loan_accounts,

        SUM(sanction_amount) AS total_sanctioned_amount,

        AVG(sanction_amount) AS average_sanctioned_amount

    FROM portfolio_base

    GROUP BY
        product_id,
        interest_rate
)

SELECT
    product_id,
    interest_rate,

    total_loan_accounts,

    ROUND(total_sanctioned_amount, 2)
        AS total_sanctioned_amount,

    ROUND(average_sanctioned_amount, 2)
        AS average_sanctioned_amount,

    ROUND(
        total_sanctioned_amount
        / NULLIF(SUM(total_sanctioned_amount) OVER (), 0)
        * 100,
        2
    ) AS sanctioned_amount_share_pct

FROM product_summary

ORDER BY total_sanctioned_amount DESC;
