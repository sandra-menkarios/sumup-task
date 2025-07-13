with sources as (
    select *
    from {{ source('raw', 'transactions') }}
)

{% if is_incremental() %}
    , max_ingested_at as (
        select MAX(transaction_ingested_at) as max_ingested_at
        from {{ this }}
    )
{% endif %}

select
    status as transaction_status,
    CAST(ingested_at as TIMESTAMP) as transaction_ingested_at,
    CAST(created_at as TIMESTAMP) as transaction_created_at,
    CAST(happened_at as TIMESTAMP) as transaction_happened_at,
    CAST(REPLACE(id, '.0', '') as INTEGER) as transaction_id,
    CAST(REPLACE(device_id, '.0', '') as INTEGER) as device_id,
    LOWER(
        TRIM(
            both ' ' from REGEXP_REPLACE(
                product_name, '\b([a-zA-Z]+)[.,]', '\1', 'g'
            )
        )
    ) as product_name,
    CAST(
        REPLACE(
            REGEXP_REPLACE(product_sku, '^[a-zA-Z]+', ''), '.0', ''
        ) as NUMERIC
    ) as product_sku,
    LOWER(REGEXP_REPLACE(category_name, '[,\.]+$', '')) as category_name,
    CAST(amount as DECIMAL) as amount_eur,
    ENCODE(DIGEST(card_number, 'sha256'), 'hex') as card_number_hashed

from sources

{% if is_incremental() %}
    cross join max_ingested_at
    where CAST(ingested_at as TIMESTAMP) > max_ingested_at.max_ingested_at
{% endif %}
