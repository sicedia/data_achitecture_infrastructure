#!/usr/bin/env python3
"""
Script para crear lineage manual de Airbyte usando la API de OpenMetadata
Conecta MariaDB.intranet.jvc_proforma → Trino.iceberg_dev.cedia_bronze_sia.jvc_proforma
"""

import requests
import json
import sys

# Configuración
OPENMETADATA_URL = "http://openmetadata-server:8585/api"
JWT_TOKEN = "eyJraWQiOiJHYjM4OWEtOWY3Ni1nZGpzLWE5MmotMDI0MmJrOTQzNTYiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzQm90IjpmYWxzZSwiaXNzIjoib3Blbi1tZXRhZGF0YS5vcmciLCJpYXQiOjE2NjM5Mzg0NjIsImVtYWlsIjoiYWRtaW5Ab3Blbm1ldGFkYXRhLm9yZyJ9.tS8um_5DKu7HgzGBzS1VTA5uUjKWOCU0B_j08WXBiEC0mr0zNREkqVfwFDD-d24HlNEbrqioLsBuFRiwIWKc1m_ZlVQbG7P36RUxhuv2vbSp80FKyNM-Tj93FDzq91jsyNmsQhyNv_fNr3TXfzzSPjHt8Go0FMMP66weoKMgW2PbXlhVKwEuXUHyakLLzewm9UMeQaEiRzhiTMU3UkLXcKbYEJJvfNFcLwSl9W8JCO_l0Yj3ud-qt_nQYEZwqW6u5nfdQllN133iikV4fM5QZsMCnm8Rq1mvLR0y9bmJiD7fwM1tmJ791TUWqmKaTnP49U493VanKpUAfzIiOiIbhg"

# Headers para autenticación
headers = {
    "Authorization": f"Bearer {JWT_TOKEN}",
    "Content-Type": "application/json"
}

def get_table_id(fully_qualified_name):
    """Obtener el ID de una tabla por su FQN"""
    url = f"{OPENMETADATA_URL}/v1/tables"
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        if data.get("data"):
            for table in data["data"]:
                if table.get("fullyQualifiedName") == fully_qualified_name:
                    return table["id"]
    return None

def create_lineage(source_fqn, destination_fqn):
    """Crear lineage entre dos tablas"""
    
    # Obtener IDs de las tablas
    source_id = get_table_id(source_fqn)
    destination_id = get_table_id(destination_fqn)
    
    if not source_id:
        print(f"❌ No se encontró la tabla fuente: {source_fqn}")
        return False
        
    if not destination_id:
        print(f"❌ No se encontró la tabla destino: {destination_fqn}")
        return False
    
    print(f"✅ Tabla fuente encontrada: {source_fqn} (ID: {source_id})")
    print(f"✅ Tabla destino encontrada: {destination_fqn} (ID: {destination_id})")
    
    # Crear el lineage
    lineage_data = {
        "fromEntity": {
            "id": source_id,
            "type": "table"
        },
        "toEntity": {
            "id": destination_id,
            "type": "table"
        },
        "description": "Airbyte ETL Pipeline: MariaDB → Iceberg Bronze",
        "pipeline": {
            "name": "airbyte_mariadb_to_iceberg",
            "displayName": "Airbyte: MariaDB to Iceberg Bronze",
            "description": "ETL pipeline that extracts data from MariaDB and loads it to Iceberg Bronze layer",
            "pipelineType": "ETL",
            "tasks": [
                {
                    "name": "extract_mariadb",
                    "displayName": "Extract from MariaDB",
                    "taskType": "Extract",
                    "description": "Extract jvc_proforma data from MariaDB intranet database"
                },
                {
                    "name": "load_iceberg",
                    "displayName": "Load to Iceberg",
                    "taskType": "Load", 
                    "description": "Load extracted data to Iceberg Bronze layer in MinIO"
                }
            ]
        }
    }
    
    # Enviar request para crear lineage
    url = f"{OPENMETADATA_URL}/v1/lineage"
    response = requests.post(url, headers=headers, json=lineage_data)
    
    if response.status_code in [200, 201]:
        print(f"✅ Lineage creado exitosamente: {source_fqn} → {destination_fqn}")
        return True
    else:
        print(f"❌ Error creando lineage: {response.status_code}")
        print(f"Response: {response.text}")
        return False

def main():
    print("🚀 Creando lineage manual de Airbyte...")
    print("=" * 50)
    
    # Definir las tablas a conectar
    source_table = "mariadb_intranet.default.intranet.jvc_proforma"
    destination_table = "trino_iceberg_dev.iceberg_dev.cedia_bronze_sia.jvc_proforma"
    
    print(f"📊 Conectando: {source_table}")
    print(f"📊 Con destino: {destination_table}")
    print()
    
    # Crear el lineage
    success = create_lineage(source_table, destination_table)
    
    if success:
        print()
        print("🎉 ¡Lineage de Airbyte creado exitosamente!")
        print("🌐 Puedes verificar en OpenMetadata: http://localhost:8585")
        print("🔗 Ve a la tabla fct_proforma y verifica el lineage completo")
    else:
        print()
        print("❌ Error creando el lineage de Airbyte")
        sys.exit(1)

if __name__ == "__main__":
    main()
