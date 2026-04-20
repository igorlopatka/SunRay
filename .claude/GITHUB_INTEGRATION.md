# GitHub Project Management Integration

This setup automatically integrates your Claude Code sessions with GitHub Issues and Projects.

## Features

- **Automatic Session Tracking**: Every Claude Code session creates a GitHub issue
- **Task Management**: Create issues for individual tasks within a session
- **Project Board Sync**: Automatically adds issues to your GitHub project board
- **Status Updates**: Update issue status as work progresses

## Setup Requirements

### 1. GitHub Personal Access Token

You need to create a GitHub Personal Access Token with these permissions:
- `repo` (full control)
- `project` (read and write)

Create one at: https://github.com/settings/tokens

### 2. Configure Claude Code

Add your GitHub token to Claude Code settings:

```json
{
  "env": {
    "GITHUB_TOKEN": "ghp_your_token_here"
  }
}
```

### 3. Install the Hook

The session start hook is already configured in `.claude/settings.json`.

## How It Works

### Session Start
When you start a Claude Code session:
1. A GitHub issue is automatically created with session details
2. The issue is labeled with `claude-session`
3. If you have a GitHub project, the issue is added to it
4. The issue number is stored in `$CLAUDE_SESSION_ISSUE` for reference

### Creating Task Issues

Use the helper script to create issues for specific tasks:

```bash
.claude/scripts/create-task-issue.sh "Fix authentication bug" "Details about the bug..."
```

Task issues:
- Are labeled with `claude-task`
- Link back to the session issue
- Are automatically added to your project board

### Updating Issue Status

Update the status of any issue:

```bash
.claude/scripts/update-issue-status.sh ISSUE_NUMBER STATUS [COMMENT]
```

Status options:
- `open` - Reopen an issue
- `in-progress` - Mark as in progress
- `done` - Mark as completed
- `closed` - Close the issue

Example:
```bash
.claude/scripts/update-issue-status.sh 42 in-progress "Starting work on this"
```

## GitHub Projects Setup

### Creating a Project

If you don't have a GitHub project yet:

1. Go to your repository on GitHub
2. Click "Projects" tab
3. Create a new project
4. The hook will automatically add issues to the first project it finds

### Project Fields

Consider adding these custom fields to your project:
- **Status**: Todo, In Progress, Done
- **Priority**: Low, Medium, High
- **Session**: Link to the Claude Code session

## Logs and Debugging

All GitHub integration activity is logged to:
```
~/.claude/github-integration.log
```

View recent activity:
```bash
tail -f ~/.claude/github-integration.log
```

## Environment Variables

The hook sets these environment variables for your session:
- `CLAUDE_SESSION_ISSUE` - The issue number for the current session
- `CLAUDE_SESSION_REPO` - The repository name (owner/repo)

Use these in your scripts or Claude interactions.

## Customization

### Modify Hook Behavior

Edit `.claude/hooks/session-start.sh` to customize:
- Issue title format
- Issue labels
- Project selection logic
- Additional automation

### Add More Hooks

You can add hooks for other events:
- **SessionEnd**: Close the session issue when session ends
- **TestRun**: Create issues for failing tests
- **CommitPush**: Update issue with commit references

## Troubleshooting

### Hook not running
- Check that `.claude/settings.json` has the SessionStart hook configured
- Verify the hook script is executable: `chmod +x .claude/hooks/session-start.sh`

### GitHub authentication fails
- Verify `GITHUB_TOKEN` is set in Claude Code settings
- Check token has correct permissions (repo, project)
- Check logs at `~/.claude/github-integration.log`

### Issues not added to project
- Verify you have a GitHub project created
- Check project permissions (must be owner or have write access)
- View logs for specific error messages

## Tips

1. **Label Strategy**: Use labels like `bug`, `feature`, `enhancement` on task issues for better organization
2. **Milestones**: Create GitHub milestones for larger features and assign issues to them
3. **Automation**: Set up GitHub Actions to auto-close issues when PRs are merged
4. **Project Views**: Create different project views (by status, by label, by milestone)

## Example Workflow

```bash
# Session starts automatically - creates issue #100

# Work on a feature
.claude/scripts/create-task-issue.sh "Add user login" "Implement OAuth2 login"
# Creates issue #101

# Update status as you work
.claude/scripts/update-issue-status.sh 101 in-progress

# Complete the task
.claude/scripts/update-issue-status.sh 101 done "Implemented and tested"

# Session ends - can manually close session issue
.claude/scripts/update-issue-status.sh 100 closed "Session completed successfully"
```
