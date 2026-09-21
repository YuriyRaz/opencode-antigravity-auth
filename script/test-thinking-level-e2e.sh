#!/bin/bash
# Thinking Level E2E Test Suite
# Verifies that --variant flag actually changes the thinking level sent to the API.
#
# Test prompt: Ask the model to report its thinking level in JSON format.
# The model should respond with the correct level based on the variant selected.
#
# Models tested:
# 1. antigravity-gemini-3.8-flash with --variant low
# 2. antigravity-gemini-3.8-flash with --variant medium
# 3. antigravity-gemini-3.8-flash with --variant high

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; ((PASS++)); }
log_fail() { echo -e "${RED}✗ FAIL${NC}: $1"; ((FAIL++)); }
log_skip() { echo -e "${YELLOW}○ SKIP${NC}: $1"; ((SKIP++)); }
log_info() { echo -e "  ${BLUE}→${NC} $1"; }

OPENCODE="C:\Users\yra\scoop\shims\opencode.exe"
PROMPT='What is current model and thinking level? Answer with JSON {"model":"<current_model>","level":"<current_thinking_level>"}'

check_response() {
  local log_file="$1"
  local expected_level="$2"
  
  # Check for common errors
  if grep -qiE "insufficient.*scope|authentication|unauthorized|403|401" "$log_file" 2>/dev/null; then
    log_skip "Auth error detected"
    return 2
  fi
  
  if grep -qiE "rate.*limit|quota.*exceeded|429" "$log_file" 2>/dev/null; then
    log_skip "Rate limit hit"
    return 2
  fi
  
  # Extract JSON response and check level
  local response
  response=$(grep -oP '"level"\s*:\s*"[^"]*"' "$log_file" 2>/dev/null | head -1 | grep -oP '"[^"]*"\s*$' | tr -d '"')
  
  if [ -z "$response" ]; then
    log_fail "No level found in response"
    return 1
  fi
  
  if [ "$response" = "$expected_level" ]; then
    log_pass "Level is '$response' (expected '$expected_level')"
    return 0
  else
    log_fail "Level is '$response' (expected '$expected_level')"
    return 1
  fi
}

echo "════════════════════════════════════════════════════════════"
echo "  Thinking Level E2E Test Suite"
echo "════════════════════════════════════════════════════════════"
echo ""

# Test 1: Low thinking level
echo "Test 1: antigravity-gemini-3.8-flash --variant low"
log_info "Sending prompt with low variant..."
& "$OPENCODE" run -m google/antigravity-gemini-3.8-flash --variant low \
  "$PROMPT" \
  > /tmp/e2e-thinking-t1.log 2>&1 || true

log_info "Response:"
cat /tmp/e2e-thinking-t1.log
echo ""
check_response /tmp/e2e-thinking-t1.log "low"
echo ""

# Test 2: Medium thinking level
echo "Test 2: antigravity-gemini-3.8-flash --variant medium"
log_info "Sending prompt with medium variant..."
& "$OPENCODE" run -m google/antigravity-gemini-3.8-flash --variant medium \
  "$PROMPT" \
  > /tmp/e2e-thinking-t2.log 2>&1 || true

log_info "Response:"
cat /tmp/e2e-thinking-t2.log
echo ""
check_response /tmp/e2e-thinking-t2.log "medium"
echo ""

# Test 3: High thinking level
echo "Test 3: antigravity-gemini-3.8-flash --variant high"
log_info "Sending prompt with high variant..."
& "$OPENCODE" run -m google/antigravity-gemini-3.8-flash --variant high \
  "$PROMPT" \
  > /tmp/e2e-thinking-t3.log 2>&1 || true

log_info "Response:"
cat /tmp/e2e-thinking-t3.log
echo ""
check_response /tmp/e2e-thinking-t3.log "high"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "  Test Results Summary"
echo "════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}Passed${NC}:  $PASS"
echo -e "  ${RED}Failed${NC}:  $FAIL"
echo -e "  ${YELLOW}Skipped${NC}: $SKIP"
echo ""

if [ $FAIL -gt 0 ]; then
  echo -e "${RED}Some tests failed!${NC} Check /tmp/e2e-thinking-t*.log for details"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
