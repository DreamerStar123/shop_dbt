# shop_dbt — a small dbt project you can run on your laptop

A tiny online shop: raw customers, orders and payments go in; clean `customers` and `orders` tables come out.
It uses **DuckDB**, a local file database, so you don't need a cloud warehouse or any login.

```
seeds (raw CSVs)          staging (views)          marts (tables)
raw_customers   ───────►  stg_customers  ─────────────────────►  customers
raw_orders      ───────►  stg_orders     ──┐                      ▲
raw_payments    ───────►  stg_payments   ──┴──►  orders  ─────────┘
```

## Project layout

```
shop_dbt/
├── dbt_project.yml              # project settings (name, folders, default materializations)
├── profiles.yml                 # connection settings (DuckDB file: shop.duckdb)
├── seeds/                       # raw data as CSV files
├── macros/cents_to_dollars.sql  # reusable SQL snippet
├── models/
│   ├── staging/                 # one cleanup model per raw table + tests (_staging.yml)
│   └── marts/                   # business-ready tables + tests (_marts.yml)
└── tests/                       # custom (singular) SQL tests
```

---

## Step-by-step

### 1. Install dbt
You need Python 3.10 or newer. In the `shop_dbt` folder:

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install dbt-core dbt-duckdb
dbt --version                      # should list core and the duckdb plugin
```

The YAML files use `data_tests:`, which needs dbt 1.8 or newer, and the `arguments:` blocks under the tests follow the newer format that dbt Fusion requires.

### 2. Check the connection
```bash
dbt debug --profiles-dir .
```
`--profiles-dir .` tells dbt to use the `profiles.yml` in this folder. You should see **All checks passed!**

To skip the flag on every command, copy `profiles.yml` to `~/.dbt/profiles.yml`, or run `export DBT_PROFILES_DIR=.` once per terminal session.

### 3. Load the raw data (seeds)
```bash
dbt seed --profiles-dir .
```
This loads the three CSVs as tables: `raw_customers`, `raw_orders` and `raw_payments`.
In a real project the raw data would arrive through an ingestion tool like Fivetran or Airbyte. Seeds are only for small, static files.

### 4. Build the models
```bash
dbt run --profiles-dir .
```
dbt reads every `ref()` and builds the models in dependency order: the 3 staging **views** first, then `orders`, then `customers`, both as **tables**.
To see the actual SQL dbt sent to the database, open `target/compiled/` or `target/run/`.

### 5. Test the data
```bash
dbt test --profiles-dir .
```
This runs the tests declared in the YAML files (`unique`, `not_null`, `accepted_values`, `relationships`) and the custom test in `tests/`. All should pass.

Tip: `dbt build --profiles-dir .` does seed, run and test together, in DAG order.

### 6. Look at the results
```bash
dbt show --select customers --profiles-dir .
```
Expected values (key columns only):

| customer_id | first_name | number_of_orders | lifetime_value |
|---|---|---|---|
| 1 | Ava   | 3 | 102.00 |
| 2 | Liam  | 2 | 54.50  |
| 3 | Sofia | 2 | 21.00  |
| 4 | Noah  | 2 | 136.00 |
| 5 | Mia   | 1 | 9.90   |
| 6 | Ethan | 0 | 0.00   |

Sofia's returned order ($33) is left out of her lifetime value, and Ethan has no orders.
You can also query `shop.duckdb` directly with the DuckDB CLI or any SQL tool, such as DBeaver.

### 7. Generate the documentation
```bash
dbt docs generate --profiles-dir .
dbt docs serve --profiles-dir .
```
This opens a website with every model, its columns and descriptions, and a lineage graph (click the graph icon at the bottom right).

---

## Exercises to try next

1. **Break a test.** In `seeds/raw_orders.csv`, change a status to `lost`, then run `dbt build`. The `accepted_values` test fails. Revert the change afterwards.
2. **Select part of the graph.** `dbt run --select stg_orders+` builds `stg_orders` and everything downstream of it. `dbt run --select +customers` builds `customers` and everything upstream of it.
3. **Change a materialization.** Add `{{ config(materialized='view') }}` at the top of `orders.sql` and run again.
4. **Add a model.** Create `models/marts/payment_methods.sql` that totals `amount` by `payment_method` from `ref('stg_payments')`. Then add a `unique` test on `payment_method`.
5. **Write a macro.** Make a macro that returns `'high'`, `'medium'` or `'low'` for a customer's lifetime value, and use it in `customers.sql`.

## Moving to a real warehouse
Install the adapter for your warehouse, such as `dbt-snowflake`, `dbt-bigquery` or `dbt-postgres`. Add an output for it in `profiles.yml`, and replace seeds with `sources` that point at your real raw tables. The models themselves don't change.
