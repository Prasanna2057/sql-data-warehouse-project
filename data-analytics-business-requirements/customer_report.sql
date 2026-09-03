/*
================================================================================
Customer Report
================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviours
    
Highlights:
    1. Gather essential fields such as names, age and transaction details.
    2. Segments customers into categories (VIP, Regular, New ) and age groups.
    3.Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculate valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend

=============================================================================*/
CREATE VIEW gold.report_customers AS
WITH base_query AS (
/*-----------------------------------------------------------------------------
Base Query : Retrieves core columns from tales
-----------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        c.first_name
        || ' '
        || c.last_name                                   AS customer_name,
        trunc(months_between(sysdate, c.birthdate) / 12) AS age
    FROM
        gold.fact_sales    f
        LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
    WHERE
        order_date IS NOT NULL
), customer_aggregation AS (
/*-----------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer lovel
-----------------------------------------------------------------------------*/
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity,
        COUNT(DISTINCT product_key)  AS total_products,
        MAX(order_date)              AS last_order_date,
        trunc(months_between(
            max(order_date),
            min(order_date)
        ))                           AS lifespan
    FROM
        base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age < 20              THEN
            'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN
            '20-29'
        WHEN age BETWEEN 30 AND 39 THEN
            '30-39'
        WHEN age BETWEEN 40 AND 49 THEN
            '40-49'
        ELSE
            '50 and above'
    END                                             AS age_group,
    CASE
        WHEN total_sales > 5000
             AND lifespan >= 12 THEN
            'VIP'
        WHEN total_sales <= 5000
             AND lifespan >= 12 THEN
            'Regular'
        ELSE
            'New'
    END                                             AS customer_segment,
    last_order_date,
    trunc(months_between(sysdate, last_order_date)) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
--Compuate average order value (AVO)
    CASE
        WHEN total_sales = 0 THEN
            0
        ELSE
            round(total_sales / total_orders, 2)
    END                                             AS average_order_value,
 --Compuate average monthly spend
    CASE
        WHEN lifespan = 0 THEN
            lifespan
        ELSE
            round(total_sales / lifespan, 2)
    END                                             AS avg_monthly_spend
FROM
    customer_aggregation
