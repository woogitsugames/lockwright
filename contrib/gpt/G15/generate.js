/* G15 Lockwright district map - deterministic procedural art, no external assets. */
const W=4096,H=4096,S=4;
const P=[
[241,238,226],[248,246,236],[226,222,208],[210,208,197],
[216,215,204],[145,143,130],[252,250,240],[75,76,72],
[172,192,195],[91,118,122],[197,207,182],[113,138,105],
[165,105,88],[146,115,97],[105,103,96],[184,159,113],
[120,138,139],[242,231,207],[95,91,83],[163,160,148],
[227,214,190],[169,179,166],[189,137,112],[225,220,204]
];
const polygons=[
 [[395,365],[535,312],[665,325],[770,428],[738,625],[597,686],[444,610],[373,475]],
 [[410,183],[600,125],[786,212],[772,362],[665,403],[536,326],[398,356]],
 [[134,387],[400,362],[449,614],[406,770],[245,838],[121,632]],
 [[242,791],[411,743],[583,715],[659,912],[447,936],[224,896]],
 [[584,676],[746,618],[859,720],[921,914],[657,916]],
 [[756,326],[916,241],[962,442],[940,693],[841,740],[758,628]]
];
const chapters=[
 ['Pierwsza zmiana','First shift'],['Nocne dyzury','Night calls'],
 ['Strychy i spadki','Attics and inheritances'],['Szlak rzemiosla','Craft trail'],
 ['Droga na dworzec','Road to the station'],['Skarbiec','The vault']
];
const places=[
 {id:'workshop',pl:'Warsztat Henryka',en:"Henryk's Workshop",x:510,y:548,chapter:1},
 {id:'town_square',pl:'Stary Rynek',en:'Old Market Square',x:598,y:464,chapter:1},
 {id:'housing',pl:'Osiedle Sloneczne',en:'Sunny Estate',x:449,y:330,chapter:1},
 {id:'night_market',pl:'Nocny Rynek',en:'Night Market',x:624,y:236,chapter:2},
 {id:'inn',pl:'Gospoda pod Lipa',en:'Linden Inn',x:706,y:322,chapter:2},
 {id:'hill',pl:'Debowe Wzgorze',en:'Oak Hill',x:253,y:462,chapter:3},
 {id:'gardens',pl:'Ogrody nad Kanalkiem',en:'Canal Gardens',x:293,y:699,chapter:3},
 {id:'guild',pl:'Dziedziniec Cechowy',en:'Guild Courtyard',x:411,y:823,chapter:4},
 {id:'forge',pl:'Stara Kuznia',en:'Old Forge',x:528,y:872,chapter:4},
 {id:'station',pl:'Dworzec Dolny',en:'Lower Station',x:702,y:823,chapter:5},
 {id:'yard',pl:'Plac Kolejowy',en:'Railway Yard',x:810,y:861,chapter:5},
 {id:'museum',pl:'Muzeum Mechanizmow',en:'Museum of Mechanisms',x:876,y:448,chapter:6},
 {id:'port',pl:'Port Rzeczny',en:'River Port',x:872,y:624,chapter:6}
];
const streets=[
 ['Lipowa','Linden Street',390,444],['Waska','Narrow Street',530,392],
 ['Mlynarska','Mill Street',635,396],['Kamienna','Stone Street',536,578],
 ['Zaulek Sasiadow','Neighbours Lane',467,512],['Targowa','Market Street',582,273],
 ['Podcienia','Arcades Street',710,278],['Nadbrzezna','Riverside Street',724,562],
 ['Dzialkowa','Allotment Street',311,666],['Wierzbowa','Willow Street',234,546],
 ['Cechowa','Guild Street',378,866],['Kowalska','Smith Street',529,804],
 ['Torowa','Rail Street',661,759],['Dworcowa','Station Street',741,840],
 ['Portowa','Harbour Street',897,583],['Muzealna','Museum Street',860,382]
];
function rng(seed){let s=seed>>>0;return ()=>{s=(Math.imul(s,1664525)+1013904223)>>>0;return s/4294967296}}
const random=rng(15112026);
const data=new Uint8Array(W*H);
function p(x,y,c){x=Math.round(x*S);y=Math.round(y*S);if(x>=0&&y>=0&&x<1024&&y<1024)data[y*W+x]=c}
function rect(x,y,w,h,c){let a=Math.max(0,Math.floor(x*S)),b=Math.min(W,Math.ceil((x+w)*S));let ya=Math.max(0,Math.floor(y*S)),yb=Math.min(H,Math.ceil((y+h)*S));for(let yy=ya;yy<yb;yy++)data.fill(c,yy*W+a,yy*W+b)}
function ell(x,y,rx,ry,c){let xa=Math.max(0,Math.floor((x-rx)*S)),xb=Math.min(W-1,Math.ceil((x+rx)*S));let ya=Math.max(0,Math.floor((y-ry)*S)),yb=Math.min(H-1,Math.ceil((y+ry)*S));let yy0=y*S,xx0=x*S,rx2=rx*S,ry2=ry*S;for(let yy=ya;yy<=yb;yy++){let t=(yy-yy0)/ry2;if(t*t>1)continue;let hh=rx2*Math.sqrt(1-t*t);let a=Math.max(0,Math.round(xx0-hh)),b=Math.min(W,Math.round(xx0+hh));data.fill(c,yy*W+a,yy*W+b)}}
function poly(points,c){let ps=points.map(q=>[q[0]*S,q[1]*S]);let ymin=Math.max(0,Math.ceil(Math.min(...ps.map(q=>q[1])))),ymax=Math.min(H-1,Math.floor(Math.max(...ps.map(q=>q[1]))));for(let y=ymin;y<=ymax;y++){let ix=[];for(let i=0;i<ps.length;i++){let a=ps[i],b=ps[(i+1)%ps.length];if((a[1]<=y&&b[1]>y)||(b[1]<=y&&a[1]>y))ix.push(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]));}ix.sort((a,b)=>a-b);for(let k=0;k+1<ix.length;k+=2){let l=Math.max(0,Math.ceil(ix[k])),r=Math.min(W,Math.floor(ix[k+1]));if(r>l)data.fill(c,y*W+l,y*W+r)}}}
function line(a,b,c,w=2){let dx=b[0]-a[0],dy=b[1]-a[1],d=Math.hypot(dx,dy),n=Math.max(1,Math.ceil(d*2));let r=w/2;for(let i=0;i<=n;i++){let t=i/n;ell(a[0]+dx*t,a[1]+dy*t,r,r,c)}}
function path(points,c,w=2){for(let i=0;i<points.length-1;i++)line(points[i],points[i+1],c,w)}
function ring(x,y,rx,ry,c,w=2,shift=0){const ps=[];for(let i=0;i<=72;i++){let a=i*Math.PI/36;let rough=1+0.019*Math.sin(i*3.7+shift)+0.014*Math.cos(i*2.19+shift);ps.push([x+Math.cos(a)*rx*rough,y+Math.sin(a)*ry*rough])}path(ps,c,w)}
function dash(a,b,color,w=1,on=8,off=5){let dx=b[0]-a[0],dy=b[1]-a[1],len=Math.hypot(dx,dy);for(let t=0;t<len;t+=on+off){let t2=Math.min(len,t+on);line([a[0]+dx*t/len,a[1]+dy*t/len],[a[0]+dx*t2/len,a[1]+dy*t2/len],color,w)}}
function outline(points,c,w=2){path([...points,points[0]],c,w)}
function road(points,w){path(points,5,w+3);path(points,6,w)}
function tree(x,y,r){ell(x+1.2,y+2,r+2,r+1,3);ell(x,y,r,r*0.91,10);ring(x,y,r*0.76,r*0.65,11,0.65);ell(x-r*.2,y-r*.17,r*.15,r*.15,11)}
function structure(x,y,w,h){rect(x+1,y+1,w,h,5);rect(x+2,y+2,w-2,h-2,4);if(w>21&&h>18){rect(x+5,y+5,w-10,h-10,20);rect(x+8,y+8,w-16,h-16,4)}}
function drawText(s,x,y,k=2,c=7){let fg={A:['01110','10001','10001','11111','10001','10001','10001'],B:['11110','10001','10001','11110','10001','10001','11110'],C:['01111','10000','10000','10000','10000','10000','01111'],D:['11110','10001','10001','10001','10001','10001','11110'],E:['11111','10000','10000','11110','10000','10000','11111'],F:['11111','10000','10000','11110','10000','10000','10000'],G:['01111','10000','10000','10111','10001','10001','01110'],H:['10001','10001','10001','11111','10001','10001','10001'],I:['11111','00100','00100','00100','00100','00100','11111'],J:['00111','00010','00010','00010','10010','10010','01100'],K:['10001','10010','10100','11000','10100','10010','10001'],L:['10000','10000','10000','10000','10000','10000','11111'],M:['10001','11011','10101','10101','10001','10001','10001'],N:['10001','11001','10101','10011','10001','10001','10001'],O:['01110','10001','10001','10001','10001','10001','01110'],P:['11110','10001','10001','11110','10000','10000','10000'],R:['11110','10001','10001','11110','10100','10010','10001'],S:['01111','10000','10000','01110','00001','00001','11110'],T:['11111','00100','00100','00100','00100','00100','00100'],U:['10001','10001','10001','10001','10001','10001','01110'],V:['10001','10001','10001','10001','10001','01010','00100'],W:['10001','10001','10001','10101','10101','10101','01010'],X:['10001','10001','01010','00100','01010','10001','10001'],Y:['10001','10001','01010','00100','00100','00100','00100'],Z:['11111','00001','00010','00100','01000','10000','11111'],' ':['00000','00000','00000','00000','00000','00000','00000'],'.':['00000','00000','00000','00000','00000','00100','00100'],1:['00100','01100','00100','00100','00100','00100','01110'],2:['01110','10001','00001','00110','01000','10000','11111'],3:['11110','00001','00001','00110','00001','00001','11110'],4:['00010','00110','01010','10010','11111','00010','00010'],5:['11111','10000','10000','11110','00001','00001','11110'],6:['01111','10000','10000','11110','10001','10001','01110'],7:['11111','00001','00010','00100','01000','01000','01000'],8:['01110','10001','10001','01110','10001','10001','01110'],9:['01110','10001','10001','01111','00001','00001','11110'],0:['01110','10001','10011','10101','11001','10001','01110']};s=String(s).toUpperCase();let xx=x;for(const ch of s){let a=fg[ch]||fg[' '];for(let iy=0;iy<7;iy++)for(let ix=0;ix<5;ix++)if(a[iy][ix]==='1')rect(xx+ix*k,y+iy*k,k,k,c);xx+=k*6;}return xx-x;}
function baseMap(){data.fill(0);const rand=rng(12401983);
 // Sparse paper fibre flecks and fold shadows: tactile but not sepia.
 for(let i=0;i<180000;i++){let x=(rand()*W)|0,y=(rand()*H)|0;if(x<110*S||x>918*S||y<110*S||y>916*S)continue;data[y*W+x]=rand()<.7?1:2}
 rect(78,76,868,868,3);rect(88,87,846,849,0);rect(108,110,806,812,1);
 // Larger stains and old fold creases.
 for(let j=0;j<23;j++){let x=110+rand()*800,y=115+rand()*785;ring(x,y,7+rand()*13,2+rand()*8,2,.45,j)}
 line([512,105],[514,914],2,1);line([510,105],[512,914],23,.6);
 line([112,515],[918,517],2,.9);line([112,519],[918,521],23,.6);
 // Print frame.
 outline([[111,112],[911,112],[911,915],[111,915]],7,1.25);
 outline([[121,124],[901,124],[901,906],[121,906]],5,.8);
 // Residential parcels. Streets will be cut out above them.
 for(let y=196;y<895;y+=35)for(let x=165;x<914;x+=39){let xx=x+(rand()-.5)*10,yy=y+(rand()-.5)*10,w=22+rand()*12,h=20+rand()*10;if((xx<398&&yy>390&&yy<730)||(xx>760&&yy>350&&yy<740))continue;if(rand()<.12)continue;structure(xx,yy,w,h)}
 // Parks and gardens, no hyper-saturated greens.
 poly([[130,379],[350,367],[381,449],[328,554],[192,555],[131,482]],10);
 poly([[137,570],[362,551],[404,718],[297,787],[156,707]],21);
 poly([[738,715],[845,677],[913,742],[901,847],[776,812]],10);
 for(let i=0;i<71;i++){let x=155+rand()*190,y=386+rand()*150;if((x-250)**2/20000+(y-456)**2/6500<1.2)tree(x,y,3+rand()*5)}
 // Allotments rectangles + hand-drawn paths.
 for(let yy=581;yy<750;yy+=25)for(let xx=171;xx<346;xx+=28){rect(xx,yy,22,19,10);outline([[xx,yy],[xx+22,yy],[xx+22,yy+19],[xx,yy+19]],11,.6);if(rand()<.45)tree(xx+10,yy+8,3)}
 for(let i=0;i<35;i++){let x=769+rand()*109,y=715+rand()*113;tree(x,y,3+rand()*4)}
 // Water canal + river, irregular mapped banks.
 const river=[[846,144],[828,224],[811,315],[816,414],[793,494],[813,581],[817,663],[792,752],[828,855],[878,900]];
 path(river,9,67);path(river,8,61);path(river,16,1);
 path([[882,603],[931,595],[940,614],[901,640],[836,642]],9,36);
 path([[882,603],[931,595],[940,614],[901,640],[836,642]],8,30);
 // Main roads on top of parcels; bridge stoneworks across water later.
 const roads=[[[183,330],[379,327],[503,362],[666,367],[783,383]],[[170,512],[348,512],[495,506],[661,516],[775,523]],[[170,710],[355,697],[501,683],[669,698],[772,704]],[[423,188],[429,328],[428,479],[439,641],[443,817]],[[577,160],[589,326],[587,489],[579,650],[588,864]],[[728,206],[707,371],[711,528],[724,700],[745,861]],[[261,257],[338,382],[403,520],[482,660],[552,773]],[[227,846],[405,823],[588,829],[763,850]]];
 for(const r of roads)road(r,13);
 const minors=[[[219,229],[280,330],[320,509]],[[303,232],[302,365],[312,500]],[[498,191],[504,312],[506,509]],[[646,185],[645,365],[654,500]],[[380,398],[389,591],[349,684]],[[479,402],[489,536],[488,674]],[[551,390],[542,480],[545,659]],[[668,386],[665,524],[668,692]],[[341,564],[512,575],[698,595]],[[277,619],[460,623],[650,634]],[[274,753],[432,755],[610,752]],[[313,284],[498,276],[691,290]],[[351,436],[524,432],[704,448]]];
 for(const r of minors)road(r,5);
 // Ring road follows a non-geographic design, not a real town.
 road([[372,359],[519,316],[665,347],[762,432],[772,606],[662,720],[479,739],[351,637],[329,485],[372,359]],15);
 // Three river crossings.
 for(const y of [386,529,701]){rect(760,y-14,98,29,5);rect(764,y-10,90,21,6);for(let xx=766;xx<851;xx+=12)line([xx,y-10],[xx,y+11],5,.7)}
 // Market and courtyards.
 poly([[548,423],[637,420],[656,474],[635,527],[554,525],[531,472]],5);
 poly([[553,429],[630,427],[647,473],[628,520],[559,518],[540,473]],6);
 for(let i=0;i<15;i++){let x=553+rand()*85,y=436+rand()*74;ell(x,y,1,1,19)}
 ell(587,474,10,10,5);ell(587,474,7,7,20);ell(587,474,3,3,7);
 // City workbench building, guild block, station and museum silhouettes.
 structure(472,540,45,24);rect(485,563,8,8,7);
 structure(368,801,81,62);rect(387,814,39,35,6);outline([[387,814],[426,814],[426,849],[387,849]],5,1.5);
 structure(655,790,93,39);for(let i=0;i<5;i++)line([660+i*17,796],[660+i*17,824],5,1);
 structure(864,412,62,55);rect(878,422,34,28,6);ell(895,435,7,7,10);
 for(let i=0;i<4;i++){rect(860+i*15,558,11,46,19);outline([[860+i*15,558],[871+i*15,558],[871+i*15,604],[860+i*15,604]],7,.8)}
 // Rail sidings and sleepers, lower edge.
 for(let offset of [-6,0,7]){line([189,884+offset],[857,879+offset],7,.9)}
 for(let i=189;i<=857;i+=13){let y=884+(879-884)*(i-189)/668;line([i,y-12],[i,y+12],5,2.1)}
 // Front gardens, blocks, stairwells, independent of real-world street patterns.
 for(let i=0;i<55;i++){let x=280+rand()*435,y=215+rand()*460;if(x>530&&x<669&&y>412&&y<542)continue;if(x>790)continue;if(rand()<.4)tree(x,y,2+rand()*2.5)}
 // City legend and production-noise typography is kept language-neutral.
 drawText('ZAMECZNO',137,135,5,7);line([137,180],[319,180],5,1.2);
 drawText('I',555,355,2,14);drawText('II',617,164,2,14);drawText('III',226,406,2,14);
 drawText('IV',330,799,2,14);drawText('V',729,759,2,14);drawText('VI',866,342,2,14);
 // Compass etched in paper.
 line([872,169],[872,218],7,.9);line([846,192],[897,192],7,.9);
 poly([[872,169],[864,195],[872,189]],7);poly([[872,169],[880,195],[872,189]],19);
 drawText('N',868,154,1.5,7);
 // Hand-inked scale: symbolic, no real distances (this town is fictional).
 line([136,895],[231,895],7,1.2);for(const x of [136,183,231])line([x,890],[x,900],7,1);
 // Four pushpin holes (the workshop pins are separate overlays).
 for(const [x,y] of [[120,120],[903,120],[120,907],[903,907]]){ell(x+1,y+2,8,8,3);ell(x,y,7,7,15);ell(x-2,y-2,2,2,1)}
 return data;
}
function addMarks(n){const points=[[[493,549],[595,474],[461,349]],[[610,235],[711,318],[559,286]],[[261,479],[293,692],[380,624]],[[402,822],[534,865],[468,760]],[[693,820],[818,852],[648,761]],[[867,450],[874,606],[919,550]]];for(let j=0;j<n;j++){const poly1=polygons[j];outline(poly1,13,1.8);outline(poly1.map(([x,y],i)=>[x+Math.sin(i*2.3+j)*3,y+Math.cos(i*3.5+j)*2]),14,.8);const pts=points[j];for(let i=0;i<pts.length;i++){let [x,y]=pts[i];ring(x,y,20,17,14,2.5,j+i);ring(x+2,y-1,22,18,19,.6,2+i);let a=i*2.1+j*0.7;line([x+Math.cos(a)*17,y+Math.sin(a)*15],[x+Math.cos(a)*28,y+Math.sin(a)*24],14,1.9)}for(let i=0;i<pts.length-1;i++)dash(pts[i],pts[i+1],14,.55,2.5,6);const cent=[[595,550],[620,236],[237,573],[406,865],[714,789],[913,364]][j];ring(cent[0],cent[1],35,34,13,1.9,j);const tx=cent[0]-(j===1||j===2||j===3||j===5?18:9);drawText(['I','II','III','IV','V','VI'][j],tx,cent[1]-14,4,7)}}
function symbol(type){data.fill(0);if(type==='pin_red'||type==='pin_brass'){
 const head=type==='pin_red'?12:15;
 ell(70,92,32,15,3);poly([[102,119],[123,112],[127,107],[105,66],[93,70]],5);
 poly([[98,112],[119,109],[113,88]],18);
 ell(94,66,41,23,18);ell(91,62,38,21,head);ell(86,56,24,11,type==='pin_red'?22:17);
 ell(82,54,9,4,1);
 }else if(type==='pencil_circle'){ring(64,64,46,43,14,2.7,1);ring(67,64,44,44,19,.8,3)}
 else if(type==='pencil_arrow'){path([[25,101],[36,86],[58,75],[89,50]],14,3);path([[67,46],[90,49],[86,72]],14,3);line([69,47],[89,50],19,.9)}
 else if(type==='pencil_tick'){path([[31,71],[56,94],[102,31]],14,3);path([[33,74],[56,96],[102,35]],19,1.1)}
 else if(type==='pencil_scribble'){for(let i=0;i<8;i++)line([27+i*8,83],[58+i*8,41],14,1.8)}
 else if(type==='pencil_dashed_area'){for(let i=0;i<16;i++){let a=i*2*Math.PI/16,b=(i+.62)*2*Math.PI/16;line([64+49*Math.cos(a),64+47*Math.sin(a)],[64+49*Math.cos(b),64+47*Math.sin(b)],14,1.8)}}
}
function crc32(bytes){let v=-1;for(let b of bytes){v^=b;for(let k=0;k<8;k++)v=(v>>>1) ^ (-(v&1)&0xedb88320)}return (v^-1)>>>0}
function append32(n,out){out.push((n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255)}
function compressRLE(bytes){let buf=new Uint8Array(Math.max(1024,Math.floor(bytes.length*0.22)));let pos=0,bitbuf=0,bitn=0;const put=(v)=>{if(pos>=buf.length){let q=new Uint8Array(buf.length*2);q.set(buf);buf=q}buf[pos++]=v};const bits=(v,n)=>{bitbuf|=v<<bitn;bitn+=n;while(bitn>=8){put(bitbuf&255);bitbuf>>>=8;bitn-=8}};const rev=(v,n)=>{let o=0;for(let i=0;i<n;i++){o=(o<<1)|(v&1);v>>>=1}return o};const lit=(c)=>{let base,n;if(c<=143){base=48+c;n=8}else if(c<=255){base=400+c-144;n=9}else if(c<=279){base=c-256;n=7}else{base=192+c-280;n=8}bits(rev(base,n),n)};
 const LB=[3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258],LE=[0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0];function match(len){for(let k=0;k<29;k++){let mx=LB[k]+(1<<LE[k])-1;if(len<=mx||k===28){lit(257+k);if(LE[k])bits(len-LB[k],LE[k]);bits(0,5);break}}}
 bits(1,1);bits(1,2); // BFINAL=1, BTYPE=01 fixed Huffman.
 let a=1,b=0,i=0;const MOD=65521;for(let j=0;j<bytes.length;j++){a+=bytes[j];b+=a;if((j&8191)===8191){a%=MOD;b%=MOD}}a%=MOD;b%=MOD;
 while(i<bytes.length){let j=i+1;if(i>0&&bytes[i]===bytes[i-1]){j=i;while(j<bytes.length&&j<i+258&&bytes[j]===bytes[i-1])j++;if(j-i>=3){match(j-i);i=j;continue}}lit(bytes[i]);i++}
 lit(256);if(bitn)put(bitbuf&255);const out=new Uint8Array(pos+6);out[0]=0x78;out[1]=0x01;out.set(buf.subarray(0,pos),2);out.set([(b>>>8)&255,b&255,(a>>>8)&255,a&255],pos+2);return out;
}
function pngIndex(im,w,h,trans=false){const raw=new Uint8Array((w+1)*h);for(let y=0;y<h;y++)raw.set(im.subarray(y*w,(y+1)*w),y*(w+1)+1);const packed=compressRLE(raw);const out=[137,80,78,71,13,10,26,10];const chunk=(name,body)=>{append32(body.length,out);const nm=[...name].map(x=>x.charCodeAt(0));out.push(...nm);for(let i=0;i<body.length;i++)out.push(body[i]);append32(crc32([...nm,...body]),out)};const ih=[];append32(w,ih);append32(h,ih);ih.push(8,3,0,0,0);chunk('IHDR',ih);chunk('PLTE',P.flat());if(trans){const alpha=P.map((_,i)=>i===0?0:(i===3||i===19?95:255));chunk('tRNS',alpha)}chunk('IDAT',packed);chunk('IEND',[]);return Uint8Array.from(out)}
function b64(b){const chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';let s='';for(let i=0;i<b.length;i+=3){let n=(b[i]<<16)|((b[i+1]||0)<<8)|(b[i+2]||0);s+=chars[(n>>>18)&63]+chars[(n>>>12)&63]+(i+1<b.length?chars[(n>>>6)&63]:'=')+(i+2<b.length?chars[n&63]:'=')}return s}
function createAll(){baseMap();const files=[];files.push({name:'maps/zameczno_base.png',bytes:pngIndex(data,W,H,false)});const clean=data.slice();for(let i=1;i<=6;i++){data.set(clean);addMarks(i);files.push({name:`maps/zameczno_chapter_${i}.png`,bytes:pngIndex(data,W,H,false)})}for(let type of ['pin_red','pin_brass','pencil_circle','pencil_arrow','pencil_tick','pencil_scribble','pencil_dashed_area']){
 data.fill(0); // Draw 128x128 logical pixels, then crop a 512x512 transparent sprite.
 symbol(type);let sprite=new Uint8Array(512*512);for(let y=0;y<512;y++)sprite.set(data.subarray(y*W,y*W+512),y*512);files.push({name:`overlays/${type}.png`,bytes:pngIndex(sprite,512,512,true)})
 }data.set(clean);return files}
if(typeof module!=='undefined')module.exports={createAll,places,streets,chapters,polygons,PNGWidth:W,b64};
// CLI regeneration: only files inside this G15 directory are written.
if (typeof require !== "undefined" && typeof module !== "undefined" && require.main === module) {
  const fs = require("fs");
  const path = require("path");
  for (const asset of createAll()) {
    const target = path.join(__dirname, asset.name);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, Buffer.from(asset.bytes));
    process.stdout.write(asset.name + " (" + asset.bytes.length + " bytes)\\n");
  }
}
