{% set unique_column = "order_item_id" %}

{{ config(
    unique_key=unique_column,
    post_hook=["{{ create_index(this.schema, this.table, '" ~ unique_column ~ "') }}"],
    tags=["staging", "stg", "order_items"]
) }}

SELECT
    {{ unique_column }}
  , order_id
  , product_id
  , product_price
  , 1 AS quantity
  , CURRENT_TIMESTAMP AS loaded_at
FROM {{ source("src", "order_items") }} s
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} n WHERE n.{{ unique_column }} = s.{{ unique_column }}
)
{% endif %}
