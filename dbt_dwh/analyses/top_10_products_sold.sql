select product_id, products_rank_by_amount

from {{ ref('mart_products__transactions') }}
where transaction_status = 'accepted'
order by products_rank_by_amount limit 10