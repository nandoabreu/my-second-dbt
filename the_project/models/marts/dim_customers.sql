WITH staged_customers AS (SELECT * FROM {{ ref("stg_customers") }})
   , staged_orders AS (SELECT * FROM {{ ref("stg_orders") }})
   , customer_orders AS (
        SELECT c.customer_id
             , c.gender
             , c.country
             , c.city
             , MIN(o.order_approved_at) AS first_order_date
             , MAX(o.order_approved_at) AS most_recent_order_date
             , COUNT(o.order_id) AS number_of_orders
        FROM staged_orders o
            INNER JOIN staged_customers c USING (customer_id)
        GROUP BY c.customer_id, c.gender, c.country, c.city, c.email
   )
SELECT * FROM customer_orders
