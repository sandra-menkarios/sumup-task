with device_type_data as (
	select store_id,
		   device_id,
		   device_type,
		   transactions_count,
		   sum(transactions_count) over() as total_transactions
	from {{ ref('mart_devices__transactions') }}
	where transaction_status = 'accepted'
),


device_type_transactions as (
	SELECT device_type,
		   sum(transactions_count) as transactions_per_device_type
	from device_type_data
	group by 1
)

select device_type_t.device_type,
	   max(transactions_per_device_type)/max(total_transactions) as perc_transaction_per_device_type
from device_type_transactions as device_type_t
	left join device_type_data as device_type_d
		on device_type_t.device_type = device_type_d.device_type
group by 1
