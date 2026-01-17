````md
# How to Structure JSON Tasks for Cursor Agent like

Use structured JSON to give AI agents precise, parseable instructions that reduce errors by 40–60% compared to plain text. This guide covers JSON structure, error handling, file naming, and agent communication.

#### JSON Structure Requirements

**Always use arrays for executable lists, never numbered objects.** Core schema:

```json
{
  "name": "Complete Web App Setup",
  "tasks": [
    {
      "name": "Environment Setup",
      "subtasks": [
        "Verify Node.js: 'node --version' (must be >=18)",
        "Verify Docker: 'docker --version' or install: 'sudo apt install docker.io'",
        "Verify Git: 'git --version' or install: 'sudo apt install git'",
        "Create project directory: 'mkdir ~/web-app && cd ~/web-app'"
      ]
    },
    {
      "name": "Database & Backend Setup",
      "subtasks": [
        "Install PostgreSQL 15+ on the system",
        "Start and enable PostgreSQL service permanently",
        "Create a database user with secure password for the application",
        "Create database 'myapp_db' assigned to the created user"
      ]
    },
    {
      "name": "Docker Infrastructure",
      "subtasks": [
        "Create docker-compose.yml with postgres, redis and nginx services",
        "Start all containers in detached mode",
        "Verify PostgreSQL is running correctly in Docker",
        "Create backup copy of docker-compose.yml as 'docker-compose.prod.yml'"
      ]
    },
    {
      "name": "Frontend Development",
      "subtasks": [
        "Initialize React project with TypeScript",
        "Install TailwindCSS with PostCSS and Autoprefixer as dev dependencies",
        "Install react-router-dom for routing",
        "Create directory structure src/components/{auth,layout,dashboard}"
      ]
    },
    {
      "name": "CI/CD Pipeline",
      "subtasks": [
        "'git init && git add . && git commit -m \"Initial commit\"'",
        "Create GitHub Actions workflow in .github/workflows/deploy.yml for automatic deployment",
        "Install Vercel CLI globally",
        "Test production deployment with Vercel"
      ]
    },
    {
      "name": "Monitoring & Security",
      "subtasks": [
        "Install and configure fail2ban for brute-force attack protection",
        "Install certbot for Let's Encrypt SSL certificates",
        "Configure Sentry for frontend error monitoring",
        "Create healthcheck endpoint at /api/health returning status 200"
      ]
    }
  ],
  "musts": [
    "Use PostgreSQL 15+, NO MySQL",
    "All services containerized with Docker Compose",
    "TypeScript everywhere, NO JavaScript",
    "HTTPS enforced, NO HTTP endpoints",
    "GitHub Actions for CI/CD, NO Jenkins",
    "Environment variables only, NO hardcoded secrets"
  ],
  "output_format": {
    "status": "pending|in_progress|completed|error",
    "current_task": 0,
    "current_subtask": 0,
    "log": [],
    "command_output": "",
    "failed_command": "",
    "next_action": "Next step or 'COMPLETED'",
    "files_created": [],
    "dirs_created": [],
    "services_running": [],
    "errors": []
  }
}
````

#### File Naming & Starting Agent

**Name:** `task.json` (Cursor recognizes `@task.json`)

**Start command in Cursor Agent / Composer:**

```text
@task.json

Execute tasks SEQUENTIALLY. For each step:

* Capture ALL output/error
* Update output_format JSON only
* Move to next step ONLY if status=completed

Respond ONLY with output_format JSON. Never free text.
```

#### Expected Agent Response Format

Agent **must respond only** with your `output_format` structure:

```json
{
  "status": "in_progress",
  "current_task": 0,
  "current_subtask": 0,
  "log": ["MariaDB installed successfully"],
  "command_output": "Creating database biblioteca...",
  "failed_command": "",
  "next_action": "Configure .env database credentials",
  "files_created": [],
  "errors": []
}
```

#### Error Handling Protocol

**When agent reports error about a command (`status=error`):**

1. **Check `failed_command`** – shows exact command that failed
2. **Check `errors` array** – detailed error messages
3. **Check `command_output`** – full terminal output

**Respond to agent with:**

```text
@task.json

Previous command failed: [paste failed_command here]

1. Fix: [your fix instructions]
2. Rerun same command
3. Continue sequence

Respond ONLY output_format JSON.
```

##### Command Execution Error

Check `failed_command`. Sometimes user must execute manually (permissions, sudo, hardware access):

```text
@task.json

Command failed: [paste failed_command here]
MANUAL EXECUTION REQUIRED - run in terminal and confirm:

[paste here]

1. After manual execution, verify: [verification command]
2. Continue sequence

Respond ONLY output_format JSON.
```

##### Non-Command Error (Missing dependency, logic error, file not found)

Check `errors` array and `command_output`:

```text
@task.json

Error: [paste errors array content]
Status: [paste status details]

Fix required:
1. [Specific fix instructions - install package, create directory, etc.]
2. Rerun current subtask
3. Continue sequence

Respond ONLY output_format JSON.
```

#### Complete Workflow Example

```text
1. Save JSON → task.json
2. Cursor Agent → @task.json + start instructions
3. Agent responds → {"status": "in_progress", ...}
4. Error? → Check failed_command → Fix → Continue
5. Success → {"status": "completed", "next_action": "COMPLETED"}
```

#### Tips

* Quote **ALL commands** – prevents parsing issues
* Include verification steps – `'rsync -av --dry-run /... /...'` before real run
* Use `failed_command` field – critical for debugging
* Always test JSON validity first: `cat task.json | jq .`
* Sequential only – never parallel subtasks

**This system achieves 95%+ task completion vs 60% for unstructured prompts.**

```
```

