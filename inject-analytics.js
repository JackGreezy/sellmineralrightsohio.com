#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const analytics = `
<script>
  window.va = window.va || function () { (window.vaq = window.vaq || []).push(arguments); };
</script>
<script defer src="/_vercel/insights/script.js"></script>`;

function htmlFiles(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const file = path.join(dir, name);
    const stat = fs.statSync(file);
    if (stat.isDirectory()) htmlFiles(file, out);
    else if (name.endsWith(".html") && !name.endsWith(".ref")) out.push(file);
  }
  return out;
}

for (const file of htmlFiles(path.join(__dirname, "public"))) {
  let source = fs.readFileSync(file, "utf8");
  if (source.includes("/_vercel/insights/script.js") || !/<\/body>/i.test(source)) continue;
  source = source.replace(/<\/body>/i, `${analytics}\n</body>`);
  fs.writeFileSync(file, source);
}
