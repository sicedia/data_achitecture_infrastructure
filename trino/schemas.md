# Trino Schemas

This document contains the necessary shell commands to create the schemas in Trino.

## Create Schema

To create a new schema in the iceberg catalog, you can use the following command:

```bash
-- DEV: crear schemas por sistema y dominios
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_bronze_sia
  WITH (location='s3a://cedia-datalake-dev/iceberg/bronze/sia/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_bronze_openerp
  WITH (location='s3a://cedia-datalake-dev/iceberg/bronze/openerp/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_bronze_pmo
  WITH (location='s3a://cedia-datalake-dev/iceberg/bronze/pmo/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_bronze_cedia_general
  WITH (location='s3a://cedia-datalake-dev/iceberg/bronze/cedia_general/');

CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_silver_finanzas
  WITH (location='s3a://cedia-datalake-dev/iceberg/silver/finanzas/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_silver_rrhh
  WITH (location='s3a://cedia-datalake-dev/iceberg/silver/rrhh/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_silver_procesos
  WITH (location='s3a://cedia-datalake-dev/iceberg/silver/procesos/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_silver_documentos
  WITH (location='s3a://cedia-datalake-dev/iceberg/silver/documentos/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_silver_proyectos
  WITH (location='s3a://cedia-datalake-dev/iceberg/silver/proyectos/');

CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_gold_bi_pge
  WITH (location='s3a://cedia-datalake-dev/iceberg/gold/bi_pge/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_gold_bi_idi
  WITH (location='s3a://cedia-datalake-dev/iceberg/gold/bi_idi/');
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_gold_bi_ia
  WITH (location='s3a://cedia-datalake-dev/iceberg/gold/bi_ia/');

-- PROD: repetir con iceberg_prod y buckets prod

```

Replace `my_schema` with the desired schema name.
