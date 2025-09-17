{{ config(materialized='table') }}

SELECT
  proforma_id,
  periodo,
  area_id,
  area_nombre,
  fecha_proforma,
  n_cupos,
  total,
  descuento,
  impuestos
FROM {{ ref('stg_proforma') }}
WHERE fecha_proforma IS NOT NULL