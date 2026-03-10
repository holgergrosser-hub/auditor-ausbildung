# Deployment-Anleitung: auditor-ausbildung.qm-guru.de

## Übersicht

| | |
|---|---|
| **Seite** | Fachdiskussion Auditorenausbildung |
| **Subdomain** | `auditor-ausbildung.qm-guru.de` |
| **GitHub Repo** | `qmguru-auditor-ausbildung` |
| **Netlify Site** | `qmguru-auditor-ausbildung.netlify.app` |
| **Marke** | QM-Guru.de |

---

## Voraussetzungen (einmalig)

```bash
# GitHub CLI installieren
brew install gh           # macOS
# winget install GitHub.cli  (Windows)
# sudo apt install gh        (Linux)

# Netlify CLI installieren
npm install -g netlify-cli

# Einloggen
gh auth login
netlify login
```

**Cloudflare-Token erstellen:**
1. https://dash.cloudflare.com/profile/api-tokens
2. "Create Token" → Template: "Edit zone DNS"
3. Permissions: Zone → DNS → Edit
4. Zone Resources: qm-guru.de auswählen
5. Token als Umgebungsvariable speichern:

```bash
echo 'export CLOUDFLARE_API_TOKEN="dein-token"' >> ~/.zshrc
echo 'export NETLIFY_AUTH_TOKEN="dein-netlify-token"' >> ~/.zshrc
source ~/.zshrc
```

---

## PHASE 1: Dateien vorbereiten

Dateistruktur (vollständig):
```
qmguru-auditor-ausbildung/
├── index.html          ← Landingpage (SEO-optimiert)
├── sitemap.xml         ← Sitemap für Google
├── robots.txt          ← Crawler-Steuerung
├── netlify.toml        ← Build-Konfiguration
├── package.json        ← npm/vite
├── vite.config.js      ← Build-Tool (esbuild!)
├── _redirects          ← HTTPS-Force
├── deploy.sh           ← Automatisierungs-Skript
├── public/
│   └── images/
│       ├── holger-grosser.webp  ← PFLICHT! Foto von Holger
│       └── grosser-logo-v1.svg  ← QM-Guru Logo
└── DEPLOYMENT.md       ← Diese Anleitung
```

**⚠️ WICHTIG: Bilder kopieren!**
```bash
# Bilder aus dem bestehenden Projekt kopieren
cp /pfad/zu/holger-grosser.webp public/images/
cp /pfad/zu/grosser-logo-v1.svg public/images/
```

---

## PHASE 2: GitHub Repository erstellen

**Automatisch (empfohlen):**
```bash
cd qmguru-auditor-ausbildung
git init
git add .
git commit -m "Initial: Fachdiskussion Auditorenausbildung – auditor-ausbildung.qm-guru.de"
git branch -M main
gh repo create qmguru-auditor-ausbildung --public --source=. --remote=origin --push
```

**Manuell:**
1. https://github.com/new
2. Name: `qmguru-auditor-ausbildung`
3. Visibility: Public
4. KEIN README anfügen
5. "Create repository"
6. Terminal-Befehle aus der GitHub-Seite kopieren und ausführen

---

## PHASE 3: Netlify Site erstellen

**Option A — Automatisch mit CLI:**
```bash
cd qmguru-auditor-ausbildung
npm install
npm run build        # Prüft ob Build funktioniert

netlify deploy --prod --dir=dist
# → "Create & configure a new site" wählen
# → Team auswählen
# → Site-Name: qmguru-auditor-ausbildung
```

**Option B — Manuell über UI:**
1. https://app.netlify.com/start
2. "Import from Git" → GitHub → `qmguru-auditor-ausbildung`
3. Build-Settings (werden aus netlify.toml gelesen):
   - Build command: `npm install && npm run build`
   - Publish directory: `dist`
4. "Deploy site" klicken
5. Site-Name ändern: Project configuration → General → Change project name
   - Neuer Name: `qmguru-auditor-ausbildung`

**Custom Domain in Netlify hinzufügen:**
1. Project configuration → Domain management → "Add custom domain"
2. Eingeben: `auditor-ausbildung.qm-guru.de`
3. "Verify" → "Yes, add domain"
4. Netlify zeigt den CNAME-Wert an (= `qmguru-auditor-ausbildung.netlify.app`)

---

## PHASE 4: Cloudflare DNS einrichten

**MANUELL (Cloudflare Dashboard):**
1. https://dash.cloudflare.com
2. Domain: **qm-guru.de** auswählen
3. DNS → Records → "Add record"
4. Eintrag:
   ```
   Type:    CNAME
   Name:    auditor-ausbildung
   Target:  qmguru-auditor-ausbildung.netlify.app
   Proxy:   DNS only (GRAUE WOLKE — nicht orange!)
   TTL:     Auto
   ```
5. "Save"
6. SSL/TLS → Overview → Modus auf **"Full"** setzen (NICHT "Full strict"!)

**AUTOMATISCH (API):**
```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID_QMGURU/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "CNAME",
    "name": "auditor-ausbildung",
    "content": "qmguru-auditor-ausbildung.netlify.app",
    "proxied": false,
    "ttl": 1,
    "comment": "Fachdiskussion Auditorenausbildung"
  }'
```

**Zone-ID finden:**
Cloudflare Dashboard → qm-guru.de → Overview → rechte Seite → "Zone ID"

---

## PHASE 5: Verifizierung & SSL

**DNS-Propagation prüfen (5–30 Min):**
```bash
dig auditor-ausbildung.qm-guru.de CNAME
# Erwartetes Ergebnis: qmguru-auditor-ausbildung.netlify.app

# Online-Tool:
# https://www.whatsmydns.net/#CNAME/auditor-ausbildung.qm-guru.de
```

**Netlify SSL prüfen:**
- Project configuration → Domain management → HTTPS
- "Waiting for DNS propagation" → 10–30 Min warten
- Falls nötig: "Renew certificate" klicken

**Finale Prüfung:**
```bash
curl -I https://auditor-ausbildung.qm-guru.de
# Erwartete Antwort: HTTP/2 200
```

---

## PHASE 6: Google Search Console

1. https://search.google.com/search-console
2. "Property hinzufügen" → URL-Präfix: `https://auditor-ausbildung.qm-guru.de`
3. Verifizierung über HTML-Tag (in `<head>` einfügen) oder DNS
4. Sitemap einreichen:
   - Sitemaps → `https://auditor-ausbildung.qm-guru.de/sitemap.xml`
   - "Einreichen"

---

## Troubleshooting

| Problem | Ursache | Lösung |
|---------|---------|--------|
| `vite: not found` | npm install vergessen | `command = "npm install && npm run build"` |
| `terser not found` | Falsche vite.config | `minify: 'esbuild'` verwenden |
| Redirect-Loop | Cloudflare SSL falsch | SSL-Modus → "Full" (nicht "Full strict") |
| SSL-Fehler | Zu früh geprüft | 10–30 Min warten, dann "Renew certificate" |
| DNS nicht propagiert | DNS-Propagation | Bis zu 24h warten, `dig` prüfen |
| Bilder fehlen | Pfad falsch | `/public/images/` verwenden, nicht `/images/` |

---

## Deployment-Zusammenfassung

| | |
|---|---|
| **Seite live unter** | https://auditor-ausbildung.qm-guru.de |
| **GitHub** | https://github.com/[USER]/qmguru-auditor-ausbildung |
| **Netlify** | https://qmguru-auditor-ausbildung.netlify.app |
| **Cloudflare CNAME** | `auditor-ausbildung` → `qmguru-auditor-ausbildung.netlify.app` |
| **SSL-Modus** | Full (nicht Full strict!) |
| **Proxy-Status** | DNS only (graue Wolke) |
| **Sitemap** | https://auditor-ausbildung.qm-guru.de/sitemap.xml |

### Cloudflare DNS-Record (zum Kopieren):
```
CNAME  auditor-ausbildung  →  qmguru-auditor-ausbildung.netlify.app  (DNS only)
```

---

## Schnell-Deployment (deploy.sh)

```bash
# 1. Zone-ID in deploy.sh eintragen (ZONE_QMGURU=...)
# 2. GitHub-User eintragen (GITHUB_USER=...)
# 3. Umgebungsvariablen setzen:
export CLOUDFLARE_API_TOKEN="..."
export NETLIFY_AUTH_TOKEN="..."

# 4. Skript ausführen:
chmod +x deploy.sh
./deploy.sh
```

---

*Erstellt: 2026-01-15 · QM-Guru.de · Holger Grosser*
