-- A singular test: any rows this query returns count as failures.
select *
from {{ ref('orders') }}
where amount < 0
