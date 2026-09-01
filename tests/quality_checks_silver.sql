/*
Quality Checks

Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.
*/

-- Checking 'silver.crm_cust_info'
-- Check For Nulls or Duplicates in Primary Key
--Expectation: No Result
SELECT
    cst_id,
    COUNT(*)
FROM
    bronze.crm_cust_info
GROUP BY
    cst_id
HAVING COUNT(*) > 1
       OR cst_id IS NULL;

-- Check for unwanted Spaces
--Expectation: No Result
SELECT
    cst_lastname
FROM
    bronze.crm_cust_info
WHERE
    cst_lastname != TRIM(cst_lastname);

--Data Standardization & Consistency
SELECT DISTINCT
    cst_gndr
FROM
    bronze.crm_cust_info;

SELECT DISTINCT
    cst_marital_status
FROM
    bronze.crm_cust_info;


-- Checking 'silver.crm_prd_info'

--Check For Nulls  or Duplicates in Primary Key
--Expectation: No result
SELECT
    prd_id,
    COUNT(*)
FROM
    bronze.crn_prd_info
GROUP BY
    prd_id
HAVING COUNT(*) > 1
       OR prd_id IS NULL;

--Check for unwanted spaces
--Expectation: No Result

SELECT
    prd_nm
FROM
    bronze.crn_prd_info
WHERE
    prd_nm != TRIM(prd_nm);

--Check for NULLs or Negative Numbers
SELECT
    prd_cost
FROM
    bronze.crn_prd_info
WHERE
    prd_cost < 0
    OR prd_cost IS NULL;

--Data Standardization & Consistency
SELECT DISTINCT
    prd_line
FROM
    bronze.crn_prd_info;

--Check for Invalid Date Orders
SELECT
    *
FROM
    bronze.crn_prd_info
WHERE
    prd_end_dt < prd_start_dt;


-- Checking 'silver.crm_sales_details'
--Check for Invalid Dates
SELECT
    nullif(sls_due_dt, 0) sls_order_dt
FROM
    crm_sales_details
WHERE
    sls_due_dt = 0
    OR length(sls_due_dt) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101;

--Check for Invalid Date Orders
SELECT
    *
FROM
    silver.crm_sales_details
WHERE
    sls_order_dt > sls_due_dt
    OR sls_order_dt > sls_ship_dt;

--Check Data Consistency: Between Sales, Quantity and Price
-->> Sales = Quantity * Price
SELECT DISTINCT
    sls_sales ,
    sls_quantity,
    sls_price
FROM
    silver.crm_sales_details
WHERE
    sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0
ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;


-- Checking 'silver.erp_cust_az12'

--Identify Out-of-Range Dates
SELECT DISTINCT
    bdate
FROM
    bronze.erp_cust_az12
WHERE
    bdate < TO_DATE('1924-01-01', 'YYYY-MM-DD')
    OR bdate > sysdate;

--Data Standarization & Consistency
SELECT DISTINCT
    gen
FROM
    bronze.erp_cust_az12;

SELECT DISTINCT
    gen
FROM
    silver.erp_cust_az12;


-- Checking 'silver.erp_loc_a101'

-- Data Standardization & Consistency
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;


-- Checking 'silver.erp_px_cat_g1v2'
--Check for Unwanted Spaces
SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;
