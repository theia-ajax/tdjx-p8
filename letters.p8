pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
cls()
m="tweet different"
n=#m
?m
memcpy(0,0x6000,999)
::_::
cls()
k=flr(t()*32)
for i=0,n-1 do
f=i/n
z=2
x=-0.8--+max(sin(-t()/4+f),0)*1.5
y=((f*12-t()*2)%16-8)/z
s=20/z
p=0.1
for l=0,s*2 do
pal(6,5+(k/3)%3)
sspr(i*4,flr(l/(s*2)*5),3,1,x*64+64-s+sin(l/(s*2)-t())*5,y*64+64-s+l,s*2,1)
k+=1
end

end
flip()goto _
