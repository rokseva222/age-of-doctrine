# Düzensiz genişlikli karolu Gemini sayfası kesici: python3 tools/grid_slice.py sayfa.png itemsNN [atlanacak_kare_indeksleri,virgüllü]
import sys,json,numpy as np
from PIL import Image
from scipy import ndimage
path,setname=sys.argv[1],sys.argv[2]
ids=json.load(open('tools/item_sets.json'))[setname]
a=np.array(Image.open(path).convert('RGB')).astype(int)
mag=(a[:,:,0]>170)&(a[:,:,1]<120)&(a[:,:,2]>170)
H,W=mag.shape
def runs(v,thr,minlen):
    r=[];s=None
    for i,x in enumerate(v):
        if x>thr and s is None: s=i
        if x<=thr and s is not None:
            if i-s>=minlen: r.append((s,i))
            s=None
    if s is not None and len(v)-s>=minlen: r.append((s,len(v)))
    return r
rows=runs((~mag).mean(1),0.08,25)
boxes=[]
for y0,y1 in rows:
    band=~mag[y0:y1]
    cols=runs(band.mean(0),0.3,20)
    for x0,x1 in cols: boxes.append((y0,x0,y1,x1))
if len(sys.argv)>3:
    for d in sorted(map(int,sys.argv[3].split(",")),reverse=True): boxes.pop(d)
print(setname,"satır",len(rows),"kare",len(boxes),"beklenen",len(ids))
out=0
for (y0,x0,y1,x1),name in zip(boxes,ids):
    c=a[y0:y1,x0:x1].copy()
    mg=mag[y0:y1,x0:x1]
    ring=np.concatenate([c[4:8,10:-10].reshape(-1,3),c[10:-10,4:8].reshape(-1,3),c[10:-10,-8:-4].reshape(-1,3)])
    tile=np.median(ring,axis=0)
    d=np.abs(c-tile).sum(axis=2)
    near=d<50
    hh,ww=near.shape
    yy,xx=np.mgrid[0:hh,0:ww]
    border=(yy<6)|(xx<6)|(xx>ww-7)|(yy>hh-7)
    seed=near&(border|ndimage.binary_dilation(mg,iterations=2))
    lab,_=ndimage.label(near)
    k=np.unique(lab[seed]); k=k[k>0]
    rem=np.isin(lab,k)|mg
    edge=ndimage.binary_dilation(rem,iterations=2)&~rem&(d<110)
    rem|=edge
    rem|=((yy<5)|(xx<5)|(xx>ww-6)|(yy>hh-6))
    tint=((c[:,:,0]-c[:,:,1])>40)&((c[:,:,2]-c[:,:,1])>40)
    rem|=tint&ndimage.binary_dilation(rem,iterations=3)
    keep=~rem
    lab2,n2=ndimage.label(keep)
    if n2==0: continue
    sz=ndimage.sum(keep,lab2,range(1,n2+1))
    keep=np.isin(lab2,[i+1 for i in range(n2) if sz[i]>=max(30,sz.max()*0.03)])
    al=ndimage.gaussian_filter(np.where(keep,255.,0.),0.6).clip(0,255).astype(np.uint8)
    im=Image.fromarray(np.dstack([c.astype(np.uint8),al]),'RGBA')
    bb=im.getbbox(); im=im.crop(bb); s=max(im.size)
    sq=Image.new('RGBA',(int(s*1.06),int(s*1.06)),(0,0,0,0)); sq.paste(im,((sq.width-im.width)//2,(sq.height-im.height)//2))
    sq.resize((256,256),Image.LANCZOS).save('assets/icons/x_%s_c.png'%name); out+=1
print("yazılan",out)
