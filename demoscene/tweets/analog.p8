pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::cls()srand()for i=0,19 do
h=rnd(128)r=40+rnd(80)f=20+rnd(40)+sin(t()/r*10)*30
for x=0,127,2 do
y=sin(x/f+t())*(20+sin(r)*5)+(h+64+t()*r)%167-20
pset(x,y,7)end
end
flip()goto _
