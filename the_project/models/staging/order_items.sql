{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_order_items') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_order_items PRIMARY KEY (order_item_id);
            END IF;
        END$$;
        ",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_order_items_order_id FOREIGN KEY (order_id) REFERENCES {{ ref('orders') }}(order_id) NOT VALID",
        "ALTER TABLE {{ this }} ADD CONSTRAINT fk_order_items_product_id FOREIGN KEY (product_id) REFERENCES {{ source('src', 'products') }}(product_id) NOT VALID"
    ]
) }}

SELECT order_item_id
     , order_id
     , product_id
     , product_price
     , 1 AS quantity
FROM {{ source("src", "order_items") }}
