pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

t = 0
dt = 1 / 60

entityid = 0

player = {}
player.x = 20
player.y = 20
player.sprite = 0
player.speed = 30

function move(dx, dy)
    player.x += dx * dt
    player.y += dy * dt
    player.moving = true
    -- player.sprite += 1
    -- if player.sprite > 3 then
    --     player.sprite = 0
    -- end
end

function new_entity()
    local entity = {}
    entityid += 1

    entity.id = entityid

    entity.x = 0
    entity.y = 0
    entity.dx = 0
    entity.dy = 0

    entity.sprite = -1

    return entity
end

function new_player()
    local player = new_entity()
    player.sprite = 0
    return player
end

function _init()
end

function _update60()
    t += 1

    player.moving = false
    if btn(0) then
        move(-player.speed, 0)
    end
    if btn(1) then
        move(player.speed, 0)
    end
    if btn(2) then
        move(0, -player.speed)
    end
    if btn(3) then
        move(0, player.speed)
    end
    if not player.moving then
        player.sprite = 0
    end
end

function _draw()
    cls()
    spr(player.sprite, player.x, player.y)
end

__gfx__
05550600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05356666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05350400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55550400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55550400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05d50400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d5d0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
