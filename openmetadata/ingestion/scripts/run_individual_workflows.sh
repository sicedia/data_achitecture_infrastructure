#!/bin/bash

# Script para ejecutar workflows individuales de OpenMetadata
# Uso: ./run_individual_workflows.sh [workflow_name]

set -e

WORKFLOWS_DIR="/opt/airflow/workflows"

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [workflow_name]"
    echo ""
    echo "Workflows disponibles:"
    echo "  trino        - Ingestion de Trino (tablas Iceberg)"
    echo "  airbyte      - Ingestion de Airbyte (sources y destinations)"
    echo "  dbt          - Ingestion de dbt (transformaciones)"
    echo "  lineage      - Lineage completo (conecta todo)"
    echo "  all          - Ejecutar todos los workflows en orden"
    echo ""
    echo "Ejemplos:"
    echo "  $0 trino     - Ejecutar solo Trino ingestion"
    echo "  $0 all       - Ejecutar todos los workflows"
}

# Función para ejecutar un workflow
run_workflow() {
    local workflow_name=$1
    local workflow_file=$2
    
    echo "📋 Ejecutando workflow: $workflow_name"
    echo "📁 Archivo: $workflow_file"
    
    if [ ! -f "$workflow_file" ]; then
        echo "❌ Archivo de workflow no encontrado: $workflow_file"
        exit 1
    fi
    
    # Ejecutar el workflow
    metadata ingest -c "$workflow_file" --verbose
    
    if [ $? -eq 0 ]; then
        echo "✅ Workflow $workflow_name completado exitosamente"
    else
        echo "❌ Error en workflow $workflow_name"
        exit 1
    fi
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

WORKFLOW_NAME=$1

case $WORKFLOW_NAME in
    "trino")
        echo "🔄 Ejecutando Trino ingestion..."
        run_workflow "trino_iceberg_ingestion" "$WORKFLOWS_DIR/trino_workflow.yaml"
        ;;
    "airbyte")
        echo "🔄 Ejecutando Airbyte ingestion..."
        run_workflow "airbyte_ingestion" "$WORKFLOWS_DIR/airbyte_workflow.yaml"
        ;;
    "dbt")
        echo "🔄 Ejecutando dbt ingestion..."
        run_workflow "dbt_ingestion" "$WORKFLOWS_DIR/dbt_workflow.yaml"
        ;;
    "lineage")
        echo "🔄 Ejecutando lineage completo..."
        run_workflow "lineage_complete" "$WORKFLOWS_DIR/lineage_workflow.yaml"
        ;;
    "all")
        echo "🔄 Ejecutando todos los workflows..."
        run_workflow "trino_iceberg_ingestion" "$WORKFLOWS_DIR/trino_workflow.yaml"
        run_workflow "airbyte_ingestion" "$WORKFLOWS_DIR/airbyte_workflow.yaml"
        run_workflow "dbt_ingestion" "$WORKFLOWS_DIR/dbt_workflow.yaml"
        run_workflow "lineage_complete" "$WORKFLOWS_DIR/lineage_workflow.yaml"
        echo "🎉 Todos los workflows completados exitosamente!"
        ;;
    *)
        echo "❌ Workflow desconocido: $WORKFLOW_NAME"
        show_help
        exit 1
        ;;
esac

echo "🌐 Puedes ver los resultados en: http://localhost:8585"
