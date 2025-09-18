{{ config(
    materialized='incremental',
    unique_key='proforma_id',
    incremental_strategy='merge',
    table_properties={'format_version': '2'}
) }}

WITH bronze AS (
  SELECT *
  FROM {{ source('sia_bronze','jvc_proforma') }}
  WHERE COALESCE(_ab_cdc_deleted_at,'') = ''
  {% if is_incremental() %}
    AND COALESCE(
          TRY(CAST(from_iso8601_timestamp(_ab_cdc_updated_at) AS timestamp)),
          TRY(from_unixtime(_airbyte_extracted_at/1000.0)),
          TRY(from_unixtime(_airbyte_extracted_at))
        )
        >
        (SELECT COALESCE(MAX(_wm_last_update), TIMESTAMP '1970-01-01') FROM {{ this }})
  {% endif %}
),
typed AS (
  SELECT
    -- claves
    CAST(prof_codigo AS bigint)      AS proforma_id,
    CAST(prof_numero AS bigint)      AS proforma_numero,

    -- fechas
    CAST(prof_fecha AS date)         AS fecha_proforma,

    -- numéricos
    CAST(prof_areaid AS bigint)      AS area_id,
    CAST(prof_periodo AS bigint)     AS periodo,
    CAST(prof_total AS double)       AS total,
    CAST(prof_subtotal AS double)    AS subtotal,
    CAST(prof_descuento AS double)   AS descuento,
    CAST(prof_impuestos AS double)   AS impuestos,
    CAST(prof_nrocupos AS double)    AS n_cupos,

    -- texto
    CAST(prof_area AS varchar)       AS area_nombre,
    CAST(prof_estado AS varchar)     AS estado,
    CAST(prof_clienteid AS varchar)  AS cliente_id,
    CAST(prof_nombrecliente AS varchar) AS cliente_nombre,

    -- watermark incremental (quedará en la tabla destino)
    COALESCE(
      TRY(CAST(from_iso8601_timestamp(_ab_cdc_updated_at) AS timestamp)),
      TRY(from_unixtime(_airbyte_extracted_at/1000.0)),
      TRY(from_unixtime(_airbyte_extracted_at))
    ) AS _wm_last_update
  FROM bronze
)

SELECT * FROM typed
