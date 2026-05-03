#!/usr/bin/env python3
"""
Cat Talk Agent War Room — Backend API
Flask web server for monitoring OpenClaw / Hermes dual-agent status.

Security: READ-ONLY. No git write commands. No file modifications.
"""

import subprocess
import json
from datetime import datetime
from pathlib import Path
from flask import Flask, jsonify, render_template

app = Flask(__name__)

# Fixed repo path
REPO_PATH = "/home/a0938/cat_talk_proper"
AGENT_DIR = f"{REPO_PATH}/.agent"


def run_cmd(cmd: str, cwd: str = REPO_PATH) -> str:
    """Run a read-only shell command and return output."""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=15,
        )
        return result.stdout.strip() if result.stdout else ""
    except Exception as e:
        return f"Error: {e}"


def read_file(path: str) -> str:
    """Read a file and return its contents."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception as e:
        return f"Error: {e}"


def parse_handoff() -> dict:
    """Parse handoff_to_hermes.md status."""
    content = read_file(f"{AGENT_DIR}/handoff_to_hermes.md")
    status = "UNKNOWN"
    waiting = False
    last_updated = ""

    for line in content.split("\n"):
        if line.startswith("- Status:"):
            status = line.split("Status:", 1)[1].strip()
        elif line.startswith("- Waiting for Hermes:"):
            waiting = "YES" in line
        elif line.startswith("- Last updated"):
            last_updated = line.split("Last updated", 1)[-1].strip()

    return {
        "status": status,
        "waiting_for_hermes": waiting,
        "last_updated": last_updated,
        "raw_snippet": content[:500],
    }


def parse_review() -> dict:
    """Parse hermes_review.md status."""
    content = read_file(f"{AGENT_DIR}/hermes_review.md")
    result = "UNKNOWN"
    last_reviewed = ""
    task_name = ""
    task_id = ""

    for line in content.split("\n"):
        if line.startswith("- Result:"):
            result = line.split("Result:", 1)[1].strip()
        elif line.startswith("- Last reviewed"):
            last_reviewed = line.split("Last reviewed", 1)[-1].strip()
        elif line.startswith("- Task name:"):
            task_name = line.split("Task name:", 1)[1].strip()
        elif line.startswith("- Task ID:"):
            task_id = line.split("Task ID:", 1)[1].strip()

    return {
        "result": result,
        "last_reviewed": last_reviewed,
        "task_name": task_name,
        "task_id": task_id,
        "raw_snippet": content[:500],
    }


def get_git_status() -> dict:
    """Get git status (read-only)."""
    output = run_cmd("git status --short")
    is_clean = output == ""
    return {
        "is_clean": is_clean,
        "output": output,
        "has_changes": not is_clean,
    }


def get_recent_commits(limit: int = 8) -> list:
    """Get recent git commits (read-only)."""
    output = run_cmd(f"git log --oneline -{limit}")
    return [
        {"hash": line.split()[0], "message": " ".join(line.split()[1:])}
        for line in output.split("\n")
        if line.strip()
    ]


def get_cron_list() -> dict:
    """Get OpenClaw cron jobs (read-only)."""
    output = run_cmd("openclaw cron list")
    return {"raw": output}


def get_cron_runs(limit: int = 10) -> list:
    """Get recent cron runs (read-only)."""
    output = run_cmd(f"openclaw cron runs --limit {limit}")
    return {"raw": output}


def determine_decision(handoff: dict, review: dict) -> dict:
    """Determine if OpenClaw can continue."""
    handoff_status = handoff.get("status", "UNKNOWN")
    waiting = handoff.get("waiting_for_hermes", False)
    review_result = review.get("result", "UNKNOWN")

    if handoff_status == "WAITING_FOR_HERMES" or waiting:
        return {
            "can_continue": False,
            "decision_text": "OpenClaw must wait for Hermes validation.",
            "reason": "handoff is WAITING_FOR_HERMES",
        }
    elif review_result == "FAIL":
        return {
            "can_continue": False,
            "decision_text": "OpenClaw must fix Hermes failure before continuing.",
            "reason": "Hermes review is FAIL",
        }
    elif handoff_status == "IDLE" and review_result == "PASS":
        return {
            "can_continue": True,
            "decision_text": "OpenClaw may continue to next task.",
            "reason": "handoff IDLE + Hermes PASS",
        }
    else:
        return {
            "can_continue": False,
            "decision_text": "Unknown state. Check .agent files manually.",
            "reason": f"handoff={handoff_status}, review={review_result}",
        }


@app.route("/")
def index():
    """Serve the dashboard HTML page."""
    return render_template("index.html")


@app.route("/api/health")
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
    })


@app.route("/api/status")
def status():
    """
    Full agent status API.

    Returns:
        JSON with all agent status fields.
    """
    handoff = parse_handoff()
    review = parse_review()
    git_status = get_git_status()
    recent_commits = get_recent_commits()
    cron_list = get_cron_list()
    cron_runs = get_cron_runs()
    decision = determine_decision(handoff, review)

    return jsonify({
        # Timestamp
        "current_time": datetime.now().isoformat(),
        "repo_path": REPO_PATH,

        # Git
        "git_status": git_status,
        "recent_commits": recent_commits,

        # Handoff
        "handoff_status": handoff["status"],
        "waiting_for_hermes": handoff["waiting_for_hermes"],
        "handoff_last_updated": handoff["last_updated"],

        # Hermes Review
        "hermes_review_result": review["result"],
        "hermes_review_last_reviewed": review["last_reviewed"],
        "latest_review_task": review["task_name"],
        "latest_review_task_id": review["task_id"],

        # Cron
        "openclaw_cron_raw": cron_list["raw"],
        "recent_cron_runs_raw": cron_runs["raw"],

        # Decision
        "can_openclaw_continue": decision["can_continue"],
        "decision_text": decision["decision_text"],
        "decision_reason": decision["reason"],

        # Raw snippets (for debugging)
        "handoff_raw_snippet": handoff.get("raw_snippet", "")[:300],
        "review_raw_snippet": review.get("raw_snippet", "")[:300],
    })


if __name__ == "__main__":
    print(f"Cat Talk Agent War Room — Starting on http://127.0.0.1:8787")
    print(f"Repo: {REPO_PATH}")
    print("Security: READ-ONLY. No git write. No file modifications.")
    app.run(host="127.0.0.1", port=8787, debug=False)