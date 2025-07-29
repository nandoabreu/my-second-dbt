{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_orders') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);
            END IF;
        END$$;
        "
    ]
) }}

SELECT order_id
     , customer_id
     , status AS order_status
     , order_approved_at
     , order_delivered_at
FROM {{ source("src", "orders") }} s
WHERE NOT EXISTS (
    SELECT 1 FROM {{ source("src", "orders_delayed") }} d WHERE d._id = s.order_id
)
