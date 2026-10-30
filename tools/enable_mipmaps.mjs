// Surface textures need mip chains to prevent sparkling floors at grazing angles.
import fs from 'node:fs';
import path from 'node:path';
const root = path.resolve('assets/textures');
let changed = 0;
function visit(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) visit(file);
    else if (/\.(png|jpg|webp)\.import$/.test(entry.name)) {
      const before = fs.readFileSync(file, 'utf8');
      const after = before.replace('mipmaps/generate=false', 'mipmaps/generate=true');
      if (after !== before) { fs.writeFileSync(file, after); changed++; }
    }
  }
}
visit(root);
console.log(`Enabled mipmaps on ${changed} texture imports.`);
