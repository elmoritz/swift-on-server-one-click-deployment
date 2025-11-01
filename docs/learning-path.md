---
layout: default
title: Learning Path
nav_order: 2
description: "Choose your learning path based on your experience level"
permalink: /learning-path
---

# Learning Path: Swift Server Deployment

Welcome! This repository demonstrates a production-ready deployment pipeline for Swift server applications. Whether you're attending the talk or exploring on your own, this guide will help you navigate the materials based on your experience level.

## Table of Contents

- [Who This Is For](#who-this-is-for)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Learning Paths by Experience Level](#learning-paths-by-experience-level)
  - [Beginner Path](#beginner-path-new-to-deployment)
  - [Intermediate Path](#intermediate-path-some-deployment-experience)
  - [Advanced Path](#advanced-path-production-deployment-experience)
- [Core Concepts You'll Learn](#core-concepts-youll-learn)
- [Repository Overview](#repository-overview)
- [Next Steps](#next-steps)

---

## Who This Is For

This repository is designed for **Swift developers** who want to learn how to deploy server-side applications to production. You'll learn:

- How to set up a complete CI/CD pipeline using GitHub Actions
- Docker containerization best practices for Swift applications
- Deployment automation with safety mechanisms (health checks, rollbacks)
- Version management and release processes
- Testing strategies for server applications

**This is NOT:**
- A framework tutorial (use official Hummingbird/Vapor docs for that)
- A Swift language guide
- A server architecture course

**This IS:**
- A practical guide to **deployment pipelines** for Swift servers
- A working example you can learn from and adapt
- A collection of best practices for production deployments

---

## Learning Objectives

By the end of this learning path, you'll be able to:

1. ✅ Understand the components of a modern CI/CD pipeline
2. ✅ Set up automated testing and deployment for Swift server apps
3. ✅ Containerize Swift applications with Docker
4. ✅ Implement blue-green deployments with automatic rollback
5. ✅ Manage semantic versioning automatically
6. ✅ Configure health checks and monitoring
7. ✅ Troubleshoot common deployment issues

---

## Prerequisites

### Required Knowledge
- ✅ Swift programming basics
- ✅ Basic command line usage (cd, ls, cat, etc.)
- ✅ Git basics (commit, push, pull)
- ✅ Basic understanding of HTTP/REST APIs

### Required Tools
- ✅ GitHub account (for Actions)
- ✅ Docker installed locally (for testing)
- ✅ Text editor or IDE
- ✅ Terminal/command line access

### Optional But Helpful
- 🔹 Basic Docker knowledge (we'll cover what you need)
- 🔹 Familiarity with CI/CD concepts
- 🔹 Linux/SSH basics (for deployment to servers)

---

## Learning Paths by Experience Level

Choose the path that matches your current experience:

### Beginner Path: New to Deployment

**Time Investment:** ~4-6 hours

You've built Swift applications but never deployed to production. This path will introduce you to all the concepts step-by-step.

#### Recommended Reading Order:

1. **Start Here:** [README.md](README.md)
   - Understand what this project is
   - Get the application running locally with Docker
   - Test the API endpoints
   - **Goal:** Have the app running on your machine

2. **Learn GitHub Actions:** [GITHUB_ACTIONS_PRIMER.md](GITHUB_ACTIONS_PRIMER.md)
   - Understand what GitHub Actions is
   - Learn about workflows, jobs, and steps
   - Understand how CI/CD works conceptually
   - **Goal:** Understand the automation foundation

3. **Understand the Pipeline:** [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)
   - Why this specific workflow structure?
   - What happens on each commit?
   - Staging vs. production deployments
   - **Goal:** Understand the big picture

4. **Hands-On Tutorial:** [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md)
   - Follow step-by-step to make your first deployment
   - See the entire pipeline in action
   - Understand each automated step
   - **Goal:** Successfully deploy a change from code to production

5. **Deep Dive:** [DEPLOYMENT.md](DEPLOYMENT.md)
   - Detailed deployment procedures
   - Manual deployment options
   - Rollback procedures
   - **Goal:** Understand all deployment options

6. **Quick Reference:** [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
   - Checklist for setting up your own pipeline
   - Environment variables and secrets
   - **Goal:** Know how to set this up for your own project

7. **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
   - Common issues and solutions
   - Debugging deployment failures
   - **Goal:** Handle problems independently

#### Hands-On Exercises:

- [ ] Fork this repository
- [ ] Run the application locally with `docker-compose up`
- [ ] Make a code change and create a pull request
- [ ] Watch the CI pipeline run
- [ ] Deploy to staging (or simulate it)
- [ ] Try a rollback scenario

---

### Intermediate Path: Some Deployment Experience

**Time Investment:** ~2-3 hours

You've deployed applications before (maybe with Heroku, Railway, or basic Docker) and understand CI/CD basics. You want to learn production-grade practices.

#### Recommended Reading Order:

1. **Quick Start:** [README.md](README.md)
   - Skim the overview
   - Focus on the "Pipeline Overview" section
   - **Goal:** Understand this specific setup

2. **Architecture Decisions:** [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)
   - Why this workflow structure over simpler alternatives?
   - Registry-based caching strategy
   - Blue-green deployment pattern
   - **Goal:** Understand the "why" behind design choices

3. **Hands-On:** [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md)
   - Quickly go through the tutorial
   - Focus on the GitHub Actions workflow details
   - **Goal:** See how all pieces connect

4. **Advanced Topics:**
   - [VERSIONING.md](VERSIONING.md) - Automatic version management
   - [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Docker caching strategy
   - [REUSABLE_ACTIONS.md](REUSABLE_ACTIONS.md) - Creating modular actions

5. **Reference:** [DEPLOYMENT.md](DEPLOYMENT.md) + [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
   - Use as reference when needed

#### Focus Areas:

- [ ] Understand the composite action pattern
- [ ] Study the Docker caching strategy
- [ ] Review the automatic rollback mechanism
- [ ] Explore the version management system
- [ ] Examine the test automation setup

---

### Advanced Path: Production Deployment Experience

**Time Investment:** ~1-2 hours

You're already deploying to production and want to see alternative patterns, optimize your pipeline, or adapt this approach to your needs.

#### Recommended Reading Order:

1. **Quick Scan:** [PIPELINE_SUMMARY.md](PIPELINE_SUMMARY.md)
   - High-level overview of the entire pipeline
   - **Goal:** Map this to your existing knowledge

2. **Architecture Deep Dive:** [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)
   - Design decisions and trade-offs
   - Compare to your current approach
   - **Goal:** Identify patterns you can adopt

3. **Technical Details:**
   - [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Registry caching (5-10x speedup)
   - [REUSABLE_ACTIONS.md](REUSABLE_ACTIONS.md) - DRY principle for workflows
   - [VERSIONING.md](VERSIONING.md) - Automatic semantic versioning

4. **Workflow Code Review:**
   - [.github/workflows/ci.yml](.github/workflows/ci.yml)
   - [.github/workflows/deploy-staging.yml](.github/workflows/deploy-staging.yml)
   - [.github/workflows/deploy-production.yml](.github/workflows/deploy-production.yml)
   - **Goal:** Understand implementation details

5. **Reusable Actions:** [.github/actions/](.github/actions/)
   - Study the modular composite actions
   - Consider adapting for your projects

#### What You'll Learn:

- ✅ Registry-based Docker caching (vs layer caching)
- ✅ Composite actions for workflow reusability
- ✅ Automatic health checks with rollback
- ✅ Extended monitoring patterns
- ✅ Git-based version automation
- ✅ Test automation at multiple levels

---

## Core Concepts You'll Learn

### 1. Continuous Integration (CI)

**What it is:** Automatically building and testing code on every commit.

**What you'll learn:**
- Running SwiftLint for code quality
- Executing unit tests automatically
- Building Docker images in CI
- Running integration tests
- Security scanning with Trivy

**Files to study:**
- [.github/workflows/ci.yml](.github/workflows/ci.yml)

---

### 2. Continuous Deployment (CD)

**What it is:** Automatically deploying tested code to environments.

**What you'll learn:**
- Staging deployment (automatic on main branch)
- Production deployment (manual with approvals)
- Blue-green deployment pattern
- Database backup before deployment
- Health check verification

**Files to study:**
- [.github/workflows/deploy-staging.yml](.github/workflows/deploy-staging.yml)
- [.github/workflows/deploy-production.yml](.github/workflows/deploy-production.yml)

---

### 3. Docker Containerization

**What it is:** Packaging your application with all dependencies.

**What you'll learn:**
- Multi-stage Docker builds for Swift
- Build caching strategies
- Non-root user security
- Health check configuration
- Registry-based caching for speed

**Files to study:**
- [Dockerfile](Dockerfile)
- [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md)

---

### 4. Version Management

**What it is:** Tracking releases with semantic versioning.

**What you'll learn:**
- Automatic build number increment
- Manual version bumps (major, minor, patch)
- Git tagging for releases
- GitHub release creation

**Files to study:**
- [VERSIONING.md](VERSIONING.md)
- [scripts/version-manager.sh](scripts/version-manager.sh)

---

### 5. Deployment Safety

**What it is:** Mechanisms to prevent and recover from bad deployments.

**What you'll learn:**
- Health check endpoints
- Automatic rollback on failure
- Database backup before deployment
- Extended monitoring period
- Blue-green deployment pattern

**Files to study:**
- [scripts/deploy.sh](scripts/deploy.sh)
- [scripts/rollback.sh](scripts/rollback.sh)
- [scripts/health-check.sh](scripts/health-check.sh)

---

### 6. Testing Strategy

**What it is:** Multi-level testing to ensure quality.

**What you'll learn:**
- Unit tests with Swift Testing/XCTest
- Integration tests in Docker
- API endpoint testing
- Security vulnerability scanning

**Files to study:**
- [tests/api/api-tests.sh](tests/api/api-tests.sh)
- [todos-fluent/Tests/AppTests/](todos-fluent/Tests/AppTests/)

---

## Repository Overview

### Key Directories

```
swift-on-server-one-click-deployment/
├── .github/
│   ├── workflows/          # CI/CD pipeline definitions
│   └── actions/            # Reusable composite actions
├── todos-fluent/           # Swift application code
│   ├── Sources/App/        # Application source
│   └── Tests/              # Unit tests
├── scripts/                # Deployment and utility scripts
├── tests/api/              # API integration tests
└── [Documentation files]   # What you're reading now!
```

### Documentation Map

| Document | Purpose | Audience |
|----------|---------|----------|
| [README.md](README.md) | Project overview & quick start | Everyone |
| [LEARNING_PATH.md](LEARNING_PATH.md) (this file) | Navigate the learning materials | Everyone |
| [GITHUB_ACTIONS_PRIMER.md](GITHUB_ACTIONS_PRIMER.md) | Introduction to GitHub Actions | Beginners |
| [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) | Why this CI/CD design? | All levels |
| [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md) | Step-by-step tutorial | Beginners/Intermediate |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Complete deployment guide | Intermediate/Advanced |
| [VERSIONING.md](VERSIONING.md) | Version management details | Intermediate/Advanced |
| [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) | Docker caching strategy | Advanced |
| [REUSABLE_ACTIONS.md](REUSABLE_ACTIONS.md) | Composite actions guide | Advanced |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues & solutions | All levels |
| [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) | Setup checklist | All levels |

---

## Next Steps

### For Talk Attendees

1. **Before the talk:** Read [README.md](README.md) and [GITHUB_ACTIONS_PRIMER.md](GITHUB_ACTIONS_PRIMER.md)
2. **During the talk:** Follow along with [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)
3. **After the talk:** Complete [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md) tutorial

### For Self-Learners

1. Choose your learning path above
2. Follow the recommended reading order
3. Complete the hands-on exercises
4. Adapt this approach to your own projects

### For Quick Reference

- **Need to deploy?** → [DEPLOYMENT.md](DEPLOYMENT.md)
- **Something broke?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Setting up your own?** → [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)
- **Understanding versions?** → [VERSIONING.md](VERSIONING.md)

---

## Getting Help

### Resources

- **Swift on Server:** https://www.swift.org/documentation/server/
- **Hummingbird Documentation:** https://docs.hummingbird.codes/
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Docker Documentation:** https://docs.docker.com/

### Community

- Swift Forums: https://forums.swift.org/c/server/
- Hummingbird Discord: (check framework docs for invite)

---

## Contributing

Found an issue or want to improve the documentation? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your improvements
4. Submit a pull request

---

**Ready to start?** Pick your [learning path](#learning-paths-by-experience-level) and dive in!
