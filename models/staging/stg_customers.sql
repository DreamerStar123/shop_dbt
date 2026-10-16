-- Staging: rename columns and tidy values. One staging model per raw table.
select
    id                         as customer_id,
    first_name,
    last_name,
    lower(trim(email))         as email,
    cast(signup_date as date)  as signup_date
from {{ ref('raw_customers') }}
