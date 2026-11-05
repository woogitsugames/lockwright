'use strict';
// Lockwright S03 -- original non-lexical synthetic character vocalizations.
// No third-party samples, AI cloning, or intelligible words. Deterministic.
const sampleRate=48000;
const profiles=[
{id:"halina",label:"Pani Halina",f0:191,f1:610,f2:1300,f3:2670,breath:.22,rough:.26,vibrato:.011,tempo:.96,voicing:.96},
{id:"zosia",label:"Pani Zosia",f0:174,f1:610,f2:1400,f3:2700,breath:.16,rough:.28,vibrato:.009,tempo:.95,voicing:.95},
{id:"stefan",label:"Pan Stefan",f0:120,f1:525,f2:1210,f3:2370,breath:.17,rough:.21,vibrato:.006,tempo:1.10,voicing:.99},
{id:"roman",label:"Pan Roman",f0:133,f1:505,f2:1350,f3:2550,breath:.10,rough:.10,vibrato:.003,tempo:.88,voicing:.95},
{id:"lena",label:"Aspirant Lena Sowa",f0:193,f1:590,f2:1550,f3:2840,breath:.12,rough:.03,vibrato:.003,tempo:.94,voicing:.98},
{id:"marta",label:"Marta",f0:213,f1:650,f2:1700,f3:3020,breath:.13,rough:.09,vibrato:.005,tempo:.95,voicing:.95},
{id:"zuzanna",label:"Zuzanna Wilk",f0:235,f1:690,f2:1810,f3:3220,breath:.12,rough:.05,vibrato:.007,tempo:.83,voicing:.98},
{id:"edek",label:"Pan Edek",f0:125,f1:480,f2:1110,f3:2350,breath:.21,rough:.22,vibrato:.010,tempo:1.07,voicing:.96},
{id:"ola_krystyna",label:"Ola / pani Krystyna (wspólny bank)",f0:182,f1:570,f2:1510,f3:2850,breath:.19,rough:.13,vibrato:.006,tempo:1.00,voicing:.96},
{id:"wladyslaw",label:"Pan Władysław",f0:109,f1:495,f2:1130,f3:2320,breath:.24,rough:.31,vibrato:.014,tempo:1.13,voicing:.92},
{id:"rygiel",label:"Dr Anna Rygiel",f0:179,f1:545,f2:1640,f3:2930,breath:.11,rough:.04,vibrato:.002,tempo:.90,voicing:.98},
{id:"jadwiga",label:"Pani Jadwiga",f0:171,f1:565,f2:1380,f3:2680,breath:.24,rough:.19,vibrato:.011,tempo:1.04,voicing:.94}
];
const events=[
{id:"greeting",label_pl:"powitanie",label_en:"greeting",duration:.75,shape:[[.08,.56,0,1,.84]],contour:[-.6,1.4,.2],vowel:-.12},
{id:"surprise",label_pl:"zdziwienie",label_en:"surprise",duration:.71,shape:[[.07,.52,1.1,1,.78]],contour:[-1,4.1,2.8],vowel:.22},
{id:"relief",label_pl:"ulga",label_en:"relief",duration:1.13,shape:[[.13,.78,-.4,.81,1.13]],contour:[1.6,-1.3,-3.0],vowel:.10},
{id:"thanks",label_pl:"podziękowanie",label_en:"thanks",duration:.89,shape:[[.09,.33,0,.83,.76],[.47,.31,2.0,.81,.69]],contour:[-.2,.6,-.8],vowel:-.18},
{id:"impatience",label_pl:"zniecierpliwienie",label_en:"impatience",duration:.88,shape:[[.08,.25,-1.1,.9,.80],[.44,.31,-2.3,.98,.85]],contour:[1.0,-1.7,-2.1],vowel:-.16},
{id:"sadness",label_pl:"smutek",label_en:"sadness",duration:1.23,shape:[[.11,.87,-1.7,.70,1.10]],contour:[.2,-1.9,-4.1],vowel:-.12},
{id:"laughter",label_pl:"śmiech",label_en:"laughter",duration:1.19,shape:[[.09,.20,2.3,.95,.95],[.36,.20,0,.94,.95],[.64,.24,1.2,.82,.97]],contour:[0,2.0,-.3],vowel:.13},
{id:"farewell",label_pl:"pożegnanie",label_en:"farewell",duration:.92,shape:[[.06,.71,.1,.83,.78]],contour:[1.0,-.3,-2.0],vowel:-.13}
];
const coeffs=[
{b:[1.53518289,-2.69180403,1.19842626],a:[1,-1.69069959,.73250471]},
{b:[.99504430,-1.99008859,.99504430],a:[1,-1.99007628,.99010090]}
];
function hash(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;}
function random(seed){let s=seed>>>0;return ()=>{s^=s<<13;s^=s>>>17;s^=s<<5;return (s>>>0)/4294967296;};}
function clamp(x,a,b){return x<a?a:x>b?b:x;}
function smooth(x){x=clamp(x,0,1);return x*x*(3-2*x);}
function filterBiquad(x,f){let x1=0,x2=0,y1=0,y2=0;const n=x.length,out=new Float64Array(n),b=f.b,a=f.a;for(let i=0;i<n;i++){let v=b[0]*x[i]+b[1]*x1+b[2]*x2-a[1]*y1-a[2]*y2;out[i]=v;x2=x1;x1=x[i];y2=y1;y1=v;}return out;}
function integratedLufs(x){let y=x;for(const f of coeffs)y=filterBiquad(y,f);const N=19200,step=4800;const zs=[];for(let start=0;start+N<=y.length;start+=step){let ss=0;for(let i=start;i<start+N;i++)ss+=y[i]*y[i];zs.push(ss/N);}if(!zs.length)throw Error("Audio shorter than 400ms");const absolute=zs.filter(z=>z>Math.pow(10,(-70+.691)/10));if(!absolute.length)throw Error("Audio silent");let avg=absolute.reduce((a,b)=>a+b,0)/absolute.length;const relative=avg/10;const chosen=absolute.filter(z=>z>=relative);avg=chosen.reduce((a,b)=>a+b,0)/chosen.length;return -.691+10*Math.log10(avg);}
function synth(profile,ev){
const rand=random(hash(profile.id+"|"+ev.id+"|S03-2026-11-05"));
const duration=ev.duration*profile.tempo*(.965+.07*rand());
const count=Math.round(duration*sampleRate);
const buf=new Float64Array(count);
const peakPitchShift=(rand()-.5)*.7;
const singing=ev.id==="laughter"?.022:ev.id==="sadness"?.012:.006;
const edges=ev.shape.map(s=>({on:s[0]*duration,off:(s[0]+s[1])*duration,shift:s[2]+peakPitchShift,amp:s[3],slope:s[4]}));
const f1=profile.f1*(1+ev.vowel*.7),f2=profile.f2*(1+ev.vowel*.4),f3=profile.f3*(1+ev.vowel*.16);
const harmonics=32,weights=new Float64Array(harmonics);
let energySum=0;
for(let h=1;h<=harmonics;h++){
let hz=profile.f0*h;
const gau=(x,c,w)=>Math.exp(-.5*((x-c)/w)**2);
const throat=(ev.id==="greeting"||ev.id==="thanks"||ev.id==="farewell")?.13:.04;
weights[h-1]=(.10+1.6*gau(hz,f1,205)+1.22*gau(hz,f2,300)+.75*gau(hz,f3,450)+throat*gau(hz,320,190))/Math.pow(h,.78);
energySum+=weights[h-1];
}
let phase=0,noiseLo=0,jitter=0;
const twopi=2*Math.PI,vib=profile.vibrato+singing;
for(let i=0;i<count;i++){
const t=i/sampleRate,tNorm=t/duration;
let env=0,weightedShift=0,edgeBreath=0;
for(const e of edges){
if(t<e.on||t>e.off)continue;
const p=(t-e.on)/(e.off-e.on);
const attack=smooth(Math.min(1,p*7)),release=smooth(Math.min(1,(1-p)*5));
const ee=e.amp*attack*release*(.88+.12*Math.sin(Math.PI*p));
env+=ee;weightedShift+=ee*e.shift;edgeBreath+=ee*(.28+(.72*(1-p)));
}
env=clamp(env,0,1.05);
const contour=ev.contour[0]*(1-smooth(tNorm*2))+ev.contour[1]*Math.sin(Math.PI*tNorm)*.6+ev.contour[2]*smooth(tNorm);
const steps=env>1e-5?weightedShift/env:0;
const pitch=Math.pow(2,(contour+steps)/12);
const vibS=Math.sin(twopi*(4.7+.15*(profile.f0%7))*t+.35)*vib;
jitter=jitter*.975+(.5-rand())*.025*profile.rough;
const f0=profile.f0*pitch*(1+vibS+jitter*.018);
phase+=twopi*f0/sampleRate;
if(phase>twopi)phase-=twopi;
let tone=0;
for(let h=1;h<=harmonics;h++)tone+=weights[h-1]*Math.sin(phase*h+.15*h+.08*Math.sin(twopi*2.1*t+h));
tone=tone/Math.sqrt(energySum*2.2);
const rnd=rand()*2-1;
noiseLo=noiseLo*.82+rnd*.18;
const breath=rnd-noiseLo;
const lowFry=(Math.sin(phase*.5+Math.sin(twopi*23*t))+.3*Math.sin(phase*.35))*.075*profile.rough;
const vocal=(tone+lowFry)*(1-.27*profile.breath);
let noise=breath*(.065+.10*profile.breath+(.13*(ev.id==="relief"||ev.id==="sadness"?1:0)))*edgeBreath;
if(ev.id==="laughter")noise*=1.42;
if(ev.id==="impatience")noise*=1.13;
let v=env*(profile.voicing*vocal+noise);
if((ev.id==="relief"||ev.id==="sadness")&&t<.15*duration){const e=smooth(t/(.045*duration))*smooth((.15*duration-t)/(.065*duration));v+=breath*.07*e;}
const fade=smooth(Math.min(1,(duration-t)/.03));
buf[i]=v*fade;
}
const before=integratedLufs(buf);
const gain=Math.pow(10,(-16-before)/20);
let peak=0;
for(let i=0;i<buf.length;i++){buf[i]*=gain;peak=Math.max(peak,Math.abs(buf[i]));}
if(peak>=.99)throw Error("Clipping "+profile.id+" "+ev.id+" "+peak);
const out=new Uint8Array(44+count*2),v=new DataView(out.buffer);
function four(pos,s){for(let i=0;i<s.length;i++)out[pos+i]=s.charCodeAt(i);}
four(0,"RIFF");v.setUint32(4,36+count*2,true);four(8,"WAVE");four(12,"fmt ");v.setUint32(16,16,true);v.setUint16(20,1,true);v.setUint16(22,1,true);v.setUint32(24,sampleRate,true);v.setUint32(28,sampleRate*2,true);v.setUint16(32,2,true);v.setUint16(34,16,true);four(36,"data");v.setUint32(40,count*2,true);
for(let i=0;i<count;i++){const s=Math.round(clamp(buf[i],-1,1)*32767);v.setInt16(44+2*i,s,true);}
const after=integratedLufs(buf);
return {bytes:out,duration:count/sampleRate,lufs:after,peak,preLufs:before};
}
function base64(bytes){const chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";let out=[];for(let i=0;i<bytes.length;i+=3){const a=bytes[i],b=i+1<bytes.length?bytes[i+1]:0,c=i+2<bytes.length?bytes[i+2]:0;let v=(a<<16)|(b<<8)|c;out.push(chars[(v>>>18)&63],chars[(v>>>12)&63],i+1<bytes.length?chars[(v>>>6)&63]:"=",i+2<bytes.length?chars[v&63]:"=");}return out.join("");}
if(typeof require!=="undefined"&&require.main===module){
const fs=require("fs"),path=require("path"),folder=process.argv[2]||path.join(__dirname,"voices");
fs.mkdirSync(folder,{recursive:true});const report=[];
for(const p of profiles){const dir=path.join(folder,p.id);fs.mkdirSync(dir,{recursive:true});
for(const e of events){const r=synth(p,e),file=path.join(dir,e.id+".wav");fs.writeFileSync(file,Buffer.from(r.bytes));report.push({file,seconds:r.duration,lufs:r.lufs,peak:r.peak,bytes:r.bytes.length});}}
fs.writeFileSync(path.join(folder,"qa.json"),JSON.stringify(report,null,2));
process.stdout.write("Generated "+report.length+" WAVs\n");
}
if(typeof module!=="undefined")module.exports={profiles,events,synth,base64};
