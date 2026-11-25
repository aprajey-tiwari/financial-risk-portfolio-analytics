-- EXERCISE 16: PRODUCT-WISE RISK SEGMENTATION
-- STEP 1: SOURCE TABLE STRUCTURE INSPECTION

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'portfolio_final'
  AND table_name IN (
      'portfolio_snapshots',
      'product_reference'
  )
ORDER BY
    table_name,
    ordinal_position;



-- EXERCISE 16
-- STEP 2: LOAN ACCOUNT STRUCTURE INSPECTION

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'portfolio_final'
  AND table_name = 'loan_accounts'
ORDER BY ordinal_position;




-- EXERCISE 16
-- STEP 3: PRODUCT REFERENCE DATA INSPECTION

SELECT
    product_id,
    interest_rate,
    COUNT(*) AS record_count
FROM portfolio_final.product_reference
GROUP BY
    product_id,
    interest_rate
ORDER BY
    product_id;




-- CHECK: DUPLICATE PRODUCT IDS

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM portfolio_final.product_reference
GROUP BY product_id
HAVING COUNT(*) > 1;




-- EXERCISE 16
-- STEP 3C: LOAN-TO-PRODUCT MAPPING VALIDATION

SELECT
    l.product_id,
    COUNT(*) AS unmapped_account_count
FROM portfolio_final.loan_accounts l
LEFT JOIN portfolio_final.product_reference p
    ON l.product_id = p.product_id
WHERE p.product_id IS NULL
GROUP BY l.product_id
ORDER BY unmapped_account_count DESC;






-- ============================================================
-- EXERCISE 16
-- STEP 4A: PRODUCT-WISE PORTFOLIO RISK SEGMENTATION
-- REPORTING DATE: 2026-10-31
-- ============================================================

SELECT
    p.product_id,
    p.interest_rate,

    COUNT(DISTINCT s.account_id) AS total_accounts,

    COUNT(DISTINCT s.account_id)
        FILTER (WHERE s.dpd > 0) AS overdue_accounts,

    ROUND(
        COUNT(DISTINCT s.account_id)
            FILTER (WHERE s.dpd > 0) * 100.0
        / NULLIF(COUNT(DISTINCT s.account_id), 0),
        2
    ) AS overdue_account_rate_pct,

    SUM(s.overdue_exposure) AS total_overdue_exposure,

    ROUND(
        AVG(
            CASE
                WHEN s.dpd > 0 THEN s.overdue_exposure
            END
        ),
        2
    ) AS avg_overdue_exposure,

    MAX(s.dpd) AS maximum_dpd,

    COUNT(DISTINCT s.account_id)
        FILTER (WHERE s.dpd BETWEEN 1 AND 30) AS dpd_1_30_accounts,

    COUNT(DISTINCT s.account_id)
        FILTER (WHERE s.dpd BETWEEN 31 AND 60) AS dpd_31_60_accounts,

    COUNT(DISTINCT s.account_id)
        FILTER (WHERE s.dpd BETWEEN 61 AND 89) AS dpd_61_89_accounts,

    COUNT(DISTINCT s.account_id)
        FILTER (WHERE s.dpd >= 90) AS dpd_90_plus_accounts

FROM portfolio_final.portfolio_snapshots s

JOIN portfolio_final.loan_accounts l
    ON s.account_id = l.account_id

JOIN portfolio_final.product_reference p
    ON l.product_id = p.product_id

WHERE s.reporting_date = DATE '2026-10-31'

GROUP BY
    p.product_id,
    p.interest_rate

ORDER BY total_overdue_exposure DESC;





-- ============================================================
-- EXERCISE 16
-- STEP 4B: ACCOUNT SNAPSHOT UNIQUENESS VALIDATION
-- REPORTING DATE: 2026-10-31
-- ============================================================

SELECT
    account_id,
    reporting_date,
    COUNT(*) AS record_count
FROM portfolio_final.portfolio_snapshots
WHERE reporting_date = DATE '2026-10-31'
GROUP BY
    account_id,
    reporting_date
HAVING COUNT(*) > 1
ORDER BY record_count DESC;