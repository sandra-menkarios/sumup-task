select
    ingested_at,
    {{ dbt_utils.generate_surrogate_key(['store_id','device_id']) }} as device_id,
    device_id as device_id_per_store,
    device_type,
    store_id

from {{ ref('stg_devices') }}
