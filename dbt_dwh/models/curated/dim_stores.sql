select
    ingested_at,
    store_created_at,
    store_name,
    store_address,
    store_country,
    store_city,
    store_typology,
    store_id

from {{ ref('stg_stores') }}
