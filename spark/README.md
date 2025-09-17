# Spark + Iceberg Data Lakehouse Setup

This directory contains the complete Apache Spark setup integrated with Apache Iceberg, Project Nessie, and MinIO for your data lakehouse architecture.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Jupyter       │    │  Spark Master   │    │  Spark Workers  │
│   Notebook      │◄──►│                 │◄──►│                 │
│                 │    │                 │    │   (2 replicas)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    Data Network        │
                    │    (data-poc)          │
                    └────────────┬────────────┘
                                 │
        ┌────────────┬───────────┼───────────┬────────────┐
        │            │           │           │            │
┌───────▼──────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐ ┌─────▼─────┐
│    MinIO     │ │ Nessie │ │ Trino  │ │  dbt   │ │  Airbyte  │
│   (S3 API)   │ │Catalog │ │ Engine │ │Transforms│ │ Ingestion │
└──────────────┘ └────────┘ └────────┘ └────────┘ └───────────┘
```

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have the core infrastructure running:

```bash
# Create the shared network
docker network create data-poc

# Start core services (MinIO, Nessie, Trino)
docker compose -p cedia \
  -f ../minio-docker-compose.yml \
  -f ../nessie-docker-compose.yml \
  -f ../trino/trino-docker-compose.yml \
  up -d
```

### 2. Start Spark Cluster

```bash
# Navigate to spark directory
cd spark

# Start Spark cluster with Jupyter
docker compose -p cedia -f spark-docker-compose.yml up -d

# Check if all services are running
docker compose -p cedia -f spark-docker-compose.yml ps
```

### 3. Access Services

- **Jupyter Notebook**: http://localhost:8888 (no token required)
- **Spark Master UI**: http://localhost:8082
- **MinIO Console**: http://localhost:9001 (admin/password123)
- **Trino**: http://localhost:8080

### 4. Verify Python Dependencies

The system automatically installs all required Python packages from `requirements.txt`. To verify:

```bash
# Check if packages are installed correctly
docker exec jupyter-spark python -c "import pynessie, pyiceberg, boto3; print('✅ All packages installed!')"
```

If installation fails, see the [troubleshooting section](#missing-dependencies) for multiple installation methods.

### 5. Run Integration Tests

1. Open Jupyter at http://localhost:8888
2. Navigate to `work/spark_integration_test.py`
3. Copy and paste each cell section into notebook cells
4. Run each cell sequentially

Or run the test script directly:

```bash
# Copy the test script into the running Jupyter container
docker cp notebooks/spark_integration_test.py jupyter-spark:/home/jovyan/work/

# Open Jupyter and create a new notebook, then copy sections from the .py file
```

## 📁 Directory Structure

```
spark/
├── spark-docker-compose.yml     # Docker Compose for Spark cluster
├── spark-config/                # Spark configuration files
│   ├── spark-defaults.conf     # Main Spark configuration
│   └── log4j2.properties       # Logging configuration
├── notebooks/                   # Jupyter notebooks and test scripts
│   ├── spark_integration_test.py # Complete integration test
│   ├── requirements.txt         # Python dependencies (auto-installed)
│   └── install_requirements.py # Manual installation helper script
└── README.md                   # This file
```

## ⚙️ Configuration Details

### Spark Configuration

The `spark-defaults.conf` includes:
- **Iceberg Integration**: Catalog and table format configuration
- **S3/MinIO Setup**: Filesystem configuration for object storage
- **Nessie Catalog**: Version control and branching for tables
- **Performance Tuning**: Memory, serialization, and optimization settings

### Docker Compose Features

- **Spark Master**: Web UI on port 8082, cluster coordination
- **Spark Workers**: 2 replicas with 2GB memory and 2 cores each
- **Jupyter Lab**: Pre-configured with all necessary dependencies
- **Shared Networking**: All services on `data-poc` network
- **Persistent Storage**: Jupyter home directory and notebooks preserved

### Python Dependencies

All dependencies are defined in `notebooks/requirements.txt` and automatically installed in the Jupyter container. Key packages include:

**Core Data Lakehouse Stack:**
- `pynessie==0.67.0`: Nessie catalog client for data versioning
- `pyiceberg[s3fs,pandas,duckdb]==0.6.1`: Apache Iceberg Python client
- `boto3==1.34.0`: AWS S3 client for MinIO integration
- `s3fs==2023.12.2`: S3 filesystem support (compatible version)
- `pandas>=2.0.0,<3.0.0`: Data processing and analysis
- `pyarrow>=13.0.0,<16.0.0`: Columnar data format support

**Analysis & Visualization:**
- `matplotlib>=3.8.0`, `seaborn>=0.13.0`, `plotly>=5.17.0`: Data visualization
- `jupyter-dash>=0.4.2`: Interactive dashboards in Jupyter
- `great-expectations>=0.18.0`: Data quality and validation
- `pytest>=7.4.0`, `ipytest>=0.14.0`: Testing frameworks

**Installation Methods:**
1. **Automatic (Default)**: Packages install during container startup via `requirements.txt`
2. **Manual in Jupyter**: Run `exec(open('install_requirements.py').read())` 
3. **Direct pip**: `!pip install -r requirements.txt` in a notebook cell

## 🧪 Test Coverage

The integration test covers:

1. **Connectivity Tests**
   - MinIO S3 API connection
   - Nessie catalog connection
   - Spark cluster connection

2. **Data Pipeline Simulation**
   - Bronze layer: Raw data ingestion
   - Silver layer: Data cleaning and standardization
   - Gold layer: Aggregations for analytics

3. **Iceberg Features**
   - Table creation and querying
   - Time travel capabilities
   - Schema evolution
   - Metadata operations

4. **Nessie Features**
   - Branch creation and isolation
   - Version control for tables
   - Catalog operations

5. **Data Quality Checks**
   - Completeness validation
   - Business rule enforcement
   - Performance testing

## 🔧 Troubleshooting

### Common Issues

1. **Services not connecting**
   ```bash
   # Check network connectivity
   docker network inspect data-poc
   
   # Restart services in order
   docker compose -p cedia -f spark-docker-compose.yml down
   docker compose -p cedia -f spark-docker-compose.yml up -d
   ```

2. **Jupyter permissions issues**
   ```bash
   # Fix ownership if needed
   docker exec -it jupyter-spark chown -R jovyan:users /home/jovyan
   ```

3. **Memory issues**
   ```bash
   # Adjust worker memory in docker-compose.yml
   # Change SPARK_WORKER_MEMORY to 1G if needed
   ```

4. **Missing dependencies**
   ```bash
   # Method 1: Restart container (recommended)
   docker compose -p cedia -f spark-docker-compose.yml restart jupyter
   
   # Method 2: Reinstall in running container
   docker exec -u root jupyter-spark pip install -r /home/jovyan/work/requirements.txt
   
   # Method 3: Install from Jupyter notebook
   # Run this in a notebook cell:
   exec(open('/home/jovyan/work/install_requirements.py').read())
   
   # Method 4: Manual pip install
   !pip install -r requirements.txt
   ```

5. **Package version conflicts**
   ```bash
   # Check installed versions
   docker exec jupyter-spark pip list | grep -E "(pynessie|pyiceberg|s3fs)"
   
   # If conflicts persist, use the helper script
   docker exec jupyter-spark python /home/jovyan/work/install_requirements.py
   ```

### Logs and Monitoring

```bash
# View Spark Master logs
docker logs spark-master

# View Jupyter logs
docker logs jupyter-spark

# View all logs
docker compose -p cedia -f spark-docker-compose.yml logs -f
```

## 🔗 Integration with Existing Stack

### dbt Integration

Your existing dbt models can connect to this Spark cluster via Trino:

```yaml
# In dbt/profiles.yml
spark_iceberg:
  target: dev
  outputs:
    dev:
      type: trino
      method: none
      host: localhost
      port: 8080
      catalog: iceberg_dev
      schema: cedia_silver_sia
```

### Airbyte Integration

Configure Airbyte destinations to write to Iceberg tables:
- **Destination**: S3/MinIO
- **Format**: Apache Iceberg
- **Catalog**: Nessie
- **Location**: `s3a://cedia-datalake-dev/iceberg/bronze/`

### BI Tools Integration

Connect analytics tools directly to Trino:
- **Superset**: Use Trino connector
- **Tableau**: Use Presto/Trino connector
- **PowerBI**: Use generic ODBC with Trino driver

## 📈 Performance Optimization

### For Production Use

1. **Resource Allocation**
   ```yaml
   # Increase worker resources
   SPARK_WORKER_MEMORY: 4G
   SPARK_WORKER_CORES: 4
   ```

2. **Partitioning Strategy**
   ```sql
   -- Partition by date for time-series data
   CREATE TABLE iceberg_dev.bronze.sales (...)
   PARTITIONED BY (year, month)
   ```

3. **Compaction Jobs**
   ```bash
   # Schedule regular compaction
   spark-sql --conf spark.sql.catalog.iceberg_dev.type=nessie \
     -e "CALL iceberg_dev.system.rewrite_data_files('bronze.sales')"
   ```

## 🆘 Support

For issues related to:
- **Spark Configuration**: Check `spark-config/` files
- **Integration Problems**: Run the test script
- **Performance Issues**: Review resource allocation
- **Data Pipeline**: Validate with sample data

## 📚 Additional Resources

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Apache Iceberg Documentation](https://iceberg.apache.org/)
- [Project Nessie Documentation](https://projectnessie.org/)
- [Trino Iceberg Connector](https://trino.io/docs/current/connector/iceberg.html)
