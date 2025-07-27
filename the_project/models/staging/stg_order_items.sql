{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_stg_order_items') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_stg_order_items PRIMARY KEY (order_item_id);
            END IF;
        END$$;
        ",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_stg_order_items_stg_order_id FOREIGN KEY (order_id) REFERENCES {{ ref('stg_orders') }} (order_id)",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_stg_order_items_raw_product_id FOREIGN KEY (product_id) REFERENCES {{ source('raw', 'raw_products') }} (product_id)"
    ]
) }}

SELECT order_item_id
     , order_id
     , product_id
     , product_price
     , 1 AS quantity
FROM {{ source("raw", "raw_order_items") }}
