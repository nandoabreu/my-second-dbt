{{ config(
    materialized='table',
    post_hook=[
        "
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pk_customers') THEN
                ALTER TABLE {{ this }} ADD CONSTRAINT pk_customers PRIMARY KEY (customer_id);
            END IF;
        END$$;
        ",
    ],
) }}

SELECT customer_id
     , email
     , gender
     , city
     , country
FROM {{ source("src", "customers") }} s
WHERE NOT EXISTS (
    SELECT 1 FROM {{ source("src", "customers_delayed") }} d WHERE d._id = s.customer_id
)
