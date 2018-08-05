pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- hello world
-- by zep
-- run: ./reload.sh

board = {}
bottom_left = 32
bottom_right = 96

drop = {}
next_drop = {}

max_lines = 16
max_columns = 5

-- bigger is slower
speed = 18

number_of_colors = 6

nr_cal = 0

function reset_board()
    printh("resetting board...")
    for i=0,max_lines do
    board[i] = {}     -- create a new row
        for j=0,max_columns do
            slot = {}
            -- start from below
            spacer = 8
            slot.x = spacer + bottom_left + j * 8
            slot.y = i * 8
            board[i][j] = slot
        end
    end

end

function drop_new ()
    -- starting point for drop
    drop.i = 0
    drop.j = 3
    drop.colors = next_drop.colors
    next_drop.colors = generate_new_colors()
    drop.timer = 10
end

function generate_new_colors()
    colors = {
        flr(rnd(number_of_colors)),
        flr(rnd(number_of_colors)),
        flr(rnd(number_of_colors))
    }
    return colors
end

function can_move_in_direction(direction)
    if not board[drop.i][drop.j+direction].color then
        return true
    else
        return false
    end
end


function _init()
    printh("Called _init")
    reset_board()
    -- Initial set of colors
    next_drop.colors = generate_new_colors()
    drop_new()
end

function _update()
    -- Only if drop is still in free fall
    block_below = false

    if board[drop.i+1][drop.j].color then
        printh("Found block below")
        block_below = true
    elseif drop.i == max_lines-1 then
        printh("Found bottom below")
        block_below = true
    end

    if block_below then
        printh("Drop ended")
        if drop.i > 0 then
            board[drop.i][drop.j].color = drop.colors[1]
            board[drop.i-1][drop.j].color = drop.colors[2]
            board[drop.i-2][drop.j].color = drop.colors[3]
        else
            print("Game Over")
            _init()
        end
        gravity()
        drop_new()
    else

        ---- Direction
        -- If left and not over left border
        if btn(1) and drop.j < max_columns and can_move_in_direction(1) then
            drop.j += 1
        -- If right and if not over right border
        elseif btn(0) and drop.j > 0 and can_move_in_direction(-1) then
            drop.j -= 1
        end

        ---- Rotation
        if btnp(4) or btnp(5) then
            currently_rotating = true
            rotate()
        end

        if btn(3) or drop.timer % speed == 0 then
           drop.i +=1
        end
    end

    drop.timer += 1
end

function clears_up(i,j)
    -- TODO Calculate Points and remove stones

    -- TODO Performance is bad
    -- TODO Allow for "L" constellations, create debug map. Maybe nil elements at end

    -- printh("calculating" .. nr_cal)
    nr_cal +=1

    -- To the left xx0 if there is space to the left
    color = board[i][j].color
    if j > 2 and
        board[i][j-1].color == color and
        board[i][j-2].color == color
        then

        printh("MATCH to left")
        board[i][j].color = nil
        board[i][j-1].color = nil
        board[i][j-2].color = nil

        gravity()
    end

    -- To the right 0xx
    if j <= max_columns - 2 and
        board[i][j+1].color == color and
        board[i][j+2].color == color then

        printh("MATCH to right")
        board[i][j].color = nil
        board[i][j+1].color = nil
        board[i][j+2].color = nil
        gravity()
    end

    -- xx0xx 4!
    -- if board[i][j+1].color == 
    --     color == board[i][j+2].color then
    --     printh("MATCH to right")
    --     board[i][j].color = nil
    --     board[i][j+1].color = nil
    --     board[i][j+2].color = nil
    --
        -- gravity()
    -- end

    -- Downwards
    if i <= max_lines - 2 and
        board[i+1][j].color == color and
        board[i+2][j].color == color
        then

        printh("MATCH to bottom")
        board[i][j].color = nil
        board[i+1][j].color = nil
        board[i+2][j].color = nil
        gravity()
    end

    -- Upwards
    if i > 2 and
        board[i-1][j].color == color and
        board[i-2][j].color == color
        then

        printh("MATCH to top")
        board[i][j].color = nil
        board[i-1][j].color = nil
        board[i-2][j].color = nil
        gravity()
    end
end

function gravity()
    -- TODO Invoke gravity for removed stones
    printh("Gravity not yet implemented")
    for i=0,max_lines do
        for j=0,max_columns do
            if i+1 < max_lines and not board[i+1][j].color then
                board[i+1][j].color = board[i][j].color
                board[i][j].color = nil
            end
        end
    end
end

function rotate()
    -- TODO Find a better way to copy values
    first = drop.colors[1]
    second = drop.colors[2]
    third = drop.colors[3]

    drop.colors[1] = second
    drop.colors[2] = third
    drop.colors[3] = first
end

function _draw ()
    cls()
    map( 0, 0, 0, 0, 128, 128)

    -- Draw drop
    spr(drop.colors[1], board[drop.i][drop.j].x, board[drop.i][drop.j].y)
    if (drop.i > 0) then
        spr(drop.colors[2], board[drop.i-1][drop.j].x, board[drop.i-1][drop.j].y)
end
    if (drop.i > 1) then
    spr(drop.colors[3], board[drop.i-2][drop.j].x, board[drop.i-2][drop.j].y)
end
    print("i=" .. drop.i, 103,25, 7)
    print("j=" .. drop.j, 103,34, 7)
    print("fps=" .. stat(8), 103,43, 7)

    -- Draw existing board
    for i=0,max_lines do
        for j=0,max_columns do

            blocked_spot = board[i][j]
            if blocked_spot.color then
                -- printh("Blocked spot in: " .. i ..",".. j)
                -- TODO This calculates everything all the time and is very slow
                clears_up(i,j)

                spr(blocked_spot.color, board[i][j].x, board[i][j].y)
            end
        end
    end

    flip()
end


--- hack for using external editor
if peek(0x4300) == 0 then
    poke(0x4300,1)
    printh("------- reloading")
    load("columns")
    run()
else
    poke(0x4300,0)
end
--- hack for external editor
--
-- DEBUGGING
--
debug = {}
function debug.tstr(t, indent)
 indent = indent or 0
 local indentstr = ''
 for i=0,indent do
  indentstr = indentstr .. ' '
 end
 local str = ''
 for k, v in pairs(t) do
  if type(v) == 'table' then
   str = str .. indentstr .. k .. '\n' .. debug.tstr(v, indent + 1) .. '\n'
  else
   str = str .. indentstr .. tostr(k) .. ': ' .. tostr(v) .. '\n'
  end
 end
  str = sub(str, 1, -2)
 return str
end
function debug.print(...)
 printh("\n")
 for v in all{...} do
  if type(v) == "table" then
   printh(debug.tstr(v))
  elseif type(v) == "nil" then
    printh("nil")
  else
   printh(v)
  end
 end
end

---

__gfx__
aaaaaaaacccccccc00888800000990000eeeeee000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000
a777777ac777777c0877888000979900e7777eee0b77bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
a7aaaaaac7cccccc8878888809779990e7eeeeeebb7bbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
a7aaaaaac7cccccc8888888899999999e7eeeeeebbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
a7aaaaaac7cccccc8888888899999999e7eeeeeebbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
a7aaaaaac7cccccc8888888809999990eeeeeeeebbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000
a7aaaaaac7cccccc0888888000999900eeeeeeee0bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaacccccccc00888800000990000eeeeee000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666555566666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66566566665666655666656600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666555566666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66655666666556655665566600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666555566666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66566566665666655666656600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666555566666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666655666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000122424241000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000122424241000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0004011a00000000001905012250152500f2501a25031050130500000000000000000000000000070502005000000000000000000000072500f2500f250102500000000000000000000000000000000000000000
0002010d00000000001c8501c8501c8501c8501c8501c8501a850188501e850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141
00 41414141

