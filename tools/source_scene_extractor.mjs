// Offline authoring tool only. No JavaScript is included in the native game.
import fs from 'node:fs/promises';
import vm from 'node:vm';
import { createRequire } from 'node:module';
const require=createRequire(import.meta.url);
const raster=require('./authoring/canvas/index.js');

export async function extract(root) {
  let source = await fs.readFile(root + '/docs/reference_script_1.txt', 'utf8');
  const manifest = JSON.parse((await fs.readFile(root + '/docs/asset_manifest.json', 'utf8')).replace(/^\ufeff/, ''));
  const assetBuffers = new Map();
  for(const a of manifest)if(a.mime.startsWith('image/'))assetBuffers.set('res://'+a.path,await fs.readFile(root+'/'+a.path));
  raster.GlobalFonts.registerFromPath(root+'/assets/fonts/embedded_000.ttf','Nosifer');
  raster.GlobalFonts.registerFromPath(root+'/assets/fonts/embedded_001.ttf','Special Elite');
  let assetIndex = 2;
  source = source.replace(/\[EMBEDDED_ASSET:[^\]]+\]/g, () => 'res://' + manifest[assetIndex++].path);
  const canvases = [];
  const noop = () => {};
  function canvasContext(canvas) {
    const gradient = () => ({addColorStop: noop});
    const base = {canvas, measureText: t => ({width: String(t).length * 12}),
      getImageData: (x,y,w,h) => ({data:new Uint8ClampedArray(w*h*4),width:w,height:h}),
      createImageData: (w,h) => ({data:new Uint8ClampedArray(w*h*4),width:w,height:h}),
      createLinearGradient: gradient, createRadialGradient: gradient,
      createPattern: () => null, isPointInPath: () => false};
    return new Proxy(base, {get(t,k) {return k in t ? t[k] : noop;}});
  }
  const elements = new Map();
  function element(tag='div') {
    if(tag==='canvas'){
      const c=raster.createCanvas(512,512);c.__canvas_id=canvases.length;c.style={};c.addEventListener=noop;c.removeEventListener=noop;c.setAttribute=noop;c.getBoundingClientRect=()=>({left:0,top:0,width:c.width,height:c.height});canvases.push(c);return c;
    }
    const el={tagName:tag.toUpperCase(),width:512,height:512,style:{},children:[],dataset:{},
      classList:{add:noop,remove:noop,toggle:noop,contains:()=>false},value:'1',checked:false,
      textContent:'',innerHTML:'',addEventListener:noop,removeEventListener:noop,
      appendChild(x){this.children.push(x);return x;},append:noop,prepend:noop,remove:noop,
      setAttribute:noop,getAttribute:()=>null,focus:noop,blur:noop,click:noop,
      querySelector:()=>element(),querySelectorAll:()=>[],getBoundingClientRect:()=>({x:0,y:0,left:0,top:0,width:1280,height:720}),
      getContext(){return this.ctx??=canvasContext(this);},toDataURL:()=>'',
      play:()=>Promise.resolve(),pause:noop,load:noop,canPlayType:()=>'',requestPointerLock:noop};
    if(tag==='canvas'){el.__canvas_id=canvases.length;canvases.push(el);}
    return el;
  }
  const document={body:element('body'),head:element('head'),documentElement:element('html'),visibilityState:'visible',hidden:false,
    createElement:element,createElementNS:(ns,tag)=>element(tag),
    getElementById(id){if(!elements.has(id)){const e=element();e.id=id;e.value=id==='graphicsQuality'?'medium':id.includes('Volume')?'70':'1';elements.set(id,e);}return elements.get(id);},
    querySelector:()=>element(),querySelectorAll:()=>[],addEventListener:noop,removeEventListener:noop,
    exitPointerLock:noop,fonts:{ready:Promise.resolve(),add:noop,load:()=>Promise.resolve([])}};
  class FakeRenderer {
    constructor(){this.domElement=element('canvas');this.capabilities={getMaxAnisotropy:()=>8,isWebGL2:true,maxSamples:4};this.shadowMap={enabled:true};this.info={render:{calls:0,triangles:0},memory:{}};this.xr={enabled:false};this.outputColorSpace='srgb';this.toneMappingExposure=1;}
    setPixelRatio(){} getPixelRatio(){return 1;} setSize(){} getSize(v){return v.set(1280,720);} getDrawingBufferSize(v){return v.set(1280,720);}
    getRenderTarget(){return null;} setRenderTarget(){} getContext(){return {};} render(){} clear(){} setClearColor(){} getClearColor(v){return v.set(0);} getClearAlpha(){return 1;} getViewport(v){return v.set(0,0,1280,720);} getScissor(v){return v.set(0,0,1280,720);} getScissorTest(){return false;} setViewport(){} setScissor(){} setScissorTest(){}
  }
  class FakeImage extends raster.Image {set src(value){this.__source_path=value;super.src=assetBuffers.get(value)??value;}get src(){return this.__source_path;}addEventListener(){}removeEventListener(){}}
  const sandbox={console,document,FakeRenderer,Image:FakeImage,HTMLImageElement:FakeImage,
    HTMLCanvasElement:raster.Canvas,HTMLVideoElement:class{},ImageBitmap:class{},
    Audio:function(){return element('audio');},location:{hash:'#test'},navigator:{userAgent:'offline-authoring'},
    innerWidth:1280,innerHeight:720,devicePixelRatio:1,
    localStorage:{getItem:()=>null,setItem:noop,removeItem:noop},performance:{now:()=>0},
    requestAnimationFrame:()=>0,cancelAnimationFrame:noop,setTimeout:()=>0,clearTimeout:noop,setInterval:()=>0,clearInterval:noop,
    addEventListener:noop,removeEventListener:noop,matchMedia:()=>({matches:false,addEventListener:noop}),
    URL,TextDecoder,TextEncoder,Uint8Array,Uint8ClampedArray,Float32Array,Float64Array,Uint16Array,Uint32Array,Int16Array,Int32Array,ArrayBuffer,
    atob:s=>Buffer.from(s,'base64').toString('binary'),btoa:s=>Buffer.from(s,'binary').toString('base64')};
  sandbox.window=sandbox;sandbox.self=sandbox;
  source=source.replace('new Xs({antialias:', 'new FakeRenderer({antialias:');
  source=source.replace("function noteObject(room,x,z,title,body,id,opts={}){interact(","function noteObject(room,x,z,title,body,id,opts={}){const record=interact(");
  source=source.replace("available:()=>!opts.once||!state.seen[id]})}","available:()=>!opts.once||!state.seen[id]});record.note_id=id;}");
  const marker="resetNpcs();baseNpcs.forEach(n=>n.visible=false);handGroup.visible=false;$t.visible=true;";
  const at=source.lastIndexOf(marker);
  if(at<0)throw Error('Final extraction marker not found');
  source=source.slice(0,at)+`globalThis.__sourceScene={scene:Wt,rooms,npcMap,doors,interactions,annexes,factoryStairs,finalSeals,MonsterVisual,HandsVisual,FinalVisual,doll,heldLentera,oldFlashVisual,crushCage,ringPortal,horrorLight,roofHole,roofY,discoverySun,explorationItems,relayRotors,relayMarks,relayCell,relayLever,relayHandle,archiveLatch,lenteraPickup,photoWorld,crateLid,dollHeadRig,pursuitRoute,extendedRoute,toolTargets,state,updateRoomLighting,ventGrateHinge,fanBlades,chasePassages,rescueShutter,pursuitSteam,handGroup,handsBody,handsHead,handArms,handElbows,handWrists,handLegs,handKnees,handFeet,chaseFootprints,chaseBlockers,machineBay,rescueBay,discovery,sunBeam,mats};\n`+source.slice(at);
  const context=vm.createContext(sandbox);
  vm.runInContext(source,context,{timeout:120000,filename:'KALA_reference_offline.js'});
  return {context,snapshot:sandbox.__sourceScene,canvases,source};
}
