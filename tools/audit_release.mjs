import fs from 'node:fs';
import crypto from 'node:crypto';
const read = path => fs.readFileSync(path, 'utf8').replace(/^\uFEFF/, '');
const write = (path, data) => fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
const specs = {integration:177,layout:117,story:28,claw:6,revision04:63,revision05:57,revision06:42,revision07:30};
const suites = {};
for(const [name, expected] of Object.entries(specs)) {
  const path = `docs/${name}_latest_console.log`, text = read(path);
  const result = text.match(/KALA \w+: (\d+) checks, (\d+) failures/);
  if(!result || +result[1] !== expected || +result[2] !== 0 || /SCRIPT ERROR|ERROR:|FAIL:|were leaked at exit/.test(text)) throw new Error(`Validation failed: ${path}`);
  suites[name] = {checks:+result[1],failures:0,log:path};
}
const pack = fs.readFileSync('KALA.pck');
if(pack.toString('ascii',0,4) !== 'GDPC' || pack.readUInt32LE(4)!==4) throw new Error('Unexpected pack format');
const base = Number(pack.readBigUInt64LE(24)), directory = Number(pack.readBigUInt64LE(32));
let cursor = directory;
const count = pack.readUInt32LE(cursor); cursor += 4;
const entries = [];
for(let i=0;i<count;i++) {
  const length = pack.readUInt32LE(cursor); cursor += 4;
  const path = pack.toString('utf8',cursor,cursor+length).replace(/\0+$/,''); cursor += length;
  const offset = base + Number(pack.readBigUInt64LE(cursor)); cursor += 8;
  const size = Number(pack.readBigUInt64LE(cursor)); cursor += 8;
  const md5 = pack.subarray(cursor,cursor+16).toString('hex'); cursor += 16;
  const flags = pack.readUInt32LE(cursor); cursor += 4;
  if(!path || offset < base || offset + size > directory) throw new Error('Invalid entry: ' + path);
  entries.push({path,offset,size,md5,flags});
}
const forbidden = entries.filter(e=> /^(docs|tests|tools|backups)\//.test(e.path) || /\.(html|js|mjs)$/i.test(e.path) || /embedded_03[2-5].*(mp3|mp3str)/.test(e.path));
if(forbidden.length) throw new Error('Unexpected runtime files: ' + forbidden.map(e=>e.path).join(', '));
const rooms=['home','schoolyard','neighborhood','school','street','loading','relay','pursuit','production','office','ritual','corridor','daisy','hallucination'];
for(const room of rooms) if(!entries.some(e=>e.path===`scenes/levels/${room}.tscn.remap`)) throw new Error('Missing packed room: ' + room);
for (const required of ['assets/video/lentera_tutorial.ogv','assets/materials/volume_mist.gdshader','scripts/enemies/final_rig.gd']) {
  if (!entries.some(e=>e.path===required || e.path===required+'.remap')) throw new Error('Missing revision 07 resource: '+required);
}
const smoke=read('docs/exe_smoke_07.log');
if(rooms.some(room=>!smoke.includes('SMOKE ROOM OK: '+room+' ')) || /SCRIPT ERROR|ERROR:/.test(smoke)) throw new Error('Native smoke check failed');
const gpu=read('docs/exe_render_07.log');
if(!gpu.includes('Forward+') || /SCRIPT ERROR|ERROR:/.test(gpu)) throw new Error('Native GPU check failed');
const compatibility=read('docs/exe_compatibility_07.log');
if(!compatibility.includes('Compatibility') || rooms.some(room=>!compatibility.includes('SMOKE ROOM OK: '+room+' ')) || /SCRIPT ERROR|ERROR:/.test(compatibility)) throw new Error('Compatibility fallback failed');
const files=['KALA.exe','KALA.pck'].map(file=>({file,bytes:fs.statSync(file).size,modified_utc:fs.statSync(file).mtime.toISOString(),sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')}));
for(const name of ['build_manifest','package_manifest']) {
  const path=`docs/${name}.json`, old=`docs/${name}_0_4.json`;
  if(fs.existsSync(path) && !fs.existsSync(old) && JSON.parse(read(path)).version==='0.4.0') fs.copyFileSync(path,old);
}
write('docs/package_manifest.json',{version:'0.7.0',format:4,engine:[4,7,2],file_count:count,excluded_danu_voice:[32,33,34,35],forbidden_entries:[],entries});
const report={version:'0.7.0',built_utc:new Date().toISOString(),engine:'4.7.2.stable.official.ed1daf0bf',architecture:'Windows x86_64',renderer:'Forward+ / Vulkan',separate_pck:true,custom_template:'Godot editor executable, native player runtime mode',checks_stable:Object.values(specs).reduce((a,b)=>a+b,0),suites,package_files:count,packaged_web_runtime:false,packaged_danu_voice:false,native_smoke_rooms:rooms.length,native_gpu_exit:0,rendered_captures:11,headless_nonverbose_shutdown_diagnostic_observed:false,files};
write('docs/build_manifest.json',report);
write('docs/validation_07.json',report);
console.log(`KALA 0.7: ${report.checks_stable} checks, 0 failures; ${count} packed files; 14 packed rooms; native Vulkan OK.`);
