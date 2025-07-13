select distinct
    transactions.transaction_id,
    transactions.amount_eur,
    transactions.transaction_status,
    transactions.product_id,
    transactions.transaction_ingested_at,
    transactions.transaction_happened_at,
    stores.store_id,
    stores.store_typology,
    stores.store_country,
    stores.store_created_at,
    transactions.device_id,
    devices.device_type

from {{ ref('fct_transactions') }} as transactions
left join
    {{ ref('dim_devices') }} as devices
    on transactions.device_id = devices.device_id
left join
    {{ ref('dim_stores') }} as stores
    on devices.store_id = stores.store_id