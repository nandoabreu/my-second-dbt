{{ config(
    materialized="incremental",
    incremental_strategy="append",
    unique_key='customer_id',
    post_hook=["{{ create_index(this.schema, this.table, 'customer_id') }}"],
    tags=["stg", "staging", "customers"]
) }}

SELECT customer_id
     , email
     , gender
     , city
     , country
     , CURRENT_TIMESTAMP AS loaded_at
FROM {{ source("src", "customers") }} s
{% if is_incremental() %}
WHERE NOT EXISTS (
    SELECT 1 FROM {{ this }} n WHERE n.customer_id = s.customer_id
)
{% endif %}
