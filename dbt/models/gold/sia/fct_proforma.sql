{{ config(materialized='table') }}

WITH base AS (
  SELECT
    proforma_id,
    periodo,
    area_id,
    area_nombre,
    fecha_proforma,
    n_cupos,
    total,
    descuento,
    impuestos,
    (COALESCE(total,0) - COALESCE(descuento,0) + COALESCE(impuestos,0)) AS total_neto,
    estado
  FROM {{ ref('stg_proforma') }}
  WHERE fecha_proforma IS NOT NULL
)

SELECT
  periodo,
  area_id,
  area_nombre,
  COUNT(DISTINCT proforma_id)                     AS n_proformas,
  SUM(COALESCE(n_cupos,0))                        AS cupos_totales,
  ROUND(SUM(COALESCE(total,0)), 2)                AS total_bruto,
  ROUND(SUM(COALESCE(descuento,0)), 2)            AS total_descuento,
  ROUND(SUM(COALESCE(impuestos,0)), 2)            AS total_impuestos,
  ROUND(SUM(COALESCE(total_neto,0)), 2)           AS total_neto
FROM base
GROUP BY 1,2,3

