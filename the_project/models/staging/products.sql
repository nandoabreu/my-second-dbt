{% set unique_column = "product_id" %}

{{ config(
    unique_key=unique_column,
    post_hook=["{{ create_index(this.schema, this.table, '" ~ unique_column ~ "') }}"],
    tags=["stg", "staging", "products"]
) }}

SELECT {{ unique_column }}
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
    SELECT 1 FROM {{ this }} n WHERE n.{{ unique_column }} = s.{{ unique_column }}
)
{% endif %}
