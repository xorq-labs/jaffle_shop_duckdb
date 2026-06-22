{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    on_schema_change='append_new_columns'
  )
}}

with payments as (

    select * from {{ ref('stg_payments') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

denormalized as (

    select
        payments.payment_id,
        payments.order_id,
        orders.customer_id,
        payments.payment_method,
        payments.amount,
        orders.order_date,
        orders.status,
        customers.first_name,
        customers.last_name

    from payments
    left join orders    on payments.order_id  = orders.order_id
    left join customers on orders.customer_id = customers.customer_id

)

select * from denormalized

{% if is_incremental() %}

-- Insert a source row when ANY of its three keys is new relative to what's
-- already loaded: a new customer_id, order_id, or payment_id. With static
-- seeds every key already exists after the first build, so reruns insert 0
-- rows (one-shot) until the table is truncated / --full-refresh'd.
where
    payment_id not in (select payment_id from {{ this }})
    or order_id not in (select order_id from {{ this }})
    or customer_id not in (select customer_id from {{ this }})

{% endif %}
