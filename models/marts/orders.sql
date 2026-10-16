-- Mart: one row per order with its total paid amount.
with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

order_payments as (
    select
        order_id,
        sum(amount)  as amount,
        count(*)     as payment_count
    from payments
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.status,
    coalesce(p.amount, 0)         as amount,
    coalesce(p.payment_count, 0)  as payment_count
from orders o
left join order_payments p using (order_id)
