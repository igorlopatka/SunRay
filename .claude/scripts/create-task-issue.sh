#!/bin/bash
set -euo pipefail

# Helper script to create GitHub issues for individual tasks
# Usage: create-task-issue.sh "Task title" "Task description"

export PATH="$HOME/.local/bin:$PATH"

TASK_TITLE="${1:-}"
TASK_DESCRIPTION="${2:-No description provided}"
LOG_FILE="$HOME/.claude/github-integration.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

if [ -z "$TASK_TITLE" ]; then
  echo "Usage: create-task-issue.sh \"Task title\" \"Task description\""
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GITHUB_TOKEN not set"
  exit 1
fi

# Authenticate
echo "$GITHUB_TOKEN" | gh auth login --with-token 2>> "$LOG_FILE" || {
  log "ERROR: Failed to authenticate"
  exit 1
}

REPO="${CLAUDE_SESSION_REPO:-}"
SESSION_ISSUE="${CLAUDE_SESSION_ISSUE:-}"

if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>> "$LOG_FILE" || echo "")
fi

if [ -z "$REPO" ]; then
  echo "ERROR: Could not determine repository"
  exit 1
fi

# Create task body with link to session issue
TASK_BODY="$TASK_DESCRIPTION

---"

if [ -n "$SESSION_ISSUE" ]; then
  TASK_BODY="$TASK_BODY
**Related Session**: #$SESSION_ISSUE"
fi

TASK_BODY="$TASK_BODY
*Created by Claude Code*"

log "Creating task issue: $TASK_TITLE"

ISSUE_NUMBER=$(gh issue create \
  --repo "$REPO" \
  --title "$TASK_TITLE" \
  --body "$TASK_BODY" \
  --label "claude-task" \
  2>> "$LOG_FILE" | grep -oP '#\K\d+' || echo "")

if [ -n "$ISSUE_NUMBER" ]; then
  echo "✅ Task issue created: https://github.com/$REPO/issues/$ISSUE_NUMBER"
  log "Created task issue #$ISSUE_NUMBER"

  # Try to add to project
  PROJECT_NUMBER=$(gh project list --owner "$(echo "$REPO" | cut -d'/' -f1)" --format json 2>> "$LOG_FILE" | \
    jq -r '.[0].number // empty' || echo "")

  if [ -n "$PROJECT_NUMBER" ]; then
    gh project item-add "$PROJECT_NUMBER" \
      --owner "$(echo "$REPO" | cut -d'/' -f1)" \
      --url "https://github.com/$REPO/issues/$ISSUE_NUMBER" \
      2>> "$LOG_FILE" || true
    log "Added task to project #$PROJECT_NUMBER"
  fi

  # Link to session issue if available
  if [ -n "$SESSION_ISSUE" ]; then
    gh issue comment "$SESSION_ISSUE" \
      --repo "$REPO" \
      --body "📋 Created task: #$ISSUE_NUMBER - $TASK_TITLE" \
      2>> "$LOG_FILE" || true
  fi

  echo "$ISSUE_NUMBER"
else
  log "ERROR: Failed to create task issue"
  exit 1
fi
