select store_id,
	   stores_transactions_amount_in_eur

from {{ ref('mart_stores__transactions') }}
where transaction_status = 'accepted'
	and store_rank_by_status_transaction_amount <= 10
order by store_rank_by_status_transaction_amount
