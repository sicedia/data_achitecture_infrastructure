#!/bin/bash

# Spark Docker Compose Setup Test Script
# This script validates that all services are running correctly

echo "🧪 Testing Spark Data Lakehouse Setup..."
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a service is running
check_service() {
    local service_name=$1
    local container_name=$2
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q $container_name; then
        echo -e "✅ ${GREEN}$service_name is running${NC}"
        return 0
    else
        echo -e "❌ ${RED}$service_name is not running${NC}"
        return 1
    fi
}

# Function to check HTTP endpoint
check_endpoint() {
    local service_name=$1
    local url=$2
    local expected_code=${3:-200}
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_code"; then
        echo -e "✅ ${GREEN}$service_name endpoint is accessible${NC}"
        return 0
    else
        echo -e "❌ ${RED}$service_name endpoint is not accessible${NC}"
        return 1
    fi
}

# Function to check network
check_network() {
    if docker network ls | grep -q "data-poc"; then
        echo -e "✅ ${GREEN}Docker network 'data-poc' exists${NC}"
        return 0
    else
        echo -e "❌ ${RED}Docker network 'data-poc' does not exist${NC}"
        echo -e "   ${YELLOW}Run: docker network create data-poc${NC}"
        return 1
    fi
}

# Start tests
echo ""
echo "1. Checking Docker Network..."
check_network

echo ""
echo "2. Checking Core Services..."
check_service "MinIO" "minio"
check_service "Nessie" "nessie"
check_service "Trino" "trino"

echo ""
echo "3. Checking Spark Services..."
check_service "Spark Master" "spark-master"
check_service "Jupyter" "jupyter-spark"

# Count running spark workers
worker_count=$(docker ps --filter "name=spark-spark-worker" --filter "status=running" | grep -c "spark-worker")
if [ $worker_count -gt 0 ]; then
    echo -e "✅ ${GREEN}Spark Workers are running ($worker_count instances)${NC}"
else
    echo -e "❌ ${RED}No Spark Workers are running${NC}"
fi

echo ""
echo "4. Checking Service Endpoints..."
check_endpoint "MinIO Console" "http://localhost:9001" "200\|403"
check_endpoint "Nessie API" "http://localhost:19120/api/v2/config" "200"
check_endpoint "Trino" "http://localhost:8083" "200"
check_endpoint "Spark Master UI" "http://localhost:8082" "200"
check_endpoint "Jupyter" "http://localhost:8888" "200\|302"

echo ""
echo "5. Checking File Structure..."
if [ -f "spark-config/spark-defaults.conf" ]; then
    echo -e "✅ ${GREEN}Spark configuration exists${NC}"
else
    echo -e "❌ ${RED}Spark configuration missing${NC}"
fi

if [ -f "notebooks/spark_integration_test.py" ]; then
    echo -e "✅ ${GREEN}Integration test script exists${NC}"
else
    echo -e "❌ ${RED}Integration test script missing${NC}"
fi

if [ -d "notebooks" ]; then
    echo -e "✅ ${GREEN}Notebooks directory exists${NC}"
else
    echo -e "❌ ${RED}Notebooks directory missing${NC}"
fi

echo ""
echo "6. Testing Basic Docker Commands..."

# Test docker exec
if docker exec spark-master spark-submit --version &>/dev/null; then
    echo -e "✅ ${GREEN}Spark Master is responsive${NC}"
else
    echo -e "❌ ${RED}Spark Master is not responsive${NC}"
fi

# Test MinIO connectivity
if docker exec minio mc alias list &>/dev/null; then
    echo -e "✅ ${GREEN}MinIO is responsive${NC}"
else
    echo -e "❌ ${RED}MinIO is not responsive${NC}"
fi

echo ""
echo "7. Resource Usage..."
echo "Docker containers resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
    $(docker ps --filter "network=data-poc" --format "{{.Names}}" | tr '\n' ' ')

echo ""
echo "=========================================="
echo "🎯 Setup Validation Complete!"
echo ""
echo "Next Steps:"
echo "1. Open Jupyter: http://localhost:8888"
echo "2. Run the integration test script"
echo "3. Check Spark Master UI: http://localhost:8082"
echo "4. Verify MinIO Console: http://localhost:9001"
echo ""
echo "📚 For detailed instructions, see: spark/README.md"
