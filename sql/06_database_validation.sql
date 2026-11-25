
/*
Purpose:
Review the foreign-key relationships configured
across the loan portfolio database.
*/

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    rc.delete_rule
FROM information_schema.table_constraints tc

JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.constraint_schema = kcu.constraint_schema

JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.constraint_schema = ccu.constraint_schema

JOIN information_schema.referential_constraints rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.constraint_schema = rc.constraint_schema

WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'

ORDER BY tc.table_name;








/*
Purpose:
Review the primary key, unique and check constraints
configured across the five loan portfolio tables.
*/

SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
  AND tc.table_name IN (
      'product_reference',
      'customer_details',
      'loan_accounts',
      'repayment_information',
      'credit_snapshot'
  )
  AND tc.constraint_type IN (
      'PRIMARY KEY',
      'UNIQUE',
      'CHECK'
  )
ORDER BY
    tc.table_name,
    tc.constraint_type,
    tc.constraint_name;








/* =====================================================
   SECTION 1: TABLE STRUCTURE VALIDATION

   Review the columns and data types defined across
   the five loan portfolio tables.
   ===================================================== */

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'product_reference',
      'customer_details',
      'loan_accounts',
      'repayment_information',
      'credit_snapshot'
  )
ORDER BY
    table_name,
    ordinal_position;







/* =====================================================
   SECTION 4: MANDATORY FIELD VALIDATION

   Verify that essential repayment fields are
   configured as mandatory in the database.
   ===================================================== */

SELECT
    column_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'repayment_information'
  AND column_name IN (
      'installment_number',
      'amount_due',
      'amount_paid'
  )
ORDER BY column_name;
