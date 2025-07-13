with stores_transactions as (
    select distinct
        store_id,
        transaction_id,
        store_typology,
        store_country,
        transaction_status,
        transaction_happened_at,
        store_created_at,
        amount_eur

    from {{ ref('int_transactions__stores') }}
    where DATE_PART('day', transaction_happened_at - store_created_at) >= 0
),

stores_avg_days as (

    select distinct
        store_id,
        transaction_id,
        transaction_status,
        DATE_PART('day', transaction_happened_at - store_created_at) as store_age_at_transaction,
        ROW_NUMBER() over (partition by store_id, transaction_status order by transaction_happened_at asc) as store_rank_by_transaction_time

    from stores_transactions
),

top_stores as (
    select
        store_id,
        transaction_status,
        AVG(store_age_at_transaction) as avg_store_age_first_5_transactions_in_days

    from stores_avg_days
    where
        store_id in (
            select distinct store_id
			from stores_avg_days
            where store_rank_by_transaction_time = 5
        )
    group by 1, 2
),

stores_amount as (
    select distinct
        store_id,
        store_typology,
        store_country,
        transaction_status,
        SUM(amount_eur) as stores_transactions_amount_in_eur

    from stores_transactions
    group by 1, 2, 3, 4
),

stores_rank as (
    select distinct
        store_id,
        store_typology,
        store_country,
        transaction_status,
        stores_transactions_amount_in_eur,
        ROW_NUMBER() over (partition by transaction_status order by stores_transactions_amount_in_eur desc) as store_rank_by_status_transaction_amount

    from stores_amount
)

select
    stores_rank.store_id,
    store_typology,
    store_country,
    stores_rank.transaction_status,
    store_rank_by_status_transaction_amount,
    ROUND(stores_transactions_amount_in_eur, 2) as stores_transactions_amount_in_eur,
    ROUND(CAST(avg_store_age_first_5_transactions_in_days as decimal), 2) as avg_store_age_first_5_transactions_in_days

from stores_rank
left join top_stores
    on stores_rank.store_id = top_stores.store_id
        and stores_rank.transaction_status = top_stores.transaction_status
