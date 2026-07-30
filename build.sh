#!/usr/bin/env bash
set -euo pipefail

ROOT=/Users/jackgreenberg/Desktop/rank-and-rent
S=$ROOT/David/clones/scripts
PROJ=$ROOT/mineral-rights/sellmineralrightsohio.com
REFHOST=suzlon-com
VOICE=$PROJ/site-voice.json
PAGES="home=https://www.suzlon.com/,about=https://www.suzlon.com/about-us/,contact=https://www.suzlon.com/contact-us/,index=https://www.suzlon.com/our-businesses/products/wind/,slug=https://www.suzlon.com/our-businesses/products/wind/5mw-bluesky-s175/"

CFG=$PROJ/home.config.json
MAP=$PROJ/relabel-map.json
CAP=$ROOT/David/clones/_captures/$REFHOST

[ -f "$CFG" ] || { echo "MISSING $CFG"; exit 1; }
[ -f "$MAP" ] || { echo "MISSING $MAP — author the relabel map per \$faithful-home"; exit 1; }

if [ ! -f "$CAP/public/home.html.ref" ]; then
  node "$S/faithful-home.mjs" --src "https://www.suzlon.com/" --pages "$PAGES" --dir "$CAP"
fi

mkdir -p "$PROJ/public" "$PROJ/qa-out"
cp "$CAP"/public/*.html.ref "$PROJ/public/"
cp "$CAP"/public/capture-manifest.json "$PROJ/public/"
cp "$PROJ/favicon.svg" "$PROJ/public/favicon.svg"
rm -rf "$PROJ/public/assets-f"
cp -R "$CAP/public/assets-f" "$PROJ/public/"
cp "$CAP"/qa-out/ref-*.png "$PROJ/qa-out/" 2>/dev/null || true

python3 "$S/normalize_content.py" "$PROJ" --voice "$VOICE"

python3 - "$PROJ" <<'PY'
import shutil, sys, os
p = sys.argv[1]
src, dst = os.path.join(p, "images"), os.path.join(p, "public/ours")
if os.path.isdir(src):
    shutil.copytree(src, dst, dirs_exist_ok=True)
PY

python3 "$S/relabel_engine.py" --config "$CFG" --map "$MAP" --voice "$VOICE"

find "$PROJ/public/assets-f/img" "$PROJ/public/assets-f/misc" -type f -delete 2>/dev/null || true
find "$PROJ/public" -type f \( -name '*.html' -o -name '*.html.ref' -o -name '*.css' \) -print0 \
  | xargs -0 perl -pi -e 's/\t/  /g; s/[ \t]+\r?\n/\n/g; s/\r\n/\n/g'
find "$PROJ/public/assets-f/js" -type f -name '*.js' -print0 \
  | xargs -0 perl -pi -e 's/[ \t]+\r?\n/\n/g; s/\r\n/\n/g'

python3 "$S/website_taste_fleet.py" --project "$PROJ"
python3 "$S/footer_maps.py" --project "$PROJ"
python3 "$S/footer_maps.py" --project "$PROJ" --check
python3 "$S/website_taste_fleet.py" --project "$PROJ" --check

python3 "$S/verify_site.py" "$PROJ" --map "$MAP" --json "$PROJ/qa-out/verify.json"
node "$S/qa_shots.mjs" "$PROJ"

if [ -f "$PROJ/inject-analytics.js" ]; then
  node "$PROJ/inject-analytics.js"
fi

echo "BUILD COMPLETE — gates green. Human QA: open $PROJ/qa-out/CONTACT-SHEET.html"
