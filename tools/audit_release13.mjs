import fs from 'node:fs';
import crypto from 'node:crypto';
const read=p=>fs.readFileSync(p,'utf8').replace(/^\uFEFF/,'');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const suites={};let checks=0;
for(const id of ['integration','layout','story','claw','revision04','revision05','revision06','revision07','revision08','revision09','revision10','revision11','revision12','revision13']) {
 const log=`docs/${id}_latest_console.log`,s=read(log),m=s.match(/KALA \w+: (\d+) checks, (\d+) failures/);
 if(!m || +m[2] || /SCRIPT ERROR|ERROR:|FAIL:|were leaked at exit/.test(s))throw Error(`Suite failed: ${log}`);
 suites[id]={checks:+m[1],failures:0,log};checks+=+m[1];
}
const rooms=['home','schoolyard','neighborhood','school','street','loading','relay','pursuit','production','office','ritual','corridor','daisy','hallucination'];
const knownDiagnostics=[],standalone={};
const exits=JSON.parse(read('docs/standalone13_exits.json'));
if(exits.length!==2 || exits.some(x=>x.exit_code!==0))throw Error('Standalone process did not exit cleanly');
for(const kind of ['forward','compatibility']) {
 const stdout=read(`docs/exe_${kind}_13_stdout.log`),stderr=read(`docs/exe_${kind}_13_stderr.log`);
 if(!stdout.includes('SMOKE BUILD: 0.13.0'))throw Error('Wrong standalone version: '+kind);
 let diagnostics=stderr;
 if(kind==='compatibility') {
  const pattern=/ERROR: Texture with GL ID of \d+: leaked 349524 bytes\.\r?\n\s+at: ~Utilities \(drivers\/gles3\/storage\/utilities\.cpp:82\)\r?\n/g;
  const matches=stderr.match(pattern)||[];
  if(matches.length===2){knownDiagnostics.push({renderer:kind,stage:'process shutdown',textures:2,bytes:699048,log:`docs/exe_${kind}_13_stderr.log`,status:'same shutdown diagnostic as versions 0.11 and 0.12; all 14 rooms loaded and process exited 0'});diagnostics=stderr.replace(pattern,'');}
 }
 if(rooms.some(id=>!stdout.includes(`SMOKE ROOM OK: ${id} `)) || /SCRIPT ERROR|ERROR:|were leaked at exit/.test(stdout+diagnostics))throw Error('Standalone failed: '+kind);
 if(!stdout.includes(kind==='forward'?'Forward+':'Compatibility'))throw Error('Renderer not confirmed: '+kind);
 standalone[kind]={exit_code:0,rooms_loaded:14,stdout:`docs/exe_${kind}_13_stdout.log`,stderr:`docs/exe_${kind}_13_stderr.log`};
}
const pack=fs.readFileSync('KALA.pck');
if(pack.toString('ascii',0,4)!=='GDPC'||pack.readUInt32LE(4)!==4)throw Error('Unexpected package header');
const base=Number(pack.readBigUInt64LE(24)),directory=Number(pack.readBigUInt64LE(32));let p=directory;
const count=pack.readUInt32LE(p);p+=4;const paths=[];
for(let i=0;i<count;i++) {
 const n=pack.readUInt32LE(p);p+=4;const name=pack.toString('utf8',p,p+n).replace(/\0+$/,'');p+=n;
 const offset=base+Number(pack.readBigUInt64LE(p));p+=8;const size=Number(pack.readBigUInt64LE(p));p+=8+16+4;
 if(offset<base||offset+size>directory)throw Error('Invalid packed file: '+name);paths.push(name);
}
if(paths.some(p=>/^(docs|tests|tools|backups|\.release_smoke)\//.test(p)||/\.(html|js|mjs)$/i.test(p)))throw Error('Development files packaged');
for(const file of ['scripts/systems/factory_route.gd','scripts/systems/mascot_model.gd','scripts/systems/student_model.gd','scripts/player/player.gd','assets/vendor/revision13/pengawas.glb','assets/vendor/revision13/female_suit.glb','assets/vendor/revision13/woman_blouse.glb','assets/vendor/revision13/woman_skirt.glb','assets/vendor/revision13/male_business.glb','assets/vendor/revision13/male_hoodie.glb','assets/vendor/revision13/ATTRIBUTION.txt']) {
 if(!paths.includes(file)&&!paths.includes(file+'.remap')&&!(file.endsWith('.glb')&&paths.includes(file+'.import')))throw Error('Missing resource '+file);
}
for(const item of JSON.parse(read('assets/vendor/revision13/SOURCES.json'))) {
 const source=`assets/vendor/revision13/${item.name}.glb`;
 if(fs.statSync(source).size!==item.bytes)throw Error('Vendor size mismatch: '+source);
}
const files=['KALA.exe','KALA.pck','THIRD_PARTY_NOTICES.txt'].map(file=>({file,bytes:fs.statSync(file).size,sha256:hash(file)}));
const screenshots=['characters','ratna','mascot','shower','classroom','route_entrance','gallery','control','route_power','claw'].map(label=>{
 const file=`docs/screenshots/${label}_13.png`;if(!fs.existsSync(file))throw Error('Missing render '+file);return {file,sha256:hash(file)};
});
const report={version:'0.13.0',verified_utc:new Date().toISOString(),checks,failures:0,suites,standalone,packed_files:count,known_diagnostics:knownDiagnostics,files,screenshots,limitations:['Automated gameplay routes and engine renders checked; a full manual playthrough to every ending was not performed.']};
fs.writeFileSync('docs/validation_13.json',JSON.stringify(report,null,2)+'\n');
console.log(`KALA 0.13: ${checks} checks, 0 failures; 14 standalone rooms in both renderers; ${knownDiagnostics.length} documented engine shutdown diagnostic; ${count} packed files.`);
