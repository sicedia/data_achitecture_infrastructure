# Data Engineering Best Practices and Architecture

This document outlines the recommended architecture and best practices for our data platform. It is designed to serve as a reference for data engineers, especially those new to the team or our toolset.

---

## **Part 0: Core Principles & Tooling**

Before diving into the architecture, let's understand the "why" behind our choices and the tools we use.

### **What Are We Trying to Achieve?**

*   **Environment Isolation:** Separate environments (dev, prod) to reduce risk. A mistake in development should never impact the production system.
*   **Code Promotion, Not Data Copying:** We promote *code* from development to production, not data. This is a standard industry practice that ensures consistency and reliability.
*   **Metadata Versioning:** Use Nessie to version our data and metadata, enabling safe experiments and rollbacks, much like Git for code.
*   **Operational Simplicity:** Keep the architecture straightforward for a small team, but with a clear path to scale in the future.

### **Our Data Stack: A Quick Introduction**

*   **MinIO (Object Storage):** Think of this as our private AWS S3. It's where we store all our raw and transformed data as files (objects). An object storage system is highly scalable and cost-effective for a data lake.
    *   **Key Concept: Bucket:** A **bucket** is the top-level container in MinIO where you store your data. We use separate buckets to create a strong wall between our `dev` and `prod` environments.

*   **Nessie (Data Version Control):** Nessie brings Git-like functionality to our data lake. It doesn't store the data itself (that's MinIO's job), but it manages the *metadata* about our tables.
    *   **Key Concept: Branch/Tag:** Just like in Git, we can create a **branch** in Nessie to experiment with data transformations in isolation. When we're happy with the result, we can merge it. This prevents breaking changes from affecting the main data views.

*   **Trino (Query Engine):** Trino is a powerful, distributed SQL query engine. It's the workhorse that lets us run fast SQL queries on the massive datasets stored in our MinIO data lake. It connects to different data sources via "catalogs."
    *   **Key Concept: Catalog:** A **catalog** in Trino is a configuration that tells it how to connect to a data source (like our Nessie-managed Iceberg data lake). We will define one catalog for each environment, pointing to the correct Nessie branch and MinIO bucket.

*   **Airbyte (Data Ingestion):** Airbyte is our data integration tool. It handles the "Extract" and "Load" parts of our ELT (Extract, Load, Transform) process, pulling data from source systems (like SIA, SGI, etc.) and loading it into our `bronze` layer in the data lake.

*   **dbt (Data Transformation):** dbt (data build tool) is what we use for the "Transform" part of ELT. It allows us to write SQL `SELECT` statements to transform raw data into clean, reliable, and business-ready `silver` and `gold` tables. It also helps us test and document our data models.

---

## **Part 1: Recommended Architecture**

This section details the recommended setup for each component of our data stack.

### **Storage (MinIO)**

*   **One bucket per environment.** This is the strongest form of isolation.
    *   `cedia-datalake-dev`
    *   `cedia-datalake-prod`

### **Catalog & Versioning (Nessie)**

*   **A single Nessie repository** with branches for each environment: `dev`.
*   Inside the `dev` branch, engineers can create feature branches (e.g., `feature/new-report`) for experimentation.
*   **Important:** Do not use `MERGE dev -> main` to "promote" data. The environments use different storage buckets, so a cross-branch merge is not appropriate. Use `MERGE` only within the same environment (e.g., merging a feature branch into `dev`).

### **Query Engine (Trino)**

*   **A single Trino service** with multiple catalogs defined.
    *   `iceberg_dev`
    *   `iceberg_prod`
*   Each catalog points to its corresponding environment:
    *   **Nessie Branch:** `dev` or `main`.
    *   **Warehouse Path:** The correct MinIO bucket (e.g., `s3a://cedia-datalake-dev` for dev, `s3a://cedia-datalake-stg` for stg, etc).

### **Ingestion (Airbyte)**

*   **One Destination per environment.**
    *   **DEV Destination** writes to: `branch=main`, `warehouse=s3://cedia-datalake-dev/iceberg/bronze`.
    *   **PROD Destination** writes to: `branch=prod`, `warehouse=s3://cedia-datalake-prod/iceberg/bronze`.
*   **One Connection per source system** (SIA, SGI, etc.). Use the `Destination Namespace` setting to organize data logically, e.g., `cedia_bronze_<system>`.
*   **Note:** By default, Airbyte commits ingested data to the `main` branch in Nessie. For this reason, we will use the `main` branch as our primary `dev` branch. We can then promote changes from `main` to `prod` within Nessie if needed for metadata consistency, but the data transformation workflow remains code-based.

### **Transformations (dbt)**

*   Use `dbt-trino` (or plain Trino SQL) to build `silver` and `gold` layers.
*   Development happens in the `dev` environment. You write your dbt models, run them, and test them against the `iceberg_dev` catalog.
*   **Promotion to Production:** This means running the *exact same dbt code* against the `prod` environment. dbt will read from the `prod` bronze tables and materialize the `silver` and `gold` tables in the `prod` bucket. This is the essence of **promoting code, not data**.

### **Governance & Security**

*   **MinIO:** Use bucket-level Access Control Lists (ACLs). The `prod` bucket should have the most restrictive policies.
*   **Trino:** Use `GRANT`/`REVOKE` to manage permissions. Restrict access to `bronze` and `silver` layers, while providing broader read access to the business-ready `gold` layer.
*   **PII Masking:** For Personally Identifiable Information (PII), create views in the `gold` layer that mask or hash sensitive columns. Users query the view, not the underlying table.

---

## **Part 2: Step-by-Step Implementation Guide**

### **Step 1: MinIO (Create Buckets)**

Ensure the buckets `cedia-datalake-dev` and `cedia-datalake-prod` exist in MinIO. This is configured in the `minio-docker-compose.yml` file.

### **Step 2: Nessie (Create Branches)**

Use the Nessie CLI to create branches for your environments.

```bash
# Create the 'dev' branch (if you use 'main' as dev, this is optional)
docker run --rm --network data-poc ghcr.io/projectnessie/nessie-cli:latest --uri http://nessie:19120/api/v2 --non-ansi -c "CREATE BRANCH dev FROM main"

# Create the 'stg' branch
docker run --rm --network data-poc ghcr.io/projectnessie/nessie-cli:latest --uri http://nessie:19120/api/v2 --non-ansi -c "CREATE BRANCH stg FROM main"

# Create the 'prod' branch
docker run --rm --network data-poc ghcr.io/projectnessie/nessie-cli:latest --uri http://nessie:19120/api/v2 --non-ansi -c "CREATE BRANCH prod FROM main"

# Verify the branches were created
docker run --rm --network data-poc ghcr.io/projectnessie/nessie-cli:latest --uri http://nessie:19120/api/v2 --non-ansi -c "LIST REFERENCES;"
```

### **Step 3: Trino (Configure Catalogs)**

Update your Trino Docker Compose to mount the catalog configuration directory. This is already implemented in `trino/trino-docker-compose.yml`.

Create the following property files in the `trino/catalog/` directory:

**`iceberg_dev.properties`**

See that in [iceberg_dev.properties](trino\catalog\iceberg_dev.properties)

**`iceberg_prod.properties`**

See that in [iceberg_prod.properties](trino\catalog\iceberg_prod.properties)

After creating the files, restart Trino and verify that the catalogs are available using a SQL client (like DBeaver or DataGrip):

```sql
SHOW CATALOGS;
-- Expected output includes: iceberg_dev, iceberg_prod

SHOW SCHEMAS FROM iceberg_dev;
SHOW SCHEMAS FROM iceberg_prod;
```

### **Step 4: Create Schemas with Locations**

For each environment, create the necessary schemas. A **schema** is a logical namespace for your tables (like a folder). The `LOCATION` property is crucial, as it tells Trino where to store the data for any tables created within that schema.

Execute these commands from a SQL client connected to Trino.

```sql
-- DEV Environment (using the dev catalog)
CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_bronze_sia
  WITH (location='s3a://cedia-datalake-dev/iceberg/bronze/sia/');

CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_silver_finanzas
  WITH (location='s3a://cedia-datalake-dev/iceberg/silver/finanzas/');

CREATE SCHEMA IF NOT EXISTS iceberg_dev.cedia_gold_bi_pge
  WITH (location='s3a://cedia-datalake-dev/iceberg/gold/bi_pge/');

-- PROD Environment (same logical names, but in the prod catalog and bucket)
CREATE SCHEMA IF NOT EXISTS iceberg_prod.cedia_bronze_sia
  WITH (location='s3a://cedia-datalake-prod/iceberg/bronze/sia/');

-- ... create other silver and gold schemas for prod as needed
```

### **Step 5: Airbyte (Configure Destinations)**

**DEV Destination (Summary):**
*   **Catalog Type:** `Nessie Catalog`
*   **Nessie Server URI:** `http://nessie:19120/api/v2`
*   **Main Branch Name:** `dev` (or `dev` if you configured it)
*   **Warehouse Location:** `s3://cedia-datalake-dev/iceberg/bronze`
*   **S3 Endpoint:** `http://minio:9000`

**PROD Destination (Summary):**
*   Same as DEV, but with:
*   **Main Branch Name:** `prod`
*   **Warehouse Location:** `s3://cedia-datalake-prod/iceberg/bronze`

For each **Connection** (e.g., SIA data source), set the **Destination Namespace** to `cedia_bronze_sia` to ensure data lands in the correct schema.

### **Step 6: Transformations and Data Quality**

This is where `dbt` shines.

1.  **Develop in `dev`:** Write your SQL models to transform data from `bronze` to `silver` and `gold`. Use the `iceberg_dev` catalog.
2.  **Add Tests:** Implement data quality tests (e.g., `not_null`, `unique`) in your dbt models. If tests fail, the build fails, and you don't promote the code.

**Example (Initial Load):**
```sql
-- models/silver/fact_factura.sql
CREATE TABLE iceberg_dev.cedia_silver_finanzas.fact_factura AS
SELECT ...
FROM iceberg_dev.cedia_bronze_openerp.factura
WHERE id_factura IS NOT NULL;
```

3.  **Promote to `prod`:** Once your dbt models are tested and approved, you run the *same code* but configure dbt to point to the `prod` environment. dbt has a concept of "targets" for this purpose.

**Example (Running in Prod):**
```sql
-- dbt will generate and run this code when targeting prod
CREATE TABLE iceberg_prod.cedia_silver_finanzas.fact_factura AS
SELECT ... FROM iceberg_prod.cedia_bronze_openerp.factura;
```

### **Step 7: Security - PII Masking Example**

Create views in the `gold` layer to expose data to consumers while protecting sensitive information.

```sql
CREATE OR REPLACE VIEW iceberg_prod.cedia_gold_bi_pge.v_empleado_masked AS
SELECT
    id_empleado,
    sha256(CAST(dni AS VARCHAR)) AS dni_hash, -- Hash the ID
    regexp_replace(email, '(^.).*(@.*$)', '\1***\2') AS email_masked, -- Mask email
    '***' || RIGHT(telefono, 3) AS telefono_masked, -- Mask phone
    fecha_alta,
    area
FROM iceberg_prod.cedia_silver_rrhh.dim_empleado;

-- Grant access to the view, not the table
GRANT SELECT ON TABLE iceberg_prod.cedia_gold_bi_pge.v_empleado_masked TO ROLE data_consumer;
REVOKE SELECT ON TABLE iceberg_prod.cedia_silver_rrhh.dim_empleado FROM ROLE data_consumer;
```

---

## **Final Checklist**

*   [ ] MinIO buckets `dev` and `prod` are created.
*   [ ] Nessie branches `dev` and `prod` exist.
*   [ ] Trino catalogs `iceberg_dev` and `iceberg_prod` are configured and working.
*   [ ] Schemas (`bronze`, `silver`, `gold`) are created in each environment with the correct `LOCATION`.
*   [ ] Airbyte Destinations are set up for `dev` and `prod`.
*   [ ] dbt models are developed and tested in `dev` before being run in `prod`.
*   [ ] Security policies (ACLs, `GRANT`/`REVOKE`, PII masking) are in place.


Autor: Felipe Mendieta