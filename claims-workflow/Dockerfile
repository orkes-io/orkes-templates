FROM node:18-slim

WORKDIR /app

# Copy package files
COPY package*.json ./

# Copy source code and run script
COPY workers/ ./workers/
COPY run.sh ./

# Install dependencies
RUN npm install

# Make run.sh executable
RUN chmod +x run.sh

# Set default environment variables
ENV ORKES_API_KEY_ID=""
ENV ORKES_API_KEY_SECRET=""
ENV ORKES_API_URL=""

# Use the run.sh script as entrypoint
ENTRYPOINT ["./run.sh"]
# Pass environment variables as default CMD arguments
CMD ["${ORKES_API_KEY_ID}", "${ORKES_API_KEY_SECRET}", "${ORKES_API_URL}"] 