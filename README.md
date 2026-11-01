# TaskFlow: Project & Workspace Management Platform

**Author:** Nalini Jain (<nalini1234jain@gmail.com>)

TaskFlow is a full-stack collaborative project management platform. Teams organise work into workspaces and projects, move tasks across a drag-and-drop Kanban board, plan sprints with a metrics dashboard, search across a workspace, and review a complete audit trail of who changed what.

**Stack:** React 18 + Tailwind CSS (Vite) · Java 17 + Spring Boot 3.3 · Spring Security + JWT (JJWT) · Spring Data JPA · PostgreSQL 16 · Redis 7

## Features

- Kanban board with To do, In progress, Review and Done columns; drag-and-drop persists order, and the board re-syncs every 5 seconds so teammates' changes appear without a refresh.
- Task creation, editing, assignment (to workspace members), priority, story points and sprint assignment.
- Sprint dashboard: completion percentage, story points, days remaining, tasks per column, and open work per person.
- Workspace-wide search (debounced) that jumps straight to the matching task, plus an in-board filter.
- Activity tracking: every create, update, move, assignment, sprint change and membership change is logged and shown in a feed.
- Role-based workspace permissions: Admin, Member, Viewer.

## Architecture

```
 React SPA (Vite, Tailwind, @hello-pangea/dnd, axios)
      │  Authorization: Bearer <JWT>   (axios request interceptor)
      ▼
 Spring Boot REST API
   JwtAuthFilter → SecurityConfig (stateless) → Controllers → Services → Repositories (JPA)
      │                         │                                    │
      │                         └── AccessService (role checks) ─────┤
      ▼                                                              ▼
   Redis 7                                                    PostgreSQL 16
   · revoked-token list (logout)                              users, workspaces, workspace_members,
   · login-failure counters                                   projects, sprints, tasks, activity_logs
   · cache: workspace roles, sprint metrics
```

Backend layers (`backend/src/main/java/com/taskflow`): `model` (entities), `repository`, `dto`, `security`, `service`, `controller`, `exception`.

## Security

| Concern | Implementation |
|---|---|
| Authentication | `POST /api/auth/register` and `/login` return an HS256-signed JWT (24h by default, configurable). |
| Password storage | BCrypt, cost 12. |
| Stateless sessions | No server session; `JwtAuthFilter` validates the signature and expiry on each request. |
| Logout / revocation | `POST /api/auth/logout` stores the token's `jti` in Redis until it would have expired; the filter rejects revoked tokens. |
| Brute-force protection | After 10 failed logins for an email, further attempts get HTTP 429 for 15 minutes (Redis counter). |
| Authorization | Every service method calls `AccessService`, which resolves the caller's role in the target workspace (Redis-cached) and enforces VIEWER < MEMBER < ADMIN. Project, sprint and task ids are resolved to their workspace first, so ids from other workspaces are refused. |
| Input validation | Bean Validation on all request DTOs; consistent JSON error bodies via `GlobalExceptionHandler`. |
| CORS | Restricted to the origins in `CORS_ORIGINS`. |

### Permission matrix

| Action | Viewer | Member | Admin |
|---|:-:|:-:|:-:|
| View projects, board, sprints, activity, members, search | ✔ | ✔ | ✔ |
| Create / edit / move / delete tasks | | ✔ | ✔ |
| Create projects, create / start / complete sprints | | ✔ | ✔ |
| Delete projects | | | ✔ |
| Add, remove members and change roles | | | ✔ |

A workspace always keeps at least one admin. Registering creates a personal workspace with you as its admin.

## REST API

| Method & path | Purpose |
|---|---|
| `POST /api/auth/register`, `/login`, `/logout`; `GET /api/auth/me` | Authentication |
| `GET, POST /api/workspaces` | List mine / create |
| `GET, POST /api/workspaces/{id}/members` | List / add by email |
| `PUT, DELETE /api/workspaces/{id}/members/{userId}` | Change role / remove |
| `GET /api/workspaces/{id}/activity?limit=` | Audit trail |
| `GET /api/workspaces/{id}/search?q=` | Search tasks across projects |
| `GET, POST /api/workspaces/{id}/projects`; `DELETE /api/projects/{id}` | Projects |
| `GET, POST /api/projects/{id}/sprints`; `POST /api/sprints/{id}/activate`, `/complete` | Sprints |
| `GET /api/projects/{id}/metrics` | Sprint dashboard numbers |
| `GET, POST /api/projects/{id}/tasks`; `PUT, DELETE /api/tasks/{id}` | Tasks |
| `PATCH /api/tasks/{id}/move` body `{status, position}` | Kanban drag-and-drop |

## Running locally

Prerequisites: JDK 17+, Maven 3.9+, Node 18+, Docker.

```bash
# 1. PostgreSQL and Redis
docker compose up -d

# 2. Backend (http://localhost:8080)
cd backend
mvn spring-boot:run

# 3. Frontend (http://localhost:5173)
cd ../frontend
npm install
npm run dev
```

Open http://localhost:5173, create an account, and start adding projects. The Vite dev server proxies `/api` to port 8080.

### Configuration (environment variables)

| Variable | Default |
|---|---|
| `DB_URL`, `DB_USER`, `DB_PASSWORD` | `jdbc:postgresql://localhost:5432/taskflow`, `taskflow`, `taskflow` |
| `REDIS_HOST`, `REDIS_PORT` | `localhost`, `6379` |
| `JWT_SECRET` | development value; **set your own (32+ characters) in any real deployment** |
| `JWT_EXPIRATION_MS` | `86400000` |
| `CORS_ORIGINS` | `http://localhost:5173` |
| `DDL_AUTO` | `update` (use a migration tool such as Flyway for production) |
| `VITE_API_URL` (frontend) | `/api` |

## Design notes and known limits

- **Live updates** use short polling (5s) rather than WebSockets. It keeps authentication simple and works behind any proxy; STOMP/WebSocket push is the natural next step.
- The schema is created by Hibernate (`ddl-auto: update`) for easy local setup; there are no migration scripts yet.
- The JWT is kept in `localStorage`, which is simple but exposed to XSS; an httpOnly-cookie flow would be stronger for production.
- There are no automated tests yet.

## Author

Designed and developed by **Nalini Jain**.
