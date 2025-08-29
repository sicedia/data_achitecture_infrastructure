# Trino Roles

## Example Roles and Privileges

Here is an example of how to define roles and grant privileges in Trino:

```sql
-- Roles ejemplo
CREATE ROLE IF NOT EXISTS rol_plataforma;   -- admin data platform
CREATE ROLE IF NOT EXISTS rol_datos;        -- data engineers
CREATE ROLE IF NOT EXISTS rol_consumo;      -- analistas/BI/usuarios

-- Privilegios por capa (DEV)
GRANT USAGE ON CATALOG iceberg_dev TO ROLE rol_plataforma, ROLE rol_datos, ROLE rol_consumo;

-- Bronze restringido (solo plataforma/datos)
GRANT USAGE ON SCHEMA iceberg_dev.cedia_bronze_sia TO ROLE rol_plataforma, ROLE rol_datos;
REVOKE USAGE ON SCHEMA iceberg_dev.cedia_bronze_sia FROM ROLE rol_consumo;

-- Silver: lectura a datos y (opcional) a consumo
GRANT USAGE ON SCHEMA iceberg_dev.cedia_silver_finanzas TO ROLE rol_plataforma, ROLE rol_datos, ROLE rol_consumo;
GRANT SELECT ON ALL TABLES IN SCHEMA iceberg_dev.cedia_silver_finanzas TO ROLE rol_datos;
-- (puedes dar SELECT limitado a consumo según el dominio)

-- Gold: lectura amplia
GRANT USAGE ON SCHEMA iceberg_dev.cedia_gold_bi_pge TO ROLE rol_plataforma, ROLE rol_datos, ROLE rol_consumo;
GRANT SELECT ON ALL TABLES IN SCHEMA iceberg_dev.cedia_gold_bi_pge TO ROLE rol_consumo;

-- Repite por dominios/áreas y en PROD con iceberg_prod.*
```