{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- set base = custom_schema_name if custom_schema_name is not none else target.schema -%}
  {{ base|lower }}
{%- endmacro %}
