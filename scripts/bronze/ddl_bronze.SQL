/*DDL Script: Create Bronze Tables*/

CREATE TABLE bronze.crm_cust_info (
    cst_id             NUMBER,
    cst_key            VARCHAR2(50),
    cst_firstname      VARCHAR2(50),
    cst_lastname       VARCHAR2(50),
    cst_marital_status VARCHAR2(50),
    cst_gndr           VARCHAR2(50),
    cst_create_date    DATE
);


CREATE TABLE bronze.crn_prd_info (
    prd_id       NUMBER,
    prd_key      VARCHAR2(50),
    prd_nm       VARCHAR2(50),
    prd_cost     NUMBER,
    prd_line     VARCHAR2(50),
    prd_start_dt DATE,
    prd_end_dt   DATE
);

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  VARCHAR2(50),
    sls_prd_key  VARCHAR2(50),
    sls_cust_id  NUMBER,
    sls_order_dt DATE,
    sls_ship_dt  DATE,
    sls_due_dt   DATE,
    sls_sales    NUMBER,
    sls_quantity NUMBER,
    sls_price    NUMBER
);

CREATE TABLE bronze.erp_cust_az12 (
    cid   VARCHAR2(50),
    bdate DATE,
    gen   VARCHAR2(50)
);

CREATE TABLE bronze.erp_loc_a101 (
    cid   VARCHAR2(50),
    cntry VARCHAR2(50)
);

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          VARCHAR2(50),
    cat         VARCHAR2(50),
    subcat      VARCHAR2(50),
    maintenance VARCHAR2(50)
);
