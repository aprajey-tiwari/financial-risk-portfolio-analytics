# Exercise 14: Monthly DPD Bucket Migration Analysis

## 1. Exercise Overview

- **Project:** Financial Risk Data Quality & Portfolio Monitoring Analytics
- **Exercise:** 14 – Monthly DPD Bucket Migration Analysis
- **Database:** PostgreSQL
- **Schema:** `portfolio_final`
- **Source table:** `portfolio_snapshots`
- **Portfolio size:** 5,000 accounts
- **Reporting period:** January 2023 – October 2026
- **Reporting frequency:** Monthly

## 2. Business Objective

Analyse how loan accounts move between delinquency buckets from one month-end reporting date to the next.

The analysis helps a credit risk analytics team identify:

- Accounts moving from current to overdue.
- Accounts migrating into more severe delinquency categories.
- Accounts improving or returning to current status.
- Changes in overdue exposure between reporting periods.

## 3. DPD Bucket Classification

The analysis uses the following delinquency categories:

| DPD Bucket | Classification |
|---|---|
| Current | DPD = 0 |
| 1–30 DPD | DPD between 1 and 30 |
| 31–60 DPD | DPD between 31 and 60 |
| 61–90 DPD | DPD between 61 and 90 |
| 91+ DPD | DPD greater than 90 |

## 4. Analytical Methodology

The analysis compares consecutive monthly portfolio snapshots.

For each account, the previous and current DPD buckets are compared to identify its migration.

The output includes:

- Previous reporting date
- Current reporting date
- Previous DPD bucket
- Current DPD bucket
- Number of migrated accounts
- Previous overdue exposure
- Current overdue exposure
- Exposure movement

### Exposure Movement

Exposure movement is calculated as:

`Current Overdue Exposure - Previous Overdue Exposure`

A positive value indicates an increase in overdue exposure, while a negative value indicates a decrease.

## 5. Monthly Continuity Validation

Month-end dates do not always have the same calendar day. For example:

- 31 January → 28 February
- 28 February → 31 March

The SQL logic uses calendar-month comparison rather than adding one month to the exact previous reporting date.

This prevents valid month-end transitions from being excluded.

## 6. Results and Validation

- The corrected query returned 424 migration output rows.
- February 2023 to March 2023 migration was successfully verified.
- Monthly transitions are represented through previous and current reporting dates.
- DPD bucket movements and exposure changes are available in the output.

The 424 rows represent migration-category combinations across reporting periods, not unique loan accounts.

## 7. Banking Relevance

DPD migration analysis supports:

- Portfolio delinquency monitoring.
- Early identification of deterioration.
- Monitoring of accounts moving into higher-risk delinquency buckets.
- Assessment of overdue exposure movement.
- Management risk reporting.

Migration into a more severe DPD bucket is a monitoring indicator and should not independently be interpreted as a confirmed default or NPA classification.

## 8. Technical Skills Demonstrated

- SQL CTEs
- CASE WHEN
- Conditional aggregation
- Date and interval operations
- Date truncation
- Monthly continuity validation
- DPD bucket classification
- Account-level aggregation
- Exposure movement calculation

## 9. Evidence

Screenshot: `reports/screenshots/exercise_14_dpd_migration_final.png`

SQL source: `sql/11_delinquency_analysis.sql`

## 10. Limitations

The analysis uses the simulated portfolio dataset and its existing DPD and exposure definitions.

Migration results should be interpreted alongside the portfolio's metric definitions, reporting-date conventions and data-quality controls.

This is an educational portfolio analysis and does not establish regulatory compliance.