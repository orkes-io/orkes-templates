# ---- Builder Stage ----
FROM node:23-slim AS builder

WORKDIR /app

# Copy package files and install all dependencies (including dev for build)
COPY package*.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy the rest of the application code (respecting .dockerignore)
COPY . .

# Build TypeScript
RUN yarn build

# ---- Final Stage ----
FROM node:23-slim

WORKDIR /app

# Create a non-root user and group
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Copy only necessary files for production
COPY package*.json yarn.lock ./

# Install only production dependencies
RUN yarn install --production --frozen-lockfile

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/run.sh ./run.sh

# Copy sample env file for reference (optional, but can be helpful)
COPY .env.sample ./

# Ensure run.sh is executable
RUN chmod +x run.sh

# Change ownership to the non-root user
RUN chown -R nodejs:nodejs /app

# Switch to the non-root user
USER nodejs

# Expose port if your application listens on one (e.g., EXPOSE 3000)
# Add this line if needed, replacing 3000 with the actual port

# Set the entrypoint to run the application using the script
# The script now reads environment variables provided at runtime
ENTRYPOINT ["./run.sh"]

# No CMD needed here as run.sh handles execution and expects ENV vars
