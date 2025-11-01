# GitHub Pages Setup Instructions

This guide will help you enable GitHub Pages for your documentation site.

## Quick Setup (5 minutes)

### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click **Settings** (top menu)
3. In the left sidebar, click **Pages**
4. Under "Build and deployment":
   - **Source:** Select "Deploy from a branch"
   - **Branch:** Select `main` (or your default branch)
   - **Folder:** Select `/docs`
5. Click **Save**

### Step 2: Wait for Build

GitHub will automatically build your site. This takes 1-2 minutes.

- You'll see a message: "Your site is ready to be published at..."
- Once complete: "Your site is live at https://yourusername.github.io/repo-name/"

### Step 3: Visit Your Site

Your documentation will be available at:
```
https://elmoritz.github.io/swift-on-server-one-click-deployment/
```

That's it! 🎉

---

## Testing Locally (Optional)

Want to preview your site before publishing? Test it locally:

### Prerequisites

- Ruby 2.7+ (check with `ruby --version`)
- Bundler (install with `gem install bundler`)

### Setup

```bash
# Navigate to docs directory
cd docs

# Install dependencies
bundle install

# Run local server
bundle exec jekyll serve

# Open in browser
open http://localhost:4000/swift-on-server-one-click-deployment/
```

The site will auto-reload when you edit markdown files.

---

## Customization Options

### Change Theme Colors

Edit `docs/_config.yml`:

```yaml
# Light or dark theme
color_scheme: light  # or: dark

# Or create custom scheme in docs/_sass/color_schemes/
```

### Add Your Logo

1. Add image to `docs/assets/images/logo.png`
2. Update `docs/_config.yml`:
   ```yaml
   logo: "/assets/images/logo.png"
   ```

### Custom Domain (Optional)

Want to use `docs.yoursite.com` instead of `github.io`?

1. **Add CNAME file:**
   ```bash
   echo "docs.yoursite.com" > docs/CNAME
   ```

2. **Configure DNS** (at your domain provider):
   - Add CNAME record: `docs` → `yourusername.github.io`

3. **Enable in GitHub:**
   - Settings → Pages → Custom domain
   - Enter: `docs.yoursite.com`
   - Check "Enforce HTTPS"

---

## Updating Documentation

### Edit Existing Pages

1. Edit markdown files in `docs/` directory
2. Commit and push to GitHub
3. GitHub automatically rebuilds the site (1-2 minutes)

### Add New Pages

1. Create new markdown file in `docs/`:
   ```markdown
   ---
   layout: default
   title: My New Page
   nav_order: 7
   description: "Description for SEO"
   permalink: /my-new-page
   ---

   # My New Page

   Content here...
   ```

2. Commit and push

The page automatically appears in navigation!

---

## Navigation Structure

Pages appear in the sidebar based on `nav_order`:

```yaml
nav_order: 1  # Home
nav_order: 2  # Learning Path
nav_order: 3  # First Deployment
# ... etc
```

### Create Sections (Optional)

For grouped navigation:

```markdown
---
layout: default
title: Tutorials
nav_order: 3
has_children: true
---

# Tutorials

Overview page...
```

Then in child pages:

```markdown
---
layout: default
title: Tutorial 1
parent: Tutorials
nav_order: 1
---
```

---

## Troubleshooting

### "Page not found" after enabling

**Solution:** Wait 2-3 minutes for initial build, then hard refresh (Cmd+Shift+R).

---

### Site looks broken (no CSS)

**Cause:** `baseurl` mismatch in `_config.yml`

**Solution:** Ensure this matches your repo name:
```yaml
baseurl: "/swift-on-server-one-click-deployment"
```

---

### Local preview doesn't work

**Error:** `cannot load such file -- webrick`

**Solution:**
```bash
bundle add webrick
bundle exec jekyll serve
```

---

### Changes not appearing

**Cause:** Browser cache or build not complete

**Solutions:**
1. Wait 2-3 minutes after push
2. Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
3. Check build status: Actions tab → Pages build and deployment

---

### Build failing on GitHub

**Check build logs:**
1. Go to Actions tab
2. Click "pages build and deployment"
3. Look for error messages

**Common issues:**
- Invalid YAML front matter (check for proper `---` delimiters)
- Special characters in filenames
- Circular references in navigation

---

## Advanced Configuration

### Enable Dark Mode

Users can toggle between light/dark:

```yaml
# docs/_config.yml
color_scheme: dark  # Default to dark mode
```

Or create a toggle button (requires custom JS).

---

### Analytics (Optional)

Add Google Analytics:

```yaml
# docs/_config.yml
google_analytics: UA-XXXXXXXXX-X
```

Or use other analytics via custom `_includes/head_custom.html`.

---

### Custom CSS

Create `docs/_sass/custom/custom.scss`:

```scss
// Custom colors
$link-color: #0366d6;
$body-text-color: #24292e;

// Custom styles
.my-custom-class {
  color: red;
}
```

---

### Search Configuration

Customize search behavior in `_config.yml`:

```yaml
search:
  heading_level: 2        # Search h1 and h2 headings
  previews: 3             # Show 3 preview results
  preview_words_before: 5 # Context words before match
  preview_words_after: 10 # Context words after match
```

---

## Maintenance

### Update Theme

```bash
cd docs
bundle update just-the-docs
```

### Update Jekyll

```bash
bundle update jekyll
```

### Clean Build Cache

```bash
bundle exec jekyll clean
bundle exec jekyll build
```

---

## Resources

- **Just the Docs Documentation:** https://just-the-docs.com/
- **Jekyll Documentation:** https://jekyllrb.com/docs/
- **GitHub Pages Documentation:** https://docs.github.com/en/pages
- **Markdown Syntax:** https://www.markdownguide.org/

---

## Support

If you encounter issues:

1. Check the [Jekyll troubleshooting guide](https://jekyllrb.com/docs/troubleshooting/)
2. Review [Just the Docs documentation](https://just-the-docs.com/)
3. Check [GitHub Pages status](https://www.githubstatus.com/)
4. Open an issue in this repository

---

**Your documentation site is ready!** 🚀

Share the link with your talk attendees and enjoy having beautiful, searchable documentation!
