from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, random, os, textwrap, json, zipfile
from pathlib import Path
random.seed(1405)
OUT=Path('/mnt/data/contrib/gpt/G14'); P=OUT/'png'
S='/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf'; SB='/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf'; L='/usr/share/fonts/truetype/lato/Lato-Regular.ttf'; LB='/usr/share/fonts/truetype/lato/Lato-Bold.ttf'; IT='/usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf'
def f(size,bold=False,serif=False,italic=False):return ImageFont.truetype(IT if italic else SB if serif and bold else S if serif else LB if bold else L,size)
def paper(w=1080,h=1500,col=(237,226,205),shape='paper',seed=0):
 rng=np.random.default_rng(seed); arr=np.empty((h,w,4),dtype=np.uint8); noise=rng.normal(0,4,(h,w)); y,x=np.indices((h,w)); grain=noise+3*np.sin(x/71+y/193)+2*np.sin(x/23-y/99)
 for c in range(3):arr[:,:,c]=np.clip(col[c]+grain,0,255)
 edge=24+rng.integers(-5,6,size=h); alpha=np.zeros((h,w),dtype=np.uint8)
 for yy in range(h):
  left=int(edge[yy]+4*np.sin(yy/21));right=w-left
  alpha[yy,max(0,left):min(w,right)]=255
 for xx in range(w):
  top=int(20+6*np.sin(xx/37)+rng.integers(-2,3));bot=int(h-20-5*np.sin(xx/41))
  alpha[:top,xx]=0;alpha[bot:,xx]=0
 if shape=='card':
  alpha=np.zeros((h,w),np.uint8)
  from PIL import ImageDraw as D
  mask=Image.new('L',(w,h));d=D.Draw(mask);d.rounded_rectangle((25,25,w-25,h-25),radius=65,fill=255);alpha=np.array(mask)
 if shape=='note':
  for xx in range(w):
   alpha[:int(40+12*np.sin(xx/17)),xx]=0
   alpha[h-int(45+10*np.sin(xx/13)):,xx]=0
 arr[:,:,3]=alpha
 im=Image.fromarray(arr,'RGBA');d=ImageDraw.Draw(im)
 for xx in range(80,w-60,90):
  if shape=='paper':d.line([(xx,29),(xx+8,33)],fill=(130,100,70,45),width=1)
 for yy in range(80,h-50,130):d.arc((25,yy,w-25,yy+130),0,10,fill=(125,99,65,18),width=2)
 return im,d
def txt(d,xy,s,size=34,bold=False,serif=False,fill=(52,47,41,255),italic=False):d.text(xy,s,font=f(size,bold,serif,italic),fill=fill)
def line(d,y,label,x=100,right=980):
 txt(d,(x,y),label,31); d.line((x,y+78,right,y+78),fill=(93,84,73,180),width=2)
def rule(d,y):d.line((100,y,980,y),fill=(100,88,70,150),width=3)
def header(d,kind,sub):
 txt(d,(100,100),'LOCKWRIGHT',57,True,True)
 txt(d,(100,167),sub,25)
 rule(d,224);txt(d,(100,265),kind,49,True,True)
def manager_stamp(im,lang):
 stamp=Image.new('RGBA',(470,200));st=ImageDraw.Draw(stamp);ink=(134,63,54,188)
 st.rounded_rectangle((10,12,458,188),radius=7,outline=ink,width=6)
 for off in (23,35): st.line((off,52,455-off,52),fill=ink,width=2)
 rows=['ADMINISTRACJA KAMIENICY','PRZY UL. LIPOWEJ'] if lang=='pl' else ['LIPOWA STREET','BUILDING MANAGEMENT']
 for i,row in enumerate(rows):st.text((40,64+i*48),row,font=f(26,True),fill=ink)
 stamp=stamp.rotate(-8,expand=True,resample=Image.Resampling.BICUBIC);im.alpha_composite(stamp,(530,1050))

def draw(kind,lang,seed):
 en=lang=='en'; w=1080;h=1500
 if kind=='tenant': w,h=1500,980
 if kind=='note':w,h=1500,960
 if kind=='envelope':w,h=1500,1000
 im,d=paper(w,h,(232,221,200) if kind in ('tenant','envelope') else (242,235,217) if kind=='note' else (236,226,207), 'card' if kind=='tenant' else 'note' if kind=='note' else 'paper',seed)
 if kind=='job':
  header(d,'JOB ORDER' if en else 'KARTA ZLECENIA','Emergency locksmith • fictional stationery' if en else 'Pogotowie zamkowe • druk fikcyjny')
  txt(d,(100,360),'No. __________',31);txt(d,(690,360),'Date: __________' if en else 'Data: __________',31)
  for y,t in zip([470,620,770,920],(['Address','Time','Client','Notes'] if en else ['Adres','Godzina','Klient','Uwagi'])):line(d,y,t+':')
  rule(d,1090);txt(d,(100,1140),'Access rights checked:' if en else 'Sprawdzono prawo do lokalu:',30)
  for i,t in enumerate((['Documents','Witness / manager','Not confirmed'] if en else ['Dokumenty','Świadek / zarządca','Nie potwierdzono'])):txt(d,(112,1200+i*65),'□  '+t,28)
 elif kind=='receipt':
  header(d,'RECEIPT' if en else 'POKWITOWANIE','Locksmith service • fictional sample' if en else 'Usługa ślusarska • druk fikcyjny')
  txt(d,(100,355),'Receipt no.: __________' if en else 'Nr rachunku: __________',30)
  for y,t in zip([440,545,650],['Date','Customer','Service'] if en else ['Data','Klient','Usługa']):line(d,y,t+':')
  txt(d,(100,810),'Description' if en else 'Opis',30,True);txt(d,(790,810),'Amount' if en else 'Kwota',30,True)
  for y in (870,940,1010):rule(d,y)
  txt(d,(100,1100),'Total: __________' if en else 'Razem: __________',38,True)
  txt(d,(100,1205),'Payment:  □ cash   □ transfer' if en else 'Płatność:  □ gotówka   □ przelew',29)
  txt(d,(100,1300),'Signature: _________________' if en else 'Podpis: _________________',28)
 elif kind=='lease':
  txt(d,(105,115),'RESIDENTIAL LEASE' if en else 'UMOWA NAJMU',55,True,True)
  txt(d,(105,190),'FICTIONAL SCENE PROP' if en else 'FIKCYJNY REKWIZYT FABULARNY',24)
  rule(d,240)
  # text intentionally illegible, only headline readable
  blur=Image.new('RGBA',im.size);bd=ImageDraw.Draw(blur)
  for row in range(14):
   y=330+row*68
   for j in range(1 if row%4 else 2):
    x=105 if j==0 else 560
    length=random.randint(220,730 if j==0 else 410)
    bd.rounded_rectangle((x,y,x+length,y+13),radius=4,fill=(77,68,57,165))
  blur=blur.filter(ImageFilter.GaussianBlur(15));im=Image.alpha_composite(im,blur);d=ImageDraw.Draw(im)
  d.line((105,1330,950,1330),fill=(110,99,79,60),width=2)
  # staple
  d.line((110,65,160,63),fill=(81,82,77,255),width=7);d.line((115,65,115,83),fill=(96,96,93,255),width=4);d.line((157,63,156,81),fill=(96,96,93,255),width=4)
 elif kind=='manager':
  txt(d,(90,95),'LIPOWA STREET BUILDING' if en else 'ADMINISTRACJA KAMIENICY',44,True,True)
  txt(d,(90,154),'MANAGEMENT' if en else 'PRZY UL. LIPOWEJ',43,True,True)
  rule(d,228)
  txt(d,(90,315),'TO THE RESIDENT' if en else 'DO LOKATORA',42,True,True)
  txt(d,(90,420),'Apartment: __________' if en else 'Lokal: __________',32)
  statements=['This note confirms that the building manager','may be contacted to verify residence.','A phone call is preferable to an assumption.'] if en else ['Niniejsza kartka informuje, że administrator','może potwierdzić zamieszkanie lokatora.','Telefon jest lepszy od przypuszczeń.']
  for i,t in enumerate(statements):txt(d,(95,540+i*70),t,34)
  txt(d,(95,850),'Date: _________________' if en else 'Data: _________________',30)
  txt(d,(95,930),'Manager: _________________' if en else 'Zarządca: _________________',30)
  manager_stamp(im,lang)
 elif kind=='tenant':
  d.rounded_rectangle((55,55,1445,925),radius=48,outline=(110,92,67,255),width=5)
  txt(d,(100,108),'LIPOWA HOUSING CO-OP' if en else 'SPÓŁDZIELNIA MIESZKANIOWA „LIPOWA”',43,True,True)
  txt(d,(100,187),'RESIDENT CARD • FICTIONAL' if en else 'KARTA LOKATORA • FIKCYJNA',30)
  ruleY=270;d.line((100,ruleY,1380,ruleY),fill=(86,77,65,255),width=3)
  d.rounded_rectangle((105,350,410,760),radius=15,fill=(200,187,165,255),outline=(146,130,104,255),width=3)
  # stylized architectural motif, not a portrait or ID emblem
  for i in range(5):d.rectangle((170+i*38,450,185+i*38,495),fill=(132,121,101,255))
  d.polygon([(150,560),(250,500),(350,560)],fill=(125,113,94,255));d.rectangle((165,561,335,689),fill=(125,113,94,255))
  labels=['Name','Apartment','Building'] if en else ['Imię i nazwisko','Lokal','Budynek']
  for i,t in enumerate(labels):
   y=365+i*145;txt(d,(470,y),t+':',34);d.line((475,y+105,1340,y+105),fill=(95,85,68,200),width=3)
  txt(d,(105,820),'CO-OP MEMO — NOT AN OFFICIAL ID' if en else 'KARTA SPÓŁDZIELNI — NIE JEST DOWODEM OSOBISTYM',24,True)
 elif kind=='envelope':
  d.line((85,190,750,650),fill=(143,126,100,105),width=4)
  d.line((1410,190,750,650),fill=(143,126,100,105),width=4)
  d.rectangle((1190,105,1385,292),outline=(153,133,102,255),width=5)
  for i in range(4):d.arc((1000+i*31,125,1250+i*31,225),205,345,fill=(132,113,85,150),width=4)
  txt(d,(190,490),'Ms Halina' if en else 'Pani Halina',65,serif=True,italic=True)
  txt(d,(190,590),'14 Lipowa Street, flat 7' if en else 'ul. Lipowa 14, m. 7',51,serif=True,italic=True)
  txt(d,(190,690),'Zameczno',49,serif=True,italic=True)
  txt(d,(100,890),'FICTIONAL ADDRESS • GAME PROP' if en else 'ADRES FIKCYJNY • REKWIZYT GRY',22)
 elif kind=='note':
  s='Soup is waiting.' if en else 'Rosół czeka.'
  txt(d,(155,260),s,130,serif=True,italic=True)
  txt(d,(205,500),'— Halina',67,serif=True,italic=True)
  d.arc((1000,400,1320,680),0,180,fill=(65,60,52,235),width=11)
  d.line((1010,545,1310,545),fill=(65,60,52,235),width=9)
  for x in (1080,1160,1240):d.arc((x,335,x+52,440),150,300,fill=(65,60,52,210),width=6)
 im.save(P/f'{kind}_{lang}.png',compress_level=2)
 return (P/f'{kind}_{lang}.png').stat().st_size
kinds=['job','receipt','lease','manager','tenant','envelope','note']; data=[]
for i,k in enumerate(kinds):
 for j,l in enumerate(['pl','en']):
  name=f'{k}_{l}.png'
  data.append((name,(P/name).stat().st_size if (P/name).exists() else draw(k,l,14+i*8+j)))
print(data)
with zipfile.ZipFile('/mnt/data/G14-paper-props.zip','w',zipfile.ZIP_DEFLATED,compresslevel=7) as z:
 for p in P.glob('*'):z.write(p,p.relative_to(OUT))
print('zip',os.path.getsize('/mnt/data/G14-paper-props.zip'))
