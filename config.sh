# TAT GPT Integration Config
# Source this file before calling GPT review
# Environment variables take precedence over these defaults

TAT_GPT_MODEL="${TAT_GPT_MODEL:-gpt-4o-mini}"
TAT_GPT_SYNOPSIS_MODEL="${TAT_GPT_SYNOPSIS_MODEL:-gpt-4o-mini}"

# DALL-E image generation
TAT_IMAGE_MODEL="${TAT_IMAGE_MODEL:-dall-e-3}"
TAT_IMAGE_SIZE="${TAT_IMAGE_SIZE:-1792x1024}"
TAT_IMAGE_QUALITY="${TAT_IMAGE_QUALITY:-standard}"

# API key comes from environment: $OPENAI_API_KEY
# Do not store keys in this file
