'use strict';
/**
 * Lockwright S03-v2: original, non-lexical episodic character vocalisations.
 * Node.js >=18, no npm dependencies, no TTS, no third-party voice recordings.
 * All samples are reproducible from these parameters and FNV/xorshift seeds.
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const SR = 48000, TARGET_MOMENTARY = -28;

// id | display | age | F0 | F1 | F2 | F3 | breath | rough | vibrato | tempo | timbre | notes
// Every individual is fictional. Ages/characters from docs/handoff/MAGNIFIC-PORTRETY.md.
const PROFILE_ROWS = `
agnieszka|Agnieszka|45|187|610|1470|2830|.28|.09|.004|1.03|.96|Tired but kind night-shift nurse; warm exhale
aino|Aino|50|169|550|1390|2740|.16|.18|.005|1.02|.96|Finnish marine engineer; assured and weathered
bartek|Bartek|30|145|535|1310|2540|.16|.08|.005|.98|.97|Shy groom; modest, almost apologetic little chuckle
basia|Basia|48|205|635|1570|2900|.14|.06|.006|.90|.98|Cheerful practical residents committee secretary
bride|Kasia (panna młoda)|29|239|710|1800|3160|.15|.03|.008|.91|.98|Brisk delighted newlywed; lively light chuckle
captain|Kapitan statku|60|107|475|1160|2370|.16|.24|.007|1.05|.98|Steady older Nordic captain, low resonant growl
claimant|Rzekoma spadkobierczyni|33|215|680|1570|2950|.10|.05|.002|.88|.99|Overconfident claimant; tightly controlled reaction

darek|Darek|40|133|500|1240|2510|.20|.25|.006|.87|.93|Tense and frustrated, not threatening
elzbieta|Elżbieta|55|181|570|1470|2810|.13|.11|.004|.97|.98|Warm, methodical building manager
ewa|Ewa|50|186|595|1480|2910|.17|.14|.004|.86|.98|Decisive, always in a hurry
gosia|Gosia|36|194|610|1600|2980|.11|.04|.005|.99|.99|Calm, self-confident furniture restorer
hall_manager|Kierownik sali|45|139|530|1360|2570|.12|.07|.004|1.03|.98|Easygoing rehearsal-room manager
hania|Hania|7|338|815|2140|3540|.22|.01|.010|.84|.97|Seven-year-old girl; small bright breathy hum
headteacher|Dyrektor szkoły|50|166|540|1430|2670|.09|.05|.002|.96|.99|Measured, welcoming school headteacher
iga|Iga|27|232|715|1730|3210|.12|.06|.009|.87|.98|Energetic punctual indie drummer
irena|Pani Irena|79|157|525|1270|2600|.27|.24|.010|1.12|.90|Elderly gentle widow; tremulous quiet warmth
jacques|Monsieur Jacques|72|123|510|1230|2440|.22|.23|.008|1.06|.95|Courteous elderly Belgian neighbour
kazimierz|Pan Kazimierz|60|126|520|1320|2550|.14|.17|.007|.96|.97|Cheerful after a family celebration
krysia|Krysia|60|179|565|1400|2710|.20|.17|.006|1.00|.95|Dry humour, newspaper-reading kiosk regular
kuba|Kuba|23|158|570|1420|2740|.24|.07|.008|.87|.95|Nervous first job interview; hesitant
leopold|Pan Leopold|70|115|500|1210|2470|.22|.23|.011|1.11|.95|Seventy-year-old antiquarian; dignified amused gravel
magda|Magda|41|202|630|1560|2910|.19|.04|.006|1.00|.96|Slightly embarrassed bilingual translator
marcel|Marcel|29|153|550|1330|2640|.11|.08|.004|.90|.99|Businesslike brisk courier
marek|Marek|45|132|505|1340|2530|.11|.19|.004|.84|.97|Impatient heir, clipped exhale
martine|Madame Martine|74|165|545|1280|2610|.22|.19|.010|1.08|.94|Older Belgian woman, reserved elegance
mietek|Mietek|30|148|530|1330|2600|.18|.11|.006|.92|.97|Busy friendly pizza cook
nadia|Nadia|29|222|685|1710|3140|.24|.06|.007|.96|.97|Early-shift baker, sleepy friendly smile
neighbour_lucyna|Pani Lucyna|70|161|540|1300|2650|.17|.22|.008|1.00|.95|Vigilant elderly neighbour with dry scepticism
neighbour_robe|Sąsiad w szlafroku|50|127|480|1250|2470|.31|.18|.005|1.12|.93|Sleepy neighbour; stifled morning yawn
norbert|Norbert|43|142|530|1290|2590|.18|.09|.005|1.02|.97|Worried, courteous brother
pieter|Brat Pieter|66|132|520|1280|2590|.15|.16|.006|1.12|.97|Gentle, patient caretaker of beguinage
piotr|Piotr|38|136|505|1260|2550|.18|.06|.003|1.10|.97|Quiet, contemplative heir
renata|Pani Renata|52|199|650|1590|2950|.16|.14|.009|.84|.98|Fast-talking spirited pizzeria owner; non-lexical only
stranger|Nieznajomy|43|157|580|1510|2740|.07|.05|.003|.80|.99|Overly polite, hurried, tightly wound stranger
teresa|Pani Teresa|65|171|585|1440|2750|.17|.13|.007|1.04|.98|Amused older neighbour in dressing gown
tomasz|Tomasz|40|137|525|1310|2620|.14|.13|.005|1.08|.98|Kind carpenter and father, reassuring steady baritone
waldek|Pan Waldek|70|119|480|1200|2480|.20|.22|.009|1.07|.94|Older practical allotment neighbour
wanda|Pani Wanda|62|172|550|1430|2750|.14|.11|.005|.99|.98|Decisive tenement manager with a binder
zbyszek|Pan Zbyszek|74|109|475|1170|2420|.25|.26|.011|1.11|.93|Elderly gardener, gently gravelly humor
`;
const PROFILES = PROFILE_ROWS.trim().split(/\n/).filter(line => line.trim()).map(line => {
  const [id,label,age,f0,f1,f2,f3,breath,rough,vibrato,tempo,voicing,notes] = line.split('|');
  return {id,label,age:+age,f0:+f0,f1:+f1,f2:+f2,f3:+f3,
    breath:+breath,rough:+rough,vibrato:+vibrato,tempo:+tempo,voicing:+voicing,notes};
});
const EMOTIONS = [
  // The spans are fractions of total duration, and always begin at time zero.
  {id:'greeting', label:'powitanie',duration:.76, pitch:[-.8,1.0,-.2],vowel:-.20,breath:.85,
    spans:[[0,.982,0,1.0]],description:'One friendly closed-mouth rising-then-settling hum'},
  {id:'surprise',label:'zdziwienie',duration:.66,pitch:[-2,5.2,3.0],vowel:.18,breath:1.15,
    spans:[[0,.976,1.0,.95]],description:'A quick open-vowel gasp with pitch jump; no words'},
  {id:'relief',label:'ulga',duration:1.12,pitch:[1.3,-.7,-3.2],vowel:.04,breath:1.7,
    spans:[[0,.98,-.5,.91]],description:'Long fading, breath-inflected vocal sigh'},
  {id:'thanks',label:'podziękowanie',duration:.87,pitch:[0,1.2,-1.2],vowel:-.18,breath:.96,
    spans:[[0,.40,0,.83],[.47,.985,1.1,.90]],description:'Two small nonverbal hum pulses, no phonemes'},
  {id:'impatient',label:'zniecierpliwienie',duration:.80,pitch:[1.0,-2.0,-2.4],vowel:-.20,breath:1.4,
    spans:[[0,.32,-1.1,1.00],[.40,.982,-2.0,.94]],description:'Two low tense nasal grunts, no words'},
  {id:'sad',label:'smutek',duration:1.18,pitch:[0,-1.7,-4.4],vowel:-.28,breath:1.45,
    spans:[[0,.980,-1.0,.73]],description:'Slow, small mournful hum into a sigh'},
  {id:'laugh',label:'śmiech',duration:1.14,pitch:[0,2.0,-.4],vowel:.23,breath:1.55,
    spans:[[0,.24,2.0,.95],[.34,.59,0,.96],[.68,.986,1.2,.89]],description:'Three breathy voiced chuckle bursts; no words'},
  {id:'goodbye',label:'pożegnanie',duration:.83,pitch:[1.3,-.2,-2.4],vowel:-.17,breath:.93,
    spans:[[0,.984,.1,.90]],description:'Brief lowering humming acknowledgement'}
];
const KWEIGHT = [
 {b:[1.53518289,-2.69180403,1.19842626],a:[1,-1.69069959,.73250471]},
 {b:[.99504430,-1.99008859,.99504430],a:[1,-1.99007628,.99010090]}
];
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
const smooth=x=>{x=clamp(x,0,1);return x*x*(3-2*x);};
const gauss=(x,c,w)=>Math.exp(-.5*Math.pow((x-c)/w,2));
function hash(text){let h=2166136261;for(const c of text){h ^= c.charCodeAt(0);h=Math.imul(h,16777619);}return h>>>0;}
function random(seed){let x=seed>>>0;return ()=>{x ^= x<<13;x ^= x>>>17;x ^= x<<5;return (x>>>0)/4294967296;};}
function filter(x,par){const {b,a}=par;const out=new Float64Array(x.length);let x1=0,x2=0,y1=0,y2=0;
  for(let i=0;i<x.length;i++){const v=b[0]*x[i]+b[1]*x1+b[2]*x2-a[1]*y1-a[2]*y2;out[i]=v;x2=x1;x1=x[i];y2=y1;y1=v;}return out;}
function momentaryLufs(samples){
  let y=samples;for(const section of KWEIGHT)y=filter(y,section);
  const window=Math.round(.4*SR), step=Math.round(.01*SR);
  if(y.length<window)throw Error('Audio shorter than 400 ms');
  let sum=0;for(let i=0;i<window;i++)sum+=y[i]*y[i];let best=sum/window;
  for(let s=step;s+window<=y.length;s+=step){
    for(let i=s-step;i<s;i++)sum-=y[i]*y[i];
    for(let i=s+window-step;i<s+window;i++)sum+=y[i]*y[i];
    best=Math.max(best,sum/window);
  }
  return best>0 ? -.691+10*Math.log10(best) : -Infinity;
}
function buildSamples(profile,ev){
  const rng=random(hash(profile.id+'|'+ev.id+'|S03v2|2026-11-05'));
  const seconds=clamp(ev.duration*profile.tempo*(.962+.076*rng()),.42,1.44);
  const N=Math.round(seconds*SR), audio=new Float64Array(N), twoPi=2*Math.PI;
  const f1=profile.f1*(1+ev.vowel*.57),f2=profile.f2*(1+ev.vowel*.31),f3=profile.f3*(1+ev.vowel*.16);
  const H=30,weights=new Float64Array(H);let energy=0;
  for(let h=1;h<=H;h++){
    const hz=profile.f0*h;
    const formants= .11+1.75*gauss(hz,f1,215)+1.29*gauss(hz,f2,310)+.66*gauss(hz,f3,460)
      +.12*gauss(hz,330,175);
    weights[h-1]=formants/Math.pow(h,.81);
    energy+=weights[h-1]*weights[h-1];
  }
  const norm=1/Math.sqrt(energy*2.35);
  const curve=ev.pitch;
  let phase=0, noiseLo=0,jitter=0;
  const segments=ev.spans.map(([from,to,shift,amplitude])=>({from,to,shift,amplitude}));
  for(let i=0;i<N;i++){
    const t=i/SR, u=i/N;
    let envelope=0,shiftSum=0,breathEdge=0;
    for(const segment of segments){
      if(u<segment.from||u>=segment.to)continue;
      const p=(u-segment.from)/(segment.to-segment.from);
      const att=smooth(p*13),rel=smooth((1-p)*11);
      const e=segment.amplitude*att*rel*(.90+.1*Math.sin(Math.PI*p));
      envelope+=e;shiftSum+=e*segment.shift;breathEdge+=e*(.65+.35*(1-p));
    }
    envelope=clamp(envelope,0,1.15);
    const pitchCurve=u<.5?curve[0]+(curve[1]-curve[0])*smooth(u*2):curve[1]+(curve[2]-curve[1])*smooth((u-.5)*2);
    jitter=jitter*.984+(rng()-.5)*profile.rough*.030;
    const wobble=Math.sin(twoPi*(4.55+.1*(profile.f0%7))*t+0.35)*(profile.vibrato+(ev.id==='laugh'?.014:.003));
    const pitch=profile.f0*Math.pow(2,(pitchCurve+(envelope>1e-8?shiftSum/envelope:0))/12)*(1+wobble+jitter*.032);
    phase+=twoPi*pitch/SR;if(phase>twoPi)phase-=twoPi;
    let tone=0;
    for(let h=1;h<=H;h++)tone+=weights[h-1]*Math.sin(h*phase+.18*h+.07*Math.sin(twoPi*2.1*t+.23*h));
    tone*=norm;
    const rawNoise=rng()*2-1;noiseLo=noiseLo*.82+rawNoise*.18;
    const airy=rawNoise-noiseLo;
    const fry=(Math.sin(phase*.5+Math.sin(twoPi*21*t))+.3*Math.sin(phase*.33))*.070*profile.rough;
    let breath=airy*(.055+.10*profile.breath+.042*(ev.breath-1))*ev.breath*breathEdge;
    if(ev.id==='laugh')breath*=1.25;
    const voice=profile.voicing*(tone+fry)*(1-.22*profile.breath);
    let value=envelope*(voice+breath);
    // A little free exhalation gives sighs their characteristic initial soft breath.
    if((ev.id==='relief'||ev.id==='sad')&&u<.16){const puff=smooth(u/.025)*smooth((.16-u)/.09);value+=airy*.064*profile.breath*puff;}
    // Always end cleanly, but never leave an empty tail.
    value*=smooth((1-u)/.022);
    audio[i]=value;
  }
  return audio;
}
function onsetAndTail(samples){
  let peak=0;for(const x of samples)peak=Math.max(peak,Math.abs(x));
  const threshold=peak*.00316;let first=0,last=0;while(first<samples.length && Math.abs(samples[first])<threshold)first++;
  for(last=samples.length-1;last>=0 && Math.abs(samples[last])<threshold;last--){}
  return {first_ms:1000*first/SR,last_silence_ms:1000*(samples.length-1-last)/SR,peak};
}
function writeWav(target,samples){
  const out=Buffer.alloc(44+samples.length*2);
  out.write('RIFF',0);out.writeUInt32LE(36+samples.length*2,4);out.write('WAVE',8);
  out.write('fmt ',12);out.writeUInt32LE(16,16);out.writeUInt16LE(1,20);out.writeUInt16LE(1,22);
  out.writeUInt32LE(SR,24);out.writeUInt32LE(SR*2,28);out.writeUInt16LE(2,32);out.writeUInt16LE(16,34);
  out.write('data',36);out.writeUInt32LE(samples.length*2,40);
  for(let i=0;i<samples.length;i++)out.writeInt16LE(Math.round(clamp(samples[i],-1,1)*32767),44+i*2);
  fs.writeFileSync(target,out);
  return crypto.createHash('sha256').update(out).digest('hex');
}
function generate(root){
  if(PROFILES.length!==39)throw Error('Expected exactly 39 voice profiles');
  const ids=new Set(PROFILES.map(p=>p.id));if(ids.size!==39)throw Error('Duplicate id');
  const manifest={schema_version:1,project:'Lockwright',asset_batch:'S03v2',format:{container:'RIFF/WAVE',codec:'PCM signed 16-bit',sample_rate_hz:SR,channels:1},
    target_momentary_lufs:TARGET_MOMENTARY,meter:'K-weighted EBU R128, peak sliding 400 ms window / 10 ms hop',
    characters:{}};
  let count=0, minTime=Infinity,maxTime=0,minLufs=Infinity,maxLufs=-Infinity,maxOnset=0,maxTail=0,maxPeak=0;
  const qa=[];
  for(const profile of PROFILES){
    const base=path.join(root,'voices',profile.id);fs.mkdirSync(base,{recursive:true});
    const all=[];
    for(const emotion of EMOTIONS){
      const samples=buildSamples(profile,emotion);
      const pre=momentaryLufs(samples);
      const gain=Math.pow(10,(TARGET_MOMENTARY-pre)/20);
      for(let i=0;i<samples.length;i++)samples[i]*=gain;
      // Audit the actually stored 16-bit samples (not just high-precision synthesis).
      const quantized=new Float64Array(samples.length);
      for(let i=0;i<samples.length;i++)quantized[i]=Math.round(clamp(samples[i],-1,1)*32767)/32767;
      const stats=onsetAndTail(quantized);const after=momentaryLufs(quantized);
      const filename=emotion.id+'.wav',rel='voices/'+profile.id+'/'+filename;
      if(samples.length/SR<.3 || samples.length/SR>1.5 || stats.first_ms>20 || stats.last_silence_ms>100 || stats.peak>=.99 || Math.abs(after-TARGET_MOMENTARY)>.16)
        throw Error('QC '+rel+': '+JSON.stringify({duration:samples.length/SR,onset:stats.first_ms,tail:stats.last_silence_ms,peak:stats.peak,momentary:after}));
      const sha256=writeWav(path.join(base,filename),samples);
      const item={file:rel,duration_seconds:+(samples.length/SR).toFixed(5),lufs_momentary:+after.toFixed(3),onset_ms:+stats.first_ms.toFixed(2),trailing_silence_ms:+stats.last_silence_ms.toFixed(2),peak_linear:+stats.peak.toFixed(5),sha256};
      all.push(item);qa.push(item);
      count++;minTime=Math.min(minTime,item.duration_seconds);maxTime=Math.max(maxTime,item.duration_seconds);
      minLufs=Math.min(minLufs,after);maxLufs=Math.max(maxLufs,after);
      maxOnset=Math.max(maxOnset,stats.first_ms);maxTail=Math.max(maxTail,stats.last_silence_ms);maxPeak=Math.max(maxPeak,stats.peak);
    }
    manifest.characters[profile.id]=all;
    process.stdout.write(profile.id+' ');
  }
  process.stdout.write('\n');
  const summary={characters:PROFILES.length,emotions:EMOTIONS.length,files:count,
    min_duration_s:+minTime.toFixed(3),max_duration_s:+maxTime.toFixed(3),
    min_momentary_lufs:+minLufs.toFixed(3),max_momentary_lufs:+maxLufs.toFixed(3),
    max_onset_ms:+maxOnset.toFixed(2),max_trailing_silence_ms:+maxTail.toFixed(2),max_peak_linear:+maxPeak.toFixed(5)};
  manifest.summary=summary;
  fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  const table=PROFILES.map(p=>`| \`${p.id}\` | ${p.label} | ${p.age} | ${p.f0} | ${p.f1}/${p.f2}/${p.f3} | ${p.breath}/${p.rough}/${p.vibrato}/${p.tempo}/${p.voicing} | ${p.notes} |`).join('\n');
  const emotionTable=EMOTIONS.map(e=>`| \`${e.id}.wav\` | ${e.label} | ${e.duration} | ${e.description} |`).join('\n');
  const assets=`# S03-v2 — karta techniczna głosów\n\n## Metoda i prawa\n\n- **Generator:** własny generator DSP w Node.js 18+, bez pakietów zewnętrznych. Synteza addytywna 30 harmonicznych ze zmienną F0, trzema szczytami formantowymi, szumem oddechu, tremolem, jitterem i obwiedniami wielopulsowymi; po syntezie normalizacja K-weighted EBU R128 momentary.\n- **Użyte modele AI / klonowanie:** żadne. Brak słów, fonemów, imitacji konkretnych realnych osób, próbek aktorów, bibliotek sampli i nagrań osób trzecich.\n- **Licencja narzędzia:** kod generatora stanowi część oryginalnego wkładu do projektu Lockwright. Node.js jest udostępniany na licencji MIT; użyto wyłącznie jego modułów wbudowanych. WAV-y zostały wytworzone matematycznie od podstaw, bez licencji na cudze sample. Zasady rozpowszechniania tych nowych assetów wynikają z licencji repozytorium.\n- **Zgodność:** każda osoba jest fikcyjna; parametry estetyczne to decyzje artystyczne oparte na \`docs/handoff/MAGNIFIC-PORTRETY.md\`, \`docs/CLIENTS.md\` i \`game/i18n/content.csv\`.\n- **Uwaga artystyczna:** proceduralne wokalizacje są prototypami, nie realistycznym aktorstwem. Nie przeprowadzano jeszcze testu zewnętrznego ASR ani odsłuchu w grze.\n\n## Przypisanie emocji\n\n| Nazwa pliku | Funkcja | Bazowa długość (s) | Prompt niemy / charakter artykulacji |\n|---|---|---:|---|\n${emotionTable}\n\n## Parametry i prompt każdej z 39 postaci\n\nPrompt dla każdej postaci: **\"Create the eight abstract non-lexical voiced hums and breaths described above, with no intelligible syllables, at profile pitch F0 and three vocal tract resonances F1/F2/F3; match the personality below; no celebrity resemblance.\"** Parametry określają indywidualne brzmienie, a nasiona FNV są deterministyczne dla \`id|emotion|S03v2|2026-11-05\`. Jednostki F0 i formantów: Hz. Współczynniki oddechu, chropowatości, vibrato, tempa i voicing są bezwymiarowe.\n\n| ID | Fikcyjna postać | Wiek | F0 Hz | F1/F2/F3 Hz | breath/rough/vibrato/tempo/voicing | Wytyczna barwy i charakteru |\n|---|---|---:|---:|---|---|---|\n${table}\n\n## Dostarczenie i pomiar\n\n- 39 × 8 = **${count}** różnych mono PCM16 WAV / 48 kHz; po jednym na emocję i ID.\n- Docelowy peak **${TARGET_MOMENTARY} LUFS momentary**, mierzony oknem 400 ms co 10 ms z korekcją K-weight (nie jest to to samo co LUFS integrated).\n- Każdy plik ma metryki i SHA-256 w \`manifest.json\`; walidator \`verify_voices.js\` sprawdza parametry niezależnie.\n- Ustawienia syntezy i prawa są opisane w źródle \`generate_voices.js\`.\n`;
  fs.writeFileSync(path.join(root,'ASSETS.md'),assets);
  const readme=`# S03-v2 — głosy epizodyczne Lockwright\n\n**312 plików WAV** dla 39 postaci × 8 emocji, bez zrozumiałych słów. Wokalizacje z generatora syntezy harmoniczno-formantowej (bez TTS i bez klonowania). Wszystkie głosy są fikcyjne i różnicowane wysokością, chropowatością, tembrem, oddechem i tempem zależnie od wieku oraz charakteru.\n\n## Struktura\n\n- \`voices/<id>/greeting.wav\` — powitanie\n- \`voices/<id>/surprise.wav\` — zdziwienie\n- \`voices/<id>/relief.wav\` — ulga\n- \`voices/<id>/thanks.wav\` — podziękowanie\n- \`voices/<id>/impatient.wav\` — zniecierpliwienie\n- \`voices/<id>/sad.wav\` — smutek\n- \`voices/<id>/laugh.wav\` — śmiech\n- \`voices/<id>/goodbye.wav\` — pożegnanie\n\nNazwy różnią się od katalogu \`S03\` (który używa m.in. \`impatience.wav\`, \`sadness.wav\`, \`laughter.wav\`, \`farewell.wav\`); tutaj obowiązują **dokładnie** nazwy z zamówienia S03-v2.\n\n## Specyfikacja\n\nWAV, PCM16 signed, mono, 48 000 Hz, długość 0,3–1,5 s, docelowo –28 LUFS EBU R128 momentary. Rozpoczęcie dźwięku do 20 ms, cisza na końcu maks. 100 ms. Weryfikacja automatyczna na etapie generacji i w \`verify_voices.js\`.\n\nMetoda, przypisania postaci, parametry 39 profili i kwestia licencji: \`ASSETS.md\`. Dokładne czasy, głośność, początek, ogon, maksymalny poziom i SHA-256 każdego WAV-a: \`manifest.json\`.\n\n## Odtworzenie (Node.js 18+)\n\nZ katalogu głównego repozytorium:\n\n\`\`\`sh\nnode contrib/gpt/S03v2/generate_voices.js contrib/gpt/S03v2\nnode contrib/gpt/S03v2/verify_voices.js contrib/gpt/S03v2\n\`\`\`\n\nNie są wymagane npm ani połączenie internetowe. Skrypt tworzy 312 plików, manifest i odtwarza także README oraz ASSETS. Powtórna generacja daje identyczne SHA-256 pod tym samym środowiskiem Node.\n\n## Kontrola jakości i ograniczenia\n\n${count} / ${count} plików spełnia numeryczne warunki weryfikacji metadanych i poziomu. Zmierzone długości: ${summary.min_duration_s}–${summary.max_duration_s} s; momentary: ${summary.min_momentary_lufs} do ${summary.max_momentary_lufs} LUFS; najpóźniejszy start: ${summary.max_onset_ms} ms; najdłuższa cisza na końcu: ${summary.max_trailing_silence_ms} ms.\n\nNie wykonano odsłuchu aktorskiego w grze ani sprawdzenia zewnętrznym ASR. Syntetyczne odgłosy nie zawierają wygenerowanych słów, ale zewnętrzny system rozpoznawania może czasem interpretować dźwięki bezsłowne jako tekst (fałszywe rozpoznania). Zalecany odsłuch losowej próby i kontrola na urządzeniach docelowych.\n`;
  fs.writeFileSync(path.join(root,'README.md'),readme);
  const report=`# S03-v2 — raport QA\n\nWynik lokalnego generatora i analizy momentary K-weighted.\n\n| Metryka | Wynik | Próg |\n|---|---:|---|\n| Postacie | ${summary.characters} | 39 |\n| Emocje na postać | ${summary.emotions} | 8 |\n| WAV | ${summary.files} | 312 |\n| Zakres długości | ${summary.min_duration_s}–${summary.max_duration_s} s | 0,3–1,5 s |\n| LUFS momentary | ${summary.min_momentary_lufs}–${summary.max_momentary_lufs} | ok. −28 |\n| Najpóźniejszy początek | ${summary.max_onset_ms} ms | ≤ 20 ms |\n| Najdłuższa końcowa cisza | ${summary.max_trailing_silence_ms} ms | ≤ 100 ms |\n| Najwyższy peak | ${summary.max_peak_linear} | < 1,0 |\n\n**Status automatyczny:** PASS. Bez oceny artystycznej, odsłuchu i ASR.\n\nDane indywidualne, w tym SHA-256, w \`manifest.json\`.\n`;
  fs.writeFileSync(path.join(root,'QA.md'),report);
  process.stdout.write(JSON.stringify(summary)+'\n');
}
if(require.main===module){generate(path.resolve(process.argv[2]||__dirname));}
module.exports={PROFILES,EMOTIONS,SR,TARGET_MOMENTARY,momentaryLufs,onsetAndTail,generate};
