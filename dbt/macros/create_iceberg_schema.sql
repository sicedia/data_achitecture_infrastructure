{% macro create_iceberg_schema(catalog, schema_name, location) -%}
  {%- set sql -%}
  CREATE SCHEMA IF NOT EXISTS {{ adapter.quote(catalog) }}.{{ adapter.quote(schema_name) }}
  WITH (location='{{ location }}');
  {%- endset -%}
  {% do run_query(sql) %}
  {{ return('') }}   -- <- evita que se imprima 'None'
{%- endmacro %}
