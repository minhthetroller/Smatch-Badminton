#!/bin/bash

# This script reads environment variables from .env file and makes them available to Xcode build
# It creates a temporary .xcconfig file that Xcode can use

set -e

PROJECT_DIR="${SRCROOT}/.."
ENV_FILE="${PROJECT_DIR}/.env"
XCCONFIG_FILE="${SRCROOT}/Flutter/EnvConfig.xcconfig"

echo "Loading environment variables from ${ENV_FILE}"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Warning: .env file not found at ${ENV_FILE}"
    echo "Creating default .xcconfig with empty values"
    
    # Create .xcconfig with empty values for CI/CD environments
    cat > "$XCCONFIG_FILE" <<EOF
// Auto-generated environment configuration
// This file is generated from .env file during build

FACEBOOK_APP_ID = 
FACEBOOK_CLIENT_TOKEN = 
GOOGLE_REVERSED_CLIENT_ID = 
EOF
    exit 0
fi

# Create the .xcconfig file
echo "// Auto-generated environment configuration" > "$XCCONFIG_FILE"
echo "// This file is generated from .env file during build" >> "$XCCONFIG_FILE"
echo "" >> "$XCCONFIG_FILE"

# Read .env file and convert to .xcconfig format
while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $line ]]; then
        continue
    fi
    
    # Split on first '=' only to handle values with '=' characters
    key="${line%%=*}"
    value="${line#*=}"
    
    # Trim whitespace from key
    key=$(echo "$key" | xargs)
    
    # Skip if key is empty
    if [[ -z $key ]]; then
        continue
    fi
    
    # Validate key contains only safe characters (alphanumeric and underscore)
    if ! [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "Warning: Skipping invalid key '$key' - must contain only letters, numbers, and underscores"
        continue
    fi
    
    # Remove leading/trailing quotes from value (both single and double)
    if [[ $value =~ ^\"(.*)\"$ ]] || [[ $value =~ ^\'(.*)\'$ ]]; then
        value="${BASH_REMATCH[1]}"
    fi
    
    # Only include relevant keys
    if [[ $key == "FACEBOOK_APP_ID" ]] || [[ $key == "FACEBOOK_CLIENT_TOKEN" ]] || [[ $key == "GOOGLE_REVERSED_CLIENT_ID" ]]; then
        # Escape any special characters in value for .xcconfig format
        # Use printf for safe string handling
        printf "%s = %s\n" "$key" "$value" >> "$XCCONFIG_FILE"
    fi
done < "$ENV_FILE"

echo "Environment configuration generated at ${XCCONFIG_FILE}"
