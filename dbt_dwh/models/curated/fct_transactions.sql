{{ config(
    post_hook=[
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_transaction_id ON {{ this }} (transaction_id)"
    ]
) }}

{% if is_incremental() %}
    with max_ingested_at as (
        select MAX(transaction_ingested_at) as max_ingested_at
        from {{ this }}
    )
{% endif %}

select distinct
    transaction_happened_at,
    transaction_ingested_at,
    transaction_id,
    stores.store_id,
    devices.device_id,
    product_id,
    amount_eur,
    transaction_status,
    card_number_hashed

from {{ ref('stg_transactions') }} as transactions
left join {{ ref('dim_devices') }} as devices
    on transactions.device_id = devices.device_id_per_store
left join {{ ref('stg_stores') }} as stores
    on devices.store_id = stores.store_id
left join {{ ref('dim_products') }} as products
    on
        transactions.product_sku = products.product_sku
        and devices.store_id = products.store_id

{% if is_incremental() %}
    cross join max_ingested_at
    where transaction_ingested_at > max_ingested_at.max_ingested_at
{% endif %}