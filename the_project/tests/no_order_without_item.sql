{{ config(severity="warn") }}

SELECT o.order_id, COUNT(oi.order_item_id)
FROM stg_orders o
     LEFT JOIN stg_order_items oi ON oi.order_id = o.order_id
GROUP BY 1
HAVING COUNT(oi.order_item_id) < 1
ORDER BY 1
