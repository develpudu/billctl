# Billctl - Professional Billing Calculator
# Multi-stage Docker build for optimal image size

# Build stage
FROM golang:1.21-alpine AS builder

# Install git for go modules that might need it
RUN apk add --no-cache git ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build arguments for version information
ARG VERSION=1.0.0
ARG BUILD_TIME
ARG GIT_COMMIT

# Set build time if not provided
RUN if [ -z "$BUILD_TIME" ]; then \
	BUILD_TIME=$(date -u +%Y-%m-%d_%H:%M:%S); \
	fi

# Build the binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
	-ldflags="-w -s -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME} -X main.GitCommit=${GIT_COMMIT}" \
	-a -installsuffix cgo \
	-o billctl .

# Runtime stage
FROM alpine:3.18

# Install ca-certificates for HTTPS requests (if needed in future)
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
	adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/billctl .

# Copy documentation and examples (optional)
COPY --from=builder /app/README.md ./
COPY --from=builder /app/examples ./examples/

# Create directory for output files
RUN mkdir -p /app/output && \
	chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Set environment variables
ENV PATH="/app:${PATH}"

# Add labels for metadata
LABEL org.opencontainers.image.title="Billctl" \
	org.opencontainers.image.description="Professional Billing Calculator - High-performance CLI tool for calculating billing amounts" \
	org.opencontainers.image.version="${VERSION}" \
	org.opencontainers.image.source="https://github.com/develpudu/billctl" \
	org.opencontainers.image.documentation="https://github.com/develpudu/billctl/blob/main/README.md" \
	org.opencontainers.image.licenses="MIT" \
	org.opencontainers.image.created="2025-07-17" \
	maintainer="DevelPudu (https://github.com/develpudu)"

# Health check (simple version check)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
	CMD ./billctl --version || exit 1

# Default command
ENTRYPOINT ["./billctl"]

# Default arguments (show help)
CMD ["--help"]

# Expose no ports (CLI application)
# EXPOSE directive not needed for CLI apps

# Volume for output files (optional)
VOLUME ["/app/output"]

# Example usage:
# docker build -t billctl:latest .
# docker run --rm billctl:latest --rates
# docker run --rm billctl:latest -m 2024-01 --currency EUR
# docker run --rm -v $(pwd)/output:/app/output billctl:latest -m 01 > output/billing.txt
