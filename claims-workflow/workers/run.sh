#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error when substituting.
# Check if required environment variables are set
if [ -z "$ORKES_API_KEY_ID" ] || [ -z "$ORKES_API_KEY_SECRET" ] || [ -z "$ORKES_API_URL" ]; then
  echo "Error: Required environment variables (ORKES_API_KEY_ID, ORKES_API_KEY_SECRET, ORKES_API_URL) are not set."
  echo "Please ensure they are defined in the .env file or exported in the environment."
  exit 1
fi

# Run the workers
echo "Starting Conductor workers..."
node dist/index.js
