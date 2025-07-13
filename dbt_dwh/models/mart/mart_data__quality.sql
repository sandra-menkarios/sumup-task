{{ config(
	materialized= 'view'
)
}}

SELECT distinct store_id,
				store_created_at,
				transaction_id,
				transaction_happened_at

FROM {{ ref('int_transactions__stores') }}
WHERE  DATE_PART('day', transaction_happened_at - store_created_at) < 0