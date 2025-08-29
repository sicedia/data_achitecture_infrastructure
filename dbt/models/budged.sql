{{ config(materialized='table') }}

select
  1            as id,
  'hello_dbt'  as msg,
  current_timestamp as loaded_at
