// Offline glTF compatibility conversion. Preserve node transforms, UVs,
// materials and animation while expanding quantized attributes to float32.
import fs from 'node:fs';
import path from 'node:path';
const folder='assets/vendor/revision10';
fs.mkdirSync('tools/downloads/revision10_originals',{recursive:true});
for(const file of fs.readdirSync(folder).filter(f=>f.endsWith('.glb'))) {
 const target=path.join(folder,file), source=fs.readFileSync(target);
 const json=JSON.parse(source.subarray(20,20+source.readUInt32LE(12)).toString());
 if(!json.extensionsRequired?.includes('KHR_mesh_quantization'))continue;
 fs.copyFileSync(target,path.join('tools/downloads/revision10_originals',file));
 const binOffset=20+source.readUInt32LE(12), bin=source.subarray(binOffset+8,binOffset+8+source.readUInt32LE(binOffset));
 const blocks=[bin]; let length=bin.length;
 const counts={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT4:16};
 const types={5120:[1,'readInt8',127],5121:[1,'readUInt8',255],5122:[2,'readInt16LE',32767],5123:[2,'readUInt16LE',65535],5125:[4,'readUInt32LE',4294967295]};
 const accessors=new Set(json.meshes.flatMap(m=>m.primitives.flatMap(p=>Object.values(p.attributes))));
 for(const index of accessors) {
  const a=json.accessors[index]; if(a.componentType===5126)continue;
  const v=json.bufferViews[a.bufferView], [bytes,read,maximum]=types[a.componentType], width=counts[a.type];
  const data=Buffer.alloc(a.count*width*4), lo=Array(width).fill(Infinity), hi=Array(width).fill(-Infinity);
  for(let n=0;n<a.count;n++)for(let c=0;c<width;c++) {
   let value=bin[read]((v.byteOffset||0)+(a.byteOffset||0)+n*(v.byteStride||bytes*width)+c*bytes);
   if(a.normalized)value=Math.max(-1,value/maximum);
   data.writeFloatLE(value,(n*width+c)*4);lo[c]=Math.min(lo[c],value);hi[c]=Math.max(hi[c],value);
  }
  const padding=(4-length%4)%4;if(padding){blocks.push(Buffer.alloc(padding));length+=padding;}
  const viewIndex=json.bufferViews.length;json.bufferViews.push({buffer:0,byteOffset:length,byteLength:data.length});
  blocks.push(data);length+=data.length;
  a.bufferView=viewIndex;a.byteOffset=0;a.componentType=5126;delete a.normalized;if(a.min)a.min=lo;if(a.max)a.max=hi;
 }
 json.extensionsUsed=json.extensionsUsed.filter(e=>e!=='KHR_mesh_quantization');
 json.extensionsRequired=json.extensionsRequired.filter(e=>e!=='KHR_mesh_quantization');
 json.buffers[0].byteLength=length;
 let jsonBytes=Buffer.from(JSON.stringify(json));jsonBytes=Buffer.concat([jsonBytes,Buffer.alloc((4-jsonBytes.length%4)%4,0x20)]);
 let binBytes=Buffer.concat(blocks);binBytes=Buffer.concat([binBytes,Buffer.alloc((4-binBytes.length%4)%4)]);
 const header=Buffer.alloc(12);header.writeUInt32LE(0x46546c67,0);header.writeUInt32LE(2,4);header.writeUInt32LE(12+8+jsonBytes.length+8+binBytes.length,8);
 const chunk=(b,type)=>{const h=Buffer.alloc(8);h.writeUInt32LE(b.length);h.writeUInt32LE(type,4);return Buffer.concat([h,b]);};
 fs.writeFileSync(target,Buffer.concat([header,chunk(jsonBytes,0x4e4f534a),chunk(binBytes,0x004e4942)]));
 console.log('Expanded quantized attributes:',file);
}
