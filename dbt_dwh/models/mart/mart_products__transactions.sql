with products as (
    select
        product_id,
        store_id,
        store_typology,
        store_country,
        transaction_status,
        sum(amount_eur) as products_purchased_amount_in_eur

    from {{ ref('int_transactions__stores') }}
    where date_part('day', transaction_happened_at - store_created_at) >= 0
    group by 1, 2, 3, 4, 5
)

select
    product_id,
    store_id,
    store_typology,
    store_country,
    transaction_status,
    products_purchased_amount_in_eur,
    row_number()
        over (
            partition by transaction_status
            order by products_purchased_amount_in_eur desc
        )
        as products_rank_by_amount

from products
