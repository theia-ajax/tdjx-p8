pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
s="fuck 'em up, hazel"
?s,0,0,7
memcpy(0,24576,384)::_::cls()for c=7,0,-1 do
for i=1,#s do
u=t()/4-i/10-c/150x=cos(u)-sin(u)y=-2.3+i/4z=4+sin(u)+cos(u)a=64+64*x/z
b=64+64*y/z
w=2+(-z+5)h=4+(-z+5)pal(7,c+7)sspr((i-1)*4,0,4,8,a-w,b-h,w*2,h*2)end
end
flip()goto _
