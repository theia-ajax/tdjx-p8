pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
e=2.71828::_::cls()srand()for n=0,50 do
circfill(64+cos(t()/(4*e)+rnd())*64,64+sin(t()/(3*e)+rnd())*64,5+rnd(5),5+flr(rnd(3)))end
for n=0,500 do
r=n/e-t()/7
m=n/5line(64+cos(r)*m,64+sin(r)*m,64+cos(r+m/360/e)*(m+5),64+sin(r+m/360/e)*(m+5),7)end
flip()goto _
