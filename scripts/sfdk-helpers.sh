#!/bin/bash
# SFDK Helper Functions for GitHub Actions
# This script provides logging functions that work with GitHub Actions
# Source this script in your actions: source /usr/local/bin/sfdk-helpers.sh

# ============================================================================
# 🎨 ANSI Color Definitions for GitHub Actions Logs
# ============================================================================
# These colors work well in GitHub Actions logs and most CI/CD systems
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'
export BLACK='\033[0;30m'
export GRAY='\033[0;90m'
export RESET='\033[0m'

# Bold variants (for emphasis)
export BOLD_RED='\033[1;31m'
export BOLD_GREEN='\033[1;32m'
export BOLD_YELLOW='\033[1;33m'
export BOLD_BLUE='\033[1;34m'
export BOLD_CYAN='\033[1;36m'
export BOLD_WHITE='\033[1;37m'

# Background colors (for highlights)
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'
export BG_CYAN='\033[46m'
export BG_WHITE='\033[47m'
export BG_GRAY='\033[100m'

# Simple logging functions
log_info() {
    echo -e "${CYAN}ℹ️  $1${RESET}"
}

log_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

log_failure() {
    echo -e "${RED}❌ $1${RESET}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${RESET}"
}

# Command printing functions
log_command() {
    local message="${1:-🎯 Executing}"
    local command="$2"
    
    echo -e "${CYAN}${message}:${RESET}"
    echo " "
    echo -e "${BG_BLUE}${WHITE} $command ${RESET}"
    echo " "
}

log_command_compact() {
    local message="${1:-🎯}"
    local command="$2"
    
    echo -e "${CYAN}${message}${RESET} ${BG_BLUE}${WHITE} $command ${RESET}"
}


# Alternative command function with different styling
log_command_emphasized() {
    local message="${1:-🎯 Executing}"
    local command="$2"
    
    echo -e "${BOLD_CYAN}${message}:${RESET}"
    echo " "
    echo -e " ${BG_YELLOW}${BLACK} ▶ ${RESET} ${BG_GRAY}${WHITE} $command ${RESET}"
    echo " "
}
