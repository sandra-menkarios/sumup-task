with devices as (
    select
        store_id,
        device_id,
        device_type,
        transaction_id,
        transaction_status

    from {{ ref('int_transactions__stores') }}
    where DATE_PART('day', transaction_happened_at - store_created_at) >= 0
)

select distinct
    store_id,
    device_id,
    device_type,
    transaction_status,
    COUNT(distinct transaction_id) as transactions_count

from devices
group by 1, 2, 3, 4
