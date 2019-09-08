pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
function _init()
	game_states={
		play={
			init=play_init,
			update=play_update,
			draw=play_draw
		},
		gameover={
			init=gameover_init,
			update=gameover_update,
			draw=gameover_draw
		}
	}
	set_state("play")
end

function _update()
	game_state.update()
end

function _draw()
	game_state.draw()
end

function set_state(state)
	local gs=game_states[state]
	if gs and gs~=game_state then
		game_state=gs
		if game_state.init then
			game_state.init()
		end
	end
end

function play_init()
	board_init()
	
	sel_x=1
	sel_p=piece_a
end

function play_update()
	if btnp(0) then
		sel_x=max(sel_x-1,1)
	end
	
	if btnp(1) then
		sel_x=min(sel_x+1,board_w)
	end
	
	if btnp(4) then
		if board_drop(sel_x,sel_p) then
			if sel_p==piece_a then
				sel_p=piece_b
			else
				sel_p=piece_a
			end
			
			is_win,win_path,win_player=board_check_win()
			is_tie=board_check_tie()
			
			if is_win or is_tie then
				gameover={
					is_tie=board_check_tie(),
					is_win=is_win,
					win_path=win_path,
					win_player=win_player
				}
				set_state("gameover")
			end
		end
	end
end

function play_draw()
	cls()
	
	circfill((sel_x-1)*(128/board_w)+(128/board_w/2),4,4,sel_p)
	
	
	board_draw()
end

function gameover_init()
	
end

function gameover_update()
	if btnp(4) then
		set_state("play")
	end
end

function gameover_draw()
	cls()
		
	board_draw()
	
	if gameover.is_win then
		draw_path(gameover.win_path)
	elseif gameover.is_tie then
		print("tie",60,62,7)
	else
		print("invalid",54,62,8)
	end
end

function draw_path(path)
	for i=1,#path-1 do
		local a,b=path[i],path[i+1]
		x1,y1=piece_to_screen(a.x,a.y)
		x2,y2=piece_to_screen(b.x,b.y)
		line(x1,y1,x2,y2,10)
	end
	for p in all(path) do
		local sx,sy=piece_to_screen(p.x,p.y)
		circ(sx,sy,2,9)
	end
end
-->8
-- board

board={}

board_w=7
board_h=6

board_draw_x=0
board_draw_y=16
board_draw_w=128
board_draw_h=96

piece_none=0
piece_a=8
piece_b=12

function board_init()
	for x=1,board_w do
		board[x]={}
		local col=board[x]
		col.size=0
		for y=1,board_h do
			col[y]=piece_none
		end
	end
end

function board_drop(x,p)
	local col=board[x]
	if col and col.size<board_h then
		col.size+=1
		col[col.size]=p
		return true
	end
	return false
end



function piece_to_screen(x,y)
	local dx,dy=board_draw_w/board_w,
		board_draw_h/board_h
	return (x-1)*dx+dx/2,
		board_draw_y+board_draw_h-(y-1)*dy-dy/2
end

function board_draw()
	local bx,by=board_draw_x,board_draw_y
	local bw,bh=board_draw_w,board_draw_h
	local dx=bw/board_w
	local dy=bh/board_h
	
	for x=1,board_w do
		local col=board[x]
		for y=1,col.size do
			local p=col[y]
			local px,py=piece_to_screen(x,y)
			circfill(px,py,min(dx-1,dy-1)/2,p)
		end
	end
	
	for x=0,128,dx do
		line(x,by,x,by+bh-1,5)
	end
	
	for y=by,by+bh,dy do
		line(bx,y,bx+bw-1,y,5)
	end
end

function board_check_win()
	local paths=board_scan_win_paths()
	if #paths>0 then
		local path=paths[1]
		local p=path[1]
		return true,path,board[p.x][p.y]
	end
	return false
end

function board_check_tie()
	for x=1,board_w do
		for y=1,board_h do
			if board[x][y]==piece_none then
				return false
			end
		end
	end
	return true
end

function board_scan_win_paths()
	local ret={}
	
	local shapes={
		function(x,y,i) return x+i,y end,
		function(x,y,i) return x,y+i end,
		function(x,y,i) return x+i,y+i end,
		function(x,y,i) return x+i,y-i end,
	}
	
	for shape in all(shapes) do
		board_check_shape(shape,ret)
	end
	
	return ret
end

function
board_check_shape(get,ret)
	local len=4
	local last=len-1
	
	local valid=function(x,y)
		return x>=1 and y>=1 and
			x<=board_w and y<=board_h
	end

	for x=1,board_w do
		for y=1,board_h do
			local p=board[x][y]
			local success=p~=piece_none
			for i=1,last do
				local xx,yy=get(x,y,i)
				if not valid(xx,yy)
					or board[xx][yy]~=p
				then
					success=false
					break
				end
			end
			if success then
				local col=add(ret,{})
				for i=0,last do
					local xx,yy=get(x,y,i)
					add(col,{x=xx,y=yy})
				end
			end
		end
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
