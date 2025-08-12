{{ config(
    tags=["mart", "customers"]
) }}

WITH
    staged_customers AS (SELECT * FROM {{ ref("customers") }})
  , raw_orders AS (SELECT * FROM {{ ref("orders") }})
  , customer_orders AS (
    SELECT c.customer_id
         , c.gender
         , c.city
         , c.country AS country_code
         , cc.name AS country_name
         , MIN(o.order_approved_at) AS first_order_date
         , MAX(o.order_approved_at) AS most_recent_order_date
         , COUNT(o.order_id) AS number_of_orders
    FROM raw_orders o
         INNER JOIN staged_customers c USING (customer_id)
         LEFT JOIN {{ ref("ref_countries") }} cc ON c.country = cc.code
    GROUP BY c.customer_id, c.gender, c.city, c.country, cc.name, c.email)
SELECT *, NOW() AS updated_at FROM customer_orders
