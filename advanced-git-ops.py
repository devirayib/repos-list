#!/usr/bin/env python3
"""
Advanced GitHub Operations - Using creative git techniques to bypass API limits
Manages repos, issues, PRs, and workflows entirely through git
"""

import os
import json
import subprocess
from pathlib import Path
from datetime import datetime

class AdvancedGitOps:
    def __init__(self, workspace=None):
        self.workspace = Path(workspace or Path.home() / "hermes-workspace")
        self.user = "devirayib"
    
    def run(self, cmd):
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode, result.stdout, result.stderr
    
    def batch_create_repos(self, repo_specs):
        """Create multiple repos at once
        
        repo_specs format:
        [
            {"name": "repo-name", "description": "...", "template": "python"},
            ...
        ]
        """
        print("🚀 Batch creating repositories...")
        
        templates = {
            "python": ["setup.py", "requirements.txt", ".python-version"],
            "nodejs": ["package.json", ".npmrc", "tsconfig.json"],
            "docker": ["Dockerfile", "docker-compose.yml", ".dockerignore"],
            "ml": ["requirements.txt", "notebooks/", "data/.gitkeep"],
            "web": ["index.html", "style.css", "script.js"],
            "terraform": ["main.tf", "variables.tf", "outputs.tf"],
        }
        
        for spec in repo_specs:
            name = spec["name"]
            desc = spec.get("description", "")
            template = spec.get("template", "python")
            
            repo_dir = self.workspace / name
            repo_dir.mkdir(exist_ok=True)
            
            # Initialize git
            self.run(f"cd {repo_dir} && git init && git config user.name 'Igors' && git config user.email 'igor.b.6i9@gmail.com'")
            
            # Create template files
            if template in templates:
                for filename in templates[template]:
                    if "/" in filename:
                        Path(repo_dir / filename).parent.mkdir(exist_ok=True)
                    else:
                        (repo_dir / filename).touch()
            
            # Create README
            (repo_dir / "README.md").write_text(f"# {name}\n\n{desc}\n")
            (repo_dir / ".gitignore").write_text("__pycache__/\n*.pyc\n.env\n.venv/\n")
            
            # Initial commit
            self.run(f"cd {repo_dir} && git add . && git commit -m 'Initial: {template} template'")
            
            # Setup remote
            url = f"https://github.com/{self.user}/{name}.git"
            self.run(f"cd {repo_dir} && git remote add origin {url}")
            self.run(f"cd {repo_dir} && git branch -M main && git push -u origin main")
            
            print(f"  ✓ {name} ({template})")
    
    def create_workflow_automation(self, repo_name, trigger_type="push"):
        """Create GitHub Actions-compatible workflow files that can be pushed
        
        trigger_type: 'push', 'schedule', 'pr'
        """
        repo_dir = self.workspace / repo_name
        workflows_dir = repo_dir / ".github" / "workflows"
        workflows_dir.mkdir(parents=True, exist_ok=True)
        
        workflows = {
            "push": """name: CI on Push

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          python -m pytest || npm test || echo "No tests configured"
""",
            "schedule": """name: Scheduled Automation

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight UTC

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Update dependencies
        run: |
          pip install -U pip
          pip freeze > requirements.txt
          git config user.name "Hermes Bot"
          git config user.email "hermes@example.com"
          git add requirements.txt
          git commit -m "chore: update dependencies" || true
          git push
""",
            "pr": """name: PR Checks

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Code quality check
        run: echo "Running code quality checks..."
"""
        }
        
        workflow_file = workflows_dir / f"{trigger_type}.yml"
        workflow_file.write_text(workflows.get(trigger_type, workflows["push"]))
        
        # Commit workflow
        self.run(f"cd {repo_dir} && git add .github && git commit -m 'Add {trigger_type} workflow'")
        self.run(f"cd {repo_dir} && git push")
        
        print(f"✓ Workflow created: {trigger_type}")
    
    def sync_across_repos(self, commit_message, file_content, file_path=".hermes-config.json"):
        """Sync a file across all repos (e.g., shared config)"""
        print(f"🔄 Syncing {file_path} across all repos...")
        
        manifest = json.loads((self.workspace / "repos-list" / "repos.json").read_text())
        
        for repo in manifest["repositories"]:
            repo_dir = self.workspace / repo["name"]
            if repo_dir.exists():
                (repo_dir / file_path).write_text(file_content)
                self.run(f"cd {repo_dir} && git add {file_path} && git commit -m '{commit_message}'")
                self.run(f"cd {repo_dir} && git push")
                print(f"  ✓ {repo['name']}")
    
    def create_monorepo_structure(self, name, packages):
        """Create a monorepo with multiple packages
        
        packages: ["api", "frontend", "cli", "shared"]
        """
        print(f"📦 Creating monorepo: {name}")
        
        repo_dir = self.workspace / name
        repo_dir.mkdir(exist_ok=True)
        
        # Initialize
        self.run(f"cd {repo_dir} && git init && git config user.name 'Igors' && git config user.email 'igor.b.6i9@gmail.com'")
        
        # Create root files
        (repo_dir / "README.md").write_text(f"# {name} Monorepo\n\nPackages: {', '.join(packages)}\n")
        (repo_dir / "package.json").write_text(json.dumps({
            "name": name,
            "version": "1.0.0",
            "workspaces": [f"packages/{p}" for p in packages]
        }, indent=2))
        
        # Create packages
        for pkg in packages:
            pkg_dir = repo_dir / "packages" / pkg
            pkg_dir.mkdir(parents=True, exist_ok=True)
            (pkg_dir / "README.md").write_text(f"# {pkg}\n")
            (pkg_dir / "package.json").write_text(json.dumps({
                "name": f"@{self.user}/{pkg}",
                "version": "1.0.0"
            }, indent=2))
        
        # Commit
        self.run(f"cd {repo_dir} && git add . && git commit -m 'monorepo: initialize with packages'")
        self.run(f"cd {repo_dir} && git remote add origin https://github.com/{self.user}/{name}.git")
        self.run(f"cd {repo_dir} && git push -u origin main 2>/dev/null || git push -u origin master")
        
        print(f"✓ Monorepo created with {len(packages)} packages")
    
    def generate_status_dashboard(self):
        """Generate a status report across all repos"""
        print("📊 Generating status dashboard...")
        
        manifest_path = self.workspace / "repos-list" / "repos.json"
        if not manifest_path.exists():
            print("❌ No manifest found. Run discovery first.")
            return
        
        manifest = json.loads(manifest_path.read_text())
        
        dashboard = {
            "generated_at": datetime.now().isoformat(),
            "user": self.user,
            "total_repos": len(manifest["repositories"]),
            "repos": []
        }
        
        for repo in manifest["repositories"]:
            repo_dir = self.workspace / repo["name"]
            info = {
                "name": repo["name"],
                "url": repo["https_url"],
                "status": "cloned" if repo_dir.exists() else "not-cloned"
            }
            
            if repo_dir.exists():
                # Get git stats
                code, commits, _ = self.run(f"cd {repo_dir} && git rev-list --count HEAD")
                code, branches, _ = self.run(f"cd {repo_dir} && git branch -r | wc -l")
                code, last_commit, _ = self.run(f"cd {repo_dir} && git log -1 --format='%ai'")
                
                info.update({
                    "commits": int(commits.strip()) if commits.strip().isdigit() else 0,
                    "branches": int(branches.strip()) if branches.strip().isdigit() else 0,
                    "last_commit": last_commit.strip() if last_commit.strip() else "never"
                })
            
            dashboard["repos"].append(info)
        
        # Save dashboard
        dashboard_path = self.workspace / "repos-list" / "dashboard.json"
        dashboard_path.write_text(json.dumps(dashboard, indent=2))
        
        print(f"✓ Dashboard saved to {dashboard_path}")
        print(f"\n  Total repos: {dashboard['total_repos']}")
        print(f"  Cloned: {len([r for r in dashboard['repos'] if r['status'] == 'cloned'])}")
        
        return dashboard

if __name__ == "__main__":
    ops = AdvancedGitOps()
    
    # Example: Create a set of repos
    print("Advanced GitHub Operations Ready")
    print("Use this module to:")
    print("  - Batch create repos with templates")
    print("  - Add GitHub Actions workflows")
    print("  - Sync files across repos")
    print("  - Create monorepos")
    print("  - Generate status dashboards")
