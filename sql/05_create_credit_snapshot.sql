
/*
Project: Financial Risk Data Quality & Portfolio Monitoring Analytics Lab
File: 05_create_credit_snapshot.sql

Purpose:
Maintain historical month-end positions for individual loan accounts.
The table will support portfolio exposure monitoring, delinquency
analysis and month-on-month risk movement.

Key design decisions:
- Each account can have multiple reporting-date records.
- An account can appear only once for a given reporting date.
- Outstanding balance and DPD cannot be negative.
- Account status represents the position at the reporting date,
  rather than only the current master status.
*/

CREATE TABLE credit_snapshot (

    -- Loan account associated with the reporting record
    account_id VARCHAR(20) NOT NULL,

    -- Month-end date for which the portfolio position is captured
    reporting_date DATE NOT NULL,

    -- Outstanding loan exposure as of the reporting date
    outstanding_balance NUMERIC(15,2)
        NOT NULL
        CHECK (outstanding_balance >= 0),

    -- Days past due as of the reporting date
    dpd INTEGER
        NOT NULL
        CHECK (dpd >= 0),

    -- Historical account status at the reporting date
    account_status VARCHAR(20)
        NOT NULL
        CHECK (account_status IN ('Active', 'Closed', 'Written Off')),

    -- Automatically records when the snapshot entry is created
    created_at TIMESTAMP
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate snapshots for the same account and date
    CONSTRAINT pk_credit_snapshot
        PRIMARY KEY (account_id, reporting_date),

    -- Ensure every snapshot belongs to a valid loan account
    CONSTRAINT fk_snapshot_account
        FOREIGN KEY (account_id)
        REFERENCES loan_accounts(account_id)
        ON DELETE RESTRICT

);
