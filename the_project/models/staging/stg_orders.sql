SELECT order_id
     , customer_id
     , status AS order_status
     , order_approved_at
     , order_delivered_at
FROM {{ source("raw_data", "orders") }}
