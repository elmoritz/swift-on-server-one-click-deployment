# Multi-stage Dockerfile for Hummingbird Todos Application
# Stage 1: Dependencies - Cache Swift package dependencies
FROM swift:5.9 as dependencies

WORKDIR /app

# Copy only package manifests for dependency resolution
COPY todos-fluent/Package.* ./

# Resolve dependencies (this layer is cached when Package.resolved doesn't change)
RUN swift package resolve

# Stage 2: Builder - Build the application
FROM swift:5.9 as builder

WORKDIR /app

# Copy resolved dependencies from previous stage
COPY --from=dependencies /app/.build ./.build
COPY --from=dependencies /app/Package.* ./

# Copy source code
COPY todos-fluent/Sources ./Sources
COPY todos-fluent/Tests ./Tests

# Build the application (benefits from cached dependencies)
RUN swift build -c release --static-swift-stdlib

# Stage 2: Runtime
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash appuser

WORKDIR /app

# Copy the built executable from builder stage
COPY --from=builder /app/.build/release/App /app/todos-server

# Create directory for database
RUN mkdir -p /app/data && chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 8080

# Environment variables with defaults
ENV HOSTNAME=0.0.0.0
ENV PORT=8080
ENV DB_PATH=/app/data/db.sqlite

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run migrations and start server
CMD ["/app/todos-server", "--hostname", "${HOSTNAME}", "--port", "${PORT}"]
