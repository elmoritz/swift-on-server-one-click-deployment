# Documentation Site

This directory contains the GitHub Pages documentation site built with Jekyll and Just the Docs theme.

## Quick Links

- **Live Site:** https://elmoritz.github.io/swift-on-server-one-click-deployment/ (once enabled)
- **Setup Instructions:** See [GITHUB_PAGES_SETUP.md](../GITHUB_PAGES_SETUP.md)

## Structure

```
docs/
├── _config.yml              # Jekyll configuration
├── Gemfile                  # Ruby dependencies
├── index.md                 # Home page
├── learning-path.md         # Learning path guide
├── first-deployment.md      # Tutorial
├── github-actions-primer.md # GitHub Actions intro
├── pipeline-architecture.md # Architecture guide
└── troubleshooting.md       # Troubleshooting guide
```

## Testing Locally

```bash
cd docs
bundle install
bundle exec jekyll serve
open http://localhost:4000/swift-on-server-one-click-deployment/
```

## Updating Content

1. Edit markdown files in this directory
2. Commit and push to GitHub
3. GitHub Pages automatically rebuilds (1-2 minutes)

## Adding New Pages

Create a new `.md` file with front matter:

```markdown
---
layout: default
title: My Page
nav_order: 7
description: "Page description"
permalink: /my-page
---

# My Page

Content here...
```

See [GITHUB_PAGES_SETUP.md](../GITHUB_PAGES_SETUP.md) for complete documentation.
