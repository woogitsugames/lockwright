/* Lockwright G06: deterministic, self-contained PNG texture generator.
 * No external dependencies. All surfaces are fictional and decorative.
 * Run: node generate.js (from anywhere).
 * Copyright (c) 2026 project owner. License: project-owned original code.
 */
'use strict';
const SIZE=2048, TAU=2*Math.PI;
const MATERIALS=['turned_brass','face_milled_brass','ground_steel','heat_tinted_steel','spring_steel','aged_brass_grease'];
const WEAR=[80,60,40,20];
const clamp=(v,lo=0,hi=255)=>Math.max(lo,Math.min(hi,Math.round(v)));
function noise(x,y,s=0){
  let n=Math.imul(x+67,0x1f123bb5)^Math.imul(y+179,0x5f356495)^Math.imul(s+53,0x45d9f3b);
  n^=n>>>16;n=Math.imul(n,0x7feb352d);n^=n>>>15;n=Math.imul(n,0x846ca68b);n^=n>>>16;
  return (n>>>0)/2147483647.5-1;
}
function periodic(x,y,a,b,p=0){return Math.sin(TAU*(a*x+b*y)/SIZE+p);}
function micro(x,y,s=0){return noise(x,y,s)*1.9+noise(x>>2,y>>2,s+5)*0.95;}
function sampleMaterial(kind,xx,yy){
  // Repeated boundary pixels enforce a mathematically testable identical seam.
  const x=xx===SIZE-1?0:xx, y=yy===SIZE-1?0:yy;
  const n=micro(x,y,kind), w1=periodic(x,y,3,2,0.13),w2=periodic(x,y,7,-5,1.11);
  let h=128, a=128;
  if(kind===0){
    const sx=Math.sin(Math.PI*x/SIZE),sy=Math.sin(Math.PI*y/SIZE);
    const r=Math.sqrt(sx*sx+1.07*sy*sy);
    const groove=Math.cos(580*r+0.10*w1),fine=Math.cos(1250*r+0.16*w2);
    h=128+20*groove+7*fine+2.6*w1+n;
    a=142+12*groove+3.8*fine+4*w2+n*0.85;
  }else if(kind===1){
    const sx=Math.sin(Math.PI*(x-310)/SIZE),sy=Math.sin(Math.PI*(y-270)/SIZE);
    const px=Math.sin(Math.PI*(x-1390)/SIZE),py=Math.sin(Math.PI*(y-1100)/SIZE);
    const r=Math.sqrt(1.45*sx*sx+sy*sy),r2=Math.sqrt(px*px+1.25*py*py);
    const c=Math.sin(420*r+0.12*w2),overlap=Math.sin(285*r2+0.12*w1);
    h=129+17*c+8*overlap+3*w1+n*1.2;
    a=145+13*c+5*overlap+4*w2+n;
  }else if(kind===2){
    const jitter=0.28*periodic(x,y,5,0);
    const stroke=Math.sin(TAU*y*205/SIZE+jitter),fine=Math.sin(TAU*y*657/SIZE+0.16*w1);
    const grain=Math.sin(TAU*y*911/SIZE)*0.4;
    h=128+16*stroke+6*fine+3*grain+2.2*w2+n*1.35;
    a=135+12*stroke+6*fine+3*w1+n;
  }else if(kind===3){
    const wash=periodic(x,y,4,2,0.32)*periodic(x,y,-3,5,1.40);
    const temper=0.52*periodic(x,y,2,1)+0.29*periodic(x,y,-3,2,0.7)+0.19*periodic(x,y,5,-4,0.5);
    h=128+8*wash+4*w1+2.5*w2+n*1.25;
    const light=clamp(7+0.04*(h-128)+1.8*wash,0,15);
    const hue=clamp(7.5+6*temper,0,15);
    a=light*16+hue;
  }else if(kind===4){
    const hair=Math.sin(TAU*y*513/SIZE+0.055*w1),brush=Math.sin(TAU*y*107/SIZE+0.1*w2);
    const scuff=Math.sin(TAU*y*997/SIZE+0.03*w2);
    h=130+10.5*hair+6*brush+4*scuff+2.2*w1+n*1.4;
    a=151+8*hair+5*brush+2*w2+n;
  }else{
    const spot=w1*0.43+w2*0.39+periodic(x,y,11,-7,0.82)*0.18;
    const pit=Math.max(0,spot-0.31);
    const crest=Math.sin(TAU*(x*233+y*18)/SIZE);
    h=124+9*crest+5*w1-30*pit+n*1.5;
    const grease=spot>0.55 || (spot>0.43&&noise(x>>3,y>>3,6)>0.76);
    const oxide=spot < -0.23;
    const polished=spot>0.19&&!grease;
    const group=grease?1:oxide?2:polished?3:0;
    a=group*64+clamp(32+7*crest+7*w2+n*2,0,63);
  }
  return [clamp(Math.round(clamp(h)/4)*4),clamp(Math.round(clamp(a)/4)*4)];
}
function paletteMaterial(kind){
  const p=new Uint8Array(256*3);
  for(let i=0;i<256;i++){
    let c;
    if(kind===3){
      const v=Math.floor(i/16),t=i%16;
      const bend=(t-7.5)/7.5;
      c=[94+v*2.2+4*bend,102+v*2.1-4*bend,106+v*1.9+4.5*Math.sin(TAU*t/15)];
    }else if(kind===5){
      const g=i>>6,v=(i&63)-32;
      const bases=[[166,133,73],[67,61,51],[100,115,84],[187,151,79]];
      c=[bases[g][0]+v*.66,bases[g][1]+v*.58,bases[g][2]+v*.50];
    }else{
      const bases=[[179,144,83],[175,139,74],[146,155,154],[0,0,0],[159,168,166]];
      const b=bases[kind],d=i-138;
      c=[b[0]+d*.50,b[1]+d*.46,b[2]+d*.38];
    }
    for(let k=0;k<3;k++)p[3*i+k]=clamp(c[k]);
  }
  return p;
}
function paletteWear(){
  const p=new Uint8Array(768),bases=[[179,169,153],[113,106,95],[132,147,148],[190,190,178]];
  for(let i=0;i<256;i++){
    const g=i>>6,v=(i&63)-32;
    for(let k=0;k<3;k++)p[3*i+k]=clamp(bases[g][k]+v*(g===2?0.8:0.6));
  }
  return p;
}
function triangle(x,c,w){return Math.max(0,1-Math.abs(x-c)/w);}
function sampleWear(level,xx,yy){
  const x=xx,y=yy;
  const ang=-0.115,ca=Math.cos(ang),sa=Math.sin(ang);
  const u=(x-245)*ca+(y-1040)*sa;
  const v=-(x-245)*sa+(y-1040)*ca;
  const taper=Math.max(0,Math.min(1,(u-1190)/465));
  let top=-185+145*taper,bot=185-138*taper;
  const baseNotches=[
    [1110,22,15],[1325,28,9],
    [1040,34,32],[1260,36,21],[1410,28,15],
    [975,40,48],[1190,47,64],[1385,28,36],[1530,24,20],
    [875,62,83],[1115,56,115],[1325,47,73],[1500,40,53]
  ];
  const sets=[[[1110,22,15]],[[1040,34,32],[1260,36,21],[1410,28,15]],[[975,40,48],[1190,47,64],[1385,28,36],[1530,24,20]],[[875,62,83],[1115,56,115],[1325,47,73],[1500,40,53]]];
  for(const [c,w,d] of sets[level])top+=d*triangle(u,c,w);
  if(level>=1)top-=12*level*triangle(u,1285,12);
  if(level>=2)bot-=16*(level-1)*triangle(u,1372,25);
  if(level===3){top+=21*triangle(u,1580,17);bot+=12*triangle(u,1547,11);}
  const cap=1660-(Math.abs(v)/200)**2*105;
  const onMetal=u>-150&&u<cap&&v>=top&&v<=bot;
  const backdrop=periodic(x,y,7,2)*2.2+periodic(x,y,2,-5)*2.4+noise(x>>2,y>>2,33)*2.2;
  if(onMetal){
    const edge=Math.min(v-top,bot-v,cap-u);
    const streak=6*Math.sin(TAU*v*119/SIZE+0.02*Math.sin(TAU*u*7/SIZE));
    const gouge=(level+1)*0.65*Math.max(0,periodic(x,y,6,2))*triangle(u,1360,240);
    let shade=clamp(32+9*periodic(x,y,3,0)+streak+noise(x,y,17)*3.8-11*gouge,0,63);
    if(edge<12){shade=clamp(30+4*edge+streak,0,63);return 3*64+shade;}
    if(edge<28)shade=clamp(shade+15,0,63);
    return 2*64+shade;
  }
  // Soft contact shadow, not a glow; tool lies loose on a workbench.
  const near= u>-150&&u<1675&&v>bot&&v<bot+70;
  if(near){
    const f=(1-(v-bot)/70)*Math.max(0,Math.min(1,(1675-u)/150));
    return 1*64+clamp(48-15*f+backdrop,0,63);
  }
  return clamp(26+backdrop+7*Math.sin(TAU*y/SIZE),0,63);
}
function crcTable(){const table=new Uint32Array(256);for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=(c&1)?(0xedb88320^(c>>>1)):(c>>>1);table[n]=c>>>0;}return table;}
const CRC_TABLE=crcTable();
function crc32(data){let c=0xffffffff;for(let i=0;i<data.length;i++)c=CRC_TABLE[(c^data[i])&255]^(c>>>8);return (c^0xffffffff)>>>0;}
function bitReverse(n,len){let v=0;while(len--){v=(v<<1)|(n&1);n>>>=1;}return v;}
function makeCodes(lens){
  const count=new Uint16Array(16),next=new Uint16Array(16),codes=new Uint16Array(lens.length);
  for(const len of lens)if(len)count[len]++;
  let code=0;for(let bits=1;bits<16;bits++){code=(code+count[bits-1])<<1;next[bits]=code;}
  for(let i=0;i<lens.length;i++)if(lens[i])codes[i]=bitReverse(next[lens[i]]++,lens[i]);
  return codes;
}
function compress(data){
  // Per-image literal histogram, smoothed to keep the DEFLATE tree <= 15 bits.
  const hist=new Uint32Array(257);for(let i=0;i<data.length;i++)hist[data[i]]++;
  const nodes=[];for(let i=0;i<257;i++)nodes.push({w:128+Math.floor(hist[i]/64)+(i===256?1:0),sym:i});
  while(nodes.length>1){
    nodes.sort((a,b)=>a.w-b.w);
    const a=nodes.shift(),b=nodes.shift();nodes.push({w:a.w+b.w,left:a,right:b});
  }
  const ll=new Uint8Array(257);
  function assign(n,depth){if(n.sym!==undefined){ll[n.sym]=Math.max(1,depth);}else{assign(n.left,depth+1);assign(n.right,depth+1);}}
  assign(nodes[0],0);
  if(Math.max(...ll)>15)throw Error('Unexpected overly deep Huffman tree');
  const cl=new Uint8Array(19);for(let k=0;k<16;k++)cl[k]=4;
  const cc=makeCodes(cl),lc=makeCodes(ll);
  const out=new Uint8Array(Math.ceil(data.length*1.4)+2048);
  let pos=0,bits=0,acc=0;
  function write(v,n){acc|=v<<bits;bits+=n;while(bits>=8){out[pos++]=acc&255;acc>>>=8;bits-=8;}}
  write(1,1);write(2,2);write(0,5);write(0,5);write(15,4);
  const order=[16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];
  for(const k of order)write(cl[k],3);
  for(const len of ll)write(cc[len],cl[len]);
  write(cc[1],cl[1]);
  for(let i=0;i<data.length;i++){const v=data[i];write(lc[v],ll[v]);}
  write(lc[256],ll[256]);
  if(bits)out[pos++]=acc&255;
  const result=new Uint8Array(pos+6);result[0]=0x78;result[1]=0x01;
  result.set(out.subarray(0,pos),2);
  let s1=1,s2=0;
  for(let i=0;i<data.length;i++){s1+=data[i];s2+=s1;if((i&4095)===4095){s1%=65521;s2%=65521;}}
  s1%=65521;s2%=65521;
  const a=((s2<<16)|s1)>>>0;
  const p=result.length-4;result[p]=a>>>24;result[p+1]=(a>>>16)&255;result[p+2]=(a>>>8)&255;result[p+3]=a&255;
  return result;
}
function be32(out,offset,v){out[offset]=(v>>>24)&255;out[offset+1]=(v>>>16)&255;out[offset+2]=(v>>>8)&255;out[offset+3]=v&255;}
function chunk(type,content){
  const arr=new Uint8Array(content.length+12);
  be32(arr,0,content.length);
  for(let i=0;i<4;i++)arr[4+i]=type.charCodeAt(i);
  arr.set(content,8);be32(arr,content.length+8,crc32(arr.subarray(4,8+content.length)));
  return arr;
}
function png(w,h,filtered,colorType,palette){
  const ihdr=new Uint8Array(13);be32(ihdr,0,w);be32(ihdr,4,h);ihdr[8]=8;ihdr[9]=colorType;
  const parts=[Uint8Array.of(137,80,78,71,13,10,26,10),chunk('IHDR',ihdr)];
  if(palette)parts.push(chunk('PLTE',palette));
  parts.push(chunk('IDAT',compress(filtered)));parts.push(chunk('IEND',new Uint8Array()));
  const len=parts.reduce((n,v)=>n+v.length,0),result=new Uint8Array(len);
  let off=0;for(const p of parts){result.set(p,off);off+=p.length;}
  return result;
}
function render(w,h,bpp,fn){
  const out=new Uint8Array(h*(1+w*bpp));let offset=0;
  for(let y=0;y<h;y++){
    out[offset]=1;const last=new Uint8Array(bpp);
    for(let x=0;x<w;x++){
      const rgb=fn(x,y);
      for(let c=0;c<bpp;c++){
        const v=bpp===1?rgb:rgb[c];
        out[offset+1+x*bpp+c]=(v-last[c]+256)&255;
        last[c]=v;
      }
    }
    offset+=1+w*bpp;
  }
  return out;
}
function makeMaterialPng(kind){
  const height=render(SIZE,SIZE,1,(x,y)=>sampleMaterial(kind,x,y)[0]);
  const albedo=render(SIZE,SIZE,1,(x,y)=>sampleMaterial(kind,x,y)[1]);
  return {height:png(SIZE,SIZE,height,0,null),albedo:png(SIZE,SIZE,albedo,3,paletteMaterial(kind))};
}
function makeWearPng(level){
  const raw=render(SIZE,SIZE,1,(x,y)=>Math.round(sampleWear(level,x,y)/4)*4);
  return png(SIZE,SIZE,raw,3,paletteWear());
}
function makeMaterialPreview(){
  const w=1152,h=768,sw=384;
  const palettes=MATERIALS.map((_,k)=>paletteMaterial(k));
  const raw=render(w,h,3,(x,y)=>{
    const tx=Math.floor(x/sw),ty=Math.floor(y/sw),kind=ty*3+tx;
    const sample=sampleMaterial(kind,Math.floor((x%sw)*SIZE/sw),Math.floor((y%sw)*SIZE/sw))[1];
    const p=palettes[kind];return [p[sample*3],p[sample*3+1],p[sample*3+2]];
  });
  return png(w,h,raw,2,null);
}
function makeWearPreview(){
  const w=2048,h=512,sw=512,p=paletteWear();
  const raw=render(w,h,3,(x,y)=>{
    const level=Math.floor(x/sw),v=Math.round(sampleWear(level,(x%sw)*4,y*4)/4)*4;
    return [p[3*v],p[3*v+1],p[3*v+2]];
  });
  return png(w,h,raw,2,null);
}
function toBase64(bytes){
  const ABC='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  let block='',chunks=[];
  for(let i=0;i<bytes.length;i+=3){
    const a=bytes[i],b=i+1<bytes.length?bytes[i+1]:0,c=i+2<bytes.length?bytes[i+2]:0;
    block+=ABC[a>>2]+ABC[((a&3)<<4)|(b>>4)]+(i+1<bytes.length?ABC[((b&15)<<2)|(c>>6)]:'=')+(i+2<bytes.length?ABC[c&63]:'=');
    if(block.length>=16384){chunks.push(block);block='';}
  }
  if(block)chunks.push(block);
  return chunks.join('');
}
if(typeof require!=='undefined' && require.main===module){
  const fs=require('node:fs'),path=require('node:path');
  const root=__dirname;
  for(const sub of ['materials','wear','previews'])fs.mkdirSync(path.join(root,sub),{recursive:true});
  for(let k=0;k<MATERIALS.length;k++){
    const img=makeMaterialPng(k);
    for(const key of ['height','albedo']){
      const file=path.join(root,'materials',MATERIALS[k]+'_'+key+'.png');
      fs.writeFileSync(file,Buffer.from(img[key]));console.log(file,img[key].length);
    }
  }
  for(let l=0;l<WEAR.length;l++){
    const file=path.join(root,'wear','tool_tip_wear_'+WEAR[l]+'.png'),bytes=makeWearPng(l);
    fs.writeFileSync(file,Buffer.from(bytes));console.log(file,bytes.length);
  }
  for(const [name,func] of [['material_contact_sheet',makeMaterialPreview],['wear_contact_sheet',makeWearPreview]]){
    const file=path.join(root,'previews',name+'.png'),bytes=func();fs.writeFileSync(file,Buffer.from(bytes));console.log(file,bytes.length);
  }
}
