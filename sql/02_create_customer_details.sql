
/*
Project: Financial Risk Data Quality & Portfolio Monitoring Analytics Lab
File: 02_create_customer_details.sql

Purpose:
Maintain a central customer master for the simulated
loan portfolio. Customer information is stored separately
so that it does not need to be repeated across loan accounts.

Key design decisions:
- Each customer is identified by a unique customer ID.
- Mandatory customer information cannot be left blank.
- Customer onboarding date is stored separately from
  the date on which the database record is created.
*/

CREATE TABLE customer_details (

    -- Unique identifier assigned to each customer
    customer_id VARCHAR(20) PRIMARY KEY,

    -- Basic customer information
    customer_name VARCHAR(100) NOT NULL,

    -- Identifies whether the customer is an individual or business
    customer_type VARCHAR(30) NOT NULL,

    -- Customer location details
    city VARCHAR(60),
    state VARCHAR(60),

    -- Actual date on which the customer was onboarded
    onboarding_date DATE NOT NULL,

    -- Automatically records when the customer entry is created
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP

);




SELECT
	column_name,
	data_type,
	is_nullable,
	column_default
FROM information_schema.columns
WHERE table_schema = 'public'
	AND table_name = 'customer_details'
ORDER BY ordinal_position;
