import fs from 'node:fs';
import crypto from 'node:crypto';
const read=p=>fs.readFileSync(p,'utf8').replace(/^\uFEFF/,'');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const suites={};let checks=0;
for(const id of ['integration','layout','story','claw','revision04','revision05','revision06','revision07','revision08','revision09','revision10','revision11','revision12','revision13','revision14']) {
 const log=`docs/${id}_latest_console.log`,s=read(log),m=s.match(/KALA \w+: (\d+) checks, (\d+) failures/);
 if(!m || +m[2] || /SCRIPT ERROR|ERROR:|FAIL:|were leaked at exit/.test(s))throw Error(`Suite failed: ${log}`);
 suites[id]={checks:+m[1],failures:0,log};checks+=+m[1];
}
const rooms=['home','schoolyard','neighborhood','school','street','loading','relay','pursuit','production','office','ritual','corridor','daisy','hallucination'];
const knownDiagnostics=[],standalone={};
const exits=JSON.parse(read('docs/standalone14_exits.json'));
if(exits.length!==2 || exits.some(x=>x.exit_code!==0))throw Error('Standalone process did not exit cleanly');
for(const kind of ['forward','compatibility']) {
 const stdout=read(`docs/exe_${kind}_14_stdout.log`),stderr=read(`docs/exe_${kind}_14_stderr.log`);
 if(!stdout.includes('SMOKE BUILD: 0.14.0'))throw Error('Wrong standalone version: '+kind);
 let diagnostics=stderr;
 if(kind==='compatibility') {
  const pattern=/ERROR: Texture with GL ID of \d+: leaked 349524 bytes\.\r?\n\s+at: ~Utilities \(drivers\/gles3\/storage\/utilities\.cpp:82\)\r?\n/g;
  const matches=stderr.match(pattern)||[];
  if(matches.length===2){knownDiagnostics.push({renderer:kind,stage:'engine process shutdown',textures:2,bytes:699048,log:`docs/exe_${kind}_14_stderr.log`,status:'same engine shutdown diagnostic as the previous release; all 14 rooms loaded and the process exited 0'});diagnostics=stderr.replace(pattern,'');}
 }
 if(rooms.some(id=>!stdout.includes(`SMOKE ROOM OK: ${id} `)) || /SCRIPT ERROR|ERROR:|were leaked at exit/.test(stdout+diagnostics))throw Error('Standalone failed: '+kind);
 if(!stdout.includes(kind==='forward'?'Forward+':'Compatibility'))throw Error('Renderer not confirmed: '+kind);
 standalone[kind]={exit_code:0,rooms_loaded:14,stdout:`docs/exe_${kind}_14_stdout.log`,stderr:`docs/exe_${kind}_14_stderr.log`};
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
const sources=['scripts/systems/factory_route.gd','scripts/systems/flashlight_burst.gd','assets/materials/flashlight_burst.gdshader','scripts/systems/expansion_cinematics.gd','scripts/systems/factory_overhaul.gd','scripts/systems/home_detail.gd','scripts/systems/student_model.gd','scripts/ui/journal_book.gd','scripts/ui/hud.gd','scripts/systems/main.gd','scripts/systems/audio.gd'];
for(const file of sources) {
 if(!paths.includes(file)&&!paths.includes(file+'.remap'))throw Error('Missing resource '+file);
}
const capture=read('docs/capture14_console.log');
if(/SCRIPT ERROR|ERROR:/.test(capture))throw Error('Render diagnostics');
const names=['pillow','conversation','journal_open','journal','guard_shelf','memo_a','keynote','keypad','burst_flash','burst_fire','burst_sparks','burst_smoke','gallery','pumps','pump_controls','distribution','route_power'];
const screenshots=names.map(label=>{
 const file=`docs/screenshots/${label}_14.png`;
 if(!capture.includes(`CAPTURE14 ${label} 0`)||!fs.existsSync(file))throw Error('Missing render '+file);
 return {file,sha256:hash(file)};
});
const effects={};
for(const [renderer,log,prefix,suffix] of [
 ['forward','docs/burst14_render_console.log','CAPTURE14','_14.png'],
 ['compatibility','docs/burst14_compat_console.log','CAPTURE14GL','_14_compat.png']
]) {
 const output=read(log);
 if(/SCRIPT ERROR|ERROR:|were leaked at exit/.test(output))throw Error('Effect render failed: '+renderer);
 for(const label of ['burst_flash','burst_fire','burst_sparks','burst_smoke']) {
  if(!output.includes(`${prefix} ${label} 0`))throw Error('Missing effect phase: '+renderer+'/'+label);
  if(renderer==='compatibility')screenshots.push({file:`docs/screenshots/${label}${suffix}`,sha256:hash(`docs/screenshots/${label}${suffix}`)});
 }
 effects[renderer]={phases_rendered:4,log};
}
const files=['KALA.exe','KALA.pck','THIRD_PARTY_NOTICES.txt'].map(file=>({file,bytes:fs.statSync(file).size,sha256:hash(file)}));
const report={version:'0.14.0',verified_utc:new Date().toISOString(),checks,failures:0,suites,standalone,effects,packed_files:count,known_diagnostics:knownDiagnostics,files,source_files:sources.map(file=>({file,sha256:hash(file)})),screenshots,limitations:['Automated gameplay, physical routes and engine renders were checked; a manual playthrough to every ending was not performed.']};
fs.writeFileSync('docs/validation_14.json',JSON.stringify(report,null,2)+'\n');
console.log(`KALA 0.14: ${checks} checks, 0 failures; 14 standalone rooms in both renderers; ${knownDiagnostics.length} documented engine shutdown diagnostic; ${count} packed files.`);
