{{ config(materialized='table', table_properties={'format_version': '2'}) }}

SELECT
  proforma_id,
  proforma_numero,
  periodo,
  area_id,
  area_nombre,
  fecha_proforma,
  n_cupos,
  total,
  descuento,
  impuestos
FROM {{ ref('stg_sia__proforma') }}
WHERE fecha_proforma IS NOT NULL
