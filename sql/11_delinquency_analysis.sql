
-- ============================================================
-- PROJECT: Financial Risk Data Quality & Portfolio Monitoring
-- EXERCISE 11: PORTFOLIO DELINQUENCY OVERVIEW
-- PURPOSE: Measure overdue accounts and overdue exposure
-- SOURCE: portfolio_final.loan_accounts
--         portfolio_final.account_summary
-- ============================================================

WITH portfolio_base AS (
    SELECT
        COUNT(*) AS total_loan_accounts
    FROM portfolio_final.loan_accounts
),

overdue_summary AS (
    SELECT
        COUNT(*) AS overdue_accounts,
        SUM(overdue_instalments) AS total_overdue_instalments,
        SUM(overdue_exposure) AS total_overdue_exposure
    FROM portfolio_final.account_summary
),

portfolio_metrics AS (
    SELECT
        pb.total_loan_accounts,
        os.overdue_accounts,

        pb.total_loan_accounts - os.overdue_accounts
            AS accounts_without_overdue_records,

        os.total_overdue_instalments,
        os.total_overdue_exposure,

        os.total_overdue_exposure
            / NULLIF(os.overdue_accounts, 0)
            AS average_overdue_exposure

    FROM portfolio_base pb
    CROSS JOIN overdue_summary os
)

SELECT
    total_loan_accounts,
    overdue_accounts,
    accounts_without_overdue_records,

    ROUND(
        overdue_accounts * 100.0
        / NULLIF(total_loan_accounts, 0),
        2
    ) AS overdue_account_rate_pct,

    total_overdue_instalments,

    ROUND(total_overdue_exposure, 2)
        AS total_overdue_exposure,

    ROUND(average_overdue_exposure, 2)
        AS average_overdue_exposure

FROM portfolio_metrics;








-- ============================================================
-- PROJECT: Financial Risk Data Quality & Portfolio Monitoring
-- EXERCISE 11: DPD BUCKET ANALYSIS
-- PURPOSE: Analyse overdue instalments by DPD bucket
-- SOURCE: portfolio_final.payment_records
-- ============================================================

SELECT
    dpd_bucket,

    COUNT(*) AS overdue_instalment_records,

    COUNT(DISTINCT account_id)
        AS affected_accounts,

    SUM(instalment_outstanding)
        AS total_overdue_exposure,

    ROUND(
        AVG(instalment_outstanding),
        2
    ) AS average_overdue_instalment_exposure,

    MAX(dpd) AS maximum_dpd

FROM portfolio_final.payment_records

WHERE dpd > 0
  AND instalment_outstanding > 0

GROUP BY dpd_bucket

ORDER BY MIN(dpd);








-- ============================================================
-- EXERCISE 11: DELINQUENCY RECONCILIATION
-- PURPOSE: Compare overdue metrics across source tables
-- ============================================================

SELECT
    'account_summary' AS source_table,
    COUNT(*) AS record_count,
    COUNT(DISTINCT account_id) AS unique_accounts,
    SUM(overdue_instalments) AS overdue_records,
    ROUND(SUM(overdue_exposure), 2) AS overdue_exposure
FROM portfolio_final.account_summary

UNION ALL

SELECT
    'payment_records' AS source_table,
    COUNT(*) AS record_count,
    COUNT(DISTINCT account_id) AS unique_accounts,
    COUNT(*) FILTER (
        WHERE dpd > 0
          AND instalment_outstanding > 0
    ) AS overdue_records,
    ROUND(
        SUM(instalment_outstanding) FILTER (
            WHERE dpd > 0
              AND instalment_outstanding > 0
        ),
        2
    ) AS overdue_exposure
FROM portfolio_final.payment_records;






-- ============================================================
-- EXERCISE 11: ACCOUNT-LEVEL DELINQUENCY RECONCILIATION
-- PURPOSE: Identify account-level differences between sources
-- ============================================================

WITH payment_overdue AS (
    SELECT
        account_id,

        COUNT(*) FILTER (
            WHERE dpd > 0
              AND instalment_outstanding > 0
        ) AS payment_overdue_instalments,

        SUM(instalment_outstanding) FILTER (
            WHERE dpd > 0
              AND instalment_outstanding > 0
        ) AS payment_overdue_exposure

    FROM portfolio_final.payment_records
    GROUP BY account_id
),

account_comparison AS (
    SELECT
        COALESCE(a.account_id, p.account_id) AS account_id,

        COALESCE(a.overdue_instalments, 0)
            AS summary_overdue_instalments,

        COALESCE(p.payment_overdue_instalments, 0)
            AS payment_overdue_instalments,

        COALESCE(a.overdue_exposure, 0)
            AS summary_overdue_exposure,

        COALESCE(p.payment_overdue_exposure, 0)
            AS payment_overdue_exposure

    FROM portfolio_final.account_summary a

    FULL OUTER JOIN payment_overdue p
        ON a.account_id = p.account_id
)

SELECT
    account_id,

    summary_overdue_instalments,
    payment_overdue_instalments,

    summary_overdue_instalments
        - payment_overdue_instalments
        AS instalment_difference,

    ROUND(summary_overdue_exposure, 2)
        AS summary_overdue_exposure,

    ROUND(payment_overdue_exposure, 2)
        AS payment_overdue_exposure,

    ROUND(
        summary_overdue_exposure
        - payment_overdue_exposure,
        2
    ) AS exposure_difference

FROM account_comparison

WHERE summary_overdue_instalments
          <> payment_overdue_instalments

   OR summary_overdue_exposure
          <> payment_overdue_exposure

ORDER BY ABS(
    summary_overdue_exposure
    - payment_overdue_exposure
) DESC;






-- ============================================================
-- EXERCISE 11: RECONCILIATION EXCEPTION CLASSIFICATION
-- PURPOSE: Quantify and classify account-level discrepancies
-- ============================================================

WITH payment_overdue AS (
    SELECT
        account_id,

        COUNT(*) FILTER (
            WHERE dpd > 0
              AND instalment_outstanding > 0
        ) AS payment_overdue_instalments,

        COALESCE(
            SUM(instalment_outstanding) FILTER (
                WHERE dpd > 0
                  AND instalment_outstanding > 0
            ),
            0
        ) AS payment_overdue_exposure

    FROM portfolio_final.payment_records
    GROUP BY account_id
),

account_comparison AS (
    SELECT
        a.account_id AS summary_account_id,
        p.account_id AS payment_account_id,

        COALESCE(a.overdue_instalments, 0)
            AS summary_overdue_instalments,

        COALESCE(p.payment_overdue_instalments, 0)
            AS payment_overdue_instalments,

        COALESCE(a.overdue_exposure, 0)
            AS summary_overdue_exposure,

        COALESCE(p.payment_overdue_exposure, 0)
            AS payment_overdue_exposure

    FROM portfolio_final.account_summary a

    FULL OUTER JOIN payment_overdue p
        ON a.account_id = p.account_id
),

classified_exceptions AS (
    SELECT
        *,

        CASE
            WHEN summary_account_id IS NULL
                THEN 'Missing from account_summary'

            WHEN payment_account_id IS NULL
                THEN 'Missing from payment_records'

            WHEN summary_overdue_instalments
                     <> payment_overdue_instalments
             AND summary_overdue_exposure
                     <> payment_overdue_exposure
                THEN 'Count and exposure mismatch'

            WHEN summary_overdue_instalments
                     <> payment_overdue_instalments
                THEN 'Count mismatch only'

            WHEN summary_overdue_exposure
                     <> payment_overdue_exposure
                THEN 'Exposure mismatch only'

            ELSE 'No mismatch'
        END AS exception_category

    FROM account_comparison
)

SELECT
    exception_category,

    COUNT(*) AS affected_accounts,

    SUM(summary_overdue_instalments)
        AS summary_overdue_instalments,

    SUM(payment_overdue_instalments)
        AS payment_overdue_instalments,

    SUM(summary_overdue_instalments
        - payment_overdue_instalments)
        AS instalment_difference,

    ROUND(SUM(summary_overdue_exposure), 2)
        AS summary_overdue_exposure,

    ROUND(SUM(payment_overdue_exposure), 2)
        AS payment_overdue_exposure,

    ROUND(
        SUM(summary_overdue_exposure
            - payment_overdue_exposure),
        2
    ) AS exposure_difference

FROM classified_exceptions

WHERE exception_category <> 'No mismatch'

GROUP BY exception_category

ORDER BY affected_accounts DESC;







-- ============================================================
-- EXERCISE 11: VALIDATE NON-OVERDUE ACCOUNT COVERAGE
-- PURPOSE: Determine whether absent summary accounts
--          genuinely have no overdue instalments
-- ============================================================

WITH payment_overdue AS (
    SELECT
        account_id,

        COUNT(*) FILTER (
            WHERE dpd > 0
              AND instalment_outstanding > 0
        ) AS overdue_instalments,

        COALESCE(
            SUM(instalment_outstanding) FILTER (
                WHERE dpd > 0
                  AND instalment_outstanding > 0
            ),
            0
        ) AS overdue_exposure

    FROM portfolio_final.payment_records
    GROUP BY account_id
)

SELECT
    COUNT(*) AS total_payment_accounts,

    COUNT(*) FILTER (
        WHERE overdue_instalments > 0
    ) AS accounts_with_overdue,

    COUNT(*) FILTER (
        WHERE overdue_instalments = 0
    ) AS accounts_without_overdue,

    COUNT(*) FILTER (
        WHERE overdue_instalments > 0
          AND account_id IN (
              SELECT account_id
              FROM portfolio_final.account_summary
          )
    ) AS overdue_accounts_in_summary,

    COUNT(*) FILTER (
        WHERE overdue_instalments > 0
          AND account_id NOT IN (
              SELECT account_id
              FROM portfolio_final.account_summary
          )
    ) AS overdue_accounts_missing_from_summary,

    (
        SELECT COUNT(*)
        FROM portfolio_final.account_summary
    ) AS summary_account_count

FROM payment_overdue;





-- ============================================================
-- EXERCISE 11: INVESTIGATE SUMMARY-ONLY ACCOUNTS
-- PURPOSE: Validate accounts in account_summary that have
--          no qualifying overdue instalments in payment_records
-- ============================================================

WITH payment_overdue AS (
    SELECT
        account_id,

        COUNT(*) FILTER (
            WHERE dpd > 0
              AND instalment_outstanding > 0
        ) AS payment_overdue_instalments,

        COALESCE(
            SUM(instalment_outstanding) FILTER (
                WHERE dpd > 0
                  AND instalment_outstanding > 0
            ),
            0
        ) AS payment_overdue_exposure

    FROM portfolio_final.payment_records
    GROUP BY account_id
),

summary_check AS (
    SELECT
        s.account_id,
        s.overdue_instalments AS summary_overdue_instalments,
        s.overdue_exposure AS summary_overdue_exposure,

        COALESCE(p.payment_overdue_instalments, 0)
            AS payment_overdue_instalments,

        COALESCE(p.payment_overdue_exposure, 0)
            AS payment_overdue_exposure

    FROM portfolio_final.account_summary s

    LEFT JOIN payment_overdue p
        ON s.account_id = p.account_id
)

SELECT
    COUNT(*) AS total_summary_accounts,

    COUNT(*) FILTER (
        WHERE payment_overdue_instalments = 0
    ) AS accounts_without_payment_overdue,

    COUNT(*) FILTER (
        WHERE payment_overdue_instalments = 0
          AND summary_overdue_instalments > 0
    ) AS accounts_with_summary_overdue_count,

    COUNT(*) FILTER (
        WHERE payment_overdue_instalments = 0
          AND summary_overdue_exposure > 0
    ) AS accounts_with_summary_overdue_exposure,

    SUM(summary_overdue_instalments) FILTER (
        WHERE payment_overdue_instalments = 0
    ) AS summary_overdue_instalments_for_these_accounts,

    ROUND(
        SUM(summary_overdue_exposure) FILTER (
            WHERE payment_overdue_instalments = 0
        ),
        2
    ) AS summary_overdue_exposure_for_these_accounts

FROM summary_check;










-- ============================================================
-- EXERCISE 11: INVESTIGATE THE 125 SUMMARY-ONLY ACCOUNTS
-- PURPOSE: Inspect underlying payment records and identify
--          why summary overdue values are not reconciled
-- ============================================================

WITH summary_only_accounts AS (
    SELECT
        account_id,
        overdue_instalments AS summary_overdue_instalments,
        overdue_exposure AS summary_overdue_exposure,
        oldest_overdue_due_date
    FROM portfolio_final.account_summary
    WHERE account_id NOT IN (
        SELECT DISTINCT account_id
        FROM portfolio_final.payment_records
        WHERE dpd > 0
          AND instalment_outstanding > 0
    )
),

payment_diagnostics AS (
    SELECT
        s.account_id,
        s.summary_overdue_instalments,
        s.summary_overdue_exposure,
        s.oldest_overdue_due_date,

        COUNT(p.account_id) AS payment_record_count,

        COUNT(p.account_id) FILTER (
            WHERE p.dpd > 0
        ) AS positive_dpd_records,

        COUNT(p.account_id) FILTER (
            WHERE p.instalment_outstanding > 0
        ) AS positive_outstanding_records,

        COUNT(p.account_id) FILTER (
            WHERE p.dpd > 0
              AND p.instalment_outstanding > 0
        ) AS qualifying_overdue_records,

        COUNT(p.account_id) FILTER (
            WHERE p.dpd IS NULL
        ) AS records_with_missing_dpd,

        ROUND(
            COALESCE(
                SUM(p.instalment_outstanding) FILTER (
                    WHERE p.dpd > 0
                ),
                0
            ),
            2
        ) AS outstanding_with_positive_dpd,

        MAX(p.dpd) AS maximum_dpd,

        STRING_AGG(
            DISTINCT p.payment_status,
            ', '
        ) AS payment_statuses

    FROM summary_only_accounts s

    LEFT JOIN portfolio_final.payment_records p
        ON s.account_id = p.account_id

    GROUP BY
        s.account_id,
        s.summary_overdue_instalments,
        s.summary_overdue_exposure,
        s.oldest_overdue_due_date
)

SELECT *
FROM payment_diagnostics
ORDER BY summary_overdue_exposure DESC;





-- ============================================================
-- EXERCISE 11: INSTALMENT-LEVEL DPD INVESTIGATION
-- PURPOSE: Inspect actual repayment records for summary-only
--          overdue accounts
-- REPORTING DATE: 2026-10-31
-- ============================================================

WITH summary_only_accounts AS (
    SELECT
        s.account_id,
        s.overdue_instalments AS summary_overdue_instalments,
        s.overdue_exposure AS summary_overdue_exposure,
        s.oldest_overdue_due_date

    FROM portfolio_final.account_summary s

    WHERE NOT EXISTS (
        SELECT 1
        FROM portfolio_final.payment_records p
        WHERE p.account_id = s.account_id
          AND p.dpd > 0
          AND p.instalment_outstanding > 0
    )
),

top_accounts AS (
    SELECT *
    FROM summary_only_accounts
    ORDER BY summary_overdue_exposure DESC
    LIMIT 5
)

SELECT
    s.account_id,

    s.summary_overdue_instalments,
    s.summary_overdue_exposure,
    s.oldest_overdue_due_date,

    p.instalment_number,
    p.due_date,
    p.payment_date,

    p.payment_status,
    p.amount_due,
    p.amount_paid,
    p.instalment_outstanding,

    p.dpd,
    p.dpd_bucket,

    DATE '2026-10-31' - p.due_date
        AS days_since_due_at_reporting_date

FROM top_accounts s

JOIN portfolio_final.payment_records p
    ON s.account_id = p.account_id

ORDER BY
    s.summary_overdue_exposure DESC,
    p.due_date,
    p.instalment_number;






-- ============================================================
-- EXERCISE 12: HISTORICAL DPD RECONSTRUCTION
-- REPORTING DATE: 2026-10-31
-- PURPOSE: Reconstruct historical overdue position using
--          instalment due dates and actual payment dates.
-- BUSINESS PROBLEM:
--          Current payment status may not reflect historical
--          delinquency at the reporting date.
-- SOURCE TABLES:
--          portfolio_final.account_summary
--          portfolio_final.payment_records
-- ============================================================



-- ============================================================
-- PROJECT: Financial Risk Data Quality & Portfolio Monitoring
-- EXERCISE 12: HISTORICAL DPD RECONSTRUCTION
-- REPORTING DATE: 2026-10-31
--
-- PURPOSE:
-- Identify instalments due by the reporting date but paid
-- after the reporting date or not yet paid.
--
-- IMPORTANT:
-- Amount due is used as an estimated month-end exposure
-- where payment occurred after the reporting date.
-- This assumes no earlier partial payment was received.
-- ============================================================

WITH summary_only_accounts AS (
    SELECT
        account_id,
        overdue_instalments AS summary_overdue_instalments,
        overdue_exposure AS summary_overdue_exposure,
        oldest_overdue_due_date
    FROM portfolio_final.account_summary
    WHERE NOT EXISTS (
        SELECT 1
        FROM portfolio_final.payment_records p
        WHERE p.account_id = account_summary.account_id
          AND p.dpd > 0
          AND p.instalment_outstanding > 0
    )
),

historical_overdue AS (
    SELECT
        p.account_id,
        p.instalment_number,
        p.due_date,
        p.payment_date,
        p.payment_status,
        p.amount_due,
        p.amount_paid,
        p.instalment_outstanding,
        p.dpd,

        DATE '2026-10-31' - p.due_date
            AS reconstructed_dpd,

        CASE
            WHEN p.payment_date > DATE '2026-10-31'
                 OR p.payment_date IS NULL
            THEN p.amount_due
            ELSE 0
        END AS estimated_overdue_exposure

    FROM portfolio_final.payment_records p

    WHERE p.due_date <= DATE '2026-10-31'
      AND (
          p.payment_date > DATE '2026-10-31'
          OR p.payment_date IS NULL
      )
)

SELECT
    h.account_id,
    s.oldest_overdue_due_date,

    h.instalment_number,
    h.due_date,
    h.payment_date,
    h.payment_status,

    h.amount_due,
    h.amount_paid,
    h.instalment_outstanding,

    h.dpd AS recorded_dpd,
    h.reconstructed_dpd,

    h.estimated_overdue_exposure,

    s.summary_overdue_instalments,
    s.summary_overdue_exposure

FROM historical_overdue h

JOIN summary_only_accounts s
    ON h.account_id = s.account_id

ORDER BY
    s.summary_overdue_exposure DESC,
    h.due_date;







-- ============================================================
-- EXERCISE 12: HISTORICAL DPD RECONSTRUCTION
-- FINAL ACCOUNT-LEVEL RECONCILIATION
-- REPORTING DATE: 2026-10-31
-- ============================================================

WITH summary_only_accounts AS (
    SELECT
        account_id,
        overdue_instalments AS summary_overdue_instalments,
        overdue_exposure AS summary_overdue_exposure
    FROM portfolio_final.account_summary a
    WHERE NOT EXISTS (
        SELECT 1
        FROM portfolio_final.payment_records p
        WHERE p.account_id = a.account_id
          AND p.dpd > 0
          AND p.instalment_outstanding > 0
    )
),

historical_overdue AS (
    SELECT
        account_id,
        COUNT(*) AS reconstructed_overdue_instalments,
        SUM(amount_due) AS reconstructed_overdue_exposure
    FROM portfolio_final.payment_records
    WHERE due_date <= DATE '2026-10-31'
      AND (
          payment_date > DATE '2026-10-31'
          OR payment_date IS NULL
      )
    GROUP BY account_id
),

account_reconciliation AS (
    SELECT
        s.account_id,
        s.summary_overdue_instalments,
        COALESCE(h.reconstructed_overdue_instalments, 0)
            AS reconstructed_overdue_instalments,
        s.summary_overdue_exposure,
        COALESCE(h.reconstructed_overdue_exposure, 0)
            AS reconstructed_overdue_exposure,

        CASE
            WHEN s.summary_overdue_instalments
                 IS DISTINCT FROM
                 COALESCE(h.reconstructed_overdue_instalments, 0)
            THEN 'Instalment count mismatch'

            WHEN s.summary_overdue_exposure
                 IS DISTINCT FROM
                 COALESCE(h.reconstructed_overdue_exposure, 0)
            THEN 'Exposure mismatch'

            ELSE 'Matched'
        END AS reconciliation_status

    FROM summary_only_accounts s
    LEFT JOIN historical_overdue h
        ON s.account_id = h.account_id
)

SELECT
    COUNT(*) AS accounts_checked,

    COUNT(*) FILTER (
        WHERE reconciliation_status = 'Matched'
    ) AS matched_accounts,

    COUNT(*) FILTER (
        WHERE reconciliation_status <> 'Matched'
    ) AS mismatched_accounts,

    SUM(summary_overdue_exposure)
        AS summary_overdue_exposure,

    SUM(reconstructed_overdue_exposure)
        AS reconstructed_overdue_exposure,

    ROUND(
        SUM(summary_overdue_exposure)
        - SUM(reconstructed_overdue_exposure),
        2
    ) AS exposure_difference

FROM account_reconciliation;





-- ============================================================
-- EXERCISE 12: VALIDATION RESULTS
-- ============================================================
-- Accounts checked:                  125
-- Matched accounts:                  125
-- Mismatched accounts:               0
-- Summary overdue exposure:          5933626.03
-- Reconstructed overdue exposure:    5933626.03
-- Exposure difference:               0.00
--
-- CONCLUSION:
-- All 125 investigated accounts reconciled successfully.
-- Historical overdue exposure was reconstructed using
-- instalment due dates and payment dates relative to
-- the reporting date of 2026-10-31.
--
-- LIMITATION:
-- The reconstruction assumes the full instalment amount
-- remained outstanding when payment occurred after the
-- reporting date. Earlier partial payments require
-- separate historical allocation.
-- ============================================================






-- TEMPORARY SCHEMA CHECK
-- No need to save this query.

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'portfolio_final'
  AND table_name = 'portfolio_snapshots'
ORDER BY ordinal_position;






-- ============================================================
-- PROJECT: Financial Risk Data Quality & Portfolio Monitoring
-- EXERCISE 13: MONTHLY PORTFOLIO DELINQUENCY TRENDS
--
-- PURPOSE:
-- Analyse monthly overdue accounts, overdue exposure,
-- delinquency severity and month-on-month movements.
--
-- SOURCE:
-- portfolio_final.portfolio_snapshots
--
-- GRAIN:
-- One account per reporting date.
--
-- METRIC DEFINITIONS:
-- Overdue account: overdue_instalments > 0
-- Overdue exposure: Sum of overdue_exposure
-- DPD buckets: Based on account-level DPD
-- ============================================================

WITH monthly_metrics AS (
    SELECT
        reporting_date,

        COUNT(*) AS snapshot_records,

        COUNT(DISTINCT account_id)
            AS total_accounts,

        COUNT(*) FILTER (
            WHERE overdue_instalments > 0
        ) AS overdue_accounts,

        SUM(overdue_instalments)
            AS total_overdue_instalments,

        ROUND(
            SUM(overdue_exposure),
            2
        ) AS total_overdue_exposure,

        ROUND(
            AVG(overdue_exposure) FILTER (
                WHERE overdue_instalments > 0
            ),
            2
        ) AS average_overdue_exposure,

        MAX(dpd) AS maximum_dpd,

        COUNT(*) FILTER (
            WHERE dpd = 0
        ) AS current_accounts,

        COUNT(*) FILTER (
            WHERE dpd BETWEEN 1 AND 30
        ) AS dpd_1_30_accounts,

        COUNT(*) FILTER (
            WHERE dpd BETWEEN 31 AND 60
        ) AS dpd_31_60_accounts,

        COUNT(*) FILTER (
            WHERE dpd BETWEEN 61 AND 89
        ) AS dpd_61_89_accounts,

        COUNT(*) FILTER (
            WHERE dpd >= 90
        ) AS dpd_90_plus_accounts

    FROM portfolio_final.portfolio_snapshots

    GROUP BY reporting_date
),

monthly_movement AS (
    SELECT
        *,

        LAG(total_overdue_exposure) OVER (
            ORDER BY reporting_date
        ) AS previous_month_overdue_exposure,

        LAG(overdue_accounts) OVER (
            ORDER BY reporting_date
        ) AS previous_month_overdue_accounts

    FROM monthly_metrics
)

SELECT
    reporting_date,

    snapshot_records,
    total_accounts,
    overdue_accounts,

    ROUND(
        overdue_accounts * 100.0
        / NULLIF(total_accounts, 0),
        2
    ) AS overdue_account_rate_pct,

    total_overdue_instalments,
    total_overdue_exposure,
    average_overdue_exposure,

    maximum_dpd,

    current_accounts,
    dpd_1_30_accounts,
    dpd_31_60_accounts,
    dpd_61_89_accounts,
    dpd_90_plus_accounts,

    previous_month_overdue_exposure,

    ROUND(
        total_overdue_exposure
        - previous_month_overdue_exposure,
        2
    ) AS overdue_exposure_mom_change,

    ROUND(
        (
            total_overdue_exposure
            - previous_month_overdue_exposure
        ) * 100.0
        / NULLIF(previous_month_overdue_exposure, 0),
        2
    ) AS overdue_exposure_mom_change_pct,

    previous_month_overdue_accounts,

    overdue_accounts
        - previous_month_overdue_accounts
        AS overdue_accounts_mom_change

FROM monthly_movement

ORDER BY reporting_date;




-- ============================================================
-- PROJECT: Financial Risk Data Quality & Portfolio Monitoring
-- EXERCISE 14: ACCOUNT-LEVEL DPD MIGRATION ANALYSIS
-- PURPOSE: Track month-on-month account delinquency movements
-- SOURCE: portfolio_final.portfolio_snapshots
-- ============================================================

WITH monthly_account_history AS (
    SELECT
        account_id,
        reporting_date,
        dpd AS current_dpd,
        overdue_exposure AS current_overdue_exposure,

        LAG(reporting_date) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_reporting_date,

        LAG(dpd) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_dpd,

        LAG(overdue_exposure) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_overdue_exposure

    FROM portfolio_final.portfolio_snapshots
),

dpd_classification AS (
    SELECT
        *,

        CASE
            WHEN previous_dpd IS NULL THEN 'No Previous Snapshot'
            WHEN previous_dpd = 0 THEN 'Current'
            WHEN previous_dpd BETWEEN 1 AND 30 THEN '1-30 DPD'
            WHEN previous_dpd BETWEEN 31 AND 60 THEN '31-60 DPD'
            WHEN previous_dpd BETWEEN 61 AND 89 THEN '61-89 DPD'
            WHEN previous_dpd >= 90 THEN '90+ DPD'
            ELSE 'Unknown'
        END AS previous_dpd_bucket,

        CASE
            WHEN current_dpd IS NULL THEN 'Unknown'
            WHEN current_dpd = 0 THEN 'Current'
            WHEN current_dpd BETWEEN 1 AND 30 THEN '1-30 DPD'
            WHEN current_dpd BETWEEN 31 AND 60 THEN '31-60 DPD'
            WHEN current_dpd BETWEEN 61 AND 89 THEN '61-89 DPD'
            WHEN current_dpd >= 90 THEN '90+ DPD'
            ELSE 'Unknown'
        END AS current_dpd_bucket

    FROM monthly_account_history
),

valid_monthly_migrations AS (
    SELECT
        *
    FROM dpd_classification
    WHERE previous_reporting_date IS NOT NULL
  AND DATE_TRUNC('month', reporting_date) =
      DATE_TRUNC('month', previous_reporting_date)
      + INTERVAL '1 month'
)

SELECT
    previous_reporting_date,
    reporting_date,

    previous_dpd_bucket,
    current_dpd_bucket,

    COUNT(*) AS migrated_accounts,

    ROUND(
        SUM(previous_overdue_exposure), 2
    ) AS previous_overdue_exposure,

    ROUND(
        SUM(current_overdue_exposure), 2
    ) AS current_overdue_exposure,

    ROUND(
        SUM(current_overdue_exposure)
        - SUM(previous_overdue_exposure), 2
    ) AS exposure_movement

FROM valid_monthly_migrations

GROUP BY
    previous_reporting_date,
    reporting_date,
    previous_dpd_bucket,
    current_dpd_bucket

ORDER BY
    reporting_date,
    previous_dpd_bucket,
    current_dpd_bucket;






-- ============================================================
-- EXERCISE 15: MONTHLY DPD ROLL RATE ANALYSIS
-- PURPOSE: Calculate account migration percentages
-- ============================================================



-- ============================================================
-- PROJECT: Financial Risk Data Quality & Portfolio Monitoring
-- EXERCISE 15: MONTHLY DPD ROLL RATE ANALYSIS
--
-- PURPOSE:
-- Calculate the percentage of accounts migrating from
-- each previous-month DPD bucket to each current-month bucket.
-- ============================================================

WITH snapshot_buckets AS (
    SELECT
        account_id,
        reporting_date,
        dpd,

        CASE
            WHEN dpd = 0 THEN 'Current'
            WHEN dpd BETWEEN 1 AND 30 THEN '1-30 DPD'
            WHEN dpd BETWEEN 31 AND 60 THEN '31-60 DPD'
            WHEN dpd BETWEEN 61 AND 89 THEN '61-89 DPD'
            ELSE '90+ DPD'
        END AS dpd_bucket

    FROM portfolio_final.portfolio_snapshots
),

account_history AS (
    SELECT
        account_id,
        reporting_date,
        dpd_bucket,

        LAG(reporting_date) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_reporting_date,

        LAG(dpd_bucket) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_dpd_bucket

    FROM snapshot_buckets
),

monthly_migrations AS (
    SELECT
        account_id,
        previous_reporting_date,
        reporting_date,
        previous_dpd_bucket,
        dpd_bucket AS current_dpd_bucket

    FROM account_history

    WHERE previous_reporting_date IS NOT NULL
      AND DATE_TRUNC('month', reporting_date) =
          DATE_TRUNC('month', previous_reporting_date)
          + INTERVAL '1 month'
),

migration_counts AS (
    SELECT
        previous_reporting_date,
        reporting_date,
        previous_dpd_bucket,
        current_dpd_bucket,
        COUNT(DISTINCT account_id) AS migrated_accounts

    FROM monthly_migrations

    GROUP BY
        previous_reporting_date,
        reporting_date,
        previous_dpd_bucket,
        current_dpd_bucket
),

roll_rate_calculation AS (
    SELECT
        *,
        SUM(migrated_accounts) OVER (
            PARTITION BY
                previous_reporting_date,
                reporting_date,
                previous_dpd_bucket
        ) AS previous_bucket_accounts

    FROM migration_counts
)

SELECT
    previous_reporting_date,
    reporting_date,
    previous_dpd_bucket,
    current_dpd_bucket,
    migrated_accounts,
    previous_bucket_accounts,

    ROUND(
        migrated_accounts * 100.0 /
        NULLIF(previous_bucket_accounts, 0),
        2
    ) AS roll_rate_pct

FROM roll_rate_calculation

ORDER BY
    previous_reporting_date,
    previous_dpd_bucket,
    current_dpd_bucket;



/* We should verify that this consistency holds across all reporting periods and previous DPD buckets


WITH snapshot_buckets AS (
    SELECT
        account_id,
        reporting_date,
        dpd,

        CASE
            WHEN dpd = 0 THEN 'Current'
            WHEN dpd BETWEEN 1 AND 30 THEN '1-30 DPD'
            WHEN dpd BETWEEN 31 AND 60 THEN '31-60 DPD'
            WHEN dpd BETWEEN 61 AND 89 THEN '61-89 DPD'
            ELSE '90+ DPD'
        END AS dpd_bucket

    FROM portfolio_final.portfolio_snapshots
),

account_history AS (
    SELECT
        account_id,
        reporting_date,
        dpd_bucket,

        LAG(reporting_date) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_reporting_date,

        LAG(dpd_bucket) OVER (
            PARTITION BY account_id
            ORDER BY reporting_date
        ) AS previous_dpd_bucket

    FROM snapshot_buckets
),

monthly_migrations AS (
    SELECT
        account_id,
        previous_reporting_date,
        reporting_date,
        previous_dpd_bucket,
        dpd_bucket AS current_dpd_bucket

    FROM account_history

    WHERE previous_reporting_date IS NOT NULL
      AND DATE_TRUNC('month', reporting_date) =
          DATE_TRUNC('month', previous_reporting_date)
          + INTERVAL '1 month'
),

migration_counts AS (
    SELECT
        previous_reporting_date,
        reporting_date,
        previous_dpd_bucket,
        current_dpd_bucket,
        COUNT(DISTINCT account_id) AS migrated_accounts

    FROM monthly_migrations

    GROUP BY
        previous_reporting_date,
        reporting_date,
        previous_dpd_bucket,
        current_dpd_bucket
),

roll_rate_calculation AS (
    SELECT
        *,
        SUM(migrated_accounts) OVER (
            PARTITION BY
                previous_reporting_date,
                reporting_date,
                previous_dpd_bucket
        ) AS previous_bucket_accounts

    FROM migration_counts
)

SELECT
    previous_reporting_date,
    reporting_date,
    previous_dpd_bucket,

    MAX(previous_bucket_accounts) AS previous_bucket_accounts,
    SUM(migrated_accounts) AS total_migrated_accounts,

    ROUND(
        SUM(migrated_accounts) * 100.0 /
        NULLIF(MAX(previous_bucket_accounts), 0),
        2
    ) AS total_roll_rate_pct

FROM roll_rate_calculation

GROUP BY
    previous_reporting_date,
    reporting_date,
    previous_dpd_bucket

HAVING ABS(
    SUM(migrated_accounts) * 100.0 /
    NULLIF(MAX(previous_bucket_accounts), 0) - 100
) > 0.01

ORDER BY
    reporting_date,
    previous_dpd_bucket;



Expected result: Zero rows.

If rows appear, those periods and buckets need investigation.

One methodological point: this calculation measures roll rates among accounts with consecutive monthly snapshots. Accounts missing a subsequent snapshot are excluded. We'll document that limitation rather than presenting this as a complete roll rate for every account originally in the portfolio.
*/






