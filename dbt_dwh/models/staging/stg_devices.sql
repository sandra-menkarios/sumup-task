with source as (
    select *
    from {{ source('raw', 'devices') }}
)

select
    cast(ingested_at as timestamp) as ingested_at,
    cast(replace(id, '.0', '') as integer) as device_id,
    cast(replace(type, '.0', '') as integer) as device_type,
    cast(replace(store_id, '.0', '') as integer) as store_id

from source
