#!/bin/bash

# Cybersecurity Lab auto-review and push script
# Runs nightly to review docs/config hygiene, then commit and push any repo changes

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

CHANGES_MADE=0

log "Running safe repository review..."

# Ensure basic gitignore hygiene
if [ -f ".gitignore" ]; then
  grep -qxF '.scripts/*.log' .gitignore || { echo '.scripts/*.log' >> .gitignore; CHANGES_MADE=1; log "Added .scripts/*.log to .gitignore"; }
  grep -qxF '.scripts/review.log' .gitignore || { echo '.scripts/review.log' >> .gitignore; CHANGES_MADE=1; log "Added .scripts/review.log to .gitignore"; }
else
  printf '.scripts/*.log\n.scripts/review.log\n' > .gitignore
  CHANGES_MADE=1
  log "Created .gitignore with script log ignores"
fi

# Remove trailing whitespace from markdown/docs files
while IFS= read -r -d '' f; do
  if grep -q '[[:space:]]$' "$f"; then
    sed -i 's/[[:space:]]\+$//' "$f"
    CHANGES_MADE=1
    log "Trimmed trailing whitespace in ${f#./}"
  fi
done < <(find . -type f \( -name '*.md' -o -name '*.txt' -o -name '*.yml' -o -name '*.yaml' \) -not -path './.git/*' -print0)

# Warn on likely missing README coverage for top-level content areas
for d in detections incident-response scripts docs; do
  if [ -d "$d" ] && [ ! -f "$d/README.md" ]; then
    log "ℹ️  Consider adding $d/README.md"
  fi
done

# Warn if env-like files are tracked
if git ls-files | grep -Eq '(^|/)(\.env|.*\.env)$'; then
  log "⚠️  Possible env file tracked by git; review recommended"
fi

# Warn on large binaries accidentally added
if find . -type f -size +20M -not -path './.git/*' | grep -q .; then
  log "⚠️  Found file(s) larger than 20MB; review large artifacts"
fi

# Check for real changes after review
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  log "Changes detected. Preparing commit..."

  git add -A

  COMMIT_MSG="Automated nightly review and sync

$(date '+%Y-%m-%d %H:%M:%S')"

  if [ "$CHANGES_MADE" -eq 1 ]; then
    COMMIT_MSG="$COMMIT_MSG

Safe cleanup and documentation hygiene applied."
  fi

  git commit -m "$COMMIT_MSG"

  log "Pushing to GitHub..."
  git push origin HEAD

  log "✅ Successfully pushed changes to GitHub"
else
  log "No changes to commit. Skipping push."
fi

log "Review complete."
