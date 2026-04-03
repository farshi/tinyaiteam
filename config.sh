# TAT GPT Integration Config
# Source this file before calling GPT review
# Environment variables take precedence over these defaults

# Chat models (v1/chat/completions): gpt-4o-mini, gpt-3.5-turbo, gpt-5.4-mini
# Responses-only models (v1/responses): gpt-5.4-pro, gpt-5.2-codex

# Plan review — 5.4-mini is good enough, saves cost
TAT_PLAN_REVIEW_MODEL="${TAT_PLAN_REVIEW_MODEL:-gpt-5.4-mini}"

# Code review — codex only, this is where quality matters most
TAT_CODE_REVIEW_MODEL="${TAT_CODE_REVIEW_MODEL:-gpt-5.2-codex}"
TAT_CODE_REVIEW_SYNOPSIS_MODEL="${TAT_CODE_REVIEW_SYNOPSIS_MODEL:-gpt-5.4-mini}"

# Quick questions / brainstorm (ask-gpt.sh) — 5.4-mini
TAT_ASK_MODEL="${TAT_ASK_MODEL:-gpt-5.4-mini}"

# DALL-E image generation
TAT_IMAGE_MODEL="${TAT_IMAGE_MODEL:-dall-e-3}"
TAT_IMAGE_SIZE="${TAT_IMAGE_SIZE:-1792x1024}"
TAT_IMAGE_QUALITY="${TAT_IMAGE_QUALITY:-standard}"

# Realtime (available: gpt-4o-mini-realtime-preview)
# TAT_REALTIME_MODEL="${TAT_REALTIME_MODEL:-gpt-4o-mini-realtime-preview}"

# Cost guard — daily budget for GPT watcher
# After budget hit, watcher downgrades from codex ($14/M out) to 5.4-mini ($4.50/M out)
TAT_DAILY_BUDGET="${TAT_DAILY_BUDGET:-3.00}"
TAT_COST_PER_CODEX="${TAT_COST_PER_CODEX:-0.05}"
TAT_COST_PER_FALLBACK="${TAT_COST_PER_FALLBACK:-0.02}"
TAT_FALLBACK_MODEL="${TAT_FALLBACK_MODEL:-gpt-5.4-mini}"

# API key comes from environment: $OPENAI_API_KEY
# Do not store keys in this file
