# Exercise 16: Product-wise Risk Segmentation

## 1. Business objective

The objective of this exercise is to segment the loan portfolio by
product as of **31 October 2026** and compare delinquency indicators
across products.

The analysis is intended to help a credit-risk or portfolio-monitoring
team: - compare account volumes and overdue-account rates across
products; - understand the distribution of overdue exposure; - review
delinquency severity using DPD buckets and maximum DPD; and - validate
that product-level reporting reconciles to the overall portfolio.

This is a portfolio-monitoring analysis of a synthetic dataset. It is
not a credit decision model or a regulatory classification.

## 2. Source tables and relationships

The analysis uses three tables in the `portfolio_final` schema.

  -------------------------------------------------------------------------
  Table                   Relevant fields inspected Purpose
  ----------------------- ------------------------- -----------------------
  `portfolio_snapshots`   `account_id`,             Monthly account-level
                          `reporting_date`,         portfolio and
                          `overdue_installments`,   delinquency snapshot
                          `overdue_exposure`, `dpd` 

  `loan_accounts`         `account_id`,             Links each loan account
                          `customer_id`,            to its product
                          `product_id`,             
                          `sanction_amount`,        
                          `disbursement_date`,      
                          `loan_tenure_months`,     
                          `account_status`,         
                          `maturity_date`           

  `product_reference`     `product_id`,             Product reference
                          `interest_rate`           attributes used in
                                                    segmentation
  -------------------------------------------------------------------------

The query joins the tables using:

-   `portfolio_snapshots.account_id = loan_accounts.account_id`
-   `loan_accounts.product_id = product_reference.product_id`

The reporting filter is
`portfolio_snapshots.reporting_date = DATE '2026-10-31'`.

## 3. Data-quality checks performed

### 3.1 Source structure inspection

Used `information_schema.columns` to inspect the column names and data
types of the three source tables before writing the segmentation query.

### 3.2 Product reference uniqueness

Grouped `product_reference` by `product_id` and checked for IDs with
`COUNT(*) > 1`.

**Observed result:** No rows were returned. The five product IDs
inspected each had one reference record.

### 3.3 Loan-to-product mapping

Used a `LEFT JOIN` from `loan_accounts` to `product_reference` and
filtered for missing product matches.

**Observed result:** No rows were returned. No unmapped product IDs were
identified by this check.

### 3.4 Account snapshot uniqueness

For the reporting date 31 October 2026, grouped `portfolio_snapshots` by
`account_id` and `reporting_date`, then filtered for `COUNT(*) > 1`.

**Observed result:** No rows were returned. No duplicate
account/reporting-date combinations were detected for the selected
reporting date.

These checks establish the outcomes of the specific validations
executed; they do not prove that every possible data-quality issue is
absent.

## 4. Product-wise portfolio results

The segmentation query returned the following results for 31 October
2026.

  -----------------------------------------------------------------------
  Product ID   Interest rate Total accounts        Overdue        Overdue
                                                  accounts   account rate
  ----------- -------------- -------------- -------------- --------------
  PL01                18.50%            983            805         81.89%

  CDL01               15.50%          1,009            849         84.14%

  BL01                16.00%          1,044            874         83.72%

  HL01                 8.50%            984            831         84.45%

  AL01                10.50%            980            819         83.57%

  **Total**              ---      **5,000**      **4,178**     **83.56%**
  -----------------------------------------------------------------------

The query also produced, for each product: - total overdue exposure; -
average overdue exposure among overdue accounts; - maximum DPD; and -
account counts in the 1--30, 31--60, 61--90 and 90+ DPD buckets.

The product-level overdue exposure values visible in the query output
were:

  Product ID     Total overdue exposure
  ------------ ------------------------
  PL01                   ₹72,879,406.70
  CDL01                  ₹72,241,254.48
  BL01                   ₹72,134,168.10
  HL01                   ₹62,435,965.02
  AL01                   ₹62,057,894.79
  **Total**         **₹341,748,689.09**

## 5. Key findings and interpretation

1.  The five product segments contain 5,000 accounts in total.
2.  The combined overdue-account count is 4,178, giving an overall
    overdue-account rate of 83.56% for this reporting date.
3.  HL01 has the highest overdue-account rate among the five products at
    84.45%; AL01 has the lowest at 83.57%. The difference is relatively
    narrow.
4.  PL01 has the highest overdue exposure in the displayed results
    (₹72.88 million), while AL01 has the lowest (₹62.06 million).
5.  The overdue-account rate and overdue-exposure amount answer
    different questions. A product with the largest overdue exposure
    does not necessarily have the highest overdue-account rate or the
    greatest risk after considering its portfolio size and balance
    distribution.

These are descriptive observations from one month-end snapshot. They do
not establish why delinquency occurred or whether product pricing caused
a difference in delinquency.

## 6. Reconciliation results

The product segmentation was checked against the overall October 2026
portfolio output.

  --------------------------------------------------------------------------
  Reconciliation    Product-level total    Overall portfolio Outcome
  measure                                             result 
  ---------------- -------------------- -------------------- ---------------
  Total accounts                  5,000                5,000 Matched

  Overdue accounts                4,178                4,178 Matched

  Overdue exposure      ₹341,748,689.09      ₹341,748,689.09 Matched
  --------------------------------------------------------------------------

The matching totals provide evidence that the product segmentation
accounts for the full portfolio for the selected reporting date, without
an observed difference in these three measures.

## 7. Limitations and assumptions

-   The analysis covers one reporting date: **31 October 2026**. It is
    not a trend analysis.
-   The overdue-account definition used in the SQL is `dpd > 0`.
-   DPD buckets are defined in the query as 1--30, 31--60, 61--90 and
    greater than 90 days.
-   `overdue_exposure` is treated as the overdue exposure measure
    supplied in `portfolio_snapshots`; its upstream business definition
    and calculation are not independently validated in this exercise.
-   `interest_rate` is a product reference attribute. The analysis does
    not establish a causal relationship between interest rate and
    delinquency.
-   The average overdue exposure is calculated only for rows where
    `dpd > 0`.
-   The uniqueness check is limited to the selected reporting date. It
    does not validate every historical month.
-   The mapping check validates loan-to-product matches against the
    current product reference table; it does not test historical changes
    to product attributes.
-   The results are based on synthetic project data and must not be
    presented as actual lender portfolio performance.
-   DPD greater than 90 is a delinquency bucket in this analysis; it
    should not automatically be described as an NPA classification. NPA
    status requires the applicable policy and regulatory definitions,
    which are outside this exercise.

## SQL implementation reference

The SQL for this exercise is maintained in the project's SQL script. It
includes: 1. source table structure inspection; 2. loan account
structure inspection; 3. product reference inspection; 4. duplicate
product ID validation; 5. loan-to-product mapping validation; 6.
product-wise portfolio risk segmentation; and 7. account snapshot
uniqueness validation.

## Exercise status

**SQL implementation and the listed validation checks: completed and
reviewed.**

This document records the observed query outputs and interpretation. It
does not replace the executable SQL script or the underlying dataset.
