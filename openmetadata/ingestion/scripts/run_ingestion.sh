#!/bin/bash

# Script para ejecutar workflows de ingestion de OpenMetadata
# Este script ejecuta los workflows en el orden correcto para el lineage completo

set -e

echo "🚀 Iniciando workflows de ingestion de OpenMetadata..."

# Configuración
OPENMETADATA_SERVER="http://localhost:8585"
WORKFLOWS_DIR="/opt/airflow/workflows"

# Función para ejecutar un workflow
run_workflow() {
    local workflow_name=$1
    local workflow_file=$2
    
    echo "📋 Ejecutando workflow: $workflow_name"
    echo "📁 Archivo: $workflow_file"
    
    # Ejecutar el workflow usando el CLI de OpenMetadata
    metadata ingest -c "$workflow_file" --verbose
    
    if [ $? -eq 0 ]; then
        echo "✅ Workflow $workflow_name completado exitosamente"
    else
        echo "❌ Error en workflow $workflow_name"
        exit 1
    fi
}

# Verificar que OpenMetadata esté disponible
echo "🔍 Verificando conexión con OpenMetadata..."
curl -f "$OPENMETADATA_SERVER/api/v1/system/version" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ OpenMetadata está disponible"
else
    echo "❌ OpenMetadata no está disponible en $OPENMETADATA_SERVER"
    exit 1
fi

# Ejecutar workflows en orden
echo "🔄 Ejecutando workflows de ingestion..."

# 1. Trino Ingestion (primero para tener las tablas base)
echo "1️⃣ Ejecutando Trino ingestion..."
run_workflow "trino_iceberg_ingestion" "$WORKFLOWS_DIR/trino_workflow.yaml"

# 2. Airbyte Ingestion (para capturar sources y destinations)
echo "2️⃣ Ejecutando Airbyte ingestion..."
run_workflow "airbyte_ingestion" "$WORKFLOWS_DIR/airbyte_workflow.yaml"

# 3. dbt Ingestion (para lineage de transformaciones)
echo "3️⃣ Ejecutando dbt ingestion..."
run_workflow "dbt_ingestion" "$WORKFLOWS_DIR/dbt_workflow.yaml"

# 4. Lineage Complete (para conectar todo)
echo "4️⃣ Ejecutando lineage completo..."
run_workflow "lineage_complete" "$WORKFLOWS_DIR/lineage_workflow.yaml"

echo "🎉 Todos los workflows de ingestion completados exitosamente!"
echo "🌐 Puedes ver el lineage en: $OPENMETADATA_SERVER"
echo "📊 Navega a: $OPENMETADATA_SERVER/explore/tables para ver las tablas"
echo "🔗 Navega a: $OPENMETADATA_SERVER/lineage para ver el lineage completo"
