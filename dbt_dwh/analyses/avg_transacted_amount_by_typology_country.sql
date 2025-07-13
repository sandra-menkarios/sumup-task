
select store_typology,
	   store_country,
	   round(avg(stores_transactions_amount_in_eur), 2) as avg_stores_transactions_amount_in_eur

from {{ ref('mart_stores__transactions') }}
where transaction_status = 'accepted'
group by 1,2
order by 3 desc