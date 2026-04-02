# TAT GPT Integration Config
# Source this file before calling GPT review
# Environment variables take precedence over these defaults

# Chat models (v1/chat/completions): gpt-4o-mini, gpt-3.5-turbo, gpt-5.4-mini
# Responses-only models (v1/responses): gpt-5.4-pro, gpt-5.2-codex

# Plan review — rare, high-stakes, use the deep thinker
TAT_PLAN_REVIEW_MODEL="${TAT_PLAN_REVIEW_MODEL:-gpt-5.2-codex}"

# Code review — Codex outperforms gpt-5.4-mini (caught real security bugs, fewer false positives)
TAT_CODE_REVIEW_MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.2-codex}"
TAT_CODE_REVIEW_SYNOPSIS_MODEL="${TAT_CODE_REVIEW_SYNOPSIS_MODEL:-gpt-4o-mini}"

# Quick questions (ask-gpt.sh) — use codex for quality answers
TAT_ASK_MODEL="${TAT_ASK_MODEL:-gpt-5.2-codex}"

# DALL-E image generation
TAT_IMAGE_MODEL="${TAT_IMAGE_MODEL:-dall-e-3}"
TAT_IMAGE_SIZE="${TAT_IMAGE_SIZE:-1792x1024}"
TAT_IMAGE_QUALITY="${TAT_IMAGE_QUALITY:-standard}"

# Realtime (available: gpt-4o-mini-realtime-preview)
# TAT_REALTIME_MODEL="${TAT_REALTIME_MODEL:-gpt-4o-mini-realtime-preview}"

# API key comes from environment: $OPENAI_API_KEY
# Do not store keys in this file
