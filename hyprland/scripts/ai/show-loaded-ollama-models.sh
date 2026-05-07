#!/bin/bash

# LM Studio default configuration
url="http://localhost"
port="1234"
json_out=0

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -j|--json_output) json_out=1 ;;
    -p|--port) port="$2"; shift ;;
    -u|--ollama_url) url="$2"; shift ;; # Kept flag name for compatibility
  esac
  shift
done

# Query LM Studio for all models and filter for those with loaded instances
# Native API /api/v1/models provides 'loaded_instances' array
response=$(curl -s "$url:$port/api/v1/models")

if [[ -z "$response" ]]; then
    [[ $json_out -eq 0 ]] && echo "Error: Could not connect to LM Studio on $url:$port"
    exit 1
fi

# Extract keys of models that are currently loaded
loaded_models=$(echo "$response" | jq -c '[.models[] | select(.loaded_instances | length > 0) | {model: .key}]')

if [[ "$json_out" -eq 1 ]]; then
    echo "$loaded_models"
else
    echo "Loaded Models:"
    echo "$loaded_models" | jq -r '.[].model'
fi
