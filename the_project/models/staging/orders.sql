{% set unique_column = "order_id" %}

{{ config(
    unique_key=unique_column,
    post_hook=["{{ create_index(this.schema, this.table, '" ~ unique_column ~ "') }}"],
    tags=["staging", "stg", "orders"]
) }}

SELECT
    {{ unique_column }}
  , customer_id
  , status AS order_status
  , order_approved_at
  , order_delivered_at
  , CURRENT_TIMESTAMP AS loaded_at
FROM {{ source("src", "orders") }} s
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} n WHERE n.{{ unique_column }} = s.{{ unique_column }}
)
{% endif %}
