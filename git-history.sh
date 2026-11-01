#!/usr/bin/env bash
# TaskFlow - Author: Nalini Jain
#
# Initialises a git repository in this folder and records the project as a series of
# logical commits attributed to Nalini Jain. Commits use the real current time, so the
# history reflects when you actually ran it.
#
# Usage:  bash git-history.sh
set -euo pipefail

AUTHOR_NAME="Nalini Jain"
AUTHOR_EMAIL="nalini1234jain@gmail.com"

cd "$(dirname "$0")"

if [ -d .git ]; then
  echo "A git repository already exists here. Aborting so history is not overwritten." >&2
  exit 1
fi

git init -q -b main
git config user.name "$AUTHOR_NAME"
git config user.email "$AUTHOR_EMAIL"

export GIT_AUTHOR_NAME="$AUTHOR_NAME" GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$AUTHOR_NAME" GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL"

commit() {
  local message="$1"; shift
  git add -- "$@"
  git commit -q -m "$message"
  echo "committed: $message"
}

J=backend/src/main/java/com/taskflow
F=frontend

commit "chore: add gitignore and local infrastructure (PostgreSQL, Redis)" .gitignore docker-compose.yml
commit "build(backend): add Maven descriptor, application config and entry point" \
  backend/pom.xml backend/src/main/resources/application.yml $J/TaskFlowApplication.java
commit "feat(domain): add JPA entities and role/status enums" $J/model
commit "feat(data): add Spring Data repositories with search and board queries" $J/repository
commit "feat(api): add DTOs, mappers and global error handling" $J/dto $J/exception
commit "feat(security): add JWT service, auth filter, Redis token blacklist and security config" $J/security
commit "feat(auth): add role-based access checks, activity logging and auth service" \
  $J/service/MembershipLookup.java $J/service/AccessService.java $J/service/ActivityService.java $J/service/AuthService.java
commit "feat(services): add workspace, project, sprint, metrics and task services" \
  $J/service/WorkspaceService.java $J/service/ProjectService.java $J/service/SprintService.java \
  $J/service/MetricsService.java $J/service/TaskService.java
commit "feat(controllers): expose REST endpoints for auth, workspaces, projects, sprints and tasks" $J/controller
commit "build(frontend): scaffold Vite, React and Tailwind" \
  $F/package.json $F/package-lock.json $F/vite.config.js $F/postcss.config.js $F/tailwind.config.js \
  $F/index.html $F/src/index.css $F/src/main.jsx
commit "feat(frontend): add axios client with JWT interceptors and login/register flow" \
  $F/src/api $F/src/context $F/src/pages/AuthPage.jsx $F/src/App.jsx
commit "feat(board): add drag-and-drop Kanban board and task modal" \
  $F/src/components/KanbanBoard.jsx $F/src/components/TaskModal.jsx
commit "feat(dashboard): add workspace and project switcher" $F/src/pages/Dashboard.jsx
commit "feat(insights): add sprint metrics, activity feed, members panel and search" \
  $F/src/components/SprintPanel.jsx $F/src/components/ActivityFeed.jsx \
  $F/src/components/MembersPanel.jsx $F/src/components/SearchBar.jsx
commit "docs: add README and history script" README.md git-history.sh

echo
git log --pretty=format:'%h %an <%ae> %ad  %s' --date=short
