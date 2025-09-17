# Script PowerShell para ejecutar workflows de ingestion de OpenMetadata
# Este script ejecuta los workflows en el orden correcto para el lineage completo

param(
    [string]$OpenMetadataServer = "http://localhost:8585",
    [string]$WorkflowsDir = "/opt/airflow/workflows"
)

Write-Host "🚀 Iniciando workflows de ingestion de OpenMetadata..." -ForegroundColor Green

# Función para ejecutar un workflow
function Run-Workflow {
    param(
        [string]$WorkflowName,
        [string]$WorkflowFile
    )
    
    Write-Host "📋 Ejecutando workflow: $WorkflowName" -ForegroundColor Yellow
    Write-Host "📁 Archivo: $WorkflowFile" -ForegroundColor Gray
    
    # Ejecutar el workflow usando el CLI de OpenMetadata
    $result = metadata ingest -c $WorkflowFile --verbose
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Workflow $WorkflowName completado exitosamente" -ForegroundColor Green
    } else {
        Write-Host "❌ Error en workflow $WorkflowName" -ForegroundColor Red
        exit 1
    }
}

# Verificar que OpenMetadata esté disponible
Write-Host "🔍 Verificando conexión con OpenMetadata..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$OpenMetadataServer/api/v1/system/version" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ OpenMetadata está disponible" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ OpenMetadata no está disponible en $OpenMetadataServer" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Ejecutar workflows en orden
Write-Host "🔄 Ejecutando workflows de ingestion..." -ForegroundColor Cyan

# 1. Trino Ingestion (primero para tener las tablas base)
Write-Host "1️⃣ Ejecutando Trino ingestion..." -ForegroundColor Yellow
Run-Workflow -WorkflowName "trino_iceberg_ingestion" -WorkflowFile "$WorkflowsDir/trino_workflow.yaml"

# 2. Airbyte Ingestion (para capturar sources y destinations)
Write-Host "2️⃣ Ejecutando Airbyte ingestion..." -ForegroundColor Yellow
Run-Workflow -WorkflowName "airbyte_ingestion" -WorkflowFile "$WorkflowsDir/airbyte_workflow.yaml"

# 3. dbt Ingestion (para lineage de transformaciones)
Write-Host "3️⃣ Ejecutando dbt ingestion..." -ForegroundColor Yellow
Run-Workflow -WorkflowName "dbt_ingestion" -WorkflowFile "$WorkflowsDir/dbt_workflow.yaml"

# 4. Lineage Complete (para conectar todo)
Write-Host "4️⃣ Ejecutando lineage completo..." -ForegroundColor Yellow
Run-Workflow -WorkflowName "lineage_complete" -WorkflowFile "$WorkflowsDir/lineage_workflow.yaml"

Write-Host "🎉 Todos los workflows de ingestion completados exitosamente!" -ForegroundColor Green
Write-Host "🌐 Puedes ver el lineage en: $OpenMetadataServer" -ForegroundColor Cyan
Write-Host "📊 Navega a: $OpenMetadataServer/explore/tables para ver las tablas" -ForegroundColor Cyan
Write-Host "🔗 Navega a: $OpenMetadataServer/lineage para ver el lineage completo" -ForegroundColor Cyan
