
/*
Project: Financial Risk Data Quality &
         Portfolio Monitoring Analytics Lab

File: 01_create_product_reference.sql

Purpose:
Create the product master table for the
simulated NBFC loan portfolio.

Business Rules:
1. Every product must have a unique ID.
2. Product names must be unique.
3. Interest rate must be between 0 and 100.
4. Product status can only be Active or Inactive.
*/

CREATE TABLE product_reference (

    -- Unique identifier for each loan product
    product_id VARCHAR(20) PRIMARY KEY,

    -- Product name must be unique and mandatory
    product_name VARCHAR(60)
        NOT NULL UNIQUE,

    -- Annual interest rate stored as percentage
    interest_rate NUMERIC(5,2)
        NOT NULL
        CHECK (interest_rate >= 0
               AND interest_rate <= 100),

    -- Default product status
    product_status VARCHAR(20)
        NOT NULL DEFAULT 'Active'
        CHECK (product_status IN ('Active', 'Inactive')),

    -- Automatically capture record creation time
    created_at TIMESTAMP
        NOT NULL DEFAULT CURRENT_TIMESTAMP);



SELECT
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'product_reference'
  AND table_schema = 'public'
ORDER BY ordinal_position;



SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.product_reference'::regclass
ORDER BY contype, conname;



