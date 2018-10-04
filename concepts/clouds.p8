pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
::_::
cls(1) 
for k=0,17 do 
	for j=0,2 do 
		srand(k) 
		x=(rnd(500)+t()*62.5)%500-250 
		y=rnd(128)-64
		z=3-k/10
		for i=0,30 do
			circfill(64+(x+rnd(60)-30+j*3)/z,
				84+(y-rnd()*rnd()*20-j+sin(rnd()+t()/8)*6)/z,
				(rnd(10)+6-j*2.5)/z,5+j)
		end
	end
end
flip()
goto _
