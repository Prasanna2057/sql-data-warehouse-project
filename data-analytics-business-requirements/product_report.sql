/*
================================================================================
Product Report
================================================================================
Purpose:
    - This report consolidates key product metrics and behaviours
    
Highlights:
    1. Gather essential fields such as product names, category, subcategory and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range or Low-Performers.
    3.Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculate valuable KPIs:
        - recency (months since last sales)
        - average order revenue (AOR)
        - average monthly revenue

=============================================================================*/
CREATE VIEW gold.report_products AS
WITH base_query AS (
/*-----------------------------------------------------------------------------
Base Query : Retrieves core columns from tales
-----------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM
        gold.fact_sales   f
        LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
    WHERE
        f.order_date IS NOT NULL
), product_aggregations AS (
/*-----------------------------------------------------------------------------
 2) Product Aggregations: Summarizes key metrics at the product lovel
-----------------------------------------------------------------------------*/
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        trunc(months_between(
            max(order_date),
            min(order_date)
        ))                           AS lifespan,
        MAX(order_date)              AS last_sale_date,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity,
        round(
            avg(sales_amount / nullif(quantity, 0)),
            1
        )                            AS avg_selling_price
    FROM
        base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)
/*-----------------------------------------------------------------------------
3) Final Query: Combines all product results into one output
----------------------------------------------------------------------------*/

SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    trunc(months_between(sysdate, last_sale_date)) AS recency_in_months,
    CASE
        WHEN total_sales > 50000  THEN
            'High-Performer'
        WHEN total_sales >= 10000 THEN
            'Mid-Range'
        ELSE
            'Low-Performer'
    END                                            AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    --Average Order Revenue (AOR)
    CASE
        WHEN total_orders = 0 THEN
            0
        ELSE
            round(total_sales / total_orders, 2)
    END                                            AS avg_order_revenue,
    
    --Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN
            total_sales
        ELSE
            round(total_sales / lifespan, 2)
    END                                            AS avg_monthly_revenue
FROM
    product_aggregations;
