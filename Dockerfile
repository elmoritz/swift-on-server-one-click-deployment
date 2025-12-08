# Multi-stage Dockerfile for Hummingbird Todos Application
# Stage 1: Dependencies - Cache Swift package dependencies
FROM swift:5.9 AS dependencies

WORKDIR /app

# Copy only package manifests for dependency resolution
COPY todos-fluent/Package.* ./
RUN swift package reset
# Resolve dependencies (this layer is cached when Package.resolved doesn't change)
RUN swift package resolve

# Stage 2: Builder - Build the application
FROM swift:5.9 AS builder

WORKDIR /app

# Copy resolved dependencies from previous stage
COPY --from=dependencies /app/.build ./.build
COPY --from=dependencies /app/Package.* ./

# Copy source code
COPY todos-fluent/Sources ./Sources
COPY todos-fluent/Tests ./Tests

# Build the application (benefits from cached dependencies)
RUN swift build -c release --static-swift-stdlib

# Stage 3: Runtime
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash appuser

WORKDIR /app

# Copy the built executable from builder stage
COPY --from=builder /app/.build/release/App /app/todos-server

# Change ownership
RUN chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 8080

# Environment variables with defaults
ENV POSTGRES_HOST=postgres
ENV POSTGRES_USER=todos
ENV POSTGRES_PASSWORD=todos
ENV POSTGRES_DB=hummingbird

# Run server
CMD ["/app/todos-server", "--hostname", "0.0.0.0", "--port", "8080"]
