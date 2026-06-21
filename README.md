# Devirayib's GitHub Automation Hub

Master repository for managing all `devirayib` repositories through automated git-based workflows.

## 🚀 Features

- **Repository Discovery** — Automatically discovers all repos under your account
- **Batch Repository Creation** — Create multiple repos with templates (Python, Node.js, Docker, etc.)
- **Unified Configuration** — Sync settings across all repos
- **GitHub Actions Integration** — Auto-add CI/CD workflows to repos
- **Monorepo Support** — Create and manage monorepos with workspaces
- **Status Dashboard** — Real-time health metrics across all repositories
- **Issue & PR Automation** — Create issue/PR tracking branches with git metadata

## 📋 Automation Tools

### github-automation.py
Main CLI for repo management:
- `discover_repos()` — Find all repos
- `create_repo(name, description)` — Create new repo
- `clone_repo(name)` — Clone a repo locally
- `sync_all_repos()` — Pull latest from all repos
- `create_issue_branch(repo, title, body)` — Create issue-tracking branch
- `create_pr_branch(repo, title, body)` — Create PR-tracking branch

### advanced-git-ops.py
Advanced operations:
- `batch_create_repos(specs)` — Create multiple repos at once with templates
- `create_workflow_automation(repo, trigger)` — Add GitHub Actions workflows
- `sync_across_repos(message, content, file)` — Sync config files across all repos
- `create_monorepo_structure(name, packages)` — Create monorepo with packages
- `generate_status_dashboard()` — Generate status report

## 🔧 Usage

### Discover All Repos
```python
from github-automation import GitHubAutomation
gh = GitHubAutomation()
repos = gh.discover_repos()
```

### Create New Repository
```python
gh.create_repo("my-new-repo", "Description here")
```

### Batch Create Repos
```python
from advanced_git_ops import AdvancedGitOps
ops = AdvancedGitOps()
specs = [
    {"name": "api-server", "template": "python"},
    {"name": "web-frontend", "template": "nodejs"},
    {"name": "infra", "template": "terraform"}
]
ops.batch_create_repos(specs)
```

### Create GitHub Actions Workflow
```python
ops.create_workflow_automation("my-repo", trigger_type="push")
```

## 📂 Repository Structure

```
repos-list/
├── github-automation.py       # Main automation CLI
├── advanced-git-ops.py        # Advanced git operations
├── repos.json                 # Manifest of all repos
├── dashboard.json             # Real-time status dashboard
├── README.md                  # This file
└── .github/
    └── workflows/
        └── sync.yml           # Auto-sync workflow
```

## 🔐 Authentication

Uses fine-grained personal access tokens stored in `~/.git-credentials`.
Token scopes: `repo`, `workflow`, `public_repo`

## 📊 Status Dashboard

View real-time status of all repos:
```json
{
  "generated_at": "2026-06-21T...",
  "user": "devirayib",
  "total_repos": 5,
  "repos": [
    {
      "name": "repo-name",
      "status": "cloned",
      "commits": 42,
      "branches": 3,
      "last_commit": "2026-06-21T10:30:00"
    }
  ]
}
```

## 🛠️ Maintenance

Run dashboard update:
```bash
python advanced-git-ops.py  # Shows status
```

Sync all repos:
```bash
cd ~/hermes-workspace/repos-list
python -c "from github-automation import GitHubAutomation; GitHubAutomation().sync_all_repos()"
```

---

**Created:** 2026-06-21  
**Maintained by:** Hermes Automation Agent  
**User:** devirayib (Igors Borovskis)
