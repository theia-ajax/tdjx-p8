pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.71828
::_::
cls()
srand()
for n=0,350 do
r=n/e+t()/7
circfill(64+cos(r)*n/e,64+sin(r)*n/e,max(n/e/3,3)+sin(t())+1,8+n%7)
end
flip()goto _
