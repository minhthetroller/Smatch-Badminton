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
    echo "Creating default .xcconfig with placeholder values"
    
    # Create .xcconfig with placeholder values for CI/CD environments
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
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    if [[ $key =~ ^#.*$ ]] || [[ -z $key ]]; then
        continue
    fi
    
    # Remove any quotes from value
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    
    # Only include relevant keys
    if [[ $key == "FACEBOOK_APP_ID" ]] || [[ $key == "FACEBOOK_CLIENT_TOKEN" ]] || [[ $key == "GOOGLE_REVERSED_CLIENT_ID" ]]; then
        echo "$key = $value" >> "$XCCONFIG_FILE"
    fi
done < "$ENV_FILE"

echo "Environment configuration generated at ${XCCONFIG_FILE}"
