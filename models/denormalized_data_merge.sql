{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='payment_id',
    on_schema_change='sync_all_columns'
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

-- Full upsert: every current source row flows through the MERGE on each run.
-- The unique_key (payment_id) keys the merge — matched rows are UPDATED in place,
-- new rows are INSERTED. No is_incremental() WHERE filter, so reruns re-merge all
-- rows (no truncate needed; updates are idempotent over static seeds).
select * from denormalized
