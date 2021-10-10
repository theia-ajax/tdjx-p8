pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

function _init()
    _update60=game_update
    _draw=game_draw
end

function game_update()
end

function game_draw()
    cls()
    map(0, 0,  0, 0, 16, 16)
    spr(1, 60, 60)
end
