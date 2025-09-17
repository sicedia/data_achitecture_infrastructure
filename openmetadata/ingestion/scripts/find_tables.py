#!/usr/bin/env python3
"""
Script para encontrar tablas que contienen 'jvc_proforma'
"""

import requests
import json

# Configuración
OPENMETADATA_URL = "http://openmetadata-server:8585/api"
JWT_TOKEN = "eyJraWQiOiJHYjM4OWEtOWY3Ni1nZGpzLWE5MmotMDI0MmJrOTQzNTYiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImlzQm90IjpmYWxzZSwiaXNzIjoib3Blbi1tZXRhZGF0YS5vcmciLCJpYXQiOjE2NjM5Mzg0NjIsImVtYWlsIjoiYWRtaW5Ab3Blbm1ldGFkYXRhLm9yZyJ9.tS8um_5DKu7HgzGBzS1VTA5uUjKWOCU0B_j08WXBiEC0mr0zNREkqVfwFDD-d24HlNEbrqioLsBuFRiwIWKc1m_ZlVQbG7P36RUxhuv2vbSp80FKyNM-Tj93FDzq91jsyNmsQhyNv_fNr3TXfzzSPjHt8Go0FMMP66weoKMgW2PbXlhVKwEuXUHyakLLzewm9UMeQaEiRzhiTMU3UkLXcKbYEJJvfNFcLwSl9W8JCO_l0Yj3ud-qt_nQYEZwqW6u5nfdQllN133iikV4fM5QZsMCnm8Rq1mvLR0y9bmJiD7fwM1tmJ791TUWqmKaTnP49U493VanKpUAfzIiOiIbhg"

# Headers para autenticación
headers = {
    "Authorization": f"Bearer {JWT_TOKEN}",
    "Content-Type": "application/json"
}

def find_tables():
    """Buscar todas las tablas que contienen 'jvc_proforma'"""
    url = f"{OPENMETADATA_URL}/v1/tables"
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        if data.get("data"):
            print("🔍 Tablas encontradas que contienen 'jvc_proforma':")
            print("=" * 60)
            
            for table in data["data"]:
                fqn = table.get("fullyQualifiedName", "")
                if "jvc_proforma" in fqn.lower():
                    print(f"📊 FQN: {fqn}")
                    print(f"   ID: {table.get('id')}")
                    print(f"   Servicio: {table.get('service', {}).get('name', 'N/A')}")
                    print(f"   Tipo: {table.get('serviceType', 'N/A')}")
                    print()
        else:
            print("❌ No se encontraron datos en la respuesta")
    else:
        print(f"❌ Error obteniendo tablas: {response.status_code}")
        print(f"Response: {response.text}")

if __name__ == "__main__":
    find_tables()

