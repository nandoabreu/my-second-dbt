{{ config(
    materialized="incremental",
    incremental_strategy="append",
    unique_key="product_id",
    post_hook=["{{ create_index(this.schema, this.table, 'product_id') }}"],
    tags=["stg", "staging", "products"]
) }}

SELECT product_id
     , name AS product_name
     , category AS product_category
     , collection AS campaign_name
     , price AS product_price
     , rating AS product_rating
     , availability AS product_availability
     , CASE WHEN availability = 't' THEN NULL ELSE CURRENT_TIMESTAMP END AS discontinued_since
     , CURRENT_TIMESTAMP AS loaded_at
FROM {{ source("src", "products") }} s
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} n WHERE n.product_id = s.product_id
)
{% endif %}
