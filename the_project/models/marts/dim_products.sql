WITH products_order_dates AS (
    SELECT oi.product_id, MAX(o.order_approved_at) as last_order_at
    FROM {{ ref('order_items') }} oi
         LEFT JOIN {{ ref('orders') }} o ON oi.order_id = o.order_id
    GROUP BY oi.product_id
)
SELECT p.product_id
     , p.product_name
     , p.product_category
     , p.campaign_name
     , od.last_order_at
FROM {{ ref('products') }} p
     LEFT JOIN products_order_dates od ON p.product_id = od.product_id
