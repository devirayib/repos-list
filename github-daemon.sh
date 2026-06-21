#!/usr/bin/env bash
# Autonomous GitHub Daemon
# Runs continuously, monitors repos, and triggers automation
# Can be scheduled as a cron job or run as a background service

set -e

WORKSPACE="$HOME/hermes-workspace"
REPOS_LIST="$WORKSPACE/repos-list"
DAEMON_LOG="$REPOS_LIST/daemon.log"
DAEMON_PID_FILE="/tmp/github-daemon.pid"

# Color codes
B='\033[0;34m'
G='\033[0;32m'
Y='\033[1;33m'
R='\033[0;31m'
NC='\033[0m'

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$DAEMON_LOG"
}

# ═══════════════════════════════════════════════════════════════════
# AUTONOMOUS TASKS
# ═══════════════════════════════════════════════════════════════════

run_hourly_sync() {
    log "🔄 Running hourly sync..."
    
    cd "$REPOS_LIST"
    for repo_dir in "$WORKSPACE"/*/.git; do
        if [ -d "$repo_dir" ]; then
            repo_path=$(dirname "$repo_dir")
            repo_name=$(basename "$repo_path")
            
            cd "$repo_path"
            git pull >/dev/null 2>&1 && log "  ✓ Pulled $repo_name" || log "  ⚠ Failed to pull $repo_name"
        fi
    done
}

run_daily_health_check() {
    log "📊 Running daily health check..."
    bash "$REPOS_LIST/github-orchestrator.sh" health-report 2>&1 | sed 's/^/  /'
}

run_daily_issue_triage() {
    log "🎯 Running daily issue triage..."
    bash "$REPOS_LIST/github-orchestrator.sh" triage 2>&1 | sed 's/^/  /'
}

run_weekly_docs_sync() {
    log "📚 Running weekly documentation sync..."
    bash "$REPOS_LIST/github-orchestrator.sh" gen-docs 2>&1 | sed 's/^/  /'
}

generate_session_snapshot() {
    log "📸 Generating session snapshot..."
    
    python3 << 'PYTHON'
import json
from datetime import datetime
from pathlib import Path
import subprocess

snapshot = {
    'timestamp': datetime.now().isoformat(),
    'repos': {},
    'system_health': {}
}

# Capture repo status
workspace = Path.home() / 'hermes-workspace'
for repo_dir in (workspace / 'repos-list').parent.glob('*/.git'):
    if repo_dir.is_dir():
        repo_path = repo_dir.parent
        repo_name = repo_path.name
        
        # Get latest commit
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%H %ai'],
            cwd=repo_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            parts = result.stdout.strip().split(' ', 1)
            snapshot['repos'][repo_name] = {
                'latest_commit': parts[0][:7],
                'last_activity': parts[1] if len(parts) > 1 else 'unknown'
            }

# Save snapshot
snapshot_dir = (workspace / 'repos-list' / 'snapshots')
snapshot_dir.mkdir(parents=True, exist_ok=True)

snapshot_file = snapshot_dir / f"snapshot-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
with open(snapshot_file, 'w') as f:
    json.dump(snapshot, f, indent=2)

print(f"✓ Snapshot saved: {snapshot_file.name}")
PYTHON
}

# ═══════════════════════════════════════════════════════════════════
# SCHEDULED EXECUTION
# ═══════════════════════════════════════════════════════════════════

run_scheduled_tasks() {
    local hour=$(date +%H)
    local day=$(date +%u)
    
    # Run every hour
    run_hourly_sync
    
    # Run daily at midnight (0 AM)
    if [ "$hour" = "00" ]; then
        run_daily_health_check
        run_daily_issue_triage
    fi
    
    # Run weekly on Monday (day 1) at 1 AM
    if [ "$day" = "1" ] && [ "$hour" = "01" ]; then
        run_weekly_docs_sync
    fi
    
    # Always snapshot
    generate_session_snapshot
}

# ═══════════════════════════════════════════════════════════════════
# DAEMON CONTROL
# ═══════════════════════════════════════════════════════════════════

start_daemon() {
    if [ -f "$DAEMON_PID_FILE" ] && kill -0 "$(cat $DAEMON_PID_FILE)" 2>/dev/null; then
        echo -e "${Y}Daemon already running (PID: $(cat $DAEMON_PID_FILE))${NC}"
        return 1
    fi
    
    echo -e "${B}Starting GitHub daemon...${NC}"
    
    # Run in background with nohup
    nohup bash -c "
    while true; do
        echo $$ > '$DAEMON_PID_FILE'
        bash '$0' --run-tasks
        sleep 3600  # Run every hour
    done
    " >> "$DAEMON_LOG" 2>&1 &
    
    local pid=$!
    echo $pid > "$DAEMON_PID_FILE"
    
    echo -e "${G}✓ Daemon started (PID: $pid)${NC}"
    echo -e "${Y}Log: $DAEMON_LOG${NC}"
}

stop_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local pid=$(cat "$DAEMON_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm "$DAEMON_PID_FILE"
            echo -e "${G}✓ Daemon stopped${NC}"
        else
            rm "$DAEMON_PID_FILE"
            echo -e "${Y}Daemon not running${NC}"
        fi
    else
        echo -e "${Y}Daemon not running${NC}"
    fi
}

status_daemon() {
    if [ -f "$DAEMON_PID_FILE" ] && kill -0 "$(cat $DAEMON_PID_FILE)" 2>/dev/null; then
        local pid=$(cat "$DAEMON_PID_FILE")
        echo -e "${G}✓ Daemon running (PID: $pid)${NC}"
        echo ""
        echo "Recent logs:"
        tail -20 "$DAEMON_LOG" | sed 's/^/  /'
    else
        echo -e "${R}✗ Daemon not running${NC}"
        if [ -f "$DAEMON_LOG" ]; then
            echo ""
            echo "Last logs:"
            tail -10 "$DAEMON_LOG" | sed 's/^/  /'
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════
# Main Dispatcher
# ═══════════════════════════════════════════════════════════════════

case "${1:-help}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    --run-tasks)
        log "Running scheduled tasks..."
        run_scheduled_tasks
        log "Tasks complete"
        ;;
    logs)
        tail -f "$DAEMON_LOG"
        ;;
    *)
        cat << HELP
${B}GitHub Autonomous Daemon${NC}

${Y}Control:${NC}
  start              Start daemon
  stop               Stop daemon
  status             Check daemon status
  restart            Restart daemon
  logs               Follow daemon logs

${Y}Manual runs (for testing):${NC}
  $0 --run-tasks     Run all scheduled tasks once

${Y}Daemon schedule:${NC}
  - Hourly sync
  - Daily health check (midnight)
  - Daily issue triage (midnight)
  - Weekly docs sync (Monday 1 AM)
  - Session snapshots (every run)

HELP
        ;;
esac
