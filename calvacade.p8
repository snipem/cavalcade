pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- run: reload.sh
-- calvacade
-- by matthias küch
-- run: ./reload.sh

-- todo
-- level
-- maybe there is a problem at multi resolve, maybe related to gravity
---- problem is: it's removing more than one line if a match 3 occurs, even those not affected
-- title screen
-- background music

board = {}
bottom_left = 32
bottom_right = 96

drop = {}
drop.nr = 0

next_drop = {}

max_lines = 16
max_columns = 5

debug_mode = false

-- higher is slower
speed = 18
level = 1

number_of_colors = 6

nr_cal = 0

score = 0

game_over_timer = 0
is_playing = true

function reset_board()
    printh(drop.nr .. " - resetting board...")
    for i=0,max_lines do
    board[i] = {}     -- create a new row
        for j=0,max_columns do
            slot = {}
            -- start from below
            spacer = 8
            slot.x = spacer + bottom_left + j * 8
            slot.y = i * 8
            slot.delete = false
            board[i][j] = slot
        end
    end

    -- Base board for debug mode
    if debug_mode then
        setup_test_board()
    end

end

function setup_test_board ()
    -- First stack
    board[15][1].color = 1
    board[14][1].color = 3
    board[13][1].color = 3

    -- Second stack
    board[15][2].color = 4
    board[14][2].color = 2
    board[13][2].color = 2

    -- Stack were drop falls
    board[15][3].color = 1
    board[14][3].color = 3
    board[13][3].color = 3

    --board[15][1].delete = false
    --board[14][2].delete = false
    --board[13][3].delete = false
end

function drop_new ()
    -- starting point for drop
    drop.i = 0
    drop.j = 3
    drop.nr = drop.nr + 1
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
    printh(drop.nr .. " - called _init")
    reset_board()
    level = 1
    -- initial set of colors
    next_drop.colors = generate_new_colors()

    -- drop stones matching to predefined board
    if debug_mode then
        next_drop.colors = {3,0,0}
    end
    drop_new()
end

function _update()
    if is_playing then
        play_game()
    elseif game_over_timer > 0 then
        game_over_timer -= 1
    else
        _init()
        is_playing = true
    end
end

function play_game()
    -- only if drop is still in free fall
    block_below = false

    if board[drop.i+1][drop.j].color then
        printh(drop.nr .. " - found block below")
        block_below = true
    elseif drop.i == max_lines-1 then
        printh(drop.nr .. " - found bottom below")
        block_below = true
    end

    if block_below then
        printh(drop.nr .. " - drop ended")
        if drop.i > 0 then
            board[drop.i][drop.j].color = drop.colors[1]
            board[drop.i-1][drop.j].color = drop.colors[2]

            -- todo here is a bug when all stack up to the top?
            if drop.i > 1 then
            board[drop.i-2][drop.j].color = drop.colors[3]
            end

        else
            --  game over
            game_over_timer = 3 * 30
            is_playing = false
            sfx(3)
            _init()
        end
        gravity()
        drop_new()
    else

        ---- direction
        -- if left and not over left border
        if btn(1) and drop.j < max_columns and can_move_in_direction(1) then
            drop.j += 1
        -- if right and if not over right border
        elseif btn(0) and drop.j > 0 and can_move_in_direction(-1) then
            drop.j -= 1
        end

        ---- rotation
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
    -- todo calculate points and remove stones

    -- todo performance is bad
    -- todo allow for "l" constellations, create debug map. maybe nil elements at end

    -- printh("calculating" .. nr_cal)
    nr_cal +=1

    -- color of the block to calculate for
    color = board[i][j].color

    -- Skip calculation if already marked for deletion
    if board[i][j].delete == true then
        printh("Already marked for deletion, skipping")
        return
    end

    -- to the left xx0 if there is space to the left
    if j > 2 and
    board[i][j-1].color == color and
    board[i][j-2].color == color
    then

    printh(drop.nr .. " - match to left")
    board[i][j].delete = true
    board[i][j-1].delete = true
    board[i][j-2].delete = true

    sfx(2)
    score+=100

    gravity()
    end

    -- to the right 0xx
    if j <= max_columns - 2 and
    board[i][j+1].color == color and
    board[i][j+2].color == color then

    printh(drop.nr .. " - match to right")
    board[i][j].delete = true
    board[i][j+1].delete = true
    board[i][j+2].delete = true

    sfx(2)
    score+=100

    gravity()
    end

    -- xx0xx 4!
    -- if board[i][j+1].color == 
    --     color == board[i][j+2].color then
    --     printh("match to right")
    --     board[i][j].delete = true
    --     board[i][j+1].delete = true
    --     board[i][j+2].delete = true
    --
    -- gravity()
    -- end

    -- downwards
    if i <= max_lines - 2 and
    board[i+1][j].color == color and
    board[i+2][j].color == color
    then

    printh(drop.nr .. " - match to bottom")
    board[i][j].delete = true
    board[i+1][j].delete = true
    board[i+2][j].delete = true

    sfx(2)
    score+=100

    gravity()
    end

    -- upwards
    --if i > 2 and
    --board[i-1][j].color == color and
    --board[i-2][j].color == color
    --then
    --
    --printh(drop.nr .. "match to top")
    --board[i][j].delete = true
    --board[i-1][j].delete = true
    --board[i-2][j].delete = true
    --
    --sfx(2)
    --score+=100
    --
    --gravity()
    --end

    gravity()
    return
    end

function gravity()
    -- todo invoke gravity for removed stones
    for i=0,max_lines do
        for j=0,max_columns do
            if i+1 < max_lines and not board[i+1][j].color then
                board[i+1][j].color = board[i][j].color
                board[i][j].delete = true
            end
        end
    end
end

function rotate()
    -- todo find a better way to copy values
    first = drop.colors[1]
    second = drop.colors[2]
    third = drop.colors[3]

    drop.colors[1] = second
    drop.colors[2] = third
    drop.colors[3] = first

    sfx(1)
end

function _draw ()
    if is_playing then
        draw_game()
    else
        cls()

        print ("score: " .. score, 40, 50)
        print ("game over", 45, 64)
        print (flr(game_over_timer / 10), 64, 78)
    end
end

function draw_game ()
    cls()
    map( 0, 0, 0, 0, 128, 128)

    -- draw drop
    spr(drop.colors[1], board[drop.i][drop.j].x, board[drop.i][drop.j].y)
    if (drop.i > 0) then
        spr(drop.colors[2], board[drop.i-1][drop.j].x, board[drop.i-1][drop.j].y)
end
    if (drop.i > 1) then
    spr(drop.colors[3], board[drop.i-2][drop.j].x, board[drop.i-2][drop.j].y)
end

    -- draw next. order has to be reversed since its the way the drop is rendered.
    spr(next_drop.colors[1], 108, 32)
    spr(next_drop.colors[2], 108, 24)
    spr(next_drop.colors[3], 108, 16)
    print("n", 101, 16)
    print("e", 101, 22)
    print("x", 101, 28)
    print("t", 101, 34)

    if debug_mode then
        rectfill(5,20, 31,55, 0)
        print("i=" .. drop.i, 7,25, 7)
        print("j=" .. drop.j, 7,34, 7)
        print("fps=" .. stat(8), 7,43, 7)
    end


    -- score
    print("score", 98,58, 7)
    print(score, 98,64, 7)

    -- level
    rectfill(96,80, 119,95, 0)
    print("level", 98,82, 7)
    print(level, 98,88, 7)

    -- draw existing board
    for i=0,max_lines do
        for j=0,max_columns do

            blocked_spot = board[i][j]
            if blocked_spot.color then
                -- printh(drop.nr .. "blocked spot in: " .. i ..",".. j)
                -- todo this calculates everything all the time and is very slow
                clears_up(i,j)

                spr(blocked_spot.color, board[i][j].x, board[i][j].y)
            end
        end
    end

    -- clear up all lines that have been set to be deleted
    -- todo add animation
    for i=0,max_lines do
        for j=0,max_columns do
            if board[i][j].delete == true then
                board[i][j].delete = false
                board[i][j].color = nil
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
-- debugging
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
1010101011000000000000122020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000122424241000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000122424241000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000121010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000122020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101011000000000000122020201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0003000000000000001c8501c8501c8501c8501c0501c0501a050180501605013050100500c0500a0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040101000001c8500d2501025013230172301d2302683023250292502c250312503325000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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