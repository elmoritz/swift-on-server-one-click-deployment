---
layout: home
title: Home
nav_order: 1
description: "Learn how to build production-ready CI/CD pipelines for Swift server applications"
permalink: /
---

# Swift Server Deployment Pipeline
{: .fs-9 }

Learn how to build production-ready CI/CD pipelines for Swift server applications.
{: .fs-6 .fw-300 }

[Get Started](#getting-started){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View on GitHub](https://github.com/elmoritz/swift-on-server-one-click-deployment){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## Welcome!

This site provides comprehensive, hands-on documentation for **Swift developers** who want to learn how to deploy server-side applications to production using modern CI/CD practices.

### What Makes This Different?

- **📚 Educational Focus:** Not just "how" but "why" - understand the decisions behind the architecture
- **🎯 Swift-Specific:** Tailored for Swift developers, not generic DevOps guides
- **🚀 Production-Ready:** Real patterns used in production, not toy examples
- **🛠️ Hands-On:** Follow along with working code and step-by-step tutorials

---

## What You'll Learn

By exploring this documentation, you'll master:

{: .note }
> All concepts are explained with Swift server examples using Hummingbird framework.

### Core Skills

- **Continuous Integration (CI)**
  Automated testing, building, and validation on every commit

- **Continuous Deployment (CD)**
  Automated deployment to staging and production environments

- **Docker Containerization**
  Package Swift applications for consistent deployment across environments

- **Version Management**
  Semantic versioning with automatic build number tracking

- **Deployment Safety**
  Health checks, automatic rollback, and blue-green deployments

- **Testing Strategies**
  Unit tests, integration tests, and API testing at multiple levels

- **DevOps Best Practices**
  Code quality checks, security scanning, monitoring, and observability

---

## Getting Started

Choose your path based on your experience level:

### 🌱 New to CI/CD?

Start with the **[Learning Path](learning-path)** to find documentation suited to your experience level.

Then follow the **[First Deployment Tutorial](first-deployment)** - a hands-on walkthrough that takes you from code commit to production deployment.

**Estimated time:** 2-4 hours

---

### 🌿 Some Deployment Experience?

Jump to **[Pipeline Architecture](pipeline-architecture)** to understand the design decisions behind this pipeline.

Explore **[GitHub Actions Primer](github-actions-primer)** if you want to understand the automation layer.

**Estimated time:** 1-2 hours

---

### 🌲 Production Experience?

Review the **[Pipeline Architecture](pipeline-architecture)** for design patterns you might adopt.

Check out **[Build Optimization](build-optimization)** for Docker registry-based caching (5-10× speedup).

Study the **[Reusable Actions](reusable-actions)** to see how to create modular GitHub Actions.

**Estimated time:** 30-60 minutes

---

## The Demo Application

This repository includes a **simple todo API** built with Hummingbird framework:

- ✅ RESTful CRUD endpoints
- ✅ SQLite database with Fluent ORM
- ✅ Health check monitoring
- ✅ Docker containerization
- ✅ Production configuration

{: .warning }
The application is intentionally simple - **the focus is on the deployment pipeline**, not application features.

---

## The Pipeline

Here's what happens when you push code:

```
Your Commit
    ↓
┌──────────────────────────────────┐
│  CI: Quality Checks (5 min)     │
│  • SwiftLint                     │
│  • Unit tests                    │
│  • Docker build                  │
│  • Integration tests             │
│  • Security scanning             │
└──────────────────────────────────┘
    ↓
┌──────────────────────────────────┐
│  Staging: Auto Deploy (5 min)   │
│  • Deploy to staging             │
│  • Health checks                 │
│  • API tests                     │
│  • 5-min monitoring              │
└──────────────────────────────────┘
    ↓
   Manual Approval
    ↓
┌──────────────────────────────────┐
│  Production: Safe Deploy (20min) │
│  • Version bump                  │
│  • Database backup               │
│  • Blue-green deployment         │
│  • 15-min monitoring             │
│  • Auto-rollback on failure      │
└──────────────────────────────────┘
```

**Key Features:**
- ⚡ **Fast:** 30-90 second builds with registry caching
- 🛡️ **Safe:** Automatic rollback if health checks fail
- 📊 **Visible:** Every step logged in GitHub Actions
- 🎯 **Reliable:** Tested in staging before production

Learn more in [Pipeline Architecture](pipeline-architecture).

---

## For Talk Attendees

{: .note }
> **Welcome!** This documentation accompanies the Swift server deployment talk.

### Before the Talk

- ⭐ Star the [GitHub repository](https://github.com/elmoritz/swift-on-server-one-click-deployment)
- 📖 Skim the [Learning Path](learning-path)
- 💻 Optional: Fork and try running locally

### During the Talk

- 📝 Follow along with [Pipeline Architecture](pipeline-architecture)
- 👀 Watch the live deployment demo
- 🙋 Ask questions!

### After the Talk

- 🚀 Complete the [First Deployment](first-deployment) tutorial
- 🔧 Adapt this pipeline to your own projects
- 💬 Share feedback via [GitHub Issues](https://github.com/elmoritz/swift-on-server-one-click-deployment/issues)

---

## Documentation Overview

| Document | Purpose | Best For |
|----------|---------|----------|
| [Learning Path](learning-path) | Choose your path by experience level | Everyone - start here! |
| [First Deployment](first-deployment) | Hands-on step-by-step tutorial | Beginners |
| [GitHub Actions Primer](github-actions-primer) | Intro to GitHub Actions | New to CI/CD |
| [Pipeline Architecture](pipeline-architecture) | Design decisions explained | All levels |
| [Troubleshooting](troubleshooting) | Common issues & solutions | When stuck |

---

## Quick Links

- 🔗 [GitHub Repository](https://github.com/elmoritz/swift-on-server-one-click-deployment)
- 📖 [Full Documentation](https://github.com/elmoritz/swift-on-server-one-click-deployment#readme)
- 🐛 [Report Issues](https://github.com/elmoritz/swift-on-server-one-click-deployment/issues)
- ⭐ [Give a Star](https://github.com/elmoritz/swift-on-server-one-click-deployment)

---

## Technology Stack

- **Framework:** [Hummingbird 2.0](https://github.com/hummingbird-project/hummingbird)
- **Language:** Swift 5.9+
- **Database:** SQLite with [Fluent](https://github.com/vapor/fluent) ORM
- **Containerization:** Docker
- **CI/CD:** GitHub Actions
- **Testing:** XCTest + Shell scripts
- **Code Quality:** [SwiftLint](https://github.com/realm/SwiftLint)
- **Security:** [Trivy](https://github.com/aquasecurity/trivy)

---

{: .tip }
> **Ready to start?** Head to the [Learning Path](learning-path) to begin your journey!
