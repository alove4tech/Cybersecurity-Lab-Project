#!/bin/bash

# Cybersecurity Lab auto-review and push script
# Runs nightly to commit and push any repo changes

set -euo pipefail

REPO_DIR="/home/claw/.openclaw/workspace/labs/github/Cybersecurity-Lab-Project"
SCRIPT_DIR="$REPO_DIR/.scripts"
LOG_DIR="/home/claw/.openclaw/logs"
LOG_FILE="$LOG_DIR/cybersecurity-lab-review.log"

mkdir -p "$SCRIPT_DIR" "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cd "$REPO_DIR"

log "Starting nightly review and push..."

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  log "Changes detected. Preparing commit..."

  git add -A

  COMMIT_MSG="Automated nightly review and sync

$(date '+%Y-%m-%d %H:%M:%S')"

  git commit -m "$COMMIT_MSG"

  log "Pushing to GitHub..."
  git push origin HEAD

  log "✅ Successfully pushed changes to GitHub"
else
  log "No changes to commit. Skipping push."
fi

log "Review complete."
