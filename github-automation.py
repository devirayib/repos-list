#!/usr/bin/env python3
"""
GitHub Automation CLI - Master control for devirayib's repos
Uses git protocol directly since API has scope restrictions
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path

GITHUB_USER = "devirayib"
GITHUB_EMAIL = "igor.b.6i9@gmail.com"
GITHUB_NAME = "Igors"
WORKSPACE = Path.home() / "hermes-workspace"

class GitHubAutomation:
    def __init__(self):
        self.workspace = WORKSPACE
        self.repos_manifest = self.workspace / "repos-list" / "repos.json"
        self.ensure_workspace()
    
    def ensure_workspace(self):
        """Ensure workspace directories exist"""
        self.workspace.mkdir(exist_ok=True)
        (self.workspace / "repos-list").mkdir(exist_ok=True)
    
    def run(self, cmd):
        """Execute shell command"""
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode, result.stdout, result.stderr
    
    def discover_repos(self):
        """Discover repos by testing common names and git protocol"""
        print(f"🔍 Discovering repos for {GITHUB_USER}...")
        
        repos = []
        test_names = [
            "dotfiles", "configs", "scripts", "tools", "utils", "lib",
            "api", "backend", "frontend", "web", "app", "mobile",
            "notes", "docs", "blog", "wiki", "knowledge",
            "projects", "portfolio", "hermes", "automation",
            "test", "sandbox", "experiments", "archive",
            "repos-list"  # The one we're creating
        ]
        
        for name in test_names:
            url = f"https://github.com/{GITHUB_USER}/{name}.git"
            code, _, _ = self.run(f"git ls-remote --heads {url}")
            if code == 0:
                repos.append({
                    "name": name,
                    "url": url,
                    "https_url": f"https://github.com/{GITHUB_USER}/{name}",
                    "discovered": datetime.now().isoformat(),
                    "status": "active"
                })
                print(f"  ✓ {name}")
        
        self.save_manifest(repos)
        return repos
    
    def save_manifest(self, repos):
        """Save repository manifest"""
        manifest = {
            "user": GITHUB_USER,
            "discovered_at": datetime.now().isoformat(),
            "repositories": repos,
            "count": len(repos)
        }
        self.repos_manifest.write_text(json.dumps(manifest, indent=2))
        print(f"\n✓ Manifest saved: {self.repos_manifest}")
    
    def create_repo(self, name, description="", public=False):
        """Create a new repo locally and push to GitHub"""
        print(f"📦 Creating repository: {name}")
        
        repo_dir = self.workspace / name
        repo_dir.mkdir(exist_ok=True)
        
        # Initialize git
        code, _, _ = self.run(f"cd {repo_dir} && git init")
        code, _, _ = self.run(f"cd {repo_dir} && git config user.name '{GITHUB_NAME}' && git config user.email '{GITHUB_EMAIL}'")
        
        # Create README
        readme_content = f"""# {name}

{description or 'Repository created by Hermes automation'}

Created: {datetime.now().isoformat()}
"""
        (repo_dir / "README.md").write_text(readme_content)
        
        # Create .gitignore
        gitignore = """__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
.env
.venv
.vscode/
.idea/
.DS_Store
*.swp
*~
"""
        (repo_dir / ".gitignore").write_text(gitignore)
        
        # Create LICENSE (MIT)
        license_text = f"""MIT License

Copyright (c) {datetime.now().year} {GITHUB_USER}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
"""
        (repo_dir / "LICENSE").write_text(license_text)
        
        # Initial commit
        code, _, _ = self.run(f"cd {repo_dir} && git add . && git commit -m 'Initial commit'")
        
        # Add remote and push
        url = f"https://github.com/{GITHUB_USER}/{name}.git"
        code, _, _ = self.run(f"cd {repo_dir} && git remote add origin {url}")
        code, _, _ = self.run(f"cd {repo_dir} && git branch -M main")
        code, out, err = self.run(f"cd {repo_dir} && git push -u origin main")
        
        if code == 0:
            print(f"✓ Repository created: {url}")
            return True
        else:
            print(f"⚠️  Push failed: {err}")
            print(f"   Create manually at https://github.com/new then run: git push -u origin main")
            return False
    
    def clone_repo(self, name):
        """Clone a repository"""
        url = f"https://github.com/{GITHUB_USER}/{name}.git"
        code, _, _ = self.run(f"cd {self.workspace} && git clone {url}")
        if code == 0:
            print(f"✓ Cloned: {name}")
            return True
        return False
    
    def sync_all_repos(self):
        """Pull latest from all repos"""
        print("📤 Syncing all repositories...")
        manifest = json.loads(self.repos_manifest.read_text())
        
        for repo in manifest["repositories"]:
            name = repo["name"]
            repo_dir = self.workspace / name
            
            if repo_dir.exists():
                code, _, _ = self.run(f"cd {repo_dir} && git pull")
                status = "✓" if code == 0 else "✗"
                print(f"  {status} {name}")
            else:
                print(f"  ⊘ {name} (not cloned)")
    
    def create_issue_branch(self, repo_name, issue_title, issue_body=""):
        """Create an issue-tracking branch"""
        repo_dir = self.workspace / repo_name
        if not repo_dir.exists():
            print(f"❌ Repo not found: {repo_name}")
            return
        
        # Sanitize branch name
        branch_name = f"issue/{issue_title.lower().replace(' ', '-')[:50]}"
        
        code, _, _ = self.run(f"cd {repo_dir} && git checkout -b {branch_name}")
        
        # Create issue metadata file
        issue_file = repo_dir / f".issue-{branch_name.replace('/', '-')}.md"
        issue_content = f"""# {issue_title}

**Created:** {datetime.now().isoformat()}
**Status:** open
**Branch:** {branch_name}

{issue_body}
"""
        issue_file.write_text(issue_content)
        
        code, _, _ = self.run(f"cd {repo_dir} && git add . && git commit -m 'Issue: {issue_title}'")
        code, _, _ = self.run(f"cd {repo_dir} && git push -u origin {branch_name}")
        
        print(f"✓ Issue branch created: {branch_name}")
        print(f"   Push to GitHub, then open PR at: https://github.com/{GITHUB_USER}/{repo_name}/compare/main...{branch_name}")
    
    def create_pr_branch(self, repo_name, pr_title, pr_body=""):
        """Create a PR-tracking branch"""
        repo_dir = self.workspace / repo_name
        if not repo_dir.exists():
            print(f"❌ Repo not found: {repo_name}")
            return
        
        branch_name = f"pr/{pr_title.lower().replace(' ', '-')[:50]}"
        
        code, _, _ = self.run(f"cd {repo_dir} && git checkout -b {branch_name}")
        
        # Create PR metadata
        pr_file = repo_dir / f".pr-{branch_name.replace('/', '-')}.md"
        pr_content = f"""# PR: {pr_title}

**Created:** {datetime.now().isoformat()}
**Status:** draft
**Branch:** {branch_name}

{pr_body}
"""
        pr_file.write_text(pr_content)
        
        code, _, _ = self.run(f"cd {repo_dir} && git add . && git commit -m 'PR: {pr_title}'")
        code, _, _ = self.run(f"cd {repo_dir} && git push -u origin {branch_name}")
        
        print(f"✓ PR branch created: {branch_name}")
        print(f"   Open PR at: https://github.com/{GITHUB_USER}/{repo_name}/compare/main...{branch_name}")

if __name__ == "__main__":
    gh = GitHubAutomation()
    
    # Run discovery
    repos = gh.discover_repos()
    
    print(f"\n📊 Found {len(repos)} repositories")
    for repo in repos:
        print(f"  • {repo['name']}")
