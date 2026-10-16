-- Mart: one row per customer with order history and lifetime value.
-- Returned orders don't count toward lifetime value.
with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('orders') }}
),

customer_orders as (
    select
        customer_id,
        min(order_date)  as first_order_date,
        max(order_date)  as most_recent_order_date,
        count(*)         as number_of_orders,
        sum(case when status != 'returned' then amount else 0 end) as lifetime_value
    from orders
    group by customer_id
)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.signup_date,
    co.first_order_date,
    co.most_recent_order_date,
    coalesce(co.number_of_orders, 0)  as number_of_orders,
    coalesce(co.lifetime_value, 0)    as lifetime_value
from customers c
left join customer_orders co using (customer_id)
