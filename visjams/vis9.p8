pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
p=fillp
l=circfill
r=rnd
d={0,0,0,0,1,2}::_::srand()cls()for i=1,99 do
s=d[flr(r(#d))+1]a=r((s+1)*30)k=a+10*(sin(t()/10)+1)f=r(1)+4*t()/max(a,10)x=64+k*cos(f)y=32+k*sin(f)/4
z=1+sin(f+r())p()l(x,y,z,r(4)+7)y=64-y+64
p(0xf0f0)l(x,y,z,r(4)+1)end
flip()goto _
