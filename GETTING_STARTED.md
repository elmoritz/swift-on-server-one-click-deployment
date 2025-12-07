# Getting Started

Quick guide to run and deploy this Swift server application with automated CI/CD.

## What This Is

A production-ready **Todo API** (Hummingbird + Fluent) with complete CI/CD pipeline demonstrating:

- Automated testing and deployment via GitHub Actions
- Docker containerization
- Staging → Production workflow with auto-rollback
- Health checks and API testing

## Quick Start (Local)

### Run with Docker

```bash
docker-compose up --build
```

### Run with Swift

```bash
cd todos-fluent
swift run App
```

### Test the API

```bash
# Health check
curl http://localhost:8080/health

# Create todo
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Swift CI/CD", "completed": false}'

# List todos
curl http://localhost:8080/api/todos
```

### Run Tests

```bash
# Unit tests
cd todos-fluent && swift test

# API integration tests
./tests/api/api-tests.sh
```

## CI/CD Pipeline

**When you push to `main`:**

1. **CI runs**: SwiftLint → Tests → Docker build → Security scan
2. **Auto-deploys to staging**: Health checks + monitoring
3. **Manual approval for production**: Version bump + blue-green deployment

## Setup Deployment

### 1. Configure GitHub Secrets

Go to Settings → Secrets and variables → Actions:

**Required Secrets:**

- `SSH_HOST`, `STAGING_USER`, `STAGING_SSH_KEY`
- `SSH_HOST`, `SSH_USER`, `PRODUCTION_SSH_KEY`

**Required Variables:**

- `DEPLOYMENT_URL`

### 2. Deploy to Staging

```bash
git push origin main  # Auto-deploys to staging
```

### 3. Deploy to Production

```bash
git tag v1.0.0
git push origin v1.0.0
# Then: GitHub Actions → Deploy to Production → Run workflow
```

## Project Structure

```
├── .github/workflows/          # CI/CD pipelines
│   ├── ci.yml                 # Tests, lint, security
│   ├── deploy-staging.yml     # Auto staging deployment
│   └── deploy-production.yml  # Manual prod deployment
├── todos-fluent/
│   ├── Sources/App/
│   │   ├── Controllers/       # TodoController
│   │   ├── Models/           # Todo model
│   │   └── Migrations/       # Database setup
│   └── Tests/                # Unit tests
├── tests/api/                # Integration tests
├── scripts/                  # Deployment utilities
├── Dockerfile               # Multi-stage build
└── docker-compose.yml       # Local development
```

## Tech Stack

- **Framework**: Hummingbird 2.0
- **Database**: SQLite + Fluent ORM
- **CI/CD**: GitHub Actions
- **Container**: Docker
- **Code Quality**: SwiftLint
- **Security**: Trivy scanner

## API Endpoints

| Method | Endpoint         | Description       |
| ------ | ---------------- | ----------------- |
| GET    | `/health`        | Health check      |
| GET    | `/api/todos`     | List all todos    |
| POST   | `/api/todos`     | Create todo       |
| GET    | `/api/todos/:id` | Get specific todo |
| PATCH  | `/api/todos/:id` | Update todo       |
| DELETE | `/api/todos/:id` | Delete todo       |

## Learn More

- **📚 Complete docs**: [docs/](docs/) folder or [GitHub Pages](https://elmoritz.github.io/swift-on-server-one-click-deployment/)
- **🎯 Learning path**: [docs/learning-path.md](docs/learning-path.md)
- **🚀 First deployment**: [docs/first-deployment.md](docs/first-deployment.md)
- **🏗️ Architecture**: [docs/pipeline-architecture.md](docs/pipeline-architecture.md)
- **🐛 Troubleshooting**: [docs/troubleshooting.md](docs/troubleshooting.md)

## Prerequisites

- Swift 5.9+
- Docker & Docker Compose
- Git
- (Optional) SwiftLint: `brew install swiftlint`

## Monitoring

```bash
# View logs
docker logs todos-staging -f

# Check version
cat /opt/todos-app/current-version.txt

# Rollback
./scripts/rollback.sh production
```

---

**Happy deploying!** 🚀
