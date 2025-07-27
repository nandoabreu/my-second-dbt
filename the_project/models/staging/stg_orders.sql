{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_stg_orders') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_stg_orders PRIMARY KEY (order_id);
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
FROM {{ source("raw", "raw_orders") }}
