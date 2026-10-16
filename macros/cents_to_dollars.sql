{#
  A macro is a reusable piece of SQL. Call it in a model with:
    {{ cents_to_dollars('amount_cents') }}
#}
{% macro cents_to_dollars(column_name, decimals=2) %}
    round({{ column_name }} / 100.0, {{ decimals }})
{% endmacro %}
