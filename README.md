# Hummingbird Todos - Production-Ready CI/CD Pipeline

A complete Swift server application built with Hummingbird framework, featuring a fully automated CI/CD pipeline for seamless deployment to staging and production environments.

## Features

- RESTful API for todo management
- SQLite database with Fluent ORM
- Automated CI/CD pipeline with GitHub Actions
- **Automatic semantic versioning with build number tracking**
- Docker containerization
- Comprehensive testing (unit, integration, API tests)
- Automated staging and production deployments
- Health monitoring and automatic rollback
- Security scanning and code quality checks
- One-click production deployments with version type selection

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

## CI/CD Pipeline

This project includes a complete CI/CD pipeline that automates the entire deployment process.

### Pipeline Stages

1. **Continuous Integration (on every push):**
   - SwiftLint code quality checks
   - Unit tests with code coverage
   - Docker image build
   - Integration API tests
   - Security vulnerability scanning

2. **Staging Deployment (automatic on main branch):**
   - Deploy to staging server
   - Health checks
   - API test suite validation
   - 5-minute monitoring

3. **Production Deployment (manual trigger):**
   - Pre-deployment validation
   - Version tag verification
   - Deploy to production
   - Smoke tests
   - 15-minute monitoring
   - Automatic rollback on failure

### Deployment Flow

```
Code Push → CI Tests → Staging Deploy → API Tests → Manual Approval → Production Deploy
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

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

## Troubleshooting

Common issues and solutions are documented in [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting).

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
