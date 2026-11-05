'use strict';
/** Original deterministic procedural foley. Node 18+, no external libraries or samples. */
function createS04() {
  const SR = 48000;
  const PEAK = Math.pow(10, -14 / 20);
  const CUES = {
    tool_roll_open:       {pl:'Rozwinięcie skórzanej zwijki',en:'Unroll leather tool wrap',ms:535,spread:25,prompt:'Soft leather fold unfolds on a workbench: short initial touch, broad fibrous swish, three shifting folds and a subdued final leather pat.'},
    tool_roll_close:      {pl:'Zwinięcie skórzanej zwijki',en:'Roll up leather tool wrap',ms:493,spread:26,prompt:'Firm, muffled leather swish winding inward, overlapping creases and a restrained closing fold on wood.'},
    pick_remove:          {pl:'Wyjęcie wytrycha z kieszeni',en:'Take pick from leather pocket',ms:246,spread:23,prompt:'Thin unbranded steel tool sliding out of a snug leather pocket: soft grainy drag, tiny polished-metal lift tick.'},
    pick_insert:          {pl:'Włożenie wytrycha do kieszeni',en:'Return pick to leather pocket',ms:260,spread:23,prompt:'Thin unbranded steel tool slipping into the leather sleeve, modest metallic slide and final cushioned pocket stop.'},
    brass_snap_pause:     {pl:'Mosiężna napa klapki pauzy',en:'Brass pause-flap press stud',ms:165,spread:14,prompt:'Small soft brass press-stud opening or closing on leather: distinct two-part dry pop and gentle folded-leather aftertouch.'},
    notebook_page_turn:   {pl:'Przewrócenie kartki zeszytu',en:'Turn notebook page',ms:447,spread:30,prompt:'A single matte notebook sheet flexes, brushes neighbouring paper and lands with a small dry flap; no interface chime.'},
    chalk_on_metal:       {pl:'Kreda po metalu',en:'Chalk rubbing on metal',ms:387,spread:31,prompt:'Dry chalk tip marks brushed satin metal: gritty interrupted friction, fine powder grains, one light starting contact.'},
    loupe_set_down:       {pl:'Odłożenie lupy na skórę',en:'Place loupe on leather',ms:218,spread:16,prompt:'Small magnifying glass with a subdued metal rim gently set on leather: padded landing, faint glass ring, no loud clang.'},
    loupe_apply:          {pl:'Przyłożenie lupy',en:'Raise loupe to eye',ms:243,spread:19,prompt:'Fingers pick a magnifier up from leather: brief leather scrape, subtle metal-rim touch, light glass handling.'},
    borescope_power_on:   {pl:'Włączenie boroskopu',en:'Switch on inspection scope',ms:428,spread:23,prompt:'Unbranded inspection scope powered on: gentle plastic switch click followed by quiet, low electric spool-up; hum itself is a separate seamless loop.'},
    phone_job_vibrate:    {pl:'Wibracja telefonu ze zleceniem na blacie',en:'Job phone vibrates on wooden counter',ms:530,spread:23,prompt:'Unbranded phone buzzes in two restrained short bursts against a wood workbench, with subtle wood rattle, no alert melody.'},
    showcase_drawer:      {pl:'Szuflada gabloty',en:'Showcase drawer',ms:549,spread:19,prompt:'Solid wooden display drawer runs along guides: dry sliding friction, a gentle hard-stop knock and tiny cabinet resonance.'},
    showcase_glass_door:  {pl:'Szklane drzwiczki gabloty',en:'Showcase glass door',ms:438,spread:29,prompt:'Small glass-fronted cabinet door moves: light frame squeak, delicate glass resonance and muted latch landing.'},
    coins_on_counter:     {pl:'Monety na blacie',en:'Coins on wooden counter',ms:383,spread:24,prompt:'A few fictional unbranded coins fall softly on a wooden worktop, irregular warm metal ticks and short staggered rolls.'},
    stamp_cancel:         {pl:'Kasownik pieczątki',en:'Self-inking receipt stamp',ms:291,spread:21,prompt:'Manual self-inking stamp depresses on paper with dull pad thump, a short mechanism click and sprung return.'},
    borescope_hum_loop:   {pl:'Pętla szumu boroskopu',en:'Inspection scope electrical hum loop',ms:1000,spread:0,prompt:'Separate 1-second seamless quiet inspection-scope electrical running hum, very subdued harmonics and fine periodic air noise, with no repeated power-on click.'}
  };
  const KINDS = {
    leather:{f:[145,322,730,1370],t:[.014,.010,.005,.003],g:[.6,.43,.24,.15],noise:.9,decay:.009},
    wood:{f:[182,300,470,765,1180],t:[.026,.018,.012,.009,.006],g:[.8,.61,.43,.25,.11],noise:.36,decay:.007},
    brass:{f:[690,1630,3350,5480],t:[.070,.037,.022,.014],g:[.8,.68,.33,.14],noise:.24,decay:.004},
    steel:{f:[1350,2870,4940,7850],t:[.064,.039,.021,.012],g:[.71,.65,.35,.17],noise:.30,decay:.005},
    glass:{f:[730,1660,3350,6080],t:[.165,.106,.061,.038],g:[.58,.8,.29,.15],noise:.11,decay:.003},
    coin:{f:[1130,2840,5510,9040],t:[.096,.064,.041,.018],g:[.74,.68,.39,.14],noise:.18,decay:.004},
    paper:{f:[340,1190,2210],t:[.006,.004,.003],g:[.2,.24,.12],noise:1.25,decay:.009},
    plastic:{f:[285,800,1650,3200],t:[.029,.019,.010,.006],g:[.9,.42,.19,.08],noise:.24,decay:.007},
    stamp:{f:[170,348,710,1320],t:[.026,.018,.008,.004],g:[1,.53,.23,.08],noise:.57,decay:.008}
  };
  function seedFor(id, v) {
    let h = 2166136261;
    const s = 'S04|20261105|' + id + '|' + v;
    for (let i=0;i<s.length;i++) { h ^= s.charCodeAt(i); h=Math.imul(h,16777619); }
    return h>>>0 || 123456789;
  }
  function random(seed) {
    let z=seed>>>0;
    return function(){z^=z<<13;z^=z>>>17;z^=z<<5;return (z>>>0)/4294967296;};
  }
  function render(id, variant) {
    if (!Object.prototype.hasOwnProperty.call(CUES,id) || !Number.isInteger(variant) || variant<1 || variant>6) throw new Error('Invalid cue/variant');
    const c=CUES[id], rnd=random(seedFor(id,variant)), r=()=>rnd()*2-1;
    const loop=id==='borescope_hum_loop';
    const durationMs=loop?1000:Math.max(80, Math.min(590, c.ms+(variant-3.5)*c.spread*.58+r()*c.spread*.44));
    const n=Math.round(durationMs*SR/1000), x=new Float64Array(n);
    const hzscale=.973+.054*rnd();
    function hit(ms,kind='leather',amp=.25,softness=1) {
      const k=KINDS[kind], at=Math.round(ms*SR/1000), lim=Math.min(n-at,Math.round(SR*Math.max(...k.t)*6));
      if(at<0||lim<=0) return;
      const detune=(rnd()-.5)*.055, phases=k.f.map(()=>rnd()*Math.PI*2);
      for(let i=0;i<lim;i++) {
        const t=i/SR, fade=Math.min(1,t/(.00016*softness)), click=r()*Math.exp(-t/k.decay)*k.noise;
        let reson=0;
        for(let m=0;m<k.f.length;m++) reson+=k.g[m]*Math.sin(2*Math.PI*k.f[m]*(1+detune)*hzscale*t+phases[m])*Math.exp(-t/k.t[m]);
        x[at+i]+=amp*fade*(reson*.64+click*.36);
      }
    }
    function rub(startMs,endMs,kind='leather',amp=.20,texture=1) {
      const at=Math.max(0,Math.round(startMs*SR/1000)), end=Math.min(n,Math.round(endMs*SR/1000));
      if(end<=at) return;
      const bands = {
        leather:[80,1850],paper:[170,5900],chalk:[520,9000],wood:[120,1800],metal:[300,7100],glass:[350,4200]
      };
      const [low,high]=bands[kind]||bands.leather, aHi=1-Math.exp(-2*Math.PI*high/SR), aLo=1-Math.exp(-2*Math.PI*low/SR);
      let lowPass=0,highPass=0,phase=rnd()*6.283185307,rate=35+35*rnd(),ridge=.32+.22*rnd();
      for(let i=at;i<end;i++) {
        const u=(i-at)/(end-at), tt=(i-at)/SR, z=r(), crest=Math.pow(Math.sin(Math.PI*u),.35);
        highPass += aHi*(z-highPass); lowPass+=aLo*(z-lowPass);
        const band=highPass-lowPass, grain=(rnd()>.979? .42*r():0);
        const scratches=(kind==='chalk'||kind==='wood'?1+.22*Math.sin(2*Math.PI*rate*tt+phase):1);
        const slip=1+ridge*Math.sin(2*Math.PI*(13+rnd()*4)*tt+phase);
        x[i]+=amp*crest*scratches*slip*(band*.79+grain*texture);
      }
    }
    function buzz(startMs,endMs,amp=.17) {
      const at=Math.round(startMs*SR/1000),end=Math.min(n,Math.round(endMs*SR/1000)),f=153+variant*3;
      for(let i=at;i<end;i++) {
        const t=(i-at)/SR,u=(i-at)/(end-at),env=Math.min(1, u*22,(1-u)*23), motor=(Math.sin(2*Math.PI*f*t)+.33*Math.sin(2*Math.PI*2*f*t)+.15*Math.sin(2*Math.PI*3*f*t));
        x[i]+=amp*env*(motor*.78+.14*r());
      }
    }
    function chirp(startMs,endMs,amp=.05) {
      const at=Math.round(startMs*SR/1000),end=Math.min(n,Math.round(endMs*SR/1000));
      for(let i=at;i<end;i++) {
        const u=(i-at)/(end-at),t=(i-at)/SR,env=Math.sin(Math.PI*u);
        x[i]+=amp*env*(.7*Math.sin(2*Math.PI*(220+85*u)*t)+.25*Math.sin(2*Math.PI*(462+160*u)*t)+.09*r());
      }
    }
    if(loop) {
      const raw=new Float64Array(n),baseHz=66+2*variant,ph1=2*Math.PI*rnd(),ph2=2*Math.PI*rnd(),ph3=2*Math.PI*rnd();
      for(let i=0;i<n;i++)raw[i]=r();
      for(let i=0;i<n;i++) {
        const t=i/SR, z=(raw[i]+raw[(i+n-1)%n]*.5+raw[(i+1)%n]*.5+raw[(i+n-2)%n]*.2+raw[(i+2)%n]*.2)/2.4;
        const breathe=1+.08*Math.sin(2*Math.PI*(2+variant%2)*t+ph3);
        x[i]=.17*breathe*(.72*Math.sin(2*Math.PI*baseHz*t+ph1)+.23*Math.sin(2*Math.PI*(baseHz*2)*t+ph2)+.08*Math.sin(2*Math.PI*(baseHz*5)*t+ph1))+z*.030;
      }
    } else {
      switch(id) {
        case 'tool_roll_open':
          hit(0,'leather',.17);rub(0,durationMs*.87,'leather',.26);for(let j=0;j<3;j++) hit(70+j*115+14*r(),'leather',.12+j*.015);hit(durationMs*.78,'leather',.27);break;
        case 'tool_roll_close':
          hit(0,'leather',.16);rub(0,durationMs*.88,'leather',.24);hit(durationMs*.38,'leather',.12);hit(durationMs*.68,'leather',.18);hit(durationMs*.84,'wood',.20);break;
        case 'pick_remove':
          hit(0,'leather',.18);rub(0,durationMs*.78,'leather',.17);rub(45,durationMs*.72,'metal',.062);hit(durationMs*.70,'steel',.18);break;
        case 'pick_insert':
          hit(0,'steel',.10);rub(0,durationMs*.82,'leather',.15);rub(20,durationMs*.82,'metal',.06);hit(durationMs*.81,'leather',.32);break;
        case 'brass_snap_pause':
          hit(0,'leather',.13);hit(3,'brass',.49);hit(35+4*r(),'brass',.20);rub(18,100,'leather',.085);break;
        case 'notebook_page_turn':
          hit(0,'paper',.15);rub(0,durationMs*.85,'paper',.28,1.5);rub(durationMs*.21,durationMs*.75,'paper',.17);hit(durationMs*.81,'paper',.37);break;
        case 'chalk_on_metal':
          hit(0,'chalk' in KINDS?'chalk':'paper',.20);rub(0,durationMs*.89,'chalk',.23,2.0);rub(70,durationMs*.82,'metal',.054);hit(durationMs*.73,'paper',.10);break;
        case 'loupe_set_down':
          hit(0,'leather',.15);rub(0,70,'leather',.13);hit(40,'glass',.09);hit(82+8*r(),'leather',.37);hit(90,'brass',.08);break;
        case 'loupe_apply':
          hit(0,'leather',.16);rub(0,durationMs*.69,'leather',.15);hit(durationMs*.42,'brass',.11);hit(durationMs*.72,'glass',.065);break;
        case 'borescope_power_on':
          hit(0,'plastic',.22);hit(16,'brass',.10);chirp(38,durationMs*.82,.055);rub(35,durationMs*.9,'metal',.025);break;
        case 'phone_job_vibrate':
          hit(0,'wood',.16);buzz(3,210,.21);hit(88,'wood',.14);buzz(270,durationMs*.93,.20);hit(340,'wood',.13);break;
        case 'showcase_drawer':
          hit(0,'wood',.18);rub(0,durationMs*.89,'wood',.23);rub(35,durationMs*.84,'metal',.065);hit(durationMs*.79,'wood',.42);break;
        case 'showcase_glass_door':
          hit(0,'wood',.15);rub(0,durationMs*.77,'glass',.16);hit(durationMs*.59,'glass',.13);hit(durationMs*.81,'plastic',.22);break;
        case 'coins_on_counter': {
          hit(0,'coin',.19);hit(1,'wood',.10);
          const count=3+(variant%3);
          for(let j=0;j<count;j++) {const ms=30+j*(43+6*rnd())+7*r();hit(ms,'coin',.33-.036*j);hit(ms+3,'wood',.09);}
          break;
        }
        case 'stamp_cancel':
          hit(0,'plastic',.12);rub(0,durationMs*.34,'metal',.065);hit(durationMs*.27,'stamp',.50);hit(durationMs*.29,'paper',.20);hit(durationMs*.56,'brass',.18);hit(durationMs*.67,'plastic',.12);break;
      }
    }
    let mean=0;for(let i=0;i<n;i++)mean+=x[i];mean/=n;
    let mx=0;
    for(let i=0;i<n;i++){
      let q=x[i]-mean;
      if(!loop){q*=Math.min(1,i/(.00022*SR))*Math.min(1,(n-1-i)/(.008*SR));}
      x[i]=q;mx=Math.max(mx,Math.abs(q));
    }
    if(!(mx>1e-8))throw new Error('silent '+id);
    const samples=new Int16Array(n);
    for(let i=0;i<n;i++)samples[i]=Math.max(-32768,Math.min(32767,Math.round(x[i]*PEAK/mx*32767)));
    const bytes=wav(samples,loop);
    let max=0,dc=0;for(let i=0;i<n;i++){max=Math.max(max,Math.abs(samples[i]));dc+=samples[i];}
    let onset=n;for(let i=0;i<n;i++){if(Math.abs(samples[i])>=max*Math.pow(10,-30/20)){onset=i;break;}}
    const stats={id,variant,frames:n,duration_ms:+(n/SR*1000).toFixed(3),onset_ms:+(onset/SR*1000).toFixed(4),peak_dbfs:+(20*Math.log10(max/32768)).toFixed(4),dc_dbfs:+(20*Math.log10(Math.abs(dc/n)/32768+1e-12)).toFixed(2),loop};
    return {bytes,stats};
  }
  function wav(samples,loop) {
    const n=samples.length, len=44+2*n+(loop?68:0),b=new Uint8Array(len),v=new DataView(b.buffer);
    const chars=(o,s)=>{for(let i=0;i<s.length;i++)b[o+i]=s.charCodeAt(i)};
    chars(0,'RIFF');v.setUint32(4,len-8,true);chars(8,'WAVE');chars(12,'fmt ');v.setUint32(16,16,true);v.setUint16(20,1,true);v.setUint16(22,1,true);v.setUint32(24,SR,true);v.setUint32(28,SR*2,true);v.setUint16(32,2,true);v.setUint16(34,16,true);
    let o=36;
    if(loop){chars(o,'smpl');v.setUint32(o+4,60,true);const nums=[0,0,Math.round(1e9/SR),60,0,0,0,1,0,0,0,0,n-1,0,0];for(let j=0;j<nums.length;j++)v.setUint32(o+8+j*4,nums[j],true);o+=68;}
    chars(o,'data');v.setUint32(o+4,n*2,true);o+=8;
    for(let i=0;i<n;i++)v.setInt16(o+2*i,samples[i],true);
    return b;
  }
  function base64(bytes) {
    const dict='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',parts=[];
    let s='';for(let i=0;i<bytes.length;i+=3){const a=bytes[i],hasB=i+1<bytes.length,hasC=i+2<bytes.length,b=hasB?bytes[i+1]:0,c=hasC?bytes[i+2]:0;
      s+=dict[a>>2]+dict[((a&3)<<4)|(b>>4)]+(hasB?dict[((b&15)<<2)|(c>>6)]:'=')+(hasC?dict[c&63]:'=');
      if(s.length>=8192){parts.push(s);s='';}}
    parts.push(s);return parts.join('');
  }
  return {SR,CUES,render,base64};
}

if (typeof require !== 'undefined' && typeof module !== 'undefined' && require.main === module) {
  const fs = require('node:fs'), path = require('node:path'), bank = createS04(), root = __dirname;
  for (const id of Object.keys(bank.CUES)) {
    const dir = path.join(root, 'ui', id); fs.mkdirSync(dir, {recursive:true});
    for (let v=1; v<=6; v++) {
      const {bytes,stats} = bank.render(id,v);
      if(stats.onset_ms>2 || Math.abs(stats.peak_dbfs+14)>.06 || (!stats.loop&&stats.duration_ms>600) || bytes.length>20000000) throw Error(JSON.stringify(stats));
      fs.writeFileSync(path.join(dir,id+'_'+String(v).padStart(2,'0')+'.wav'),Buffer.from(bytes));
    }
  }
  process.stdout.write('Rendered '+Object.keys(bank.CUES).length*6+' WAV files.\n');
}
