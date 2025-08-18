## Daily Phrases (for GitHub Pages)

- URL (after enabling Pages on the repo): `https://shinbeomsoo.github.io/damda/daily_phrases.json`
- Hosting: GitHub Pages → Source: Deploy from a branch → Branch: `main` → Folder: `/docs`

### Schema
Array of objects:

```json
{
  "id": 1,
  "en": "Could I get a cup of coffee?",
  "ko": "커피 한 잔 부탁드려요.",
  "tags": ["cafe", "polite"],
  "level": "A1"
}
```

### Updating content
1. Edit `docs/daily_phrases.json`
2. Commit and push to `main`
3. Wait ~30–120 seconds for Pages to refresh

### Notes
- `.nojekyll` prevents Jekyll processing on Pages
- Keep entries short and conversational for speaking practice


