/* Load Silver Layer (Bronze -> Silver) 

Script Purpose:
    This performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' tables from the 'bronze'.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
*/

-- Loading silver.crm_cust_info

TRUNCATE TABLE silver.crm_cust_info;

INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) cst_firstname,
        TRIM(cst_lastname)  cst_last_name,
        CASE
            WHEN upper(trim(cst_marital_status)) = 'M' THEN
                'Married'
            WHEN upper(trim(cst_marital_status)) = 'S' THEN
                'Single'
            ELSE
                'n/a'
        END                 cst_marital_status,
        CASE
            WHEN upper(trim(cst_gndr)) = 'M' THEN
                'Male'
            WHEN upper(trim(cst_gndr)) = 'F' THEN
                'Female'
            ELSE
                'n/a'
        END                 cst_gndr,
        cst_create_date
    FROM
        (
            SELECT
                c.*,
                ROW_NUMBER()
                OVER(PARTITION BY cst_id
                     ORDER BY
                         cst_create_date DESC
                ) AS flag_last
            FROM
                crm_cust_info c
            WHERE
                cst_id IS NOT NULL
        )
    WHERE
        flag_last = 1; -- Select the most recent record per customer

COMMIT;

--Loading silver.crm_prd_info
TRUNCATE TABLE silver.crm_prd_info;

INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
    SELECT
        prd_id,
        replace(
            substr(prd_key, 1, 5),
            '-',
            '_'
        )                       AS cat_id,        -- Extract category ID
        substr(prd_key,
               7,
               length(prd_key)) AS prd_key,       -- Extract product key
        prd_nm,
        nvl(prd_cost, 0)        AS prd_cost,
        CASE upper(trim(prd_line))
            WHEN 'M' THEN
                'Mountain'
            WHEN 'R' THEN
                'Road'
            WHEN 'S' THEN
                'Other Sales'
            WHEN 'T' THEN
                'Touring'
            ELSE
                'n/a'
        END                     AS prd_line,      -- Map product line codes to descriptive values
        prd_start_dt,
        LEAD(prd_start_dt)
        OVER(PARTITION BY prd_key
             ORDER BY
                 prd_start_dt
        ) - 1                   AS prd_end_dt        -- Calculate end date as one day before the next start date
    FROM
        bronze.crn_prd_info;

COMMIT;

--Loading crm_sales_details
TRUNCATE TABLE silver.crm_sales_details;

INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
    )
    SELECT
      sls_ord_num,
      sls_prd_key,
      sls_cust_id,
      CASE
          WHEN sls_order_dt = 0
               OR length(sls_order_dt) != 8 THEN
              NULL
          ELSE
              TO_DATE(to_char(sls_order_dt),
                      'YYYYMMDD')
      END AS sls_order_dt,
      CASE
          WHEN sls_ship_dt = 0
               OR length(sls_ship_dt) != 8 THEN
              NULL
          ELSE
              TO_DATE(to_char(sls_ship_dt),
                      'YYYYMMDD')
      END AS sls_ship_dt,
      CASE
          WHEN sls_due_dt = 0
               OR length(sls_due_dt) != 8 THEN
              NULL
          ELSE
              TO_DATE(to_char(sls_due_dt),
                      'YYYYMMDD')
      END AS sls_due_dt,
      CASE
          WHEN sls_sales IS NULL
               OR sls_sales <= 0
                  OR sls_sales != sls_quantity * abs(sls_price) THEN
              sls_quantity * abs(sls_price)
          ELSE
              sls_sales         
      END AS sls_sales,      -- Recalculate sales if original value is missing or incorrect
      sls_quantity,
      CASE
          WHEN sls_price IS NULL
               OR sls_price <= 0 THEN
              sls_sales / nullif(sls_quantity, 0)
          ELSE
              sls_price        -- Derive price if original value is invalid
      END AS sls_price
  FROM
      bronze.crm_sales_details
      
      commit;

-- Loading erp_cust_az12
TRUNCATE TABLE silver.erp_cust_az12;

INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN
                substr(cid,
                       4,
                       length(cid))         -- Remove 'NAS' prefix if present
            ELSE
                cid
        END AS cid,
        CASE
            WHEN bdate > sysdate THEN
                NULL
            ELSE
                bdate
        END bdate,          -- Set future birthdates to NULL
        CASE
            WHEN upper(trim(gen)) IN ( 'F', 'FEMALE' ) THEN
                'Female'
            WHEN upper(trim(gen)) IN ( 'M', 'MALE' ) THEN
                'Male'
            ELSE
                'n/a'
        END AS gen           -- Normalize gender values and handle unknown cases
    FROM
        bronze.erp_cust_az12 commit;

-- Loading erp_loc_a101
TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
    SELECT
        replace(cid, '-', '') cid,
        CASE
            WHEN TRIM(cntry) = 'DE' THEN
                'Germany'
            WHEN TRIM(cntry) IN ( 'US', 'USA' ) THEN
                'United States'
            WHEN TRIM(cntry) = ''
                 OR cntry IS NULL THEN
                'n/a'
            ELSE
                TRIM(cntry)
        END                   AS cntry                 -- Normalize and Handle missing or blank country codes
    FROM
        bronze.erp_loc_a101;


-- Loading erp_px_cat_g1v2
TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM
        bronze.erp_px_cat_g1v2;


