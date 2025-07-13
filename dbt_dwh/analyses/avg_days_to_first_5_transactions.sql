
select store_id,
	   avg_store_age_first_5_transactions_in_days

from {{ ref('mart_stores__transactions') }}
where transaction_status = 'accepted'
	and avg_store_age_first_5_transactions_in_days is not null
