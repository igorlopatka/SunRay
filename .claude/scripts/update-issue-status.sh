#!/bin/bash
set -euo pipefail

# Helper script to update GitHub issue status
# Usage: update-issue-status.sh ISSUE_NUMBER STATUS [COMMENT]
#   STATUS can be: open, closed, in-progress, done

export PATH="$HOME/.local/bin:$PATH"

ISSUE_NUMBER="${1:-}"
STATUS="${2:-}"
COMMENT="${3:-}"
LOG_FILE="$HOME/.claude/github-integration.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

if [ -z "$ISSUE_NUMBER" ] || [ -z "$STATUS" ]; then
  echo "Usage: update-issue-status.sh ISSUE_NUMBER STATUS [COMMENT]"
  echo "  STATUS: open, closed, in-progress, done"
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GITHUB_TOKEN not set"
  exit 1
fi

echo "$GITHUB_TOKEN" | gh auth login --with-token 2>> "$LOG_FILE" || exit 1

REPO="${CLAUDE_SESSION_REPO:-}"
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>> "$LOG_FILE" || echo "")
fi

if [ -z "$REPO" ]; then
  echo "ERROR: Could not determine repository"
  exit 1
fi

log "Updating issue #$ISSUE_NUMBER status to: $STATUS"

# Add status comment
STATUS_EMOJI=""
case "$STATUS" in
  "in-progress"|"in_progress")
    STATUS_EMOJI="🔄"
    STATUS="In Progress"
    ;;
  "done"|"completed")
    STATUS_EMOJI="✅"
    STATUS="Completed"
    ;;
  "closed")
    STATUS_EMOJI="✅"
    gh issue close "$ISSUE_NUMBER" --repo "$REPO" 2>> "$LOG_FILE"
    log "Closed issue #$ISSUE_NUMBER"
    ;;
  "open")
    STATUS_EMOJI="📋"
    gh issue reopen "$ISSUE_NUMBER" --repo "$REPO" 2>> "$LOG_FILE"
    log "Reopened issue #$ISSUE_NUMBER"
    ;;
esac

# Add comment with status update
COMMENT_TEXT="$STATUS_EMOJI **Status Update**: $STATUS"
if [ -n "$COMMENT" ]; then
  COMMENT_TEXT="$COMMENT_TEXT

$COMMENT"
fi

gh issue comment "$ISSUE_NUMBER" \
  --repo "$REPO" \
  --body "$COMMENT_TEXT" \
  2>> "$LOG_FILE" || log "Failed to add comment"

echo "✅ Issue #$ISSUE_NUMBER updated to: $STATUS"
log "Successfully updated issue #$ISSUE_NUMBER"
