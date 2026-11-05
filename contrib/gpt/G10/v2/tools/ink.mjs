import { createRequire } from 'module'; import fs from 'fs';
const require=createRequire('/workspace/lockwright/mockups/');
let pw; try{pw=require('playwright')}catch{pw=require('/opt/node-tools/node_modules/playwright')}
const SP=process.argv[2], DIR='/workspace/lockwright/contrib/gpt/G10/pages-svg/';
const font=fs.readFileSync(SP+'/Caveat.ttf').toString('base64');
const hide=['#8e714a','#657f95','#a86359','#ae936f','#715538','#1d1b17','#5b533e','#856742'];
const b=await pw.chromium.launch(); const p=await b.newPage({viewport:{width:1600,height:2200}});
const out={};
for(const f of fs.readdirSync(DIR).filter(x=>/^(0[34]|ii-)/.test(x))){
  const svg=fs.readFileSync(DIR+f,'utf8');
  await p.setContent(`<html><head><style>@font-face{font-family:Cv;src:url(data:font/ttf;base64,${font})} html,body{margin:0;background:transparent} svg text{font-family:Cv !important;font-style:normal !important}</style></head><body>${svg}</body></html>`);
  const bb=await p.evaluate((hide)=>{
    const s=document.querySelector('svg'); let box=null;
    for(const e of s.querySelectorAll('*')){
      const fl=(e.getAttribute('fill')||''), st=(e.getAttribute('stroke')||'');
      if(fl==='url(#paper)'){const r=e.getBBox(); box=[r.x,r.y,r.width,r.height];}
      if(e.tagName==='text'||e.closest('text')) continue;
      if(fl.startsWith('url(')||hide.includes(fl.toLowerCase())||hide.includes(st.toLowerCase())||e.getAttribute('filter')) { if(!['stop','linearGradient','radialGradient','filter','defs'].includes(e.tagName)&&!e.closest('defs')) e.style.display='none'; }
    }
    s.style.background='transparent'; return box;
  },hide);
  await p.waitForTimeout(300);
  await p.screenshot({path:`${SP}/g10/${f.replace('.svg','')}.png`,omitBackground:true});
  out[f]=bb;
}
fs.writeFileSync(SP+'/g10/boxes.json',JSON.stringify(out)); await b.close();
