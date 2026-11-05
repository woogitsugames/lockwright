'use strict';
/** Independent manifest / WAV / EBU R128 momentary verification for S03v2. */
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {PROFILES,EMOTIONS,SR,momentaryLufs,onsetAndTail}=require('./generate_voices');
function fail(s){throw Error('S03v2 VERIFY FAIL: '+s);}
function readWav(file){
  const buf=fs.readFileSync(file);
  if(buf.length<44 || buf.toString('ascii',0,4)!=='RIFF'||buf.toString('ascii',8,12)!=='WAVE'||buf.toString('ascii',12,16)!=='fmt '||buf.toString('ascii',36,40)!=='data')fail('Invalid RIFF/WAVE PCM header '+file);
  const channels=buf.readUInt16LE(22),rate=buf.readUInt32LE(24),bits=buf.readUInt16LE(34),format=buf.readUInt16LE(20),byteLength=buf.readUInt32LE(40);
  if(channels!==1||rate!==SR||bits!==16||format!==1||byteLength!==buf.length-44)fail('Wrong PCM format '+file);
  const result=new Float64Array(byteLength/2);
  for(let i=0;i<result.length;i++)result[i]=buf.readInt16LE(i*2+44)/32767;
  return {samples:result,sha256:crypto.createHash('sha256').update(buf).digest('hex')};
}
function verify(root){
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'manifest.json'),'utf8'));
  const ids=PROFILES.map(x=>x.id).sort(),events=EMOTIONS.map(x=>x.id);
  if(JSON.stringify(Object.keys(manifest.characters).sort())!==JSON.stringify(ids))fail('IDs incomplete or unexpected');
  let verified=0;let maxError=0;
  for(const id of ids){
    const items=manifest.characters[id];if(!Array.isArray(items)||items.length!==8)fail('Wrong file count '+id);
    if(JSON.stringify(items.map(x=>path.basename(x.file)))!==JSON.stringify(events.map(x=>x+'.wav')))fail('Emotion filenames/order '+id);
    for(const x of items){
      const basename=path.join('voices',id,path.basename(x.file)).split(path.sep).join('/');
      if(x.file!==basename)fail('Unexpected relative path '+x.file);
      const full=path.join(root,x.file);if(!fs.existsSync(full))fail('Missing '+x.file);
      const {samples,sha256}=readWav(full);
      const dur=samples.length/SR,lufs=momentaryLufs(samples),q=onsetAndTail(samples);
      if(dur<.3||dur>1.5)fail('Out-of-range duration '+x.file);
      if(Math.abs(lufs+28)>.30)fail('Out-of-range momentary '+x.file+' '+lufs);
      if(q.first_ms>20||q.last_silence_ms>100)fail('Onset/tail '+x.file+' '+JSON.stringify(q));
      if(q.peak>=1)fail('Clipping '+x.file);
      if(sha256!==x.sha256)fail('SHA mismatch '+x.file);
      if(Math.abs(dur-x.duration_seconds)>.0001||Math.abs(lufs-x.lufs_momentary)>.003||Math.abs(q.first_ms-x.onset_ms)>.06||Math.abs(q.last_silence_ms-x.trailing_silence_ms)>.06)fail('Manifest values inconsistent '+x.file);
      maxError=Math.max(maxError,Math.abs(lufs+28));verified++;
    }
  }
  const found=[];
  for(const id of ids){const dir=path.join(root,'voices',id);for(const name of fs.readdirSync(dir))if(name.endsWith('.wav'))found.push(path.join(id,name));}
  if(found.length!==312||verified!==312)fail('Unexpected WAV count: '+found.length+' verified '+verified);
  process.stdout.write('S03-v2 VERIFY PASS: '+verified+' WAV / 39 persons / 8 emotions; max loudness error '+maxError.toFixed(4)+' LU.\n');
}
if(require.main===module){verify(path.resolve(process.argv[2]||__dirname));}
module.exports={verify};
