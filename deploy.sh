#!/bin/bash
set -e

# ============================================================
# DEPLOYMENT-SKRIPT: Auditorenausbildung-Diskussion
# Subdomain: auditor-ausbildung.qm-guru.de
# Erstellt: 2026-01-15
# ============================================================

# --- KONFIGURATION (VOR BENUTZUNG ANPASSEN!) ---
GITHUB_USER="[dein-github-user]"        # z.B. "holgergrosser"
REPO_NAME="qmguru-auditor-ausbildung"
SUBDOMAIN="auditor-ausbildung"
DOMAIN="qm-guru.de"
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"

# Cloudflare Zone-ID für qm-guru.de
# Zu finden: https://dash.cloudflare.com → qm-guru.de → Overview → Zone ID
CF_TOKEN="${CLOUDFLARE_API_TOKEN}"
ZONE_QMGURU="DEINE_ZONE_ID_QMGURU"

# Netlify Token (aus: https://app.netlify.com/user/applications)
NETLIFY_TOKEN="${NETLIFY_AUTH_TOKEN}"
NETLIFY_SITE="${REPO_NAME}.netlify.app"

echo "🚀 Deployment: Auditorenausbildung-Diskussion"
echo "   Ziel: https://${FULL_DOMAIN}"
echo "=========================================="

# --- PHASE 1: Prüfen ob alle Dateien vorhanden sind ---
echo ""
echo "📁 [1/5] Dateien prüfen..."
MISSING=""
for FILE in index.html sitemap.xml robots.txt netlify.toml package.json vite.config.js _redirects; do
  if [ ! -f "$FILE" ]; then
    MISSING="${MISSING} ${FILE}"
    echo "  ❌ Fehlt: ${FILE}"
  else
    echo "  ✅ OK: ${FILE}"
  fi
done
if [ -n "$MISSING" ]; then
  echo ""
  echo "  ⛔ Fehlende Dateien! Deployment abgebrochen."
  exit 1
fi
echo "  ✅ Alle Dateien vorhanden."

# --- PHASE 2: GitHub Repository ---
echo ""
echo "📦 [2/5] GitHub Repository..."
if [ ! -d ".git" ]; then
  git init
  git add .
  git commit -m "Initial: Fachdiskussion Auditorenausbildung – auditor-ausbildung.qm-guru.de"
  gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push
  echo "  ✅ Repo erstellt: https://github.com/${GITHUB_USER}/${REPO_NAME}"
else
  echo "  ℹ️  Git-Repo existiert bereits — Update pushen..."
  git add .
  git commit -m "Update: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null || echo "  ℹ️  Keine Änderungen."
  git push 2>/dev/null || {
    git remote set-url origin "https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
    git push -u origin main --force
  }
  echo "  ✅ Update gepusht."
fi

# --- PHASE 3: Netlify Build & Deploy ---
echo ""
echo "🌐 [3/5] Netlify Deploy..."
npm install
npm run build

if netlify status 2>/dev/null | grep -q "netlify.app"; then
  echo "  ℹ️  Netlify-Site bereits verknüpft — deploye Update..."
  netlify deploy --prod --dir=dist
else
  echo "  ℹ️  Neue Netlify-Site erstellen..."
  netlify deploy --prod --dir=dist --site="${REPO_NAME}" 2>/dev/null || {
    echo "  ⚠️  Manuelle Verknüpfung nötig:"
    echo "      → https://app.netlify.com/start → Import from Git → ${REPO_NAME}"
    echo "      → Danach erneut: netlify deploy --prod --dir=dist"
  }
fi
echo "  ✅ Netlify: https://${NETLIFY_SITE}"

# --- PHASE 4: Custom Domain in Netlify ---
echo ""
echo "🔗 [4/5] Custom Domain: ${FULL_DOMAIN}..."
echo "  ⚠️  MANUELL ERFORDERLICH:"
echo "      1. https://app.netlify.com → ${REPO_NAME}"
echo "      2. Project configuration → Domain management → Add custom domain"
echo "      3. Domain eingeben: ${FULL_DOMAIN}"
echo "      4. 'Verify' → 'Yes, add domain'"
echo "      5. CNAME-Wert notieren: ${NETLIFY_SITE}"

# --- PHASE 5: Cloudflare DNS ---
echo ""
echo "☁️  [5/5] Cloudflare DNS..."

if [ -z "$CF_TOKEN" ] || [ "$ZONE_QMGURU" = "DEINE_ZONE_ID_QMGURU" ]; then
  echo "  ⚠️  Cloudflare nicht konfiguriert — MANUELL:"
  echo "      1. https://dash.cloudflare.com → qm-guru.de → DNS"
  echo "      2. Add record:"
  echo "         Type:   CNAME"
  echo "         Name:   ${SUBDOMAIN}"
  echo "         Target: ${NETLIFY_SITE}"
  echo "         Proxy:  DNS only (graue Wolke!)"
  echo "         TTL:    Auto"
  echo "      3. SSL/TLS → Overview → Modus: Full (NICHT Full strict!)"
else
  CF_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_QMGURU}/dns_records" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"type\": \"CNAME\",
        \"name\": \"${SUBDOMAIN}\",
        \"content\": \"${NETLIFY_SITE}\",
        \"proxied\": false,
        \"ttl\": 1,
        \"comment\": \"Fachdiskussion Auditorenausbildung\"
    }")

  if echo "$CF_RESPONSE" | grep -q '"success":true'; then
    echo "  ✅ DNS: ${FULL_DOMAIN} → ${NETLIFY_SITE}"
  else
    echo "  ⚠️  DNS-Fehler oder Eintrag existiert bereits:"
    echo "$CF_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ', d.get('errors', ''))" 2>/dev/null || echo "$CF_RESPONSE"
  fi
fi

# --- ABSCHLUSS ---
echo ""
echo "=========================================="
echo "🎉 Deployment-Prozess abgeschlossen!"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "  1. Netlify Custom Domain manuell hinzufügen (siehe oben)"
echo "  2. Cloudflare: SSL-Modus → 'Full' prüfen (nicht 'Full strict'!)"
echo "  3. DNS-Propagation prüfen (5–30 Min):"
echo "     dig ${FULL_DOMAIN} CNAME"
echo "     oder: https://www.whatsmydns.net/#CNAME/${FULL_DOMAIN}"
echo "  4. SSL-Zertifikat prüfen (Netlify → HTTPS → Renew certificate)"
echo "  5. Google Search Console:"
echo "     Property: https://${FULL_DOMAIN}"
echo "     Sitemap:  https://${FULL_DOMAIN}/sitemap.xml"
echo ""
echo "🌍 Ziel-URL: https://${FULL_DOMAIN}"
echo ""
