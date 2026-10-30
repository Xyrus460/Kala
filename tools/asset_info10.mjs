import fs from 'node:fs';
for (const name of fs.readdirSync('assets/vendor/revision10').filter(n => n.endsWith('.glb'))) {
 const b=fs.readFileSync('assets/vendor/revision10/'+name);
 const j=JSON.parse(b.subarray(20,20+b.readUInt32LE(12)).toString());
 console.log(name, 'materials',j.materials?.map(m=>[m.name,m.pbrMetallicRoughness?.baseColorFactor]), 'nodes',j.nodes?.slice(0,4).map(n=>n.name));
}
