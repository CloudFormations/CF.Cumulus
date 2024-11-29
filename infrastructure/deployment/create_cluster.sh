#!/bin/bash

# Exit on error, undefined vars, and propagate pipe failures
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR

# Logging function
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

# Function to check required environment variables
check_required_vars() {
    local required_vars=(
        "ADB_WORKSPACE_URL"
        "ADB_WORKSPACE_ID"
        "DATABRICKS_CLUSTER_NAME"
        "DATABRICKS_SPARK_VERSION"
        "DATABRICKS_NODE_TYPE"
        "DATABRICKS_NUM_WORKERS"
        "DATABRICKS_AUTO_TERMINATE_MINUTES"
        "DATABRICKS_MIN_WORKERS"
        "DATABRICKS_MAX_WORKERS"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log "ERROR: Required variable $var is not set"
            exit 1
        fi
    done
}

# Function to get Azure tokens
get_azure_tokens() {
    local max_retries=3
    local retry_count=0
    local wait_time=5
    
    while [[ $retry_count -lt $max_retries ]]; do
        try {
            adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
            azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)
            break
        } catch {
            retry_count=$((retry_count + 1))
            if [[ $retry_count -eq $max_retries ]]; then
                log "ERROR: Failed to obtain Azure tokens after $max_retries attempts"
                exit 1
            fi
            log "WARNING: Failed to get tokens, retrying in $wait_time seconds..."
            sleep $wait_time
        }
    done
}

# Function to create cluster configuration
create_cluster_config() {
    # Spark configuration with optimizations
       local DATABRICKS_SPARK_CONF='{
        // General Delta Lake optimizations

        "spark.databricks.delta.preview.enabled": "true",        // Enables preview features for Delta Lake operations
        "spark.eventLog.unknownRecord.maxSize": "16m",           // Sets maximum size for unknown event records in Spark logs, prevents log overflow
        "spark.databricks.io.cache.enabled": "true",             // Enables Databricks IO cache for better read performance
        "spark.databricks.io.cache.maxMetaDataCache": "1g",      // Allocates 1GB for caching file metadata, improves file lookup performance
        "spark.databricks.delta.autoCompact.enabled": "true",    // Automatically compacts small files in Delta tables
        "spark.speculation": "true",                             // Enables speculative execution of tasks, helps with straggler tasks
                
        // Parquet-specific optimizations

        "spark.sql.parquet.compression.codec": "snappy",        // Balanced compression ratio and speed
        //"spark.sql.parquet.mergeSchema": "false",               // Improves reading performance when schema evolution not needed
        "spark.sql.parquet.filterPushdown": "true",             // Enables filter pushdown for better query performance
        "spark.sql.files.maxPartitionBytes": "134217728",       // Optimizes partition size for better parallelism
        
        // Memory management optimizations

        "spark.memory.offHeap.enabled": "true",                 // Enables off-heap memory to reduce GC pressure
        "spark.memory.offHeap.size": "10g",                     // Allocates 10GB for off-heap memory
        "spark.sql.shuffle.partitions": "200",                  // Sets default number of shuffle partitions
        "spark.sql.adaptive.enabled": "true",                   // Enables adaptive query execution
        "spark.sql.adaptive.coalescePartitions.enabled": "true", // Optimizes partition sizes during runtime
        
        // I/O and performance optimizations

        "spark.sql.files.maxRecordsPerFile": "50000000",       // Prevents creating too many small files
        "spark.sql.broadcastTimeout": "600",                   // Increases timeout for broadcast joins (in seconds)
        "spark.sql.autoBroadcastJoinThreshold": "64mb",        // Optimizes small table broadcasts
        
        // Caching optimizations for large datasets

        "spark.databricks.io.cache.maxDiskUsage": "50g",        // Sets maximum disk space for caching
        "spark.databricks.io.cache.compression.enabled": "true" // Enables compression for cached data
    }'


    # Create cluster configuration JSON
    CLUSTER_CREATE_JSON_STRING=$(jq -n -c \
        --arg cn "$DATABRICKS_CLUSTER_NAME" \
        --arg sv "$DATABRICKS_SPARK_VERSION" \
        --arg nt "$DATABRICKS_NODE_TYPE" \
        --arg nw "$DATABRICKS_NUM_WORKERS" \
        --arg spc "$DATABRICKS_SPARK_CONF" \
        --arg at "$DATABRICKS_AUTO_TERMINATE_MINUTES" \
        --arg minw "${DATABRICKS_MIN_WORKERS:-$DATABRICKS_NUM_WORKERS}" \
        --arg maxw "${DATABRICKS_MAX_WORKERS:-$DATABRICKS_NUM_WORKERS}" \
        '{
            cluster_name: $cn,
            idempotency_token: $cn,
            spark_version: $sv,
            node_type_id: $nt,
            autoscale: {
                min_workers: ($minw|tonumber),
                max_workers: ($maxw|tonumber)
            },
            autotermination_minutes: ($at|tonumber),
            spark_conf: ($spc|fromjson),
            custom_tags: {
                ResourceGroup: env.RESOURCE_GROUP,
                Environment: env.ENVIRONMENT_TYPE
            }
        }')
}

# Function to create cluster via API
create_cluster() {
    local api_url="https://${ADB_WORKSPACE_URL}/api/2.0/clusters/create"
    local auth_header="Authorization: Bearer $adbGlobalToken"
    local mgmt_token="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
    local resource_id="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

    # Make API request with retry logic
    local max_retries=3
    local retry_count=0
    local wait_time=5

    while [[ $retry_count -lt $max_retries ]]; do
        response=$(echo $CLUSTER_CREATE_JSON_STRING | curl -sS -X POST \
            -H "$auth_header" \
            -H "$mgmt_token" \
            -H "$resource_id" \
            -H "Content-Type: application/json" \
            --retry 3 \
            --retry-delay 5 \
            --data-binary "@-" \
            "$api_url")

        if [[ $(echo "$response" | jq -r 'has("error")') == "false" ]]; then
            break
        fi

        retry_count=$((retry_count + 1))
        if [[ $retry_count -eq $max_retries ]]; then
            log "ERROR: Failed to create cluster after $max_retries attempts. Response: $response"
            exit 1
        fi
        log "WARNING: Failed to create cluster, retrying in $wait_time seconds..."
        sleep $wait_time
    done

    echo "$response" > $AZ_SCRIPTS_OUTPUT_PATH
    log "Cluster creation initiated successfully"
}

# Main execution
main() {
    log "Starting cluster creation process"
    check_required_vars
    log "Required variables validated"
    
    get_azure_tokens
    log "Azure tokens obtained"
    
    create_cluster_config
    log "Cluster configuration created"
    
    create_cluster
    log "Cluster creation process completed"
}

# Execute main function
main