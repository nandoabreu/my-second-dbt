{% set unique_column = "customer_id" %}

{{ config(
    unique_key=unique_column,
    post_hook=["{{ create_index(this.schema, this.table, '" ~ unique_column ~ "') }}"],
    tags=["stg", "staging", "customers"]
) }}

SELECT {{ unique_column }}
     , email
     , gender
     , city
     , country
     , CURRENT_TIMESTAMP AS loaded_at
FROM {{ source("src", "customers") }} s
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} n WHERE n.{{ unique_column }} = s.{{ unique_column }}
)
{% endif %}
