pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
e=2.71828k=circfill
::_::cls()for i=0,99 do
u=t()/e/32
a=i*1/e/1+u
b=(i+.2)*1/e/1+u
r=i*2/e+20*sin(a*20)q=(i+.2)*2/e+20*sin(b*20)x=64+r*cos(a)y=64+r*sin(a)w=64+q*cos(b)z=64+q*sin(b)pset(x,y,7)c=8+(15-i/30+t()*8)%8
d=a/e/3
k(x,y,d,c)k(x+d/3,y-d/3,d/2.2,7)end
?"★ special stage ★",30+sin(t()/2)*20,60
flip()goto _
