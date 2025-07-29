{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_products') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_products PRIMARY KEY (product_id);
            END IF;
        END$$;
        "
    ]
) }}

SELECT product_id
     , name AS product_name
     , category AS product_category
     , collection AS campaign_name
     , price AS product_price
     , rating AS product_rating
     , availability AS product_availability
     , CASE WHEN availability IS TRUE THEN NULL ELSE CURRENT_TIMESTAMP END AS discontinued_since
     , CURRENT_TIMESTAMP AS updated_at
     , CURRENT_TIMESTAMP AS created_at
FROM {{ source("src", "products") }} s
WHERE NOT EXISTS (
    SELECT 1 FROM {{ source("src", "products_delayed") }} d WHERE d._id = s.product_id
)
