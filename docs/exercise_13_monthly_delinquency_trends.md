# Exercise 13: Monthly Portfolio Delinquency Trends

## 1. Exercise Overview

**Project:** Financial Risk Data Quality & Portfolio Monitoring Analytics  
**Exercise:** 13 – Monthly Portfolio Delinquency Trends  
**Database:** PostgreSQL  
**Schema:** portfolio_final  
**Source Table:** portfolio_snapshots  
**Reporting Period:** January 2023 – October 2026  
**Reporting Frequency:** Monthly

## 2. Business Objective

The objective is to monitor the historical movement of portfolio delinquency and identify changes in overdue accounts, overdue instalments and overdue exposure over time.

This analysis helps a risk analytics team:

- Monitor portfolio delinquency trends.
- Track changes in overdue exposure.
- Understand delinquency severity through DPD buckets.
- Identify month-on-month movements.
- Support portfolio monitoring and management reporting.

## 3. Key Metrics

| Metric | Definition |
|---|---|
| Total Accounts | Total accounts represented in the monthly snapshot |
| Overdue Accounts | Accounts with overdue instalments |
| Overdue Account Rate | Overdue accounts / total accounts × 100 |
| Total Overdue Instalments | Number of overdue instalment records |
| Total Overdue Exposure | Outstanding overdue exposure |
| Average Overdue Exposure | Average overdue exposure per overdue account |
| Maximum DPD | Highest days past due observed |
| DPD Buckets | Overdue accounts grouped by delinquency severity |
| MoM Exposure Change | Current month's overdue exposure minus previous month's exposure |
| MoM Exposure Change % | Percentage change in overdue exposure against the previous month |

## 4. Reporting Results

The query generated **46 monthly records**, covering January 2023 through October 2026.

### October 2026 snapshot

| Metric | Result |
|---|---:|
| Reporting Date | 31 October 2026 |
| Snapshot Records | 5,000 |
| Total Accounts | 5,000 |
| Overdue Accounts | 4,178 |
| Overdue Account Rate | 83.56% |
| Total Overdue Instalments | 13,652 |
| Total Overdue Exposure | ₹34,174,868.09 |
| Average Overdue Exposure | ₹81,797.20 |
| Maximum DPD | 1,365 |
| Current Accounts | 822 |

### DPD Distribution – October 2026

| DPD Bucket | Accounts |
|---|---:|
| 1–30 DPD | 215 |
| 31–60 DPD | 103 |
| 61–90 DPD | 103 |
| 90+ DPD | 3,757 |
| **Total Overdue Accounts** | **4,178** |

## 5. Key Observations

1. The historical dataset contains 46 monthly snapshots with 5,000 accounts represented in each snapshot.
2. The overdue account rate increased from 0% in January 2023 to 83.56% in October 2026.
3. October 2026 recorded overdue exposure of approximately ₹3.42 crore.
4. The 90+ DPD bucket represents the largest delinquency category, with 3,757 accounts.
5. The historical results indicate a sustained increase in overdue accounts and overdue exposure throughout the reporting period.

These are observations from the synthetic portfolio dataset and should not be interpreted as actual market or lender performance.

## 6. Banking Relevance

Monthly delinquency monitoring is an important portfolio risk management activity.

It helps risk teams:

- Monitor deterioration in repayment performance.
- Identify changes in delinquency concentration.
- Track overdue exposure and its movement.
- Support portfolio review meetings.
- Identify areas requiring further investigation.

DPD buckets describe payment delinquency. They should not automatically be treated as equivalent to regulatory NPA classification.

## 7. Technical Concepts Used

- Monthly portfolio aggregation.
- Conditional aggregation.
- DPD bucket classification.
- Window functions for previous-month comparisons.
- LAG() for historical movement.
- Month-on-month absolute and percentage change calculations.
- Date-based reporting.

## 8. Evidence

The corresponding query is maintained in:

`sql/11_delinquency_analysis.sql`

Result screenshots are maintained in:

`reports/screenshots/`

- exercise_13_monthly_delinquency_trends(1).png
- exercise_13_monthly_delinquency_trends(2).png

## 9. Limitations and Interpretation Notes

- The dataset is synthetic and intended for educational portfolio analytics.
- The historical trend describes the generated dataset, not an actual financial institution.
- A high DPD value is not, by itself, sufficient evidence of NPA classification.
- Month-on-month changes should be interpreted alongside account-level movements and data-quality checks.
- The analysis is descriptive and does not establish the causes of delinquency growth.

## 10. Exercise Status

**Status:** SQL execution completed and result screenshots captured.

**Next step:** Continue with the next portfolio analytics exercise and retain its SQL script, result evidence and documentation separately.