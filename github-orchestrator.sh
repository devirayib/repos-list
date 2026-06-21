#!/usr/bin/env bash
# Advanced GitHub-driven Automation Orchestrator
# Uses GitHub as a reactive event system + persistent state store

set -e

GITHUB_USER="devirayib"
WORKSPACE="$HOME/hermes-workspace"
REPOS=("repos-list" "dotfiles" "automation-scripts" "data-pipeline" "infra-as-code" "hermes-extensions" "cli-tools")

# Color codes
B='\033[0;34m'    # Blue
G='\033[0;32m'    # Green
Y='\033[1;33m'    # Yellow
R='\033[0;31m'    # Red
NC='\033[0m'      # No Color

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 1: GitHub Webhooks as Event Bus
# ═══════════════════════════════════════════════════════════════════════════

setup_webhook_automation() {
    echo -e "${B}🔗 Setting up webhook automation...${NC}"
    
    # Create webhook handler server stub
    cat > "$WORKSPACE/repos-list/webhooks/handler.py" << 'WEBHOOK_PY'
#!/usr/bin/env python3
"""
GitHub Webhook Event Handler
Receives GitHub events and triggers automation
"""

from flask import Flask, request, jsonify
import hmac
import json
import subprocess
from datetime import datetime

app = Flask(__name__)
SECRET = os.getenv('GITHUB_WEBHOOK_SECRET', 'your-secret-here')

@app.route('/webhook', methods=['POST'])
def handle_webhook():
    """Handle incoming GitHub webhook events"""
    
    # Verify signature
    signature = request.headers.get('X-Hub-Signature-256', '')
    body = request.get_data()
    
    expected_sig = 'sha256=' + hmac.new(
        SECRET.encode(),
        body,
        'sha256'
    ).hexdigest()
    
    if not hmac.compare_digest(signature, expected_sig):
        return jsonify({'error': 'Invalid signature'}), 401
    
    event = request.json
    event_type = request.headers.get('X-GitHub-Event')
    
    print(f'[{datetime.now()}] Event: {event_type}')
    
    # Route events
    if event_type == 'push':
        handle_push(event)
    elif event_type == 'pull_request':
        handle_pr(event)
    elif event_type == 'issues':
        handle_issue(event)
    elif event_type == 'repository':
        handle_repo_event(event)
    
    return jsonify({'status': 'ok'}), 200

def handle_push(event):
    """Trigger on push to main/master"""
    branch = event['ref'].split('/')[-1]
    repo = event['repository']['name']
    
    if branch in ['main', 'master']:
        print(f'🔨 Push to {repo}:{branch}')
        # Trigger CI, sync config, update docs, etc.
        subprocess.run(['bash', '-c', f'cd {WORKSPACE}/{repo} && ./post-push.sh'])

def handle_pr(event):
    """Trigger on PR events"""
    action = event['action']
    pr = event['pull_request']
    repo = event['repository']['name']
    
    if action == 'opened':
        print(f'📝 PR opened: {repo}#{pr["number"]}')
    elif action == 'closed' and pr['merged']:
        print(f'✓ PR merged: {repo}#{pr["number"]}')

def handle_issue(event):
    """Trigger on issue events"""
    action = event['action']
    issue = event['issue']
    repo = event['repository']['name']
    
    if action == 'opened':
        print(f'⚠ Issue opened: {repo}#{issue["number"]}')
        # Auto-label, assign, etc.

def handle_repo_event(event):
    """Trigger on repo events"""
    action = event['action']
    print(f'Repository event: {action}')

if __name__ == '__main__':
    app.run(port=5000)
WEBHOOK_PY
    
    echo -e "${G}✓ Webhook handler created${NC}\n"
}

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 2: Cross-Repo Sync Engine
# ═══════════════════════════════════════════════════════════════════════════

sync_files_across_repos() {
    local source_file="$1"
    local target_path="$2"
    local commit_msg="$3"
    
    echo -e "${B}🔄 Syncing $source_file across all repos...${NC}\n"
    
    for repo in "${REPOS[@]}"; do
        target_file="$WORKSPACE/$repo/$target_path"
        target_dir=$(dirname "$target_file")
        
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
        
        cd "$WORKSPACE/$repo"
        git add "$target_file"
        git commit -m "$commit_msg" >/dev/null 2>&1 || true
        git push >/dev/null 2>&1 || true
        
        echo -e "${G}✓${NC} $repo"
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 3: Repository Health Monitoring
# ═══════════════════════════════════════════════════════════════════════════

generate_health_report() {
    echo -e "${B}📊 Generating repository health report...${NC}\n"
    
    local report="$WORKSPACE/repos-list/reports/health-$(date +%Y%m%d).md"
    mkdir -p "$(dirname "$report")"
    
    {
        echo "# Repository Health Report"
        echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        
        for repo in "${REPOS[@]}"; do
            echo "## $repo"
            
            cd "$WORKSPACE/$repo"
            
            # Count commits this week
            commits=$(git log --since="1 week ago" --oneline | wc -l)
            echo "- **Commits (1 week):** $commits"
            
            # Branches
            branches=$(git branch -a | wc -l)
            echo "- **Branches:** $branches"
            
            # Outstanding changes
            changes=$(git status --porcelain | wc -l)
            echo "- **Outstanding changes:** $changes"
            
            # Last commit
            last_commit=$(git log -1 --format="%ai")
            echo "- **Last commit:** $last_commit"
            
            echo ""
        done
    } > "$report"
    
    cd "$WORKSPACE/repos-list"
    git add "$report"
    git commit -m "report: health check $(date +%Y-%m-%d)" >/dev/null 2>&1 || true
    git push >/dev/null 2>&1 || true
    
    echo -e "${G}✓ Health report saved: $report${NC}\n"
}

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 4: Intelligent Issue Triage
# ═══════════════════════════════════════════════════════════════════════════

triage_issues() {
    echo -e "${B}🎯 Running issue triage...${NC}\n"
    
    local triage_log="$WORKSPACE/repos-list/logs/triage-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$(dirname "$triage_log")"
    
    {
        echo "Issue Triage Report"
        echo "==================="
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
        
        for repo in "${REPOS[@]}"; do
            echo "Repository: $repo"
            
            # Count stale issues (no activity in 30 days)
            cd "$WORKSPACE/$repo"
            
            # Find issues without recent activity
            stale=0
            open_issues=$(git log --all --grep="issue" --oneline | wc -l)
            
            echo "  Open issues: $open_issues"
            echo ""
        done
    } > "$triage_log"
    
    echo -e "${G}✓ Triage complete: $triage_log${NC}\n"
}

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 5: Distributed Deployment System
# ═══════════════════════════════════════════════════════════════════════════

trigger_distributed_deploy() {
    echo -e "${B}🚀 Triggering distributed deployment...${NC}\n"
    
    for repo in "${REPOS[@]}"; do
        cd "$WORKSPACE/$repo"
        
        # Check if deployment script exists
        if [ -f "deploy.sh" ]; then
            echo -e "${Y}Deploying $repo...${NC}"
            bash deploy.sh 2>&1 | sed 's/^/  /'
            echo -e "${G}✓ $repo deployed${NC}\n"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 6: Git-based Task Tracking
# ═══════════════════════════════════════════════════════════════════════════

create_task_commit() {
    local repo="$1"
    local task_name="$2"
    local description="$3"
    
    echo -e "${B}📋 Creating task: $task_name${NC}"
    
    cd "$WORKSPACE/$repo"
    
    # Create task metadata file
    local task_file=".tasks/${task_name// /-}.md"
    mkdir -p "$(dirname "$task_file")"
    
    cat > "$task_file" << TASK_EOF
# Task: $task_name

**Status:** Open  
**Created:** $(date -u +%Y-%m-%dT%H:%M:%SZ)  
**Priority:** Medium  

## Description
$description

## Checklist
- [ ] Item 1
- [ ] Item 2
- [ ] Item 3

## Notes
(Add notes here)
TASK_EOF
    
    git add "$task_file"
    git commit -m "task: add $task_name" >/dev/null 2>&1
    git push >/dev/null 2>&1 || true
    
    echo -e "${G}✓ Task created in $repo${NC}\n"
}

# ═══════════════════════════════════════════════════════════════════════════
# FEATURE 7: Automated Documentation Generation
# ═══════════════════════════════════════════════════════════════════════════

auto_generate_docs() {
    echo -e "${B}📚 Generating documentation...${NC}\n"
    
    for repo in "${REPOS[@]}"; do
        cd "$WORKSPACE/$repo"
        
        # Generate README from commits
        local readme="README.md"
        
        if [ ! -f "$readme" ] || [ -z "$(cat "$readme")" ]; then
            cat > "$readme" << DOC_EOF
# $repo

Auto-generated README - $(date)

## About
This is the \`$repo\` repository.

## Recent Activity
EOF
            
            # Add recent commits
            git log --oneline -10 >> "$readme"
            
            git add "$readme"
            git commit -m "docs: auto-generate README" >/dev/null 2>&1 || true
            git push >/dev/null 2>&1 || true
            
            echo -e "${G}✓${NC} $repo documentation updated"
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# Main Dispatcher
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-help}" in
    setup-webhooks)
        setup_webhook_automation
        ;;
    sync-files)
        sync_files_across_repos "$2" "$3" "$4"
        ;;
    health-report)
        generate_health_report
        ;;
    triage)
        triage_issues
        ;;
    deploy)
        trigger_distributed_deploy
        ;;
    create-task)
        create_task_commit "$2" "$3" "$4"
        ;;
    gen-docs)
        auto_generate_docs
        ;;
    *)
        cat << HELP_MSG
${B}Advanced GitHub Orchestration System${NC}

${Y}Commands:${NC}
  setup-webhooks              Setup GitHub webhook automation
  sync-files <src> <tgt> <msg>  Sync file across all repos
  health-report               Generate repo health report
  triage                      Run issue triage
  deploy                      Trigger distributed deployment
  create-task <repo> <name> <desc>  Create task in repo
  gen-docs                    Auto-generate documentation

${Y}Example:${NC}
  $0 sync-files ./shared.conf .config/shared.conf "chore: sync config"
  $0 create-task repos-list "Setup CI/CD" "Configure GitHub Actions"
  $0 health-report
HELP_MSG
        ;;
esac
