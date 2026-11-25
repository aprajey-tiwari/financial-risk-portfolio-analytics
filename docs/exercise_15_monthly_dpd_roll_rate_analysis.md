# Exercise 15: Monthly DPD Roll Rate Analysis

## 1. Exercise Overview

**Project:** Financial Risk Data Quality & Portfolio Monitoring Analytics  
**Exercise:** 15 – Monthly DPD Roll Rate Analysis  
**Database:** PostgreSQL  
**Schema:** `portfolio_final`  
**Source Table:** `portfolio_snapshots`  
**Reporting Frequency:** Monthly  
**Reporting Period:** January 2023 – October 2026

## 2. Business Objective

The objective is to analyse how loan accounts migrate between delinquency buckets from one monthly reporting period to the next.

This analysis helps a credit risk analytics team:

- Monitor deterioration and improvement in portfolio delinquency.
- Identify accounts moving into higher DPD buckets.
- Track accounts returning to the Current bucket.
- Measure the proportion of accounts migrating between delinquency categories.
- Support portfolio monitoring and early-warning analysis.

## 3. DPD Bucket Classification

The analysis uses the following delinquency categories:

| DPD Bucket | Classification |
|---|---|
| Current | DPD = 0 |
| 1–30 DPD | DPD between 1 and 30 |
| 31–60 DPD | DPD between 31 and 60 |
| 61–90 DPD | DPD between 61 and 90 |
| 91+ DPD | DPD greater than 90 |

These are analytical buckets used in this project. They should not automatically be interpreted as regulatory NPA classifications.

## 4. Analytical Methodology

The analysis follows these steps:

1. Identify consecutive monthly reporting periods.
2. Classify accounts into DPD buckets for each reporting period.
3. Match accounts across consecutive reporting periods.
4. Identify each account's previous and current DPD bucket.
5. Aggregate migrated accounts by previous and current bucket.
6. Calculate the roll rate for each migration category.
7. Validate the distribution of migration percentages.

## 5. Roll Rate Formula

**Roll Rate (%) =**

Migrated accounts from a previous bucket to a current bucket  
÷ Total accounts in the previous bucket  
× 100

The denominator is the number of accounts in the previous bucket that have a matched snapshot in the next reporting period.

Therefore, the calculation represents migration among matched accounts, not necessarily the entire original portfolio population.

## 6. SQL Output

The analysis generated 424 migration-result rows.

Key output fields include:

| Field | Description |
|---|---|
| previous_reporting_date | Earlier reporting date |
| reporting_date | Current reporting date |
| previous_dpd_bucket | Earlier delinquency category |
| current_dpd_bucket | Current delinquency category |
| migrated_accounts | Number of accounts in the migration combination |
| previous_bucket_accounts | Matched account population in the previous bucket |
| roll_rate_pct | Percentage of the previous bucket migrating to the current bucket |

## 7. Validation and Reconciliation

A separate SQL validation was performed by grouping the migration results by reporting-period pair and previous DPD bucket.

The validation checked whether the sum of roll rates across all current buckets equalled 100%, within a tolerance of 0.01 percentage points.

**Validation result:**

- Validation query executed successfully.
- Exceptions returned: 0.
- All tested groups passed the roll-rate distribution check.

This confirms arithmetic consistency of the migration percentages.

It does not independently establish the completeness of the source population or correctness of the underlying DPD classifications.

## 8. Business Interpretation

The migration matrix helps distinguish:

- **Deterioration:** Accounts moving into higher delinquency buckets.
- **Improvement:** Accounts moving into lower delinquency buckets.
- **Cure:** Accounts moving from a delinquent bucket to Current.
- **Persistence:** Accounts remaining in the same delinquency bucket.

These movements can help risk teams identify emerging portfolio deterioration and monitor recovery patterns.

## 9. Important Limitations

1. Roll rates depend on accounts having matched snapshots in consecutive reporting periods.
2. Accounts without a subsequent reporting-period snapshot are not represented in the matched migration population.
3. The results depend on the accuracy of the source DPD and bucket classification.
4. A 100% roll-rate reconciliation confirms percentage distribution, not data completeness or business accuracy.
5. Migration patterns alone do not establish the cause of delinquency changes.

## 10. Evidence and Project Files

**SQL analysis:** `sql/11_delinquency_analysis.sql`  
Use the existing SQL file containing Exercise 15. Do not create a duplicate SQL file solely for this exercise.

**Validation screenshot:** `reports/screenshots/exercise_15_roll_rate_validation.png`

**Documentation:** `docs/exercise_15_monthly_dpd_roll_rate_analysis.md`

## 11. Banking and Risk Analytics Concepts Demonstrated

- Delinquency bucket classification
- Month-on-month portfolio monitoring
- DPD migration analysis
- Roll rate calculation
- Portfolio deterioration and cure analysis
- SQL aggregation and reconciliation
- Analytical limitations and reporting controls

## 12. Exercise Conclusion

The monthly DPD roll rate analysis provides an account-level view of delinquency migration across consecutive reporting periods.

The SQL output was successfully generated, and the roll-rate distribution validation returned zero exceptions.

The analysis is suitable as an educational portfolio-monitoring exercise using synthetic project data. It should not be represented as a production regulatory reporting control.