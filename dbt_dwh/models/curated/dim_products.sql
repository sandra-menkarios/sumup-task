{% if is_incremental() %}
WITH max_ingested_at AS (
    SELECT MAX(product_ingested_at) AS max_ingested_at
    FROM {{ this }}
)
{% endif %}

select
    transaction_ingested_at as product_ingested_at,
    {{ dbt_utils.generate_surrogate_key(['store_id','product_sku']) }} as product_id,
    store_id,
    product_sku,
    product_name,
    category_name

from {{ ref('stg_transactions') }} as transactions
left join {{ ref('stg_devices') }} as devices
    on transactions.device_id = devices.device_id

{% if is_incremental() %}
CROSS JOIN max_ingested_at
WHERE transaction_ingested_at > max_ingested_at.max_ingested_at
{% endif %}