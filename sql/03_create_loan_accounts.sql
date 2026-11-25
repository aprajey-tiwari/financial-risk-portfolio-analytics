
/*
Project: Financial Risk Data Quality & Portfolio Monitoring Analytics Lab
File: 03_create_loan_accounts.sql

Purpose:
Maintain the loan account master for the simulated NBFC portfolio.
Each loan account is linked to an existing customer and loan product.

Key design decisions:
- Every loan account has a unique account ID.
- Customer and product references must exist in their respective master tables.
- Sanction amount and loan tenure must be positive.
- Account status is restricted to the defined business categories.
- Existing loan records cannot lose their customer or product references
  through accidental deletion of master records.
*/

CREATE TABLE loan_accounts (

    -- Unique identifier assigned to each loan account
    account_id VARCHAR(20) PRIMARY KEY,

    -- Link the loan account to an existing customer
    customer_id VARCHAR(20) NOT NULL,

    -- Identify the product under which the loan was sanctioned
    product_id VARCHAR(20) NOT NULL,

    -- Original sanctioned amount must be greater than zero
    sanction_amount NUMERIC(15,2)
        NOT NULL
        CHECK (sanction_amount > 0),

    -- Actual date on which the loan was disbursed
    disbursement_date DATE NOT NULL,

    -- Original repayment tenure expressed in whole months
    loan_tenure_months INTEGER
        NOT NULL
        CHECK (loan_tenure_months > 0),

    -- Current status of the loan account
    account_status VARCHAR(20)
        NOT NULL
        CHECK (account_status IN ('Active', 'Closed', 'Written Off')),

    -- Automatically records when the loan account entry is created
    created_at TIMESTAMP
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Maintain the relationship with the customer master
    CONSTRAINT fk_loan_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer_details(customer_id)
        ON DELETE RESTRICT,

    -- Maintain the relationship with the product master
    CONSTRAINT fk_loan_product
        FOREIGN KEY (product_id)
        REFERENCES product_reference(product_id)
        ON DELETE RESTRICT

);
