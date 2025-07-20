SELECT customer_id
     , email
     , gender
     , city
     , country
FROM {{ source("raw_data", "customers") }}
