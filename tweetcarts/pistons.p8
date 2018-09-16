pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
_set_fps(60)::_::cls(1)for q=48,12,-1 do
for i=0,1,.1 do
r=q+12*sin(t()/2+i*3)x=cos(i)*r+64
y=sin(i)*r+64
z=cos(i+.1)*r+64
w=sin(i+.1)*r+64line(x,y,z,w,12)end
end
flip()goto _
