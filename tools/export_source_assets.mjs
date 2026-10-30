import fs from 'node:fs/promises';
import path from 'node:path';

export async function exportAssets(extracted, root, only = null) {
 const s=extracted.snapshot;
 const out=root+'/assets/models/source';
 await fs.mkdir(out,{recursive:true});await fs.mkdir(root+'/assets/textures/source_generated',{recursive:true});
 if(!only)for(const c of extracted.canvases)await fs.writeFile(root+`/assets/textures/source_generated/canvas_${c.__canvas_id}.png`,c.toBuffer('image/png'));
 let serial=0;
 s.scene.traverse(n=>{if(!n.name)n.name='Source_'+serial++;});
 // The live HTML hides the arm group outside combat; actors still need all six arms.
 s.handGroup.visible=true;
 s.handGroup.name='HandsArms';s.handsBody.name='HandsBody';s.handsHead.name='HandsHead';
 for(const [label,parts]of Object.entries({Arm:s.handArms,Elbow:s.handElbows,Wrist:s.handWrists,Leg:s.handLegs,Knee:s.handKnees,Foot:s.handFeet}))parts.forEach((n,i)=>n.name='Hands'+label+i);
 for(const [key,d]of Object.entries(s.doors)){d.root.name='DoorRoot_'+key;d.pivot.name='DoorPivot_'+key;d.leaf.name='DoorLeaf_'+key;}
 s.relayRotors.forEach((n,i)=>n.name='RotorPivot'+i);s.relayMarks.forEach((n,i)=>n.name='RelayMark'+i);
 s.finalSeals.forEach((c,i)=>{c.mesh.name='Candle'+i;c.flame.name='Flame';c.glow.name='FireLight';c.mesh.visible=true;c.flame.visible=true;c.glow.visible=true;});
 s.doll.name='DaisyDoll';s.dollHeadRig.name='DaisyHead';s.crateLid.name='CabinetHinge';s.archiveLatch.name='ArchiveLatch';s.relayCell.name='RelayCell';s.relayHandle.name='RelayLever';s.lenteraPickup.root.name='LenteraPickup';s.photoWorld.name='EvidencePhoto';
 for(const [id,stair]of Object.entries(s.factoryStairs))stair.gate.name='StairGate_'+id;
 s.ventGrateHinge.name='VentGrate';s.fanBlades.name='FanBlades';s.rescueShutter.name='RescueShutter';s.pursuitSteam.forEach((n,i)=>n.mist.name='Steam_'+i);
 // Retain the authored face and body proportions, correct Sari's school outfit.
 const sari=s.npcMap.Sari,body=sari.children[0],hip=sari.children[1],head=sari.userData.head;
 hip.visible=false;
 const skirtMat=hip.material.clone();skirtMat.color.set(0x596c79);skirtMat.roughness=.94;
 const skirt=new body.constructor(new body.geometry.constructor(.20,.32,.56,32),skirtMat);skirt.name='Sari_School_Skirt';skirt.position.set(0,.74,0);sari.add(skirt);
 const hairMat=head.children[1].material.clone();hairMat.color.set(0x191b1b);
 head.children[1].material=hairMat;
 const hair=new head.children[0].constructor(head.children[0].geometry.clone(),hairMat);hair.name='Sari_Long_Hair';hair.position.set(0,1.45,-.075);hair.scale.set(1.05,1.8,.78);sari.add(hair);
 for(const m of sari.children)if(m.geometry?.parameters?.height===.66)m.material=head.children[0].material;
 sari.name='Sari';
 const files=[];
 async function glb(object,name,cx=0,actor=false) {
  if(only&&!only.includes(name))return;
  const gl={asset:{version:'2.0',generator:'KALA offline source geometry migration'},scene:0,scenes:[{nodes:[0]}],nodes:[{name:name,translation:[-cx,0,0],children:[]}],meshes:[],materials:[],accessors:[],bufferViews:[],buffers:[],images:[],textures:[],samplers:[],extensionsUsed:[]};
  const chunks=[];let byteOffset=0;const geomCache=new Map(),matCache=new Map(),textureCache=new Map();
  function accessor(array,size,target,minmax=false){
   const padding=(4-byteOffset%4)%4;if(padding){chunks.push(Buffer.alloc(padding));byteOffset+=padding;}
   const buffer=Buffer.from(array.buffer,array.byteOffset,array.byteLength);const view=gl.bufferViews.length;gl.bufferViews.push({buffer:0,byteOffset,byteLength:buffer.length,target});chunks.push(buffer);byteOffset+=buffer.length;
   const a={bufferView:view,componentType:array instanceof Uint32Array?5125:array instanceof Uint16Array?5123:5126,count:array.length/size,type:size===1?'SCALAR':size===2?'VEC2':size===3?'VEC3':'VEC4'};
   if(minmax){a.min=Array(size).fill(Infinity);a.max=Array(size).fill(-Infinity);for(let i=0;i<array.length;i++){a.min[i%size]=Math.min(a.min[i%size],array[i]);a.max[i%size]=Math.max(a.max[i%size],array[i]);}}
   gl.accessors.push(a);return gl.accessors.length-1;
  }
  function tex(t){
   if(!t?.image)return undefined;let file=t.image.__source_path??t.image.src;
   if(t.image.__canvas_id!==undefined)file='res://assets/textures/source_generated/canvas_'+t.image.__canvas_id+'.png';
   if(typeof file!=='string'||!file.startsWith('res://assets/'))return undefined;
   const key=file+String(t.wrapS)+String(t.wrapT);let index=textureCache.get(key);
   if(index===undefined){const image=gl.images.length;gl.images.push({uri:path.posix.relative('assets/models/source',file.slice(6))});const sampler=gl.samplers.length;gl.samplers.push({magFilter:9729,minFilter:9987,wrapS:t.wrapS===1000?10497:33071,wrapT:t.wrapT===1000?10497:33071});index=gl.textures.length;gl.textures.push({source:image,sampler});textureCache.set(key,index);}
   const info={index};if(t.repeat.x!==1||t.repeat.y!==1||t.offset.x!==0||t.offset.y!==0){info.extensions={KHR_texture_transform:{scale:t.repeat.toArray(),offset:t.offset.toArray()}};if(!gl.extensionsUsed.includes('KHR_texture_transform'))gl.extensionsUsed.push('KHR_texture_transform');}return info;
  }
  function material(m){
   if(matCache.has(m.uuid))return matCache.get(m.uuid);
   const color=m.color?.toArray()??[1,1,1],pbr={baseColorFactor:[...color,m.opacity??1],metallicFactor:m.metalness??0,roughnessFactor:m.roughness??1};
   const t=tex(m.map);if(t)pbr.baseColorTexture=t;
   const result={name:m.name||'SourceMaterial_'+gl.materials.length,pbrMetallicRoughness:pbr,doubleSided:m.side===2};
   if(m.transparent)result.alphaMode='BLEND';else if(m.alphaTest>0){result.alphaMode='MASK';result.alphaCutoff=m.alphaTest;}
   const normal=tex(m.normalMap);if(normal)result.normalTexture={...normal,scale:m.normalScale?.x??1};
   const rough=tex(m.roughnessMap);if(rough)pbr.metallicRoughnessTexture=rough;
   if(m.emissive){result.emissiveFactor=m.emissive.toArray().map(v=>Math.min(1,v*(m.emissiveIntensity??1)));const e=tex(m.emissiveMap);if(e)result.emissiveTexture=e;}
   if(m.isMeshBasicMaterial){result.extensions={KHR_materials_unlit:{}};if(!gl.extensionsUsed.includes('KHR_materials_unlit'))gl.extensionsUsed.push('KHR_materials_unlit');}
   gl.materials.push(result);matCache.set(m.uuid,gl.materials.length-1);return gl.materials.length-1;
  }
  function mesh(m){
   const materials=Array.isArray(m.material)?m.material:[m.material],key=m.geometry.uuid+materials.map(v=>v.uuid).join();if(geomCache.has(key))return geomCache.get(key);
   const g=m.geometry,attrs={};for(const [src,dst]of [['position','POSITION'],['normal','NORMAL'],['uv','TEXCOORD_0'],['color','COLOR_0']]){const a=g.attributes[src];if(!a||(src==='color'&&!materials.some(v=>v.vertexColors)))continue;const array=new Float32Array(a.count*a.itemSize);for(let i=0;i<a.count;i++)for(let j=0;j<a.itemSize;j++){let value=a.getComponent?a.getComponent(i,j):a.array[i*a.itemSize+j];if(src==='uv'&&j===1)value=1-value;array[i*a.itemSize+j]=Number.isFinite(value)?value:0;}attrs[dst]=accessor(array,a.itemSize,34962,src==='position');}
   let indices=g.index?new Uint32Array(g.index.array):Uint32Array.from({length:g.attributes.position.count},(_,i)=>i);
   const groups=g.groups.length&&materials.length>1?g.groups:[{start:0,count:indices.length,materialIndex:0}];
   const primitives=groups.map(group=>({attributes:attrs,indices:accessor(indices.slice(group.start,group.start+group.count),1,34963),material:material(materials[group.materialIndex]??materials[0]),mode:4}));
   gl.meshes.push({name:m.name,primitives});geomCache.set(key,gl.meshes.length-1);return gl.meshes.length-1;
  }
  function node(n,parent,isRoot=false){
   if(!isRoot&&!n.visible)return;
   if(n.isLight||n.isPoints||n.isLine||n.isCamera)return;
   const item={name:n.name||'SourceNode',translation:isRoot&&actor?[0,0,0]:n.position.toArray(),rotation:isRoot&&actor?[0,0,0,1]:n.quaternion.toArray(),scale:n.scale.toArray()};
   if(n.isMesh&&n.geometry?.attributes?.position&&n.geometry.drawRange.count!==0)item.mesh=mesh(n);
   const index=gl.nodes.length;gl.nodes.push(item);(gl.nodes[parent].children??=[]).push(index);
   for(const child of n.children)node(child,index);
  }
  node(object,0,true);gl.buffers=[{byteLength:byteOffset}];
  let json=Buffer.from(JSON.stringify(gl));json=Buffer.concat([json,Buffer.alloc((4-json.length%4)%4,32)]);
  let bin=Buffer.concat(chunks);bin=Buffer.concat([bin,Buffer.alloc((4-bin.length%4)%4)]);
  const header=Buffer.alloc(12),jh=Buffer.alloc(8),bh=Buffer.alloc(8);header.writeUInt32LE(0x46546c67);header.writeUInt32LE(2,4);header.writeUInt32LE(12+8+json.length+8+bin.length,8);jh.writeUInt32LE(json.length);jh.writeUInt32LE(0x4e4f534a,4);bh.writeUInt32LE(bin.length);bh.writeUInt32LE(0x004e4942,4);
  await fs.writeFile(out+'/'+name+'.glb',Buffer.concat([header,jh,json,bh,bin]));files.push({name,meshes:gl.meshes.length,nodes:gl.nodes.length,bytes:header.readUInt32LE(8)});
 }
 const meta={rooms:{},characters:{},lighting:s.horrorLight,doll_position:s.doll.getWorldPosition(s.doll.position.clone()).toArray().map((v,i)=>i===0?v-1400:v)};
 for(const [id,r]of Object.entries(s.rooms)){
  r.group.updateMatrixWorld(true);
  const doors=Object.entries(s.doors).filter(([k,d])=>{let p=d.root;while(p){if(p===r.group)return true;p=p.parent;}return false;}).map(([key,d])=>({key,pivot:d.pivot.name,leaf:d.leaf.name,width:d.width,height:d.height,angle:d.openAngle??-1.5,position:[d.root.position.x-r.cx,d.root.position.y,d.root.position.z]}));
  const lights=[];r.group.traverse(n=>{if(n.isPointLight){const v=n.getWorldPosition(n.position.clone());lights.push({name:n.name,position:[v.x-r.cx,v.y,v.z],color:n.color.toArray(),power:n.intensity,range:n.distance});}});
  meta.rooms[id]={cx:r.cx,width:r.width,depth:r.depth,height:r.height??3.2,bounds:r.bounds.map((v,i)=>i<2?v-r.cx:v),spawn:[r.spawn.x-r.cx,.05,r.spawn.z],yaw:r.spawn.yaw,colliders:r.colliders.map(c=>[c.minX-r.cx,c.minZ,c.maxX-c.minX,c.maxZ-c.minZ]),doors,lights,
   interactions:s.interactions.filter(a=>a.room===id).map(a=>({label:a.label,x:(a.npc?.position.x??a.x)-r.cx,z:a.npc?.position.z??a.z,y:a.focusY??(a.npc?1.25:1.35),radius:a.radius,note_id:a.note_id,fn:String(a.fn),annex:a.annex?.id})),
   tools:s.toolTargets.filter(a=>a.room===id).map(a=>({label:a.label,point:a.point().toArray().map((v,i)=>i===0?v-r.cx:v),radius:a.radius,fn:String(a.onGrab)}))};
  await glb(r.group,id,r.cx);
 }
 for(const [name,n]of Object.entries(s.npcMap)){meta.characters[name]={position:n.position.toArray(),yaw:n.rotation.y};await glb(n,'npc_'+name,0,true);}
 for(const [name,n]of Object.entries({overseer:s.MonsterVisual,hands:s.HandsVisual,tumbal:s.FinalVisual,daisy:s.doll,lentera:s.heldLentera.root,flashlight:s.oldFlashVisual})){
  n.visible=true;await glb(n,name==='daisy'?'actor_daisy':name,0,true);
 }
 meta.pursuit_route=s.pursuitRoute.map(p=>[p[0]-1800,0,p[1]]);meta.extended_route=s.extendedRoute.map(p=>[p[0]-1800,p[2],p[1]]);
 meta.chase_passages=s.chasePassages.map(p=>({a:[p.a[0]-1800,p.a[2],p.a[1]],b:[p.b[0]-1800,p.b[2],p.b[1]],width:p.width,height:p.height,vent:p.vent}));
 for(const room of Object.values(meta.rooms))for(const record of [...room.interactions,...room.tools])delete record.fn;
 if(!only){await fs.writeFile(root+'/assets/source_layout.json',JSON.stringify(meta));await fs.writeFile(root+'/docs/source_geometry_manifest.json',JSON.stringify(files,null,2));}return files;
}
