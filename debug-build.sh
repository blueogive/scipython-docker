#!/bin/bash
set -e

# Create a temporary file to store the image ID
IIDFILE=.docker-iid.txt

if [ -s "$IIDFILE" ]; then
  # File exists and has content
  LAST_ID=$(cat "$IIDFILE")
  echo "Starting debug shell in image $LAST_ID"
  docker run --rm -it -p 8888:8888 "$LAST_ID" /bin/bash
else
  # Try to get the ID of the last cached layer
  CACHE_ID=$(docker images -q -f "dangling=true" | head -1)
  if [ -n "$CACHE_ID" ]; then
    echo "Starting debug shell in cached image $CACHE_ID"
    docker run --rm -it -p 8888:8888 "$CACHE_ID" /bin/bash
  else
    echo "No successful intermediate build found"
    exit 1
  fi
fi
