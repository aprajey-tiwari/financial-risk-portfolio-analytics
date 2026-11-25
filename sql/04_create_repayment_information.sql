
/*
Project: Financial Risk Data Quality & Portfolio Monitoring Analytics Lab
File: 04_create_repayment_information.sql

Purpose:
Maintain installment-level repayment information for the
simulated loan portfolio. Each record represents one scheduled
installment against a loan account.

Key design decisions:
- Every installment has a unique repayment record ID.
- Each installment must belong to an existing loan account.
- The same installment cannot be recorded twice for one account.
- Partial payments are permitted.
- Payment date remains blank until a payment is received.
*/

CREATE TABLE repayment_information (

    -- Unique identifier for each scheduled installment
    repayment_id VARCHAR(25) PRIMARY KEY,

    -- Link the installment to an existing loan account
    account_id VARCHAR(20) NOT NULL,

    -- Sequence number of the installment within the loan
    installment_number INTEGER
        NOT NULL
        CHECK (installment_number > 0),

    -- Scheduled repayment date
    due_date DATE NOT NULL,

    -- Actual payment date; remains NULL if unpaid
    payment_date DATE,

    -- Amount scheduled for the installment
    amount_due NUMERIC(15,2)
        NOT NULL
        CHECK (amount_due > 0),

    -- Cumulative amount received against this installment
    amount_paid NUMERIC(15,2)
        NOT NULL DEFAULT 0
        CHECK (amount_paid >= 0 AND amount_paid <= amount_due),

    -- Automatically records when the installment entry is created
    created_at TIMESTAMP
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Prevent duplicate installment numbers within the same account
    CONSTRAINT uq_account_installment
        UNIQUE (account_id, installment_number),

    -- Ensure every repayment record belongs to a valid loan account
    CONSTRAINT fk_repayment_account
        FOREIGN KEY (account_id)
        REFERENCES loan_accounts(account_id)
        ON DELETE RESTRICT

);
