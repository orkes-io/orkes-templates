#!/bin/bash

# Default values
ORKES_API_KEY_ID=${1:-""}
ORKES_API_KEY_SECRET=${2:-""}
ORKES_API_URL=${3:-""}

# Export the environment variables
export ORKES_API_KEY_ID
export ORKES_API_KEY_SECRET
export ORKES_API_URL

# Check if required Node modules are installed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Run the workers
echo "Starting Conductor workers..."
npx ts-node workers/index.ts 