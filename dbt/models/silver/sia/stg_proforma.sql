{{ config(
    materialized='table',
    tmp_relation_type='table',
    intermediate_relation_type='table',
    on_schema_change='append_new_columns',
    properties={
      "format_version": "2"
    }
) }}

WITH bronze AS (
  SELECT
    -- Campos crudos
    _airbyte_raw_id,
    _airbyte_extracted_at,               -- BIGINT (epoch s/ms)
    _airbyte_meta,
    _airbyte_generation_id,
    prof_area,
    prof_fecha,
    prof_total,
    prof_areaid,
    prof_codigo,                         -- BIGINT NOT NULL
    prof_estado,
    prof_numero,                         -- BIGINT (puede ser NULL)
    prof_paquete,
    prof_periodo,
    prof_nrocupos,
    prof_subtotal,
    prof_clienteid,
    prof_descuento,
    prof_fechacrea,
    prof_impuestos,
    _ab_cdc_cursor,
    prof_ultimoitem,
    _ab_cdc_log_pos,
    prof_diasvalidez,
    prof_nrocontrato,
    prof_usuariocrea,
    _ab_cdc_log_file,
    prof_fechavalidez,
    prof_tiposervicio,
    prof_cargocontacto,
    prof_contactocedia,
    prof_fechamodifica,
    prof_nombrecliente,
    prof_observaciones,
    prof_ultimoadjunto,
    _ab_cdc_deleted_at,                  -- VARCHAR
    _ab_cdc_updated_at,                  -- VARCHAR
    prof_codigocaracter,
    prof_correocontacto,
    prof_condicionespago,
    prof_contactocliente,
    prof_usuariomodifica,
    prof_telefonocontacto
  FROM {{ source('sia_bronze','jvc_proforma') }}
  -- Trata vacío como NULL y filtra bajas lógicas
  WHERE COALESCE(_ab_cdc_deleted_at, '') = ''
),
typed AS (
  SELECT
    -- PK técnica (ajusta si prefieres usar prof_numero)
    CAST(prof_codigo AS bigint)                      AS proforma_id,
    CAST(prof_numero AS bigint)                      AS proforma_numero,

    -- Fechas/horas
    CAST(prof_fecha AS date)                         AS fecha_proforma,
    CAST(prof_fechacrea AS timestamp(6))             AS creado_en,
    CAST(prof_fechamodifica AS timestamp(6))         AS modificado_en,
    CAST(prof_fechavalidez AS date)                  AS fecha_validez,

    -- Conversión de _airbyte_extracted_at (epoch s/ms -> timestamp)
  CAST(
      CASE
        WHEN _airbyte_extracted_at > 9999999999
          THEN from_unixtime(_airbyte_extracted_at / 1000.0)
        ELSE from_unixtime(_airbyte_extracted_at)
      END AS timestamp
    ) AS airbyte_extracted_ts,

    -- _ab_cdc_updated_at como timestamp (intenta ISO y casteo simple)
    COALESCE(
      CAST(TRY(from_iso8601_timestamp(_ab_cdc_updated_at)) AS timestamp),
      TRY(CAST(_ab_cdc_updated_at AS timestamp))
    )                                                AS ab_cdc_updated_ts,

    -- Numéricos
    CAST(prof_areaid AS bigint)                      AS area_id,
    CAST(prof_periodo AS bigint)                     AS periodo,
    CAST(prof_total AS double)                       AS total,
    CAST(prof_subtotal AS double)                    AS subtotal,
    CAST(prof_descuento AS double)                   AS descuento,
    CAST(prof_impuestos AS double)                   AS impuestos,
    CAST(prof_nrocupos AS double)                    AS n_cupos,
    CAST(prof_ultimoitem AS bigint)                  AS ultimo_item,
    CAST(prof_diasvalidez AS bigint)                 AS dias_validez,
    CAST(prof_ultimoadjunto AS bigint)               AS ultimo_adjunto,
    CAST(_ab_cdc_cursor AS bigint)                   AS ab_cdc_cursor,
    CAST(_ab_cdc_log_pos AS double)                  AS ab_cdc_log_pos,

    -- Texto
    CAST(prof_area AS varchar)                       AS area_nombre,
    CAST(prof_estado AS varchar)                     AS estado,
    CAST(prof_paquete AS varchar)                    AS paquete,
    CAST(prof_clienteid AS varchar)                  AS cliente_id,
    CAST(prof_tiposervicio AS varchar)               AS tipo_servicio,
    CAST(prof_nrocontrato AS varchar)                AS nro_contrato,
    CAST(prof_usuariocrea AS varchar)                AS usuario_crea,
    CAST(_ab_cdc_log_file AS varchar)                AS ab_cdc_log_file,
    CAST(prof_cargocontacto AS varchar)              AS cliente_cargo,
    CAST(prof_contactocedia AS varchar)              AS contacto_cedia,
    CAST(prof_nombrecliente AS varchar)              AS cliente_nombre,
    CAST(prof_observaciones AS varchar)              AS observaciones,
    CAST(prof_codigocaracter AS varchar)             AS codigo_caracter,
    CAST(prof_correocontacto AS varchar)             AS cliente_correo,
    CAST(prof_condicionespago AS varchar)            AS condiciones_pago,
    CAST(prof_contactocliente AS varchar)            AS cliente_contacto,
    CAST(prof_usuariomodifica AS varchar)            AS usuario_modifica,
    CAST(prof_telefonocontacto AS varchar)           AS cliente_telefono,

    -- Auditoría Airbyte
    CAST(_airbyte_raw_id AS varchar)                 AS airbyte_raw_id
  FROM bronze
)
SELECT
  *,
  -- Watermark unificada para auditoría
  COALESCE(ab_cdc_updated_ts, modificado_en, airbyte_extracted_ts) AS _wm_last_update
FROM typed
