with source as (
    select *
    from {{ source('raw', 'stores') }}
)

select
    ingested_at,
    name as store_name,
    address as store_address,
    city as store_city,
    country as store_country,
    typology as store_typology,
    CAST(created_at as TIMESTAMP) as store_created_at,
    CAST(REPLACE(id, '.0', '') as INTEGER) as store_id,
    CAST(customer_id as INTEGER) as customer_id

from source
