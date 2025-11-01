---
layout: default
title: Quick Start Checklist
nav_order: 7
description: "Get your documentation site live in 5 minutes"
permalink: /quick-start-checklist
---

# Quick Start Checklist
{: .no_toc }

Get your documentation site live in 5 minutes!
{: .fs-6 .fw-300 }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Enable GitHub Pages

### Step 1: Go to Repository Settings

1. Navigate to your repository on GitHub
2. Click **Settings** in the top menu
3. Scroll down and click **Pages** in the left sidebar

### Step 2: Configure Source

Under "Build and deployment":

- **Source:** Deploy from a branch
- **Branch:** `main` (or your default branch)
- **Folder:** `/docs`
- Click **Save**

### Step 3: Wait for Build

⏱️ **Wait 1-2 minutes** for GitHub to build your site.

You'll see: "Your site is live at https://elmoritz.github.io/swift-on-server-one-click-deployment/"

### Step 4: Visit Your Site

🎉 **Done!** Your documentation is now live.

Visit: `https://elmoritz.github.io/swift-on-server-one-click-deployment/`

---

## Before Your Talk

### Checklist

- [ ] Enable GitHub Pages (done above)
- [ ] Visit the live site to verify everything works
- [ ] Test the search functionality
- [ ] Check site on mobile device
- [ ] Add URL to your talk slides
- [ ] Test all internal links work
- [ ] Share URL with attendees in advance (optional)

### Add URL to Talk Materials

**In your slides:**
```
📖 Documentation: https://elmoritz.github.io/swift-on-server-one-click-deployment/
```

**QR Code (optional):**
Generate a QR code at: https://www.qr-code-generator.com/

---

## During Your Talk

### Quick Reference

Point attendees to these pages:

- **Main Site:** Your GitHub Pages URL
- **Learning Path:** `/learning-path`
- **Architecture:** `/pipeline-architecture`
- **Tutorial:** `/first-deployment`

### Live Demo

Follow [First Deployment](first-deployment) for live demo steps.

---

## After Your Talk

### Share Everywhere

- [ ] Tweet the documentation URL
- [ ] Post to Swift forums
- [ ] Share on Reddit (/r/swift)
- [ ] Swift Server Discord
- [ ] LinkedIn post

### Gather Feedback

- [ ] Add link in talk description asking for feedback
- [ ] Monitor GitHub Issues for questions
- [ ] Update documentation based on common questions

---

## Troubleshooting

### Site not loading?

1. Wait 2-3 minutes after enabling (first build takes time)
2. Hard refresh: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)
3. Check: Settings → Pages → "Your site is live at..."

### Pages show 404?

1. Verify `/docs` folder is selected (not root)
2. Check that `baseurl` in `_config.yml` matches your repo name
3. Wait for build to complete (check Actions tab)

### CSS/styling broken?

1. Verify `baseurl` in `docs/_config.yml` is correct:
   ```yaml
   baseurl: "/swift-on-server-one-click-deployment"
   ```
2. Hard refresh browser

### Still stuck?

See [GITHUB_PAGES_SETUP.md](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/GITHUB_PAGES_SETUP.md) for detailed troubleshooting.

---

## Optional: Custom Domain

Want `docs.yoursite.com` instead of `.github.io`?

### Quick Setup

1. Add `docs/CNAME` file:
   ```bash
   echo "docs.yoursite.com" > docs/CNAME
   ```

2. Configure DNS (at your domain provider):
   - Type: `CNAME`
   - Name: `docs`
   - Value: `elmoritz.github.io`

3. Enable in GitHub:
   - Settings → Pages → Custom domain
   - Enter: `docs.yoursite.com`
   - Check "Enforce HTTPS"

See [GITHUB_PAGES_SETUP.md](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/GITHUB_PAGES_SETUP.md#custom-domain-optional) for details.

---

## Need Help?

- 📖 [Full Setup Guide](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/GITHUB_PAGES_SETUP.md)
- 🐛 [GitHub Issues](https://github.com/elmoritz/swift-on-server-one-click-deployment/issues)
- 💬 [GitHub Pages Docs](https://docs.github.com/en/pages)

---

**You're all set!** Good luck with your talk! 🎉
