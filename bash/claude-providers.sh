#!/bin/bash
# Claude CLI provider toggles — source this, don't execute.
export CLAUDE_PROVIDER=""

_claude_provider_tag() {
  if [[ -n "${CLAUDE_PROVIDER}" ]]; then
    printf " [claude:%s]" "${CLAUDE_PROVIDER}"
  fi
}

use-bedrock() {
  echo -e "\033[0;35m⚡ Sourcing claude-providers.sh → Bedrock (sandbox)\033[00m"
  unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_DEFAULT_HAIKU_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_MODEL
  export CLAUDE_CODE_USE_BEDROCK=1
  export AWS_PROFILE=admin-sandbox
  export AWS_REGION=us-east-1
  export ANTHROPIC_MODEL="us.anthropic.claude-haiku-4-5-20251001-v1:0"
  export CLAUDE_PROVIDER="bedrock"
  echo -e "\033[0;32m✓ Provider: Bedrock | Profile: admin-sandbox | Model: us.anthropic.claude-haiku-4-5-20251001-v1:0\033[00m"
}

use-openrouter() {
  echo -e "\033[0;35m⚡ Sourcing claude-providers.sh → OpenRouter\033[00m"
  unset CLAUDE_CODE_USE_BEDROCK AWS_PROFILE ANTHROPIC_CUSTOM_MODEL_OPTION
  export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
  export ANTHROPIC_API_KEY="${OPENROUTER_API_KEY}"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="anthropic/claude-haiku-4.5"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="anthropic/claude-sonnet-4.5"
  export ANTHROPIC_MODEL="anthropic/claude-haiku-4.5"
  export CLAUDE_PROVIDER="openrouter"
  echo -e "\033[0;32m✓ Provider: OpenRouter | Model: anthropic/claude-haiku-4.5\033[00m"
}
