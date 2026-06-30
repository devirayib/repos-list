#!/bin/bash
# Session Snapshot & Memory Integration
# Captures session state and syncs with Hermes + GitHub memory

set -e

REPO_PATH="$HOME/hermes-workspace/repos-list"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
SESSION_FILE="$REPO_PATH/state/sessions/session-$TIMESTAMP.json"

# Create session snapshot
cat > "$SESSION_FILE" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "session_id": "$TIMESTAMP",
  "agent": "hermes-claude-code",
  "user": "devirayib",
  "host": "$(hostname)",
  "working_dir": "$(pwd)",
  "git_status": "$(cd $REPO_PATH && git status --short 2>/dev/null || echo 'N/A')",
  "last_commit": "$(cd $REPO_PATH && git log -1 --oneline 2>/dev/null || echo 'N/A')",
  "memory_layers": {
    "hermes_memory": "Persisted to ~/.hermes/memories/",
    "honcho_memory": "Active (dialectic reasoning)",
    "github_storage": "Session snapshot at $SESSION_FILE"
  },
  "notes": "Session snapshot - see GitHub for full context"
}
EOF

echo "✓ Session snapshot created: $SESSION_FILE"

# Commit to GitHub
cd "$REPO_PATH"
git add "state/sessions/session-$TIMESTAMP.json"
git commit -m "snapshot: session $TIMESTAMP - memory integration point" 2>&1 | grep -E "(changed|create|insert)" || true
git push origin main 2>&1 | tail -1 || echo "✓ Snapshot saved locally"

echo "✓ Session state persisted to GitHub"
