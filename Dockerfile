# Salesforce CI/CD Toolkit Docker Image
# Optimized for sf-deploy-kit workflows with pre-installed tools
FROM node:lts-slim

# Metadata
LABEL maintainer="Teja Narala - Salesforce DevOps Team"
LABEL description="Optimized Salesforce CI/CD toolkit with pre-installed CLI and tools"
LABEL version="1.0.0"

# Set environment variables for optimal CI/CD performance
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_ENV=production
ENV SF_CONTAINER_MODE=true
ENV SF_DISABLE_TELEMETRY=true
ENV SF_IMPROVED_CODE_COVERAGE=true
ENV SF_JSON_TO_STDOUT=true
ENV SF_LOG_LEVEL=ERROR
ENV SF_LOG_ROTATION_PERIOD=1d
ENV SF_DISABLE_AUTOUPDATE=true
ENV SF_DISABLE_NEW_VERSION_CHECK=true
ENV SF_PLUGINS_CACHE_PATH=/root/.local/share/sf/plugins
ENV SF_DISABLE_INSTALL_PROMPTS=true
ENV SF_DATA_DIR=/root/.local/share/sf
ENV SF_CACHE_DIR=/root/.cache/sf
ENV SHELL=/bin/bash
# Force plugin discovery and prevent JIT installation
ENV SF_DISABLE_JIT_PLUGINS=true
ENV SF_DISABLE_INTERACTIVE=true
# SFDX legacy support
ENV SFDX_DISABLE_AUTOUPDATE=true
ENV SFDX_DISABLE_TELEMETRY=true

ARG CLI_VERSION=latest

# Install system dependencies (minimal set for CI/CD)
RUN apt update && apt install -y --no-install-recommends \
    curl \
    wget \
    jq \
    git \
    unzip \
    ca-certificates \
    && apt autoremove -y \
    && apt autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN npm install --global @salesforce/cli@${CLI_VERSION}

# Install yq for YAML parsing (more reliable than grep/sed)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq

# Verify Salesforce CLI installation and show what's available
RUN sf version --verbose \
    && echo "Available commands in base CLI:" \
    && sf --help | head -20 \
    && echo "CLI verification completed"

# Install essential Salesforce plugins for CI/CD workflows
RUN echo "🔧 Installing Salesforce plugins..." \
    && echo "📋 Current user: $(whoami)" \
    && echo "📋 Current directory: $(pwd)" \
    && echo "📋 Environment variables:" \
    && env | grep SF_ | sort \
    && echo "📋 Installing sfdx-git-delta plugin via sf (with auto-yes)..." \
    && echo y | sf plugins install sfdx-git-delta \
    && SGDELTA_EXIT_CODE=$? \
    && echo "📋 sfdx-git-delta installation exit code: $SGDELTA_EXIT_CODE" \
    && echo "📋 Installing code-analyzer plugin via sf..." \
    && echo y | sf plugins install code-analyzer \
    && ANALYZER_EXIT_CODE=$? \
    && echo "📋 code-analyzer installation exit code: $ANALYZER_EXIT_CODE" \
    && echo "📋 Verifying plugin installation location..." \
    && ls -la /root/.local/share/sf/plugins/ || echo "No plugins directory found yet" \
    && echo "📋 Immediate plugin check:" \
    && sf plugins \
    && echo "✅ Plugin installation completed"

# Verify plugin installations
RUN echo "🧪 Verifying plugin installations..." \
    && echo "📋 Current user: $(whoami)" \
    && echo "📋 Current directory: $(pwd)" \
    && echo "📋 System info:" \
    && uname -a \
    && echo "📋 Node.js version:" \
    && node --version \
    && echo "📋 SF CLI version:" \
    && sf version \
    && echo "📋 SF Plugins installed:" \
    && sf plugins \
    && echo "📋 SF Plugin directories:" \
    && ls -la /root/.local/share/sf/plugins/ || echo "Plugin directory not found" \
    && echo "📋 Plugin directory contents:" \
    && find /root/.local/share/sf/plugins/ -type f -name "*.json" 2>/dev/null | head -5 || echo "No plugin manifests found" \
    && echo "📋 SF Config directories:" \
    && ls -la /root/.local/share/sf/ || echo "SF data dir not found" \
    && echo "📋 Testing sfdx-git-delta command:" \
    && sf sgd --help > /dev/null 2>&1 && echo "✅ sfdx-git-delta accessible via sf sgd" || echo "❌ sfdx-git-delta not accessible via sf sgd" \
    && echo "📋 Testing code-analyzer command:" \
    && sf code-analyzer --help > /dev/null 2>&1 && echo "✅ code-analyzer accessible via sf code-analyzer" || echo "❌ code-analyzer not accessible via sf code-analyzer" \
    && echo "📋 Plugin installation summary:" \
    && sf plugins --json 2>/dev/null | jq '.[] | {name: .name, version: .version, type: .type}' 2>/dev/null || echo "Cannot parse plugin JSON" \
    && echo "✅ All plugins verified and ready"

# Pre-warm CLI by running help command (speeds up first usage)
RUN sf --help > /dev/null 2>&1

# Copy entrypoint script and verify it's the latest version
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy helper scripts for GitHub Actions (since entrypoint is bypassed)
COPY scripts/sfdk-helpers.sh /usr/local/bin/sfdk-helpers.sh
RUN chmod +x /usr/local/bin/sfdk-helpers.sh

# Create executable wrapper scripts for each helper function
# This makes them work in any context (GitHub Actions, bash -c, etc.)
RUN echo '#!/bin/bash' > /usr/local/bin/log_info && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_info && \
    echo 'log_info "$@"' >> /usr/local/bin/log_info && \
    chmod +x /usr/local/bin/log_info && \
    \
    echo '#!/bin/bash' > /usr/local/bin/log_success && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_success && \
    echo 'log_success "$@"' >> /usr/local/bin/log_success && \
    chmod +x /usr/local/bin/log_success && \
    \
    echo '#!/bin/bash' > /usr/local/bin/log_failure && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_failure && \
    echo 'log_failure "$@"' >> /usr/local/bin/log_failure && \
    chmod +x /usr/local/bin/log_failure && \
    \
    echo '#!/bin/bash' > /usr/local/bin/log_warning && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_warning && \
    echo 'log_warning "$@"' >> /usr/local/bin/log_warning && \
    chmod +x /usr/local/bin/log_warning && \
    \
    echo '#!/bin/bash' > /usr/local/bin/log_command && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_command && \
    echo 'log_command "$@"' >> /usr/local/bin/log_command && \
    chmod +x /usr/local/bin/log_command && \
    \
    echo '#!/bin/bash' > /usr/local/bin/log_command_compact && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_command_compact && \
    echo 'log_command_compact "$@"' >> /usr/local/bin/log_command_compact && \
    chmod +x /usr/local/bin/log_command_compact && \
    \
    echo '#!/bin/bash' > /usr/local/bin/log_command_emphasized && \
    echo 'source /usr/local/bin/sfdk-helpers.sh' >> /usr/local/bin/log_command_emphasized && \
    echo 'log_command_emphasized "$@"' >> /usr/local/bin/log_command_emphasized && \
    chmod +x /usr/local/bin/log_command_emphasized

# Also make helper functions available globally for interactive shells
RUN echo "source /usr/local/bin/sfdk-helpers.sh" >> /etc/bash.bashrc && \
    echo "source /usr/local/bin/sfdk-helpers.sh" >> /etc/profile

# Verify entrypoint content (shows in build logs if it's updated)
RUN timestamp() { echo "$(date '+%Y-%m-%d %H:%M:%S')"; } && \
    echo "$(timestamp) 📋 Entrypoint verification:" \
    && head -10 /usr/local/bin/entrypoint.sh \
    && echo "$(timestamp) 📋 Entrypoint functions available:" \
    && grep -o "log_[a-z_]*(" /usr/local/bin/entrypoint.sh | sort | uniq \
    && echo "$(timestamp) 📋 Helper script verification:" \
    && head -5 /usr/local/bin/sfdk-helpers.sh \
    && echo "$(timestamp) 📋 Helper functions available:" \
    && grep -o "log_[a-z_]*(" /usr/local/bin/sfdk-helpers.sh | sort | uniq \
    && echo "$(timestamp) 📋 Executable wrapper verification:" \
    && ls -la /usr/local/bin/log_* \
    && echo "$(timestamp) 📋 Testing executable wrappers:" \
    && /usr/local/bin/log_info "Wrapper test successful" \
    && /usr/local/bin/log_success "All wrappers verified" \
    && echo "$(timestamp) ✅ Entrypoint, helpers, and executable wrappers installed and verified"

# Note: Removed WORKDIR as GitHub Actions will mount GITHUB_WORKSPACE
# and set it as the working directory, overriding any WORKDIR setting

# Health check to ensure CLI is working (with graceful fallback)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD sf version --json > /dev/null || exit 1

# Use entrypoint for runtime initialization
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/bin/bash"]

