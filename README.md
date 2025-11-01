# Swift Server Deployment Pipeline: From Code to Production

**Learn how to build a production-ready CI/CD pipeline for Swift server applications.**

This repository demonstrates a complete deployment pipeline for Swift server applications, from local development to automated production deployments. It's designed to teach you modern DevOps practices specifically for Swift on the server.

## Why This Repository Exists

If you're a Swift developer who wants to:
- ✅ Deploy server-side Swift applications to production
- ✅ Learn CI/CD and DevOps practices
- ✅ Understand Docker, GitHub Actions, and deployment automation
- ✅ See a real-world example you can adapt to your own projects

**This is for you.**

## What You'll Learn

By exploring this repository, you'll understand:

1. **Continuous Integration (CI):** Automated testing, building, and validation on every commit
2. **Continuous Deployment (CD):** Automated deployment to staging and production environments
3. **Docker Containerization:** Packaging Swift applications for consistent deployment
4. **Version Management:** Semantic versioning with automatic build tracking
5. **Deployment Safety:** Health checks, automatic rollback, and blue-green deployments
6. **Testing Strategies:** Unit tests, integration tests, and API testing
7. **DevOps Best Practices:** Code quality checks, security scanning, and monitoring

## Start Here

**🎯 Repository Owner?** → Read [START_HERE.md](START_HERE.md) - Setup guide and next steps (enable GitHub Pages in 5 minutes!)

**📚 New to CI/CD?** → Read [LEARNING_PATH.md](LEARNING_PATH.md) to find your learning path

**🚀 Want to see it in action?** → Follow [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md) for a hands-on tutorial

**🏗️ Understand the "why"?** → Read [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) for design decisions

**🐛 Need help?** → Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues

---

## The Demo Application

This repository includes a **simple todo API** built with Hummingbird. The application itself is intentionally simple - the focus is on the deployment pipeline, not the app features.

### Features

- RESTful API for todo management (CRUD operations)
- SQLite database with Fluent ORM
- Health check endpoint for monitoring
- Docker containerization
- Production-ready configuration

## Quick Start

### Local Development

1. **Build and run with Swift:**

```bash
cd todos-fluent
swift run App
```

2. **Or use Docker Compose:**

```bash
docker-compose up --build
```

3. **Run tests:**

```bash
# Unit tests
cd todos-fluent && swift test

# API integration tests
./tests/api/api-tests.sh
```

### Access the API

The server runs on `http://localhost:8080`

- Health check: `GET http://localhost:8080/health`
- List todos: `GET http://localhost:8080/api/todos`
- Create todo: `POST http://localhost:8080/api/todos`

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check endpoint |
| GET | `/api/todos` | List all todos |
| POST | `/api/todos` | Create a new todo |
| GET | `/api/todos/:id` | Get a specific todo |
| PATCH | `/api/todos/:id` | Update a todo |
| DELETE | `/api/todos/:id` | Delete a todo |

### Example Usage

```bash
# Create a todo
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Hummingbird", "completed": false}'

# List all todos
curl http://localhost:8080/api/todos

# Update a todo
curl -X PATCH http://localhost:8080/api/todos/{id} \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Hummingbird", "completed": true}'
```

## The CI/CD Pipeline

This is the heart of the repository - a complete automated pipeline that takes your code from commit to production.

### What Happens When You Push Code?

```
Your Commit
    ↓
┌───────────────────────────────────────┐
│  CI: Automated Quality Checks         │
│  • SwiftLint (code style)             │
│  • Unit tests                         │
│  • Docker build                       │
│  • Integration tests                  │
│  • Security scanning                  │
│  ✓ All pass in ~5 minutes             │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│  Staging: Automatic Deployment        │
│  • Deploy to staging server           │
│  • Health checks                      │
│  • API tests                          │
│  • 5-minute monitoring                │
│  • Auto-rollback if issues            │
└───────────────────────────────────────┘
    ↓
   Manual Review & Approval
    ↓
┌───────────────────────────────────────┐
│  Production: Safe Deployment          │
│  • Version bump (semantic)            │
│  • Database backup                    │
│  • Blue-green deployment              │
│  • Health checks                      │
│  • 15-minute monitoring               │
│  • Auto-rollback if issues            │
└───────────────────────────────────────┘
```

**Key Features:**
- ⚡ **Fast:** Registry-based Docker caching (builds in 30-90 seconds after first run)
- 🛡️ **Safe:** Automatic rollback if anything fails
- 📊 **Visible:** Every step is logged in GitHub Actions
- 🎯 **Reliable:** Tested in staging before production

Want to understand the design decisions? See [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)

## Project Structure

```
HummingbirdPlublication/
├── .github/
│   └── workflows/
│       ├── ci.yml                    # CI pipeline
│       ├── deploy-staging.yml        # Staging deployment
│       └── deploy-production.yml     # Production deployment
├── todos-fluent/
│   ├── Sources/
│   │   └── App/
│   │       ├── App.swift            # Main entry point
│   │       ├── Application+build.swift
│   │       ├── Controllers/
│   │       │   └── TodoController.swift
│   │       ├── Models/
│   │       │   └── Todo.swift
│   │       └── Migrations/
│   │           └── CreateTodo.swift
│   └── Tests/
│       └── AppTests/
│           └── AppTests.swift
├── tests/
│   └── api/
│       └── api-tests.sh             # API integration tests
├── scripts/
│   ├── deploy.sh                    # Manual deployment script
│   ├── rollback.sh                  # Manual rollback script
│   └── health-check.sh              # Health check utility
├── Dockerfile                       # Multi-stage Docker build
├── docker-compose.yml               # Local development
├── .swiftlint.yml                   # Code quality config
└── DEPLOYMENT.md                    # Deployment guide
```

## Technology Stack

- **Framework**: Hummingbird 2.0
- **Language**: Swift 5.9+
- **Database**: SQLite with Fluent ORM
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Testing**: XCTest + Shell scripts
- **Code Quality**: SwiftLint
- **Security Scanning**: Trivy

## Development

### Prerequisites

- Swift 5.9 or later
- Docker and Docker Compose
- Git

### Setup for Development

1. Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/HummingbirdPlublication.git
cd HummingbirdPlublication
```

2. Install dependencies:

```bash
cd todos-fluent
swift package resolve
```

3. Run the application:

```bash
swift run App
```

4. Run tests:

```bash
swift test
```

### Code Quality

Before committing, ensure your code passes linting:

```bash
# Install SwiftLint (macOS)
brew install swiftlint

# Run linting
swiftlint lint

# Auto-fix issues where possible
swiftlint --fix
```

## Deployment

### Setting Up CI/CD

1. **Fork or create the repository on GitHub**

2. **Configure GitHub Secrets** (Settings > Secrets and variables > Actions):
   - `STAGING_HOST`
   - `STAGING_USER`
   - `STAGING_SSH_KEY`
   - `PRODUCTION_HOST`
   - `PRODUCTION_USER`
   - `PRODUCTION_SSH_KEY`

3. **Configure GitHub Variables**:
   - `STAGING_URL`
   - `PRODUCTION_URL`

4. **Push to main branch** - Staging deploys automatically

5. **Deploy to production** - Create a version tag and trigger manually:

```bash
git tag v1.0.0
git push origin v1.0.0
# Then: Actions > Deploy to Production > Run workflow
```

For complete setup instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Testing

### Unit Tests

```bash
cd todos-fluent
swift test
```

### Integration Tests

```bash
# Start the application first
docker-compose up -d

# Run API tests
./tests/api/api-tests.sh

# Stop the application
docker-compose down
```

### Health Check

```bash
./scripts/health-check.sh http://localhost:8080
```

## Monitoring and Maintenance

### View Logs

```bash
# Docker container logs
docker logs todos-staging -f
docker logs todos-production -f

# Check deployment status
cat /opt/todos-app/current-version.txt
cat /opt/todos-app/last-deployment.txt
```

### Manual Rollback

```bash
# On the server
./scripts/rollback.sh production
```

### Database Backups

Automatic backups are created before each deployment in `/opt/todos-app/backups/`.

Manual backup:
```bash
cp /opt/todos-app/data/db.sqlite /opt/todos-app/backups/db.sqlite.backup.$(date +%Y%m%d-%H%M%S)
```

---

## Documentation Guide

All documentation is designed to be educational and accessible:

| Document | Purpose | Best For |
|----------|---------|----------|
| [LEARNING_PATH.md](LEARNING_PATH.md) | Choose your learning path based on experience | Everyone - start here! |
| [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md) | Step-by-step hands-on tutorial | Beginners wanting practical experience |
| [GITHUB_ACTIONS_PRIMER.md](GITHUB_ACTIONS_PRIMER.md) | Introduction to GitHub Actions | Developers new to CI/CD |
| [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) | Why this pipeline is designed this way | Understanding design decisions |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions | When things go wrong |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Complete deployment reference | Production deployments |
| [VERSIONING.md](VERSIONING.md) | Version management guide | Understanding versioning |
| [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) | Docker caching strategy | Performance optimization |

---

## For Talk Attendees

**Welcome!** This repository accompanies the talk on Swift server deployment.

### Before the Talk
- ⭐ Star this repository
- 📖 Skim through [LEARNING_PATH.md](LEARNING_PATH.md)
- 💻 Optionally: Fork the repo and try running it locally

### During the Talk
- 📝 Follow along with [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)
- 👀 Watch the live demo of the deployment pipeline
- 🙋 Ask questions!

### After the Talk
- 🚀 Complete [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md) tutorial
- 🔧 Adapt this pipeline to your own projects
- 💬 Share your experience or ask questions via GitHub issues

---

## Troubleshooting

Having issues? Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for solutions to common problems.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure tests pass
5. Submit a pull request

## Security

- Never commit secrets or API keys
- Use environment variables for configuration
- Keep dependencies up to date
- Review security scan results in CI pipeline

## License

This project is open source and available under the MIT License.

## Acknowledgments

- Built with [Hummingbird](https://github.com/hummingbird-project/hummingbird) framework
- Uses [Fluent](https://github.com/vapor/fluent) ORM
- Inspired by [TodoBackend](https://todobackend.com/) specification

## Support

For issues, questions, or contributions:

- Open an issue on GitHub
- Review [DEPLOYMENT.md](DEPLOYMENT.md) for deployment help
- Check GitHub Actions logs for CI/CD issues

---

**Happy deploying!** 🚀
