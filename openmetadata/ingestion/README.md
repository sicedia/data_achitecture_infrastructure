# OpenMetadata Ingestion - Lineage Completo

Este directorio contiene la configuración completa de ingestion de OpenMetadata para capturar y visualizar el lineage de datos en tu arquitectura de datos moderna.

## 🎯 **Objetivo**

Crear un lineage completo y visualizable que muestre el flujo de datos desde las fuentes originales hasta los modelos finales de negocio:

**MariaDB → Airbyte → Iceberg Bronze → dbt Silver → dbt Gold**

## 🏗️ **Arquitectura de Datos**

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────────┐
│   MariaDB       │    │   Airbyte    │    │   Iceberg Bronze    │
│   (Source)      │───▶│   (ETL)      │───▶│   (MinIO + Nessie)  │
│   intranet      │    │              │    │   cedia_bronze_sia  │
└─────────────────┘    └──────────────┘    └─────────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────┐    ┌─────────────────────┐
│   OpenMetadata  │    │     dbt      │    │   Iceberg Silver    │
│   (Lineage UI)  │◀───│ (Transform)  │◀───│   (MinIO + Nessie)  │
│   localhost:8585│    │              │    │   cedia_silver_sia  │
└─────────────────┘    └──────────────┘    └─────────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────────┐
                                               │   Iceberg Gold      │
                                               │   (MinIO + Nessie)  │
                                               │   cedia_gold_sia    │
                                               └─────────────────────┘
```

## 📁 **Estructura de Archivos Explicada**

```
openmetadata/ingestion/
├── workflows/                           # 📋 Configuraciones de ingestion
│   ├── mariadb_workflow.yaml           # 🔗 Conecta MariaDB como fuente original
│   ├── trino_all_schemas.yaml          # 🗄️ Conecta Trino con todos los schemas
│   ├── airbyte_simple.yaml             # ⚡ Conecta Airbyte para lineage ETL
│   ├── dbt_correct.yaml                # 🔄 Conecta dbt para lineage de transformaciones
│   └── lineage_mapping.yaml            # 🗺️ Mapeo manual de lineage entre herramientas
├── scripts/                            # 🚀 Scripts de automatización
│   ├── run_ingestion.sh                # 🐧 Script Linux para ejecutar todos los workflows
│   ├── run_ingestion.ps1               # 🪟 Script PowerShell para Windows
│   └── run_individual_workflows.sh     # ⚙️ Script para ejecutar workflows individuales
├── env.example                         # 🔐 Variables de entorno de ejemplo
└── README.md                           # 📖 Este archivo de documentación
```

### 📋 **Descripción Detallada de Cada Archivo**

#### **Workflows de Ingestion Activos**

1. **`mariadb_workflow.yaml`** - 🔗 **Fuente Original**
   - **Propósito**: Conecta MariaDB como la fuente de datos original
   - **Captura**: Tablas, esquemas, columnas de MariaDB
   - **Configuración**: Host, puerto, credenciales, filtros de tablas
   - **Resultado**: Tabla `mariadb_intranet.intranet.jvc_proforma` visible en OpenMetadata
   - **Estado**: ✅ **ACTIVO** - Funcionando correctamente

2. **`trino_all_schemas.yaml`** - 🗄️ **Capa de Datos**
   - **Propósito**: Conecta Trino para capturar todas las capas de datos (Bronze, Silver, Gold)
   - **Captura**: Schemas, tablas, columnas de Iceberg via Trino
   - **Configuración**: Catálogo `iceberg_dev`, schemas específicos
   - **Resultado**: Todas las tablas de Bronze, Silver y Gold visibles en OpenMetadata
   - **Estado**: ✅ **ACTIVO** - Funcionando correctamente

3. **`dbt_correct.yaml`** - 🔄 **Transformaciones**
   - **Propósito**: Conecta dbt para capturar el lineage de transformaciones
   - **Captura**: Modelos, sources, tests, lineage entre modelos
   - **Configuración**: Archivos de dbt (manifest.json, catalog.json, run_results.json)
   - **Resultado**: Lineage Bronze → Silver → Gold
   - **Estado**: ✅ **ACTIVO** - Funcionando correctamente

4. **`airbyte_simple.yaml`** - ⚡ **Pipeline de ETL**
   - **Propósito**: Conecta Airbyte para capturar el lineage de extracción y carga
   - **Captura**: Sources, destinations, connections, pipelines
   - **Configuración**: URL de Airbyte, credenciales, filtros de pipelines
   - **Resultado**: Lineage MariaDB → Iceberg Bronze
   - **Estado**: ⏳ **PENDIENTE** - Configuración en progreso

5. **`lineage_mapping.yaml`** - 🗺️ **Mapeo Manual**
   - **Propósito**: Define mapeos explícitos de lineage cuando la detección automática falla
   - **Contenido**: Mapeos entre tablas de diferentes herramientas
   - **Uso**: Para casos complejos o cuando las herramientas no pueden inferir el lineage automáticamente
   - **Estado**: ✅ **ACTIVO** - Disponible para casos especiales

#### **Scripts de Automatización**

1. **`run_ingestion.sh`** - 🐧 **Script Principal Linux**
   - **Propósito**: Ejecuta todos los workflows de ingestion en secuencia
   - **Funcionalidad**: Carga variables de entorno, ejecuta workflows, maneja errores
   - **Uso**: `./scripts/run_ingestion.sh`

2. **`run_ingestion.ps1`** - 🪟 **Script Principal Windows**
   - **Propósito**: Versión PowerShell del script principal para Windows
   - **Funcionalidad**: Equivalente al script Linux pero para PowerShell
   - **Uso**: `.\scripts\run_ingestion.ps1`

3. **`run_individual_workflows.sh`** - ⚙️ **Script Individual**
   - **Propósito**: Ejecuta workflows específicos por separado
   - **Funcionalidad**: Permite ejecutar solo el workflow que necesites
   - **Uso**: `./scripts/run_individual_workflows.sh mariadb`

#### **Archivos de Configuración**

1. **`env.example`** - 🔐 **Variables de Entorno**
   - **Propósito**: Template de variables de entorno para configuración
   - **Contenido**: URLs, credenciales, configuraciones de servicios
   - **Uso**: Copiar a `.env` y personalizar con tus valores

## 🚀 **Configuración Paso a Paso**

### **Paso 1: Verificar Servicios** ✅

Antes de comenzar, asegúrate de que todos los servicios estén ejecutándose:

```bash
# 1. Verificar OpenMetadata (debe estar en puerto 8585)
curl http://localhost:8585/api/v1/system/version
# Respuesta esperada: {"version": "1.9.7"}

# 2. Verificar Trino (debe estar en puerto 8083)
curl http://localhost:8083/v1/info
# Respuesta esperada: información del servidor Trino

# 3. Verificar Nessie (debe estar en puerto 19120)
curl http://localhost:19120/api/v2/config
# Respuesta esperada: configuración de Nessie

# 4. Verificar MinIO (debe estar en puerto 9000)
curl http://localhost:9000/minio/health/live
# Respuesta esperada: {"status": "ok"}

# 5. Verificar Airbyte (debe estar en puerto 8000)
curl http://localhost:8000/api/v1/workspaces/list
# Respuesta esperada: lista de workspaces o error de autenticación
```

### **Paso 2: Configurar dbt** 🔄

**IMPORTANTE**: dbt debe ejecutarse ANTES de los workflows de ingestion para generar los archivos necesarios:

```bash
# 1. Navegar al directorio dbt
cd dbt

# 2. Instalar dependencias
dbt deps

# 3. Ejecutar modelos (esto crea las tablas en Iceberg)
dbt run

# 4. Generar documentación (esto crea los archivos de lineage)
dbt docs generate

# 5. Verificar que se generaron los archivos necesarios
ls -la target/
# Debes ver: manifest.json, catalog.json, run_results.json
```

**¿Por qué es importante este paso?**
- `manifest.json`: Contiene la estructura completa del proyecto dbt y las relaciones entre modelos
- `catalog.json`: Contiene información sobre columnas y tipos de datos
- `run_results.json`: Contiene información sobre la ejecución más reciente

### **Paso 3: Configurar Variables de Entorno** 🔐

```bash
# 1. Copiar el archivo de ejemplo
cp openmetadata/ingestion/env.example openmetadata/ingestion/.env

# 2. Editar con tus valores específicos
nano openmetadata/ingestion/.env
```

**Variables importantes a configurar:**
```bash
# OpenMetadata
OPENMETADATA_HOST_PORT=http://localhost:8585
OPENMETADATA_JWT_TOKEN=tu_jwt_token_aqui

# MariaDB
MARIADB_HOST=srvdesagx01.cedia.org.ec
MARIADB_PORT=3306
MARIADB_USERNAME=root
MARIADB_PASSWORD=tu_password_aqui
MARIADB_DATABASE=intranet

# Airbyte
AIRBYTE_HOST_PORT=http://localhost:8000
AIRBYTE_USERNAME=tu_usuario_airbyte
AIRBYTE_PASSWORD=tu_password_airbyte

# Trino
TRINO_HOST_PORT=trino:8083
TRINO_USERNAME=dbt
TRINO_CATALOG=iceberg_dev
```

## 🔄 **Ejecutar Workflows de Ingestion**

### **Orden de Ejecución Recomendado** 📋

**IMPORTANTE**: Ejecuta los workflows en este orden específico para asegurar que el lineage se construya correctamente:

```bash
# 1. PRIMERO: MariaDB (fuente original) ✅ ACTIVO
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/mariadb_workflow.yaml

# 2. SEGUNDO: Trino (todas las capas de datos) ✅ ACTIVO
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/trino_all_schemas.yaml

# 3. TERCERO: dbt (lineage de transformaciones) ✅ ACTIVO
docker exec openmetadata_ingestion metadata ingest-dbt -c /opt/airflow/dbt

# 4. CUARTO: Airbyte (lineage de ETL) ⏳ PENDIENTE
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/airbyte_simple.yaml
```

**Estado Actual del Lineage:**
- ✅ **MariaDB → Trino**: Funcionando
- ✅ **Trino Bronze → Silver → Gold**: Funcionando (via dbt)
- ⏳ **MariaDB → Airbyte → Trino Bronze**: Pendiente de configuración

### **Opción 1: Scripts Automatizados** 🤖

```bash
# Linux/Mac - Ejecutar todos los workflows
./openmetadata/ingestion/scripts/run_ingestion.sh

# Windows PowerShell - Ejecutar todos los workflows
.\openmetadata\ingestion\scripts\run_ingestion.ps1

# Ejecutar workflow individual
./openmetadata/ingestion/scripts/run_individual_workflows.sh mariadb
./openmetadata/ingestion/scripts/run_individual_workflows.sh trino
./openmetadata/ingestion/scripts/run_individual_workflows.sh dbt
./openmetadata/ingestion/scripts/run_individual_workflows.sh airbyte
```

### **Opción 2: Ejecución Manual** ⚙️

```bash
# 1. Conectar al contenedor de ingestion
docker exec -it openmetadata_ingestion bash

# 2. Ejecutar workflows individuales (en orden)
metadata ingest -c /opt/airflow/workflows/mariadb_workflow.yaml
metadata ingest -c /opt/airflow/workflows/trino_all_schemas.yaml
metadata ingest-dbt -c /opt/airflow/dbt
metadata ingest -c /opt/airflow/workflows/airbyte_simple.yaml
```

### **Opción 3: Ejecución con Logs Detallados** 🔍

```bash
# Para debugging y troubleshooting
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/mariadb_workflow.yaml --verbose
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/trino_all_schemas.yaml --verbose
```

### **Verificar Éxito de la Ejecución** ✅

Después de cada workflow, verifica que se ejecutó correctamente:

```bash
# Buscar estas líneas en la salida:
# ✅ "Success %: 100.0" - Indica éxito completo
# ✅ "Processed records: X" - Indica que se procesaron registros
# ❌ "Errors: X" - Si X > 0, hay errores que revisar
```

## 📊 **Verificar Lineage en OpenMetadata**

### **Paso 1: Acceder a OpenMetadata** 🌐

```bash
# Abrir OpenMetadata en el navegador
http://localhost:8585
```

### **Paso 2: Explorar Tablas** 🔍

```bash
# Navegar a la sección de tablas
http://localhost:8585/explore/tables
```

**Deberías ver estas tablas:**
- `mariadb_intranet.intranet.jvc_proforma` (fuente original)
- `trino_iceberg_dev.cedia_bronze_sia.jvc_proforma` (bronze layer)
- `trino_iceberg_dev.cedia_silver_sia.stg_proforma` (silver layer)
- `trino_iceberg_dev.cedia_gold_sia.fct_proforma` (gold layer)

### **Paso 3: Verificar Lineage** 🔗

1. **Hacer clic en una tabla** (ej: `fct_proforma`)
2. **Ir a la pestaña "Lineage"**
3. **Verificar que aparezca el flujo completo**:

```
mariadb_intranet.intranet.jvc_proforma
    ↓ (Airbyte - si está configurado)
trino_iceberg_dev.cedia_bronze_sia.jvc_proforma
    ↓ (dbt stg_proforma)
trino_iceberg_dev.cedia_silver_sia.stg_proforma
    ↓ (dbt fct_proforma)
trino_iceberg_dev.cedia_gold_sia.fct_proforma
```

### **Paso 4: Verificar Metadata** 📋

En cada tabla, verifica que aparezcan:
- ✅ **Columnas** con tipos de datos
- ✅ **Descripciones** (si están configuradas en dbt)
- ✅ **Tags** (bronze, silver, gold)
- ✅ **Propietarios** (data-team)
- ✅ **Tests** de dbt (si están configurados)

## 🚀 **Escalabilidad y Mejores Prácticas**

### **Agregar Nuevas Fuentes de Datos** 📈

#### **1. Agregar Nueva Base de Datos**

```bash
# 1. Crear nuevo workflow
cp openmetadata/ingestion/workflows/mariadb_workflow.yaml openmetadata/ingestion/workflows/nueva_db_workflow.yaml

# 2. Modificar configuración
nano openmetadata/ingestion/workflows/nueva_db_workflow.yaml
```

**Configuración ejemplo para PostgreSQL:**
```yaml
source:
  type: postgres
  serviceName: "postgres_nueva_fuente"
  serviceConnection:
    config:
      type: Postgres
      hostPort: "nueva-db:5432"
      username: "usuario"
      password: "password"
      database: "nueva_db"
      databaseSchema: "public"
```

#### **2. Agregar Nuevos Schemas en Trino**

```yaml
# En trino_all_schemas.yaml, agregar nuevos schemas:
schemaFilterPattern:
  includes:
    - "cedia_bronze_sia"
    - "cedia_silver_sia" 
    - "cedia_gold_sia"
    - "nuevo_bronze_schema"    # ← Agregar aquí
    - "nuevo_silver_schema"    # ← Agregar aquí
    - "nuevo_gold_schema"      # ← Agregar aquí
```

#### **3. Agregar Nuevos Modelos dbt**

```bash
# 1. Crear nuevos modelos en dbt
mkdir dbt/models/silver/nuevo_dominio
mkdir dbt/models/gold/nuevo_dominio

# 2. Agregar configuración en dbt_project.yml
nano dbt/dbt_project.yml
```

**Agregar al dbt_project.yml:**
```yaml
models:
  dbt_lakehouse_cedia:
    silver:
      nuevo_dominio:                    # ← Nuevo dominio
        +tags: ['silver', 'nuevo_dominio']
        +meta:
          domain: "nuevo_dominio"
    gold:
      nuevo_dominio:                    # ← Nuevo dominio
        +tags: ['gold', 'nuevo_dominio']
        +meta:
          domain: "nuevo_dominio"
```

### **Mejores Prácticas de Organización** 🏗️

#### **1. Estructura de Directorios Recomendada**

```
openmetadata/ingestion/
├── workflows/
│   ├── sources/                    # Fuentes de datos
│   │   ├── mariadb_workflow.yaml
│   │   ├── postgres_workflow.yaml
│   │   └── mysql_workflow.yaml
│   ├── warehouses/                 # Data warehouses
│   │   ├── trino_workflow.yaml
│   │   ├── snowflake_workflow.yaml
│   │   └── bigquery_workflow.yaml
│   ├── etl/                       # Herramientas ETL
│   │   ├── airbyte_workflow.yaml
│   │   ├── airflow_workflow.yaml
│   │   └── fivetran_workflow.yaml
│   └── transformations/            # Herramientas de transformación
│       ├── dbt_workflow.yaml
│       └── spark_workflow.yaml
├── configs/                       # Configuraciones específicas
│   ├── dev/
│   ├── staging/
│   └── prod/
└── scripts/
```

#### **2. Naming Conventions** 📝

**Servicios:**
- `{tipo}_{nombre}_{entorno}`: `mariadb_intranet_prod`
- `{herramienta}_{catalogo}_{entorno}`: `trino_iceberg_dev`

**Workflows:**
- `{fuente}_{tipo}_workflow.yaml`: `mariadb_source_workflow.yaml`
- `{herramienta}_{entorno}_workflow.yaml`: `dbt_prod_workflow.yaml`

**Tags:**
- **Capas**: `bronze`, `silver`, `gold`
- **Dominios**: `sia`, `finanzas`, `ventas`
- **Entornos**: `dev`, `staging`, `prod`
- **Calidad**: `validated`, `tested`, `certified`

#### **3. Configuración por Entornos** 🌍

```bash
# Crear configuraciones específicas por entorno
mkdir openmetadata/ingestion/configs/dev
mkdir openmetadata/ingestion/configs/staging  
mkdir openmetadata/ingestion/configs/prod

# Copiar workflows base
cp openmetadata/ingestion/workflows/*.yaml openmetadata/ingestion/configs/dev/
cp openmetadata/ingestion/workflows/*.yaml openmetadata/ingestion/configs/staging/
cp openmetadata/ingestion/workflows/*.yaml openmetadata/ingestion/configs/prod/
```

### **Automatización y CI/CD** 🤖

#### **1. Script de Automatización Completo**

```bash
#!/bin/bash
# scripts/run_full_ingestion.sh

set -e  # Salir si hay errores

echo "🚀 Iniciando ingestion completa de OpenMetadata..."

# Cargar variables de entorno
source .env

# Verificar servicios
echo "🔍 Verificando servicios..."
./scripts/check_services.sh

# Ejecutar dbt
echo "🔄 Ejecutando dbt..."
cd dbt && dbt run && dbt docs generate && cd ..

# Ejecutar workflows en orden
echo "📊 Ejecutando workflows de ingestion..."

echo "1️⃣ MariaDB..."
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/mariadb_workflow.yaml

echo "2️⃣ Trino..."
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/trino_all_schemas.yaml

echo "3️⃣ dbt..."
docker exec openmetadata_ingestion metadata ingest-dbt -c /opt/airflow/dbt

echo "4️⃣ Airbyte..."
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/airbyte_simple.yaml

echo "✅ Ingestion completa finalizada!"
echo "🌐 Abrir OpenMetadata: http://localhost:8585"
```

#### **2. Monitoreo y Alertas**

```bash
# scripts/monitor_ingestion.sh
#!/bin/bash

# Verificar estado de workflows
check_workflow_status() {
    local workflow=$1
    local result=$(docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/${workflow}.yaml 2>&1)
    
    if echo "$result" | grep -q "Success %: 100.0"; then
        echo "✅ $workflow: OK"
        return 0
    else
        echo "❌ $workflow: ERROR"
        echo "$result" | tail -10
        return 1
    fi
}

# Verificar todos los workflows
check_workflow_status "mariadb_workflow"
check_workflow_status "trino_all_schemas"
check_workflow_status "airbyte_simple"
```

### **Troubleshooting Avanzado** 🔧

#### **Problemas Comunes y Soluciones**

1. **Error: "Service not found"**
   ```bash
   # Verificar que el servicio existe en OpenMetadata
   curl -s "http://localhost:8585/api/v1/services" | jq '.data[] | .name'
   ```

2. **Error: "Connection refused"**
   ```bash
   # Verificar conectividad desde el contenedor
   docker exec openmetadata_ingestion curl -v http://servicio:puerto
   ```

3. **Error: "Invalid credentials"**
   ```bash
   # Verificar credenciales
   docker exec openmetadata_ingestion curl -u usuario:password http://servicio:puerto/api/test
   ```

4. **Error: "No tables found"**
   ```bash
   # Verificar que las tablas existen en la fuente
   docker exec trino trino --execute "SHOW TABLES FROM iceberg_dev.cedia_bronze_sia;"
   ```

#### **Logs y Debugging**

```bash
# Ver logs detallados
docker logs openmetadata_ingestion --tail 100 -f

# Ver logs de OpenMetadata
docker logs openmetadata_server --tail 100 -f

# Ver logs de Trino
docker logs trino --tail 100 -f

# Debugging específico de workflow
docker exec openmetadata_ingestion metadata ingest -c /opt/airflow/workflows/mariadb_workflow.yaml --verbose
```

## 📈 **Monitoreo y Mantenimiento**

### **Programación Automática** ⏰

```bash
# Crear cron job para ejecutar workflows automáticamente
# Editar crontab
crontab -e

# Agregar línea para ejecutar cada 6 horas
0 */6 * * * /ruta/al/proyecto/openmetadata/ingestion/scripts/run_full_ingestion.sh >> /var/log/openmetadata_ingestion.log 2>&1
```

### **Métricas de Rendimiento** 📊

```bash
# Script para generar reporte de ingestion
#!/bin/bash
# scripts/generate_ingestion_report.sh

echo "📊 Reporte de Ingestion - $(date)"
echo "=================================="

# Contar tablas por servicio
echo "📋 Tablas por Servicio:"
curl -s "http://localhost:8585/api/v1/tables" | jq '.data | group_by(.service) | map({service: .[0].service, count: length})'

# Verificar estado de workflows
echo "🔄 Estado de Workflows:"
./scripts/monitor_ingestion.sh

# Verificar lineage
echo "🔗 Verificación de Lineage:"
curl -s "http://localhost:8585/api/v1/lineage" | jq '.data | length' | xargs echo "Total de relaciones de lineage:"
```

### **Alertas y Notificaciones** 🚨

```bash
# Configurar alertas por email
#!/bin/bash
# scripts/send_alert.sh

send_alert() {
    local message=$1
    local subject="OpenMetadata Ingestion Alert"
    
    # Enviar email (configurar con tu SMTP)
    echo "$message" | mail -s "$subject" admin@tu-empresa.com
    
    # O enviar a Slack
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        https://hooks.slack.com/services/TU/WEBHOOK/URL
}

# Verificar y enviar alertas
if ! ./scripts/monitor_ingestion.sh; then
    send_alert "❌ Error en workflows de OpenMetadata ingestion"
fi
```

## 🎯 **Casos de Uso Avanzados**

### **1. Lineage Multi-Entorno** 🌍

```bash
# Configurar lineage para múltiples entornos
# dev, staging, prod

# Crear workflows específicos por entorno
cp openmetadata/ingestion/workflows/mariadb_workflow.yaml openmetadata/ingestion/workflows/mariadb_dev_workflow.yaml
cp openmetadata/ingestion/workflows/mariadb_workflow.yaml openmetadata/ingestion/workflows/mariadb_prod_workflow.yaml

# Modificar configuraciones específicas
# dev: hostPort: "dev-db:3306"
# prod: hostPort: "prod-db:3306"
```

### **2. Lineage de Datos Sensibles** 🔒

```yaml
# En los workflows, agregar filtros para datos sensibles
sourceConfig:
  config:
    type: DatabaseMetadata
    tableFilterPattern:
      includes:
        - "public.*"
      excludes:
        - ".*password.*"
        - ".*secret.*"
        - ".*pii.*"
    columnFilterPattern:
      excludes:
        - ".*password.*"
        - ".*ssn.*"
        - ".*credit_card.*"
```

### **3. Lineage de APIs y Microservicios** 🔌

```yaml
# Ejemplo para conectar APIs
source:
  type: custom-rest
  serviceName: "api_microservices"
  serviceConnection:
    config:
      type: CustomRest
      hostPort: "https://api.tu-empresa.com"
      headers:
        Authorization: "Bearer token"
  sourceConfig:
    config:
      type: APIMetadata
      includeEndpoints: true
      includeSchemas: true
```

## 🔧 **Configuración Avanzada**

### **Personalización de Workflows** ⚙️

```yaml
# Ejemplo de workflow personalizado con filtros avanzados
sourceConfig:
  config:
    type: DatabaseMetadata
    # Filtros de esquemas
    schemaFilterPattern:
      includes:
        - "cedia_.*"
      excludes:
        - ".*_temp"
        - ".*_backup"
    
    # Filtros de tablas
    tableFilterPattern:
      includes:
        - ".*_fact"
        - ".*_dim"
      excludes:
        - ".*_log"
        - ".*_audit"
    
    # Filtros de columnas
    columnFilterPattern:
      includes:
        - ".*"
      excludes:
        - ".*_internal"
    
    # Configuraciones adicionales
    includeTables: true
    includeViews: true
    includeTags: true
    includeOwners: true
    markDeletedTables: true
    markAllDeletedTables: false
```

### **Configuración de Tags Automáticos** 🏷️

```yaml
# En dbt_project.yml, configurar tags automáticos
models:
  dbt_lakehouse_cedia:
    +tags: ['cedia', 'dwh']
    silver:
      +tags: ['silver', 'cleaned']
      sia:
        +tags: ['sia', 'domain']
    gold:
      +tags: ['gold', 'business']
      sia:
        +tags: ['sia', 'domain', 'aggregated']
```

## 📚 **Referencias y Recursos**

### **Documentación Oficial** 📖

- [OpenMetadata Documentation](https://docs.open-metadata.org/)
- [dbt Documentation](https://docs.getdbt.com/)
- [Trino Documentation](https://trino.io/docs/)
- [Airbyte Documentation](https://docs.airbyte.com/)
- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Project Nessie Documentation](https://projectnessie.org/)

### **Comunidad y Soporte** 🤝

- [OpenMetadata Slack](https://slack.open-metadata.org/)
- [dbt Community](https://getdbt.com/community/)
- [Trino Community](https://trino.io/community.html)
- [Airbyte Community](https://airbyte.com/community)

### **Herramientas Adicionales** 🛠️

- [Great Expectations](https://greatexpectations.io/) - Data Quality
- [Apache Superset](https://superset.apache.org/) - Data Visualization
- [Apache Airflow](https://airflow.apache.org/) - Workflow Orchestration
- [Prefect](https://www.prefect.io/) - Modern Workflow Orchestration

## 🎉 **¡Felicitaciones!**

Has configurado exitosamente un sistema completo de lineage de datos con OpenMetadata. Este setup te permitirá:

- ✅ **Visualizar** el flujo completo de datos desde fuentes hasta modelos finales
- ✅ **Rastrear** cambios y dependencias en tu arquitectura de datos
- ✅ **Documentar** automáticamente tus pipelines de datos
- ✅ **Escalar** fácilmente agregando nuevas fuentes y transformaciones
- ✅ **Monitorear** la calidad y estado de tus datos

**¡Tu arquitectura de datos ahora tiene visibilidad completa y está lista para crecer!** 🚀
