#!/bin/bash
#
# Reindex Search API content in controlled batches on Pantheon
#
# site → your Pantheon site machine name
# env → environment (dev, test, live)
# index_machine_name → the Search API index ID
#
# This script allows you to control both batch size and pacing, which can greatly reduce strain on the database during reindexing
#
# Usage: ./reindex-searchapi.sh <site> <env> <index_machine_name>

SITE=$1
ENV=$2
INDEX=$3

# Configurable settings
BATCH_SIZE=25000   # number of items per batch
SLEEP_TIME=15      # seconds to pause between batches

# Get total items to index
TOTAL=$(terminus drush $SITE.$ENV -- search-api:index --index=$INDEX --status --format=json | jq -r '.remaining')
echo "Total items to index: $TOTAL"

OFFSET=0

while [ $OFFSET -lt $TOTAL ]
do
  echo "Indexing batch: offset=$OFFSET size=$BATCH_SIZE"
  
  # Run indexing command
  terminus drush $SITE.$ENV -- search-api:index $INDEX --limit=$BATCH_SIZE --start=$OFFSET
  
  # Exit code check
  if [ $? -ne 0 ]; then
    echo "❌ Error during indexing at offset $OFFSET. Rerun script to resume."
    exit 1
  fi
  
  OFFSET=$((OFFSET + BATCH_SIZE))
  
  echo "✅ Completed batch up to offset $OFFSET"
  
  # Sleep to avoid hammering MySQL
  echo "Sleeping $SLEEP_TIME seconds..."
  sleep $SLEEP_TIME
done

echo "🎉 Indexing complete for $INDEX"
