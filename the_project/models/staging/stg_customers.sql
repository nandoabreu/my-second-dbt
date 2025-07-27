{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_stg_customers') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_stg_customers PRIMARY KEY (customer_id);
            END IF;
        END$$;
        "
    ]
) }}

SELECT customer_id
     , email
     , gender
     , city
     , country
FROM {{ source("raw", "raw_customers") }} raw
WHERE NOT EXISTS(
    SELECT 1 FROM {{ source("raw", "raw_customers_delayed") }} d WHERE d._id = raw.customer_id
  )
