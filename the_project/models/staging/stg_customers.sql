SELECT customer_id
     , email
     , gender
     , city
     , country
FROM {{ source("source", "customers") }}
