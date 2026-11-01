import fs from 'node:fs';
import path from 'node:path';
const folder = 'tools/downloads/revision13_candidates';
fs.mkdirSync(folder, {recursive:true});
const candidates = [
  ['woman_dress','zMyPlQXBzq'], ['woman_casual','jpKRgGDxhk'],
  ['woman_blouse','qJ2gsTUBHL'], ['woman_skirt','nIItLV9nxS'],
  ['man','HMnuH5geEG'], ['man_alternate','DgOCW9ZCRJ'],
  ['rabbit','RPZ9gxcFL3'], ['bunny','irZjWFARyl'],
  ['male_business','JFrLIKqvCH'], ['male_hoodie','gKLBoRsyKe'],
  ['female_suit','sOUciDsoVV']
];
const sources = await Promise.all(candidates.map(async ([name,id]) => {
  const saved=path.join(folder,name+'.glb');
  if(fs.existsSync(saved))return JSON.parse(fs.readFileSync(path.join(folder,'SOURCES.json'))).find(s=>s.name===name);
  const url = `https://poly.pizza/m/${id}`;
  const response = await fetch(url); if(!response.ok)throw Error(`${url}: ${response.status}`);
  const html = await response.text();
  fs.writeFileSync(path.join(folder,name+'.html'),html);
  const urls = [...new Set(html.match(/https:\/\/static\.poly\.pizza\/[a-zA-Z0-9_-]+\.glb/g))];
  if(!urls.length)throw Error(`No glb at ${url}`);
  const download = urls[0];
  const r = await fetch(download); if(!r.ok)throw Error(`${download}: ${r.status}`);
  const buffer = Buffer.from(await r.arrayBuffer());
  fs.writeFileSync(path.join(folder,name+'.glb'), buffer);
  const json = JSON.parse(buffer.subarray(20,20+buffer.readUInt32LE(12)));
  for(const image of json.images||[])if(image.uri && !image.uri.startsWith('data:')) {
    const ir=await fetch(new URL(image.uri,download)); if(!ir.ok)throw Error(`Texture ${image.uri}`);
    fs.writeFileSync(path.join(folder,path.basename(image.uri)), Buffer.from(await ir.arrayBuffer()));
  }
  const thumbnail = html.match(/<meta[^>]+(?:property|name)="og:image"[^>]+content="([^"]+)"/)?.[1];
  if(thumbnail) {
    const ir=await fetch(thumbnail);
    if(ir.ok)fs.writeFileSync(path.join(folder,name+'.png'),Buffer.from(await ir.arrayBuffer()));
  }
  const record={name,url,download,thumbnail,author:'Quaternius',license:name==='female_suit'?'CC-BY-3.0':'CC0-1.0',bytes:buffer.length};
  console.log(JSON.stringify({...record, meshes:json.meshes?.map(m=>m.name),materials:json.materials?.map(m=>m.name),bones:json.nodes?.filter(n=>n.name?.includes('Leg')).map(n=>n.name),animations:json.animations?.map(a=>a.name)}));
  return record;
}));
fs.writeFileSync(path.join(folder,'SOURCES.json'),JSON.stringify(sources,null,2)+'\n');
