// Re-proportion the licensed CC0 rig, meshes and all animation translations together.
import fs from 'node:fs';
const input='assets/vendor/revision13/bunny.glb',output='assets/vendor/revision13/pengawas.glb';
const file=fs.readFileSync(input),jsonSize=file.readUInt32LE(12);
const j=JSON.parse(file.subarray(20,20+jsonSize));
const bin=Buffer.from(file.subarray(28+jsonSize,28+jsonSize+file.readUInt32LE(20+jsonSize)));
const mul=(a,b)=>Array.from({length:16},(_,i)=>{const r=i%4,c=Math.floor(i/4);let s=0;for(let k=0;k<4;k++)s+=a[k*4+r]*b[c*4+k];return s;});
const inv=a=>{const rows=Array.from({length:4},(_,r)=>Array.from({length:8},(_,c)=>c<4?a[c*4+r]:+(c-4===r)));for(let c=0;c<4;c++){let p=c;for(let r=c+1;r<4;r++)if(Math.abs(rows[r][c])>Math.abs(rows[p][c]))p=r;[rows[c],rows[p]]=[rows[p],rows[c]];const d=rows[c][c];if(Math.abs(d)<1e-14)throw Error('Singular transform');for(let k=0;k<8;k++)rows[c][k]/=d;for(let r=0;r<4;r++)if(r!==c){const d=rows[r][c];for(let k=0;k<8;k++)rows[r][k]-=d*rows[c][k];}}return Array.from({length:16},(_,i)=>rows[i%4][4+Math.floor(i/4)]);};
const point=(m,p)=>[0,1,2].map(r=>m[r]*p[0]+m[4+r]*p[1]+m[8+r]*p[2]+m[12+r]);
const matrix=n=>{if(n.matrix)return n.matrix;const [x,y,z,w]=n.rotation||[0,0,0,1],s=n.scale||[1,1,1],t=n.translation||[0,0,0];return [(1-2*y*y-2*z*z)*s[0],(2*x*y+2*z*w)*s[0],(2*x*z-2*y*w)*s[0],0,(2*x*y-2*z*w)*s[1],(1-2*x*x-2*z*z)*s[1],(2*y*z+2*x*w)*s[1],0,(2*x*z+2*y*w)*s[2],(2*y*z-2*x*w)*s[2],(1-2*x*x-2*y*y)*s[2],0,...t,1];};
const identity=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1];
const parents=j.nodes.map(()=>-1);j.nodes.forEach((n,i)=>(n.children||[]).forEach(c=>parents[c]=i));
const original=[];const world=i=>original[i]||=(parents[i]<0?matrix(j.nodes[i]):mul(world(parents[i]),matrix(j.nodes[i])));
j.nodes.forEach((_,i)=>world(i));
const knots=[[0,0],[0.85,1.25],[1.8,2.35],[2.45,3.00],[3.44,3.65]];
const ymap=y=>{for(let i=1;i<knots.length;i++)if(y<=knots[i][0]){const [a,b]=knots[i-1],[c,d]=knots[i];return b+(y-a)*(d-b)/(c-a);}return 3.65+(y-3.44)*0.65;};
const deform=p=>[p[0],ymap(p[1]),p[2]];
const changed=original.map(m=>{const n=m.slice();n.splice(12,3,...deform(m.slice(12,15)));return n;});
const translationDelta=j.nodes.map((n,i)=>{const p=parents[i]<0?identity:changed[parents[i]];const t=point(inv(p),changed[i].slice(12,15));const d=t.map((v,k)=>v-(n.translation?.[k]||0));n.translation=t;return d;});
const dimensions={SCALAR:1,VEC2:2,VEC3:3,VEC4:4,MAT4:16};
function access(index,visit){const a=j.accessors[index],v=j.bufferViews[a.bufferView];if(a.componentType!==5126)throw Error('Expected float');const n=dimensions[a.type],stride=v.byteStride||n*4,offset=(v.byteOffset||0)+(a.byteOffset||0);const lo=Array(n).fill(Infinity),hi=Array(n).fill(-Infinity);for(let i=0;i<a.count;i++){const p=Array.from({length:n},(_,k)=>bin.readFloatLE(offset+i*stride+k*4)),out=visit(p,i)||p;for(let k=0;k<n;k++){bin.writeFloatLE(out[k],offset+i*stride+k*4);lo[k]=Math.min(lo[k],out[k]);hi[k]=Math.max(hi[k],out[k]);}}if(a.min)a.min=lo;if(a.max)a.max=hi;}
const processed=new Set();
j.nodes.forEach((node,ni)=>{if(node.mesh===undefined||node.name==='Carrot')return;const from=original[ni],to=inv(changed[ni]);for(const primitive of j.meshes[node.mesh].primitives){const ai=primitive.attributes.POSITION;if(processed.has(ai))continue;processed.add(ai);access(ai,p=>point(to,deform(point(from,p))));}});
j.skins.forEach((skin,si)=>{
 const meshNode=j.nodes.findIndex(n=>n.skin===si);
 // Default node rotations are an A-pose; the inverse bind matrices describe
 // the original T-pose. Preserve that bind orientation when changing lengths.
 access(skin.inverseBindMatrices,oldBind=>{
  const bindWorld=mul(original[meshNode],inv(oldBind));
  bindWorld.splice(12,3,...deform(bindWorld.slice(12,15)));
  return mul(inv(bindWorld),changed[meshNode]);
 });
});
const animationAccessors=new Set();
for(const animation of j.animations)for(const channel of animation.channels)if(channel.target.path==='translation'){const a=animation.samplers[channel.sampler].output;if(animationAccessors.has(a))continue;animationAccessors.add(a);const d=translationDelta[channel.target.node];access(a,p=>p.map((v,k)=>v+d[k]));}
// The original prop must not influence the fitted bounds or appear in the enemy.
j.nodes.forEach(n=>{if(n.children)n.children=n.children.filter(i=>j.nodes[i].name!=='Carrot');});
j.nodes.filter(n=>n.name==='Carrot').forEach(n=>{delete n.mesh;delete n.skin;});
j.asset.extras={adaptation:'KALA Reka / Pengawas: elongated legs and torso, shorter ears; CC0 Quaternius Bunny. Original rig and animations retained.'};
let data=Buffer.from(JSON.stringify(j));data=Buffer.concat([data,Buffer.alloc((4-data.length%4)%4,32)]);
const header=Buffer.alloc(12);header.writeUInt32LE(0x46546c67);header.writeUInt32LE(2,4);header.writeUInt32LE(28+data.length+bin.length,8);
const chunk=(b,type)=>{const h=Buffer.alloc(8);h.writeUInt32LE(b.length);h.writeUInt32LE(type,4);return Buffer.concat([h,b]);};
fs.writeFileSync(output,Buffer.concat([header,chunk(data,0x4e4f534a),chunk(bin,0x004e4942)]));
console.log(output,processed.size,'position streams adapted; all inverse bind matrices rebuilt');
