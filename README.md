# Financial Risk Data Quality & Portfolio Monitoring Analytics Lab

## Project overview
An educational, synthetic-data project demonstrating a practical workflow for monthly loan-portfolio monitoring, data-quality controls, delinquency segmentation, reconciliation and reporting.

**Reporting window:** January 2023–October 2026  
**Portfolio size:** 5,000 accounts in the latest snapshot (31 October 2026)  
**Tools:** PostgreSQL, SQL, Python, pandas, NumPy, Jupyter Notebook and Power BI

All records are synthetic. This project is not an operational credit decisioning system and does not claim regulatory or BCBS 239 compliance.

## Business questions
- How is the loan portfolio distributed across products?
- How many accounts are current or overdue at the reporting date?
- How is delinquency distributed across DPD buckets?
- How does delinquency migrate month to month?
- Can key portfolio datasets be validated and reconciled before reporting?

## Repository structure
- `data/raw/` — source synthetic input files.
- `data/processed/` — generated portfolio tables used by the analyses.
- `sql/` — schema creation, validation, portfolio and delinquency queries.
- `python/` — reusable data-quality and reconciliation scripts.
- `notebooks/` — data generation and exploratory/quality-control workflows.
- `docs/` — exercise-level analysis notes.
- `reports/` — exported KPI, reconciliation, validation and segmentation outputs.
- `powerbi/` — Power BI report file.
- `reports/screenshots/` — selected analysis evidence.

## Key results from the supplied outputs
At 31 October 2026, the supplied portfolio outputs report 5,000 accounts, 4,178 overdue accounts (83.56%), overdue exposure of ₹341,748,689.09 and maximum DPD of 1,365 days. These are synthetic portfolio results, not real-world portfolio benchmarks.

### DPD bucket convention
The consistent convention used in the final SQL correction and Python outputs is:
- Current: 0 DPD
- 1–30 DPD
- 31–60 DPD
- 61–89 DPD
- 90+ DPD

The original SQL used 61–90 and greater than 90. Seven accounts at exactly 90 DPD therefore appeared in different buckets across SQL and Python. The corrected SQL now places exactly 90 DPD in 90+.

`reports/product_wise_risk_segmentation_corrected.csv` is independently recalculated from the supplied processed CSVs using the above convention. It is not represented as the result of executing the SQL script against PostgreSQL.

## How to run
1. Create a PostgreSQL database for the project.
2. Execute the SQL files in `sql/` in numerical order where applicable. The later analysis scripts depend on the schema and tables created earlier.
3. Open the notebooks in `notebooks/` using Jupyter.
4. Install Python dependencies:
   ```bash
   python -m pip install -r requirements.txt
   ```
5. Run the reusable checks from the repository root:
   ```bash
   python python/data_quality_checks.py
   python python/reconciliation.py
   ```
6. Open `powerbi/Financial_Risk_Portfolio_Monitoring_Dashboard.pbix` in Power BI Desktop and refresh only after configuring the relevant data sources.

## Important interpretation notes
- `overdue_exposure` is overdue exposure, not total outstanding principal or total portfolio balance.
- DPD is a delinquency measure; 90+ DPD should not automatically be labelled NPA without an explicit policy definition and supporting fields.
- Missing `payment_date` values in unpaid payment records are expected in the supplied data and should be interpreted with payment status and amount fields, not treated as defects automatically.
- SQL execution and Power BI refresh must be verified in the local environment before claiming they ran successfully.

## AI-assisted workflow reflection
ChatGPT was used as an assistant for planning, code drafting, debugging, interpreting outputs and documentation. The workflow also exposed why AI-generated analysis must be checked against source data: the initial SQL and Python DPD bucket boundaries differed, producing a seven-account discrepancy. The discrepancy was resolved by inspecting the source snapshot and counting accounts at exactly 90 DPD. AI assistance did not replace local SQL execution, Power BI refresh or human validation.

## Limitations
- Synthetic data only; no customer or employer data.
- Educational analytics, not a production risk platform.
- No claim of regulatory compliance, IFRS 9 implementation, capital calculation or validated NPA classification.
- Database execution and report refresh depend on local configuration.
