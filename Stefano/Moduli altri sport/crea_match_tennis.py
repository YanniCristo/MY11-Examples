import json,zipfile,io,time,datetime,sys
from PIL import Image,ImageDraw,ImageFont
R='/home/claude/tennis/ref/';G='/home/claude/my11-examples/Stefano/Copia file Fulvio (con possibili modifiche)/Pics/ATP Giocatori/'
W_,L_,score,fw,fl,full=sys.argv[1:7]   # winner surname, loser surname, score, flag files, full name
M=json.load(open(R+'manifest.json'));F=M['formation']
def flag(p):
    im=Image.open(p).convert('RGBA');im=im.crop(im.getbbox());im.thumbnail((256,256),Image.LANCZOS);b=io.BytesIO();im.save(b,'PNG',optimize=True);return b.getvalue()
title=f'{W_[:3]} {score} {L_[:3]}'.upper().replace('.','')
now=datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat(timespec='microseconds')+'Z'
F.update(id=f'frm_{int(time.time()*1e6)}',name=full,title=title,createdAt=now,updatedAt=now)
F['starterNames']['tn_tc']=W_;F['starterNames']['tn_bc']=L_
img={e['slotId']:e['file'] for e in M['slotImages']}
files={}
for n in ['theme/pitch_theme_catalog.jpg']+[e['file'] for e in M['slotImages']]: files[n]=open(R+n,'rb').read()
files[img['tn_tc']]=open(G+W_+'.png','rb').read();files[img['tn_bc']]=open(G+L_+'.png','rb').read()
files['logos/left.png']=flag(fw);files['logos/right.png']=flag(fl)
# thumbnail
W,H=393,505;th=Image.new('RGB',(W,H),(0,0,0));th.paste(Image.open(R+'theme/pitch_theme_catalog.jpg').convert('RGB').resize((W,H-62),Image.LANCZOS),(0,62));th=th.convert('RGBA');dr=ImageDraw.Draw(th)
FB='/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf'
dr.text((W/2,31),title,fill=(255,204,0),font=ImageFont.truetype(FB,24),anchor='mm')
for fn,x in [('logos/left.png',8),('logos/right.png',W-56)]:
    im=Image.open(io.BytesIO(files[fn])).convert('RGBA');im.thumbnail((48,48),Image.LANCZOS);th.alpha_composite(im,(x,31-im.height//2))
fid=F['freeImageIds'][0];b=Image.open(io.BytesIO(files[img[fid]])).convert('RGBA');b=b.crop(b.getbbox());b.thumbnail((110,110),Image.LANCZOS)
x,y=F['pinnedCenters'][fid];th.alpha_composite(b,(round(6+381.6*x-b.width/2),round(85+406*y-b.height/2)))
for sid in ['tn_tc','tn_bc']:
    x,y=F['pinnedCenters'][sid];cx=6+381.6*x;cy=85+406*y;sc=F['slotPhotoScales'][sid];ws=F['slotWidthScales'][sid];lh=9*ws;lw=40*ws
    im=Image.open(io.BytesIO(files[img[sid]])).convert('RGBA');im.thumbnail((52.8*sc,49.6*sc),Image.LANCZOS);th.alpha_composite(im,(round(cx-im.width/2),round(cy-lh-im.height)))
    dr.rectangle([cx-lw,cy-lh,cx+lw,cy+lh],fill=(250,200,20))
    f=ImageFont.truetype(FB,14)
    while dr.textlength(F['starterNames'][sid],font=f)>2*lw-8: f=ImageFont.truetype(FB,f.size-1)
    dr.text((cx,cy),F['starterNames'][sid],fill=(40,40,40),font=f,anchor='mm')
bb=io.BytesIO();th.convert('RGB').quantize(colors=128,method=Image.MEDIANCUT).save(bb,'PNG',optimize=True);files['thumbnail.png']=bb.getvalue()
th.convert('RGB').save('/tmp/mthumb.png')
out=f'/home/claude/tennis/{title}.my11'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    z.writestr('manifest.json',json.dumps(M,ensure_ascii=False,separators=(',',':')))
    for k,v in files.items(): z.writestr(k,v)
print(out)
