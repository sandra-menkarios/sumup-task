with date_spine as (

    select date_day
    from ( {{ dbt_utils.date_spine(
        start_date="'2020-01-01'::date",
        end_date= "'2030-12-31'::date",
        datepart="day"
    ) }} )

)

select
    date_day as date,
    EXTRACT(year from date_day) as year,
    EXTRACT(month from date_day) as month,
    EXTRACT(day from date_day) as day,
    TO_CHAR(date_day, 'Day') as day_of_week_name,
    EXTRACT(dow from date_day) as day_of_week_index,
    TO_CHAR(date_day, 'Month') as month_name,
    DATE_TRUNC('week', date_day) as week_start_date,
    DATE_TRUNC('month', date_day) as month_start_date,
    DATE_TRUNC('quarter', date_day) as quarter_start_date,
    DATE_TRUNC('year', date_day) as year_start_date
from date_spine
order by date_day