#!/usr/bin/env python3
"""
Installation script for Spark + Iceberg + Nessie requirements
Run this in Jupyter notebook if automatic installation fails
"""

import subprocess
import sys

def install_package(package):
    """Install a package using pip"""
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        print(f"✅ Successfully installed {package}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install {package}: {e}")
        return False

def main():
    """Install all required packages"""
    print("🚀 Installing Spark + Iceberg + Nessie requirements...")
    
    # Core packages - install in order to handle dependencies
    core_packages = [
        "pynessie==0.67.0",
        "boto3==1.34.0", 
        "s3fs==2023.12.2",
        "pyiceberg[s3fs,pandas,duckdb]==0.6.1",
    ]
    
    # Additional packages
    additional_packages = [
        "matplotlib>=3.8.0",
        "seaborn>=0.13.0", 
        "plotly>=5.17.0",
        "jupyter-dash>=0.4.2",
        "great-expectations>=0.18.0",
        "pytest>=7.4.0",
        "ipytest>=0.14.0"
    ]
    
    all_packages = core_packages + additional_packages
    failed_packages = []
    
    for package in all_packages:
        if not install_package(package):
            failed_packages.append(package)
    
    print("\n" + "="*50)
    if failed_packages:
        print(f"❌ Installation completed with {len(failed_packages)} failures:")
        for pkg in failed_packages:
            print(f"   - {pkg}")
        print("\n💡 Try installing failed packages individually")
    else:
        print("✅ All packages installed successfully!")
        
    # Test imports
    print("\n🧪 Testing package imports...")
    test_imports = [
        ("pynessie", "pynessie"),
        ("pyiceberg", "pyiceberg.catalog"),
        ("boto3", "boto3"),
        ("s3fs", "s3fs"),
        ("matplotlib", "matplotlib.pyplot"),
        ("seaborn", "seaborn"),
        ("plotly", "plotly.graph_objects")
    ]
    
    for name, module in test_imports:
        try:
            __import__(module)
            print(f"✅ {name} import successful")
        except ImportError as e:
            print(f"❌ {name} import failed: {e}")

if __name__ == "__main__":
    main()

