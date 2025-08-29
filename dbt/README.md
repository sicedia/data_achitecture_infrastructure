# dbt Proforma Pipeline with Trino, Iceberg, and Nessie

This document outlines the dbt pipeline for processing "proforma" data. It details the data flow from ingestion to final business intelligence (BI) models, including the purpose of each data layer (Bronze, Silver, Gold), the data models, the incremental processing logic (CDC), and instructions for running the pipeline using Docker Compose.

## Table of Contents

- [dbt Proforma Pipeline with Trino, Iceberg, and Nessie](#dbt-proforma-pipeline-with-trino-iceberg-and-nessie)
  - [Table of Contents](#table-of-contents)
  - [1. Data Flow Overview](#1-data-flow-overview)
  - [2. Data Layers](#2-data-layers)
    - [Bronze Layer](#bronze-layer)
    - [Silver Layer](#silver-layer)
    - [Gold Layer](#gold-layer)
  - [3. Data Models](#3-data-models)
    - [Bronze: `jvc_proforma`](#bronze-jvc_proforma)
    - [Silver: `stg_proforma`](#silver-stg_proforma)
    - [Gold: `fct_proforma`](#gold-fct_proforma)
  - [4. Incremental Logic (CDC) in Silver Layer](#4-incremental-logic-cdc-in-silver-layer)
  - [5. Project Structure](#5-project-structure)
  - [6. Key Configurations](#6-key-configurations)
    - [`dbt_project.yml`](#dbt_projectyml)
    - [`stg_proforma.sql`](#stg_proformasql)
  - [7. Getting Started: Running the Pipeline](#7-getting-started-running-the-pipeline)
    - [Prerequisites](#prerequisites)
    - [Development Environment](#development-environment)
    - [Production Environment](#production-environment)
  - [8. Validation and Maintenance](#8-validation-and-maintenance)
    - [Quick Validation in Trino](#quick-validation-in-trino)
    - [Maintenance Tasks](#maintenance-tasks)
  - [9. Troubleshooting](#9-troubleshooting)
  - [10. Glossary](#10-glossary)

## 1. Data Flow Overview

The pipeline processes data in the following sequence:

1.  **Airbyte**: Ingests data from a MariaDB source and lands it in an S3/Iceberg table (Bronze layer).
2.  **Trino + Nessie**: Provides the query engine and data cataloging capabilities.
3.  **dbt**: Executes SQL transformations to clean, standardize, and aggregate the data.
    -   **Silver Layer**: Cleans and standardizes the raw data (`stg_proforma`).
    -   **Gold Layer**: Creates aggregated tables for BI and analytics (`fct_proforma`).
4.  **Trino/BI Tools**: End users can query the Gold layer tables for analysis.

```mermaid
Airbyte (MariaDB → S3/Iceberg: Bronze)
       │
       ▼
Trino + Nessie (Catalog: iceberg_dev / iceberg_prod)
       │
       ▼
dbt (SQL + Jinja Transformations)
   ├─ Silver: stg_proforma      ← Cleans, standardizes, and applies CDC logic
   └─ Gold  : fct_proforma      ← Aggregates metrics for BI consumption
       │
       ▼
BI & Analytics Tools (Queries via Trino)
```

## 2. Data Layers

### Bronze Layer

-   **Purpose**: Raw data ingestion. Data is stored as it arrives from the source system via Airbyte.
-   **Location**: `iceberg_dev.cedia_bronze_sia.jvc_proforma`

### Silver Layer

-   **Purpose**: Cleaned and standardized data, ready for reuse.
-   **Tables**: `stg_*`
-   **Location**: `iceberg_dev.cedia_silver_sia`

### Gold Layer

-   **Purpose**: Aggregated data, ready for BI consumption.
-   **Tables**: `fct_*`, `dim_*`
-   **Location**: `iceberg_dev.cedia_gold_sia`

## 3. Data Models

### Bronze: `jvc_proforma`

This table contains the raw data from Airbyte, including CDC fields.

**Key Fields**:

-   `prof_codigo`: Technical ID, used as the primary key in the Silver layer.
-   `prof_numero`: Business proforma number.
-   `prof_fecha`: Proforma date.
-   `_airbyte_extracted_at`: Extraction timestamp.
-   `_ab_cdc_updated_at`, `_ab_cdc_deleted_at`: CDC fields for upserts and deletes.

### Silver: `stg_proforma`

This model cleans and standardizes the bronze data.

**Key Transformations**:

-   Renames and casts columns (e.g., `prof_codigo` -> `proforma_id`).
-   Handles CDC logic to perform upserts and deletes.
-   Converts timestamps to a consistent format.

### Gold: `fct_proforma`

This model aggregates the silver data for BI analysis.

**Example Aggregations**:

-   `n_proformas`: Number of proformas.
-   `total_bruto`: Gross total.
-   `total_neto`: Net total.

## 4. Incremental Logic (CDC) in Silver Layer

The `stg_proforma` model is materialized incrementally using a `merge` strategy.

-   **Input**: `jvc_proforma` (Bronze table with CDC data).
-   **Filter**: Ignores records where `_ab_cdc_deleted_at` is not null.
-   **Watermark**: `COALESCE(ab_cdc_updated_ts, modificado_en, airbyte_extracted_ts)`
-   **Unique Key**: `proforma_id`

## 5. Project Structure

```
dbt/
├── dbt_project.yml
├── profiles/
│   └── profiles.yml
├── macros/
│   ├── create_iceberg_schema.sql
│   └── generate_schema_name.sql
└── models/
    ├── sources/
    │   └── sia_sources.yml
    ├── silver/
    │   └── sia/
    │       ├── stg_proforma.sql
    │       └── schema.yml
    └── gold/
        └── sia/
            └── fct_proforma.sql
```

## 6. Key Configurations

### `dbt_project.yml`

```yaml
on-run-start:
  - "{% do create_iceberg_schema(target.database, 'cedia_silver_sia', 's3a://cedia-datalake-dev/iceberg/silver/sia/') %}"
  - "{% do create_iceberg_schema(target.database, 'cedia_gold_sia',   's3a://cedia-datalake-dev/iceberg/gold/sia/') %}"

models:
  cedia_dwh:
    +on_schema_change: append_new_columns
    +persist_docs: {relation: true, columns: true}
    +tmp_relation_type: table
    +intermediate_relation_type: table

    silver:
      +schema: cedia_silver_sia
      +materialized: incremental
      +incremental_strategy: merge
      +properties: {format_version: '2'}

    gold:
      +schema: cedia_gold_sia
      +materialized: table
```

### `stg_proforma.sql`

```sql
{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  unique_key='proforma_id',
  tmp_relation_type='table',
  intermediate_relation_type='table',
  properties={"format_version":"2"}
) }}
```

## 7. Getting Started: Running the Pipeline

### Prerequisites

-   Docker and Docker Compose
-   A running Trino instance connected to the `data-poc` network.

### Development Environment

1.  **Create the Docker network:**
    ```bash
    docker network create data-poc
    ```

2.  **Connect Trino to the network:**
    ```bash
    docker network connect data-poc trino
    ```

3.  **Test the dbt connection:**
    ```bash
    docker compose -p cedia -f ./dbt/docker-compose.yml run --rm dbt dbt debug --target dev
    ```

4.  **Build the models:**
    ```bash
    docker compose -p cedia -f ./dbt/docker-compose.yml run --rm dbt dbt build --target dev --select stg_proforma fct_proforma
    ```

5.  **Run incrementally:**
    ```bash
    docker compose -p cedia -f ./dbt/docker-compose.yml run --rm dbt dbt run --target dev --select stg_proforma
    ```

6.  **Full refresh (if needed):**
    ```bash
    docker compose -p cedia -f ./dbt/docker-compose.yml run --rm dbt dbt run --target dev --select stg_proforma --full-refresh
    ```

### Production Environment

1.  **Configure `profiles.yml` for production:**
    Ensure you have a `prod` output in your `profiles.yml` pointing to the production Iceberg catalog.

2.  **Parameterize sources and locations:**
    Update `sia_sources.yml` and `dbt_project.yml` to use `target.database` and conditional logic for production-specific paths.

3.  **Run dbt for production:**
    ```bash
    docker compose -p cedia -f ./dbt/docker-compose.yml run --rm dbt dbt build --target prod --select stg_proforma fct_proforma
    ```

## 8. Validation and Maintenance

### Quick Validation in Trino

```sql
-- Silver
SHOW TABLES FROM iceberg_dev.cedia_silver_sia;
SELECT * FROM iceberg_dev.cedia_silver_sia.stg_proforma LIMIT 5;

-- Gold
SHOW TABLES FROM iceberg_dev.cedia_gold_sia;
SELECT * FROM iceberg_dev.cedia_gold_sia.fct_proforma LIMIT 5;
```

### Maintenance Tasks

-   **Dropping a Silver table:**
    ```sql
    DROP TABLE IF EXISTS iceberg_dev.cedia_silver_sia.stg_proforma;
    ```
-   **Handling duplicate schemas:**
    Use the `generate_schema_name.sql` macro to prevent duplicate schemas.

## 9. Troubleshooting

-   **`createView is not supported for Iceberg Nessie catalogs`**:
    Add `tmp_relation_type='table'` and `intermediate_relation_type='table'` to your model or `dbt_project.yml`.
-   **`Permission denied: /home/dbtuser/app/logs/dbt.log`**:
    Set the `DBT_LOG_PATH` environment variable.
-   **`profiles.yml` or `dbt_project.yml` not found**:
    Check your volume mounts in `docker-compose.yml`.

## 10. Glossary

-   **Nessie**: A catalog for Iceberg that provides Git-like semantics for data.
-   **Iceberg**: A high-performance format for huge analytic tables.
-   **dbt**: A transformation workflow tool that lets you quickly and collaboratively deploy analytics code.
-   **CDC (Change Data Capture)**: A process that identifies and captures changes made to data in a database.
-   **MERGE**: An SQL operation that performs an `INSERT`, `UPDATE`, or `DELETE` on a target table based on a source table.
-   **Watermark**: A timestamp used to process only new or updated data.
