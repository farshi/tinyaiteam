#!/bin/bash
# smoke-test.sh — Validate a TAT installation works
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ✗ $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo "  ⚠ $1"
  WARN=$((WARN + 1))
}

echo "TAT Installation Smoke Test"
echo "==========================="
echo ""

# 1. TAT.md exists
if [ -f "$HOME/.tinyaiteam/TAT.md" ]; then
  pass "TAT.md exists at ~/.tinyaiteam/TAT.md"
else
  fail "TAT.md missing at ~/.tinyaiteam/TAT.md"
fi

# 2. config.sh exists
if [ -f "$HOME/.tinyaiteam/config.sh" ]; then
  pass "config.sh exists at ~/.tinyaiteam/config.sh"
else
  fail "config.sh missing at ~/.tinyaiteam/config.sh"
fi

# 3. Scripts directory exists
if [ -d "$HOME/.tinyaiteam/scripts" ]; then
  pass "Scripts directory exists at ~/.tinyaiteam/scripts/"
else
  fail "Scripts directory missing at ~/.tinyaiteam/scripts/"
fi

# 4. tat-gpt.sh exists and is executable
if [ -f "$HOME/.tinyaiteam/scripts/tat-gpt.sh" ] && [ -x "$HOME/.tinyaiteam/scripts/tat-gpt.sh" ]; then
  pass "tat-gpt.sh exists and is executable"
elif [ -f "$HOME/.tinyaiteam/scripts/tat-gpt.sh" ]; then
  fail "tat-gpt.sh exists but is not executable"
else
  fail "tat-gpt.sh missing at ~/.tinyaiteam/scripts/tat-gpt.sh"
fi

# 5. TAT skill installed
if [ -f "$HOME/.claude/skills/tat/SKILL.md" ]; then
  pass "TAT skill installed at ~/.claude/skills/tat/SKILL.md"
else
  fail "TAT skill missing at ~/.claude/skills/tat/SKILL.md"
fi

# 6. OPENAI_API_KEY is set (non-critical)
echo ""
echo "Optional checks:"
if [ -n "${OPENAI_API_KEY:-}" ]; then
  pass "OPENAI_API_KEY is set"

  # 7. Live GPT test call
  echo ""
  echo "GPT connectivity test:"
  # shellcheck source=/dev/null
  source "$HOME/.tinyaiteam/config.sh"
  # shellcheck source=/dev/null
  source "$HOME/.tinyaiteam/scripts/tat-gpt.sh"

  if tat_gpt_call "gpt-4o-mini" "You are a test." "Say OK" 2>/dev/null && [ -n "${REVIEW:-}" ]; then
    pass "GPT test call succeeded (response: \"${REVIEW}\")"
  else
    fail "GPT test call failed or returned empty response"
  fi
else
  warn "OPENAI_API_KEY is not set — GPT review features will not work"
fi

# Summary
CRITICAL_TOTAL=5
echo ""
echo "==========================="
echo "Results: $PASS/$((PASS + FAIL)) checks passed"
if [ "$WARN" -gt 0 ]; then
  echo "Warnings: $WARN (non-critical)"
fi

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "✗ Installation incomplete — $FAIL critical check(s) failed."
  echo "  Run ./install.sh to fix missing files."
  exit 1
else
  echo ""
  echo "✓ TAT installation looks good."
  exit 0
fi
