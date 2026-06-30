# Hybrid Memory System - Architecture & Implementation

**Deployed:** 2026-06-30  
**Status:** ✓ Operational  
**Purpose:** Unified memory across Hermes, Honcho, and GitHub

---

## // ARCHITECTURE //

### Three Memory Layers

**Layer 1: Hermes Memory**
- Location: `~/.hermes/memories/`
- Content: User profile (name, preferences, patterns, style)
- Updated: Manually via mcp__memory tool
- Purpose: Inform agent reasoning and decision-making

**Layer 2: Honcho Memory**
- Location: Honcho workspace (dialectic reasoning)
- Content: Conclusions, behavioral analysis, inferences
- Updated: Automatically via honcho_conclude and observations
- Purpose: Deep understanding of user patterns and preferences

**Layer 3: GitHub Storage**
- Location: `repos-list/state/` and `repos-list/knowledge/`
- Content: Session snapshots, operational history, learnings
- Updated: After each session via snapshot scripts
- Purpose: Timestamped evidence, version control, collaboration

---

## // HOW THEY WORK TOGETHER //

### Session Flow

1. **Session Starts**
   ```
   Hermes Memory Injected → System Prompt
   GitHub History Loaded → Context
   Honcho Memory Available → honcho_* tools
   ```

2. **During Work**
   ```
   Reasoning uses: Hermes (who you are) + GitHub (what happened)
   Conclusions use: Honcho (what I infer) + GitHub (evidence)
   Execution uses: All three layers in parallel
   ```

3. **Session Ends**
   ```
   Create Snapshot → GitHub (operational record)
   Update Hermes → New facts learned
   Save Honcho Conclusions → Automatic
   Commit Everything → Version control
   ```

---

## // FILES & STRUCTURE //

### GitHub Storage Structure
```
repos-list/
├── state/
│   ├── sessions/
│   │   └── session-YYYYMMDD-HHMMSS.json
│   │       (What happened each session)
│   └── snapshots/
│       └── system-YYYYMMDD-HHMMSS.json
│           (System state at key moments)
│
├── knowledge/
│   ├── docs/kb/
│   │   └── *.md (Discovered procedures, patterns)
│   └── learnings/
│       └── *.md (Insights about what works)
│
└── operations/
    └── tasks/
        └── *.json (Current projects, status)
```

### Key Scripts
- `snapshot-session.sh` — Captures session state
- `hybrid-memory-system.py` — Integration logic
- `github-daemon.sh` — Background persistence

---

## // USAGE //

### Automatic (No Action Needed)
- Session snapshots created after major operations
- Hermes memory injected at session start
- Honcho conclusions saved automatically
- GitHub history available for context

### Manual (When You Want)
- Create snapshot: `bash snapshot-session.sh`
- View learnings: `cat repos-list/knowledge/learnings/*.md`
- Check history: `ls repos-list/state/sessions/`

---

## // DATA FLOW //

```
┌─────────────────────────────────────────┐
│  Session Starts                         │
│  • Load Hermes Memory (user facts)      │
│  • Load GitHub History (past sessions)  │
│  • Activate Honcho (reasoning)          │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│  During Execution                       │
│  • Use Hermes for decision logic        │
│  • Use GitHub for context               │
│  • Use Honcho for synthesis             │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│  Session Ends                           │
│  • Snapshot to GitHub                   │
│  • Update Hermes Memory                 │
│  • Conclude via Honcho                  │
│  • Commit version control               │
└─────────────────────────────────────────┘
```

---

## // INTEGRATION POINTS //

### Hermes Memory
- **What it stores:** Profile facts, preferences, patterns
- **Who updates it:** Me (via mcp__memory)
- **Who reads it:** Me (injected in system prompt)
- **Why:** Informs how I work with you

### Honcho Memory
- **What it stores:** Conclusions, behavioral analysis
- **Who updates it:** Me (via honcho_conclude)
- **Who reads it:** Me (via honcho_reasoning, honcho_search)
- **Why:** Deep understanding of you and patterns

### GitHub Storage
- **What it stores:** Timestamped facts, history, evidence
- **Who updates it:** Me (via git commits)
- **Who reads it:** You (GitHub web) + Me (loading context)
- **Why:** Permanent record, collaboration, version control

---

## // NO REDUNDANCY //

Each layer serves unique purpose:
- ❌ Don't duplicate user facts in GitHub (belongs in Hermes)
- ❌ Don't duplicate conclusions in GitHub (belongs in Honcho)
- ❌ Don't duplicate operational data in Hermes (belongs in GitHub)

Each answers different question:
- Hermes: "Who is this user?"
- Honcho: "What can I infer about this user?"
- GitHub: "What actually happened and when?"

---

## // BENEFITS //

✓ **Maximum Persistence** — Survives everything (GitHub backup)  
✓ **Maximum Context** — All three layers active simultaneously  
✓ **Maximum Autonomy** — I improve session-to-session  
✓ **Maximum Collaboration** — You can review GitHub history  
✓ **Maximum Safety** — Distributed, no single point of failure  

---

## // ACTIVATED //

This hybrid system is now:
- ✓ Deployed
- ✓ Functional
- ✓ Automatic
- ✓ Non-intrusive
- ✓ Zero additional setup needed

All three memory layers will now work together seamlessly.

