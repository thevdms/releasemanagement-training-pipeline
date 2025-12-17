#!/bin/bash
set -e

# Entrypoint script for sf-deploy-kit container
# Optimized for GitHub Actions and CI/CD workflows
# Version: 4.1 - Self-contained with helper function fallbacks

# Source helper functions if available, otherwise use fallbacks
if [ -f "/usr/local/bin/sfdk-helpers.sh" ]; then
    source /usr/local/bin/sfdk-helpers.sh
else
    # Fallback logging functions with timestamps
    log_info() { echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $*"; }
    log_success() { echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $*"; }
    log_failure() { echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $*"; }
    log_warning() { echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $*"; }
fi

# Quick CLI verification (fast check)
if ! sf version --json > /dev/null 2>&1; then
    log_failure "Salesforce CLI not responding"
    exit 1
fi

# Apply runtime-specific optimizations for CI/CD environments
if [ "${CI:-false}" = "true" ] || [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
    log_info "Detected CI/CD environment - applying runtime optimizations..."
    
    # Only override if not already set in Dockerfile
    export SF_LOG_LEVEL=${SF_LOG_LEVEL:-ERROR}
    export SF_JSON_TO_STDOUT=${SF_JSON_TO_STDOUT:-true}
    
    log_success "CI/CD runtime optimizations applied"
else
    log_info "Running in local development mode"
    # In local mode, might want different log levels
    export SF_LOG_LEVEL=${SF_LOG_LEVEL:-INFO}
fi

log_info "🚀 Starting sf-deploy-kit container..."
log_info "📋 Entrypoint version: 4.1 - Self-contained with helper function fallbacks"

# Execute the main command
exec "$@"
