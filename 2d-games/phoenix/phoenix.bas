#include "raylib.bi"  ' v5.0 bindings from: https://github.com/WIITD/raylib-freebasic/tree/main
#include "fbsound_dynamic.bi"

''-----------------------------------------------------------------------------
'' Utility Functions
''-----------------------------------------------------------------------------
namespace util

function console_input() as string
	dim as string temp
	input temp
	return temp
end function


''-----------------------------------------------------------------------------
function rand_range(lhs as integer, rhs as integer) as integer
	dim as integer ret = lhs + int(rnd * (rhs - lhs)) ' [lhs, rhs)
	return ret
end function


''-----------------------------------------------------------------------------
declare function to_int overload (value as integer) as integer
declare function to_int overload (value as double) as integer
declare function to_int overload (value as string) as integer

function to_int(value as integer) as integer
	return value
end function

function to_int(value as double) as integer
	return fix(value)
end function

function to_int(value as string) as integer
	return valint(value)
end function



''-----------------------------------------------------------------------------
function max(lhs as double, rhs as double) as double
	if lhs > rhs then
		return lhs
	end if
	return rhs
end function

function min(lhs as double, rhs as double) as double
	if lhs < rhs then
		return lhs
	end if
	return rhs
end function


''-----------------------------------------------------------------------------
function clock() as double
	static basetime as double = 0
	static first as boolean = true
	if first then
		first = false
		basetime = timer
	end if
	return timer - basetime
end function


end namespace


sub DrawTextureProRGBA(byval texture as Texture2D, byval tx as single, byval ty as single, byval tw as single, byval th as single, byval dx as single, byval dy as single, byval dw as single, byval dh as single, byval ox as single, byval oy as single, byval rot as single, byval r as integer, byval g as integer, byval b as integer, byval a as integer)
	DrawTexturePro(texture, Rectangle(tx, ty, tw, th), Rectangle(dx, dy, dw, dh), Vector2(ox, oy), rot, RLColor(r, g, b, a))
end sub

dim shared as RLColor DARKDARKGRAY = RLColor(20, 20, 20, 255)
dim shared as RLColor DARKRED = RLColor(128, 20, 25, 255)
dim shared as RLColor SHARKGRAY = RLColor(34, 32, 39, 255)
dim shared as RLColor BITTERSWEET = RLColor(254, 111, 94, 255)
dim shared as RLColor CYAN = RLColor(0, 224, 224, 255)
''-----------------------------------------------------------------------------


randomize

''-----------------------------------------------------------------------------
'' Global Enumeration
''-----------------------------------------------------------------------------

enum enumtype
    ARM_HELMET
    ARM_MAIL
    ARM_SHIELD
    CHASE
    CONTROLS
    GAME
    HEART
    INTRO
    INVALID
    KEY
    MOVE_DOWN
    MOVE_LEFT
    MOVE_RIGHT
    MOVE_UP
    POTION_HEALTH
    POTION_MANA
    ROD
    TURKEY_LEG
    WANDER
    WIN
end enum


''-----------------------------------------------------------------------------
'' Structure Definitions
''-----------------------------------------------------------------------------

type notification
    txt as string
    color__ as RLColor
    timer as single
end type

type entity_s
    px as single
    py as single
    ix as long
    iy as long
    kx as long
    ky as long
    r as long
    g as long
    b as long
    sprite as long
    health as long
    max_health as long
    mana as long
    max_mana as long
    defense as long
    power as long
    level as long
    skip_update as long
    cooldown as single
    state as enumtype
    enemy as boolean
    block_movement as boolean
end type

type vec2i
    x as long
    y as long
end type

type projectile_s
    px as single
    py as single
    vx as single
    vy as single
    active as boolean
end type

type room_s
    x as long
    y as long
    w as long
    h as long
    cx as long
    cy as long
end type

type item_s
    ix as long
    iy as long
    sprite as long
    name__ as string
    color__ as RLColor
    kind as enumtype
    skip_update as long
    block_movement as boolean
    found as boolean
end type


''-----------------------------------------------------------------------------
'' Function Declarations
''-----------------------------------------------------------------------------

declare sub unload_sounds()
declare sub ui_draw()
declare sub draw_house()
declare sub draw_intro()
declare sub draw_controls()
declare sub draw_win()
declare sub add_note(text as string, color__ as RLColor, cooldown as single)
declare sub draw_text(x as long, y as long, txt as string, color__ as RLColor)
declare sub draw_text_center(x as long, y as long, txt as string, color__ as RLColor)
declare sub draw_text_right(x as long, y as long, txt as string, color__ as RLColor)
declare sub draw_text_sm(x as long, y as long, txt as string, color__ as RLColor)
declare sub draw_text_sm_center(x as long, y as long, txt as string, color__ as RLColor)
declare sub draw_text_sm_right(x as long, y as long, txt as string, color__ as RLColor)

declare sub entity_new(x as long, y as long, sprite as long, health as long, level as long, power as long, defense as long, enemy as boolean)
declare sub entity_draw_all()
declare sub entity_draw_player()
declare sub entity_move(eidx as long, move_dir as enumtype)
declare sub entity_spawn_monster(x as long, y as long, lvl as long)
declare sub entity_update(eidx as long, t_delta as double)
declare sub entity_update_all()

declare function gen_rooms() as boolean
declare sub update_dist(idx as long)
declare function check_room_plot(x as long, y as long, w as long, h as long) as boolean
declare sub gen_room_plot(x as long, y as long, w as long, h as long)
declare sub gen_hallway(r0_in as long, r1_in as long)
declare sub draw_map()
declare sub map_update_visibility()

declare sub item_new(x as long, y as long, sprite as long, color__ as RLColor, block_movement as boolean, name__ as string, kind as enumtype)
declare sub item_draw_all()
declare sub get_player_input()

''-----------------------------------------------------------------------------
'' Entry Point
''-----------------------------------------------------------------------------
const VERSION as string = "v1.0.0"
const SCALE as long = 3
const XRES as long = 600
const XRES_HALF as long = XRES / 2
const YRES as long = 320
const YRES_HALF as long = YRES / 2
const SCALE_8 as long = SCALE * 8

const DIR_UP as long = 0
const DIR_DOWN as long = 1
const DIR_LEFT as long = 2
const DIR_RIGHT as long = 3

const MAP_WIDTH as long = 75
const MAP_HEIGHT as long = 36
const MAP_SZ = 3000

InitWindow(XRES * SCALE, YRES * SCALE, "Dungeon of the Phoenix " + VERSION + " - by Syn9")
SetExitKey(KEY_NULL)
SetTargetFPS(60)
BeginDrawing()
ClearBackground(BLACK)
EndDrawing()

dim shared icons as Texture
icons = LoadTexture("assets/icons.png")

dim shared reveal as Texture
reveal = LoadTexture("assets/reveal.png")

dim shared gradient as Texture
gradient = LoadTexture("assets/gradient.png")

dim shared fnt as Font
fnt = LoadFont("assets/alagard.fnt")

dim shared fnt_sm as Font
fnt_sm = LoadFont("assets/font.png")

dim shared note as notification
dim shared quit_game as boolean = false
dim shared game_win as boolean = false
dim shared last_move as enumtype = MOVE_UP

fbs_Init()
dim as integer hWave

dim shared snd_blip as integer
dim shared snd_hurt as integer
dim shared snd_attack as integer
dim shared snd_pickup as integer
dim shared snd_potion as integer
dim shared snd_ambient_1 as integer
dim shared snd_ambient_2 as integer
dim shared snd_ambient_3 as integer
dim shared snd_cast as integer
dim shared snd_dead as integer
dim shared snd_door as integer
dim shared snd_levelup as integer
dim shared snd_shake as integer
dim shared snd_melody as integer

fbs_Load_OGGFile("assets/sounds/blip.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_blip)
fbs_Load_OGGFile("assets/sounds/hurt.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_hurt)
fbs_Load_OGGFile("assets/sounds/attack.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_attack)
fbs_Load_OGGFile("assets/sounds/pickup.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_pickup)
fbs_Load_OGGFile("assets/sounds/potion.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_potion)
fbs_Load_OGGFile("assets/sounds/ambient-1.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_ambient_1)
fbs_Load_OGGFile("assets/sounds/ambient-2.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_ambient_2)
fbs_Load_OGGFile("assets/sounds/ambient-3.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_ambient_3)
fbs_Load_OGGFile("assets/sounds/cast.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_cast)
fbs_Load_OGGFile("assets/sounds/dead.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_dead)
fbs_Load_OGGFile("assets/sounds/door.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_door)
fbs_Load_OGGFile("assets/sounds/levelup.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_levelup)
fbs_Load_OGGFile("assets/sounds/shake.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_shake)
fbs_Load_OGGFile("assets/sounds/melody.ogg", @hWave)
fbs_Create_Sound(hWave, @snd_melody)

dim shared blip_timer as single = 0.0
dim shared ambient_timer as single = 0.0

dim shared screen_shake as boolean = false
dim shared shake_sound_played as boolean = false
dim shared t_shake_move as double = 0.0
dim shared t_shake_timer as double = 5
dim shared shake_x as single = 0.0
dim shared shake_y as single = 0.0
dim shared phoenix_frame as double = 0.0
dim shared t_clock as double = 0.0
dim shared t_game as double = 0.0
dim shared intro_hold as boolean = true
dim shared menu as enumtype = INTRO
dim shared t_win as double = 0.0

dim shared entities(100) as entity_s
dim shared num_entities as long
dim shared flame(6) as RLColor = { YELLOW, ORANGE, WHITE, RED, ORANGE, WHITE }
dim shared magic(5) as RLColor = { GREEN, DARKGREEN, YELLOW, GREEN, DARKGREEN }
dim shared torches(25) as vec2i
dim shared num_torches as long
dim shared t_flames as double = 0.0
dim shared magic_ball as projectile_s

dim shared board(MAP_SZ) as integer
dim shared board2(MAP_SZ) as integer
dim shared board3(MAP_SZ) as integer
dim shared dist(MAP_SZ) as integer
dim shared dist2(MAP_SZ) as integer
dim shared seen(MAP_SZ) as boolean
dim shared known(MAP_SZ) as boolean

for i as integer = 0 to MAP_SZ - 1
	board(i) = -1
	board2(i) = -1
	board3(i) = -1
	dist(i) = -1
	dist2(i) = -1
	seen(i) = false
	known(i) = false
next


dim shared rooms(100) as room_s
dim shared num_rooms as long
dim shared keep_going as boolean = false
dim shared start_idx as long = 0
dim shared win_idx as long = 0

dim shared ceiling_tex as RenderTexture2D
dim shared ceiling_tex_tex as Texture
ceiling_tex = LoadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8)
ceiling_tex_tex = ceiling_tex.texture

dim shared ground_tex as RenderTexture2D
dim shared ground_tex_tex as Texture
ground_tex = LoadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8)
ground_tex_tex = ground_tex.texture

dim shared pre_game_tex as RenderTexture2D
dim shared pre_game_tex_tex as Texture
pre_game_tex = LoadRenderTexture(MAP_WIDTH * 8, MAP_HEIGHT * 8)
pre_game_tex_tex = pre_game_tex.texture

dim shared loot(100) as item_s
dim shared num_loot as long
dim shared inventory(2) as long = { 1, 1 }
dim shared found_helmet as boolean = false
dim shared found_mail as boolean = false
dim shared found_shield as boolean = false
dim shared found_key as boolean = false
dim shared found_rod as boolean = false
dim shared found_tears as boolean = false
dim shared phoenix_loc as long = 0

dim shared key_delay as long = 0
dim shared amort as long = 0


while true
    if gen_rooms() then
        exit while
    end if
wend

map_update_visibility()
fbs_Play_Sound(snd_melody)
t_clock = util.clock()

while true
    BeginDrawing()
    ClearBackground(BLACK)
    draw_map()
    if not intro_hold then
        item_draw_all()
        entity_draw_all()
    end if
    ui_draw()
	
    EndDrawing()
    
	amort = ( amort + 1 ) mod 4
    get_player_input()
    entity_update_all()
	
    if WindowShouldClose() OrElse quit_game then
        exit while
    end if
wend

CloseAudioDevice()
CloseWindow()


''-----------------------------------------------------------------------------
'' Function Definitions
''-----------------------------------------------------------------------------

sub ui_draw()
    if screen_shake then
        dim dt as double = 1 / 60
        phoenix_frame = phoenix_frame + dt
        if phoenix_frame > 1 then
            phoenix_frame = phoenix_frame + dt * 0.50
        end if
        if phoenix_frame > 8 then
            phoenix_frame = 8
        end if
        t_shake_timer = t_shake_timer - dt
        if t_shake_timer < 4.50 AndAlso not shake_sound_played then
            fbs_Play_Sound(snd_shake)
            shake_sound_played = true
            found_tears = true
            fbs_Play_Sound(snd_levelup)
            note.txt = "Found Phoenix Tears!"
            note.color__ = RLColor(0, 224, 224, 225)
            note.timer = 999.00
        end if
        if shake_sound_played then
            t_shake_move = t_shake_move - dt
            if 0 > t_shake_move then
                t_shake_move = 0.05
                dim an as single = rnd() * 2 * 3.141593
                shake_x = cos(an) * 4
                shake_y = sin(an) * 4
            end if
            if 0 > t_shake_timer then
                screen_shake = false
                shake_x = 0
                shake_y = 0
                menu = WIN
                fbs_Play_Sound(snd_melody)
				fbs_Set_SoundMuted(snd_melody, false)
                game_win = true
                for eidx as integer = 1 to num_entities - 1
                    if 0 < eidx AndAlso game_win then
                        entities(eidx).health = 0
                        entities(eidx).sprite = 39
                        entities(eidx).block_movement = false
                    end if
                next
            end if
        end if
    end if
    dim t_delta as double = 1 / 60
    dim lvl as long = entities(0).level
    draw_text(0, ( YRES - 30 ) * SCALE, "Level: " + str(lvl), DARKGRAY)
    draw_text(76 * SCALE, ( YRES - 30 ) * SCALE, "Pwr: " + str(entities(0).power), DARKGRAY)
    draw_text(144 * SCALE, ( YRES - 30 ) * SCALE, "Def: " + str(entities(0).defense), DARKGRAY)
    dim tx as long = 0
    dim ty as long = 5
    if found_shield then
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, 208 * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 128, 0, 255, 255)
    end if
    tx = 1
    if found_helmet then
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, 224 * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 128, 0, 255, 255)
    end if
    tx = 2
    if found_mail then
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, 240 * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 128, 0, 255, 255)
    end if
    tx = 7
    ty = 6
    if found_key then
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, 256 * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 255, 255, 0, 255)
    end if
    tx = 7
    ty = 7
    if found_tears then
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, 256 * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 32, 192, 255, 255)
    end if
    if not game_win AndAlso not screen_shake then
        t_game = util.clock() - t_clock
    end if
    dim stime as string = "GameTime: "
    dim m as long = t_game / 60
    dim s as long = t_game - m * 60
    stime = stime + str(m) + ":"
    if s < 10 then
        stime = stime + "0"
    end if
    stime = stime + str(s)
    draw_text_sm(208 * SCALE, ( YRES - 10 ) * SCALE, stime, GRAY)
    if 0.00 < note.timer then
        note.timer = note.timer - t_delta
        dim color__ as RLColor = note.color__
        if 2.00 > note.timer then
            color__ = DARKGRAY
        end if
        if 1.00 > note.timer then
            color__ = DARKDARKGRAY
        end if
        draw_text(0, ( YRES - 16 ) * SCALE, "> " + note.txt, color__)
    else
        draw_text(0, ( YRES - 16 ) * SCALE, ">", DARKDARKGRAY)
    end if
    dim r as single = entities(0).health / entities(0).max_health
    dim inc as single = 1.00 / ( lvl * 3 * 2 )
    dim tot as single = 0
    for i as integer = 0 to lvl * 2 - 1
        tx = 0
        ty = 6
        DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2, ( YRES - 16 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, DARKGRAY)
        tot = tot + inc
        if r > tot then
            DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2, ( YRES - 16 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, DARKRED)
        end if
        tot = tot + inc
        if r > tot then
            tx = 1
            DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF - 16 ) * SCALE + i * SCALE_8 * 2, ( YRES - 16 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, RED)
        end if
        tot = tot + inc
    next
    draw_text(( XRES_HALF - 16 ) * SCALE, ( YRES - 30 ) * SCALE, "HP: " + str(entities(0).health) + "/" + str(entities(0).max_health), DARKRED)
    tx = 3
    ty = 6
    DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF + 84 ) * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, RED)
    draw_text(( XRES_HALF + 100 ) * SCALE, ( YRES - 30 ) * SCALE, "x" + str(inventory(0)), RED)
    draw_text(( XRES_HALF + 68 ) * SCALE, ( YRES - 30 ) * SCALE, "H:", RED)
	
    if found_rod then
        dim r as single = entities(0).mana / entities(0).max_mana
        dim inc as single = 1.00 / ( lvl * 3 * 2 )
        dim tot as single = 0
        for i as integer = 0 to lvl * 2 - 1
            tx = 6
            ty = 6
            DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2, ( YRES - 16 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, DARKGRAY)
            tot = tot + inc
            if r > tot then
                DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2, ( YRES - 16 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, DARKGREEN)
            end if
            tot = tot + inc
            if r > tot then
                DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF + 150 ) * SCALE + i * SCALE_8 * 2, ( YRES - 16 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, GREEN)
            end if
            tot = tot + inc
        next
        draw_text(( XRES_HALF + 150 ) * SCALE, ( YRES - 30 ) * SCALE, "MP: " + str(entities(0).mana) + "/" + str(entities(0).max_mana), DARKGREEN)
        tx = 2
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, ( XRES_HALF + 150 - 18 ) * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 128, 255, 128, 255)
        tx = 3
        DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(( XRES_HALF + 252 ) * SCALE, ( YRES - 32 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, GREEN)
        draw_text(( XRES_HALF + 268 ) * SCALE, ( YRES - 30 ) * SCALE, "x" + str(inventory(1)), GREEN)
        draw_text(( XRES_HALF + 234 ) * SCALE, ( YRES - 30 ) * SCALE, "M:", GREEN)
        draw_text(( XRES_HALF + 134 ) * SCALE, ( YRES - 15 ) * SCALE, "C:", GREEN)
    end if
    if INTRO = menu then
        draw_intro()
    elseif CONTROLS = menu then
        draw_controls()
    elseif WIN = menu then
        draw_win()
    end if
end sub

sub draw_house()
    dim x as long = XRES_HALF - 110
    dim y as long = YRES_HALF
    DrawTexturePro(gradient, Rectangle(0, 0, 110, 26), Rectangle(x * SCALE, ( y - 52 ) * SCALE, 220 * SCALE, 52 * SCALE), Vector2(0, 0), 0, WHITE)
    DrawTexturePro(icons, Rectangle(5 * 8, 0, 8, 8), Rectangle(x * SCALE, y * SCALE, 220 * SCALE, 46 * SCALE), Vector2(0, 0), 0, SHARKGRAY)
    DrawTexturePro(icons, Rectangle(0, 80, 8, 8),  Rectangle(( x - 8 ) * SCALE, ( y - 60 ) * SCALE, SCALE_8, SCALE_8), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(40, 80, 8, 8), Rectangle(( x + 220 ) * SCALE, ( y - 60 ) * SCALE, SCALE_8, SCALE_8), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(48, 80, 8, 8), Rectangle(( x - 8 ) * SCALE, ( y + 46 ) * SCALE, SCALE_8, SCALE_8), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(56, 80, 8, 8), Rectangle(( x + 220 ) * SCALE, ( y + 46 ) * SCALE, SCALE_8, SCALE_8), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(8, 80, 8, 8),  Rectangle(x * SCALE, ( y - 60 ) * SCALE, 220 * SCALE, SCALE_8), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(32, 80, 8, 8), Rectangle(x * SCALE, ( y + 46 ) * SCALE, 220 * SCALE, SCALE_8), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(24, 80, 8, 8), Rectangle(( x - 8 ) * SCALE, ( y - 52 ) * SCALE, SCALE_8, 98 * SCALE), Vector2(0, 0), 0, GOLD)
    DrawTexturePro(icons, Rectangle(16, 80, 8, 8), Rectangle(( x + 220 ) * SCALE, ( y - 52 ) * SCALE, SCALE_8, 98 * SCALE), Vector2(0, 0), 0, GOLD)
end sub

sub draw_intro()
    draw_house()
    dim x as long = XRES_HALF - 110
    dim y as long = YRES_HALF
    DrawTextureProRGBA(icons, 0, 0, 8, 8, ( XRES_HALF - 40 ) * SCALE, ( y - 30 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 0, 128, 255, 255)
    DrawTexturePro(icons, Rectangle(0, 8, 8, 8), Rectangle(( XRES_HALF - 8 ) * SCALE, ( y - 30 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, BITTERSWEET)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 4 ) * SCALE, "Dear", WHITE)
    draw_text_sm(( x + 30 ) * SCALE, ( y + 4 ) * SCALE, "Adventurer", BLUE)
    draw_text_sm(( x + 81 ) * SCALE, ( y + 4 ) * SCALE, ", your mother is gravely ill.", WHITE)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 14 ) * SCALE, "You must find the", LIGHTGRAY)
    draw_text_sm(( x + 87 ) * SCALE, ( y + 14 ) * SCALE, "Tears of the Phoenix", CYAN)
    draw_text_sm(( x + 186 ) * SCALE, ( y + 14 ) * SCALE, "in the", LIGHTGRAY)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 24 ) * SCALE, "forbidden ruins to save her. Please hurry...", GRAY)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to start.", GRAY)
end sub

sub draw_controls()
    draw_house()
    dim x as long = XRES_HALF - 110
    dim y as long = YRES_HALF
    DrawTextureProRGBA(icons, 0, 0, 8, 8, ( XRES_HALF - 40 ) * SCALE, ( y - 30 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 0, 128, 255, 255)
    DrawTexturePro(icons, Rectangle(0, 8, 8, 8), Rectangle(( XRES_HALF - 8 ) * SCALE, ( y - 30 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2), Vector2(0, 0), 0, BITTERSWEET)
    draw_text_sm(( x + 7 ) * SCALE, ( y + 4 ) * SCALE, "Controls:", WHITE)
    draw_text_sm(( x + 19 ) * SCALE, ( y + 14 ) * SCALE, "Move: Arrow Keys", WHITE)
    draw_text_sm(( x + 14 ) * SCALE, ( y + 24 ) * SCALE, "Attack: Bump", WHITE)
    draw_text_sm(( x + 121 ) * SCALE, ( y + 4 ) * SCALE, "H: Heal Potion", RED)
    draw_text_sm(( x + 120 ) * SCALE, ( y + 14 ) * SCALE, "M: Mana Potion", GREEN)
    draw_text_sm(( x + 121 ) * SCALE, ( y + 24 ) * SCALE, "C: Cast Magic", GREEN)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to start.", GRAY)
end sub

sub draw_win()
    dim x as long = XRES_HALF - 110
    dim y as long = YRES_HALF
    t_win = t_win + 1 / 60
    if t_win < 0.50 then
        return 
    end if
    draw_house()
    dim xx as single = t_win * 10
    dim alpha as single = 255 * ( 1 - t_win / 10 )
    if alpha < 0 then
        alpha = 0
    end if
    DrawTextureProRGBA(icons, 0, 0, 8, 8, ( XRES_HALF - 40 + xx ) * SCALE, ( y - 30 ) * SCALE, SCALE_8 * 2, SCALE_8 * 2, 0, 0, 0, 0, 128, 255, alpha)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 10 ) * SCALE, "I'm almost there, please hold on...", CYAN)
    draw_text_sm_center(XRES_HALF * SCALE, ( y + 37 ) * SCALE, "Press <SPACE> to end.", GRAY)
end sub

sub add_note(text as string, color__ as RLColor, cooldown as single)
    note.txt = text
    note.color__ = color__
    note.timer = cooldown
end sub

sub draw_text(x as long, y as long, txt as string, color__ as RLColor)
    DrawTextEx(fnt, txt, Vector2(x, y), 15 * SCALE, 1, color__)
end sub

sub draw_text_center(x as long, y as long, txt as string, color__ as RLColor)
    dim m as long = MeasureTextEx(fnt, txt, 15 * SCALE, 1).x
    draw_text(x - m / 2, y, txt, color__)
end sub

sub draw_text_right(x as long, y as long, txt as string, color__ as RLColor)
    dim m as long = MeasureTextEx(fnt, txt, 15 * SCALE, 1).x
    draw_text(x - m, y, txt, color__)
end sub

sub draw_text_sm(x as long, y as long, txt as string, color__ as RLColor)
    DrawTextEx(fnt_sm, txt, Vector2(x, y), SCALE_8, 0, color__)
end sub

sub draw_text_sm_center(x as long, y as long, txt as string, color__ as RLColor)
    dim m as long = MeasureTextEx(fnt_sm, txt, SCALE_8, 0).x
    draw_text_sm(x - m / 2, y, txt, color__)
end sub

sub draw_text_sm_right(x as long, y as long, txt as string, color__ as RLColor)
    dim m as long = MeasureTextEx(fnt_sm, txt, SCALE_8, 0).x
    draw_text_sm(x - m, y, txt, color__)
end sub


sub entity_new(x as long, y as long, sprite as long, health as long, level as long, power as long, defense as long, enemy as boolean)
    dim e as entity_s
    e.px = x
    e.py = y
    e.ix = x
    e.iy = y
    e.sprite = sprite
    e.block_movement = true
    e.health = health
    e.max_health = e.health
    e.defense = defense
    e.power = power
    e.mana = 0
    e.max_mana = 0
    e.level = level
    e.enemy = enemy
    e.state = WANDER
    e.skip_update = - 1
	entities(num_entities) = e
	num_entities = num_entities + 1
end sub

sub entity_draw_all()
    dim px as single = entities(0).px
    dim py as single = entities(0).py
    if 0 = entities(0).health then
        entity_draw_player()
    end if
    for i as integer = 1 to num_entities - 1
        if 0 > entities(i).skip_update then
            if not seen(entities(i).iy * MAP_WIDTH + entities(i).ix) then
                continue for
            end if
            dim x as single = entities(i).px
            dim y as single = entities(i).py
            if 0 < entities(i).health then
                dim dx as single = px - entities(i).px
                dim dy as single = py - entities(i).py
                dim dist as single = sqr(dx * dx + dy * dy)
                if dist < 7.00 then
                    dim sprite as long = entities(i).sprite
                    dim tx as long = sprite mod 8
                    dim ty as long = ( sprite - tx ) / 8
                    dim ratio as single = entities(0).level / ( entities(i).level + 2 ) * 0.75
                    if ratio > 1 then
                        ratio = 1
                    end if
                    dim r as long = 48
                    dim g as long = 48
                    dim b as long = 48
                    if dist < 5.00 then
                        r = 255 * ( 1 - ratio )
                        g = 255 * ratio
                        b = 0
                    end if
                    DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, x * SCALE_8 + shake_x, y * SCALE_8 + shake_y, SCALE_8, SCALE_8, 0, 0, 0, r, g, b, 255)
                else
                    entities(i).skip_update = util.rand_range(5, 10)
                end if
            else
                DrawTexturePro(icons, Rectangle(7 * 8, 4 * 8, 8, 8), Rectangle(x * SCALE_8 + shake_x, y * SCALE_8 + shake_y, SCALE_8, SCALE_8), Vector2(0, 0), 0, DARKRED)
            end if
        else
            entities(i).skip_update = entities(i).skip_update - 1
        end if
        dim kx as long = entities(i).kx
        dim ky as long = entities(i).ky
        if kx < 0 then
            entities(i).kx = kx + 1
        end if
        if kx > 0 then
            entities(i).kx = kx - 1
        end if
        if ky < 0 then
            entities(i).ky = ky + 1
        end if
        if ky > 0 then
            entities(i).ky = ky - 1
        end if
    next
    t_flames = t_flames + 1 / 60
    for i as integer = 0 to num_torches - 1
        dim ix as long = torches(i).x
        dim iy as long = torches(i).y
        if ix = entities(0).ix AndAlso iy = entities(0).iy AndAlso 0 < entities(0).health then
            entities(0).health = 0
            fbs_Play_Sound(snd_dead)
        end if
        if seen(iy * MAP_WIDTH + ix) then
            dim ofs as long = util.to_int(( t_flames * 12 + i )) mod 6
            dim tx as long = util.to_int(( t_flames * 12 + i )) mod 7
            dim ty as long = 7
            DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(ix * SCALE_8 + shake_x, iy * SCALE_8 + shake_y, SCALE_8, SCALE_8), Vector2(0, 0), 0, flame(ofs))
        end if
    next
    if magic_ball.active then
		DrawTexturePro(icons, Rectangle(6 * 8, 6 * 8, 8, 8), Rectangle(magic_ball.px * SCALE_8 + shake_x, magic_ball.py * SCALE_8 + shake_y, SCALE_8, SCALE_8), Vector2(0, 0), 0, magic(util.rand_range(0, 5)))
    end if
    if 0 < entities(0).health then
        entity_draw_player()
    end if
end sub

sub entity_draw_player()
    dim tx as long = 0
    dim ty as long = 0
    dim x as single = entities(0).px
    dim y as single = entities(0).py
    if 0 < entities(0).health then
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, x * SCALE_8, y * SCALE_8, SCALE_8, SCALE_8, 0, 0, 0, 0, 128, 255, 255)
    else
        DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, x * SCALE_8, y * SCALE_8, SCALE_8, SCALE_8, 0, 0, 0, 64, 64, 64, 255)
    end if
end sub

sub entity_move(eidx as long, move_dir as enumtype)
    dim ix as long = entities(eidx).ix
    dim iy as long = entities(eidx).iy
    dim idx as long = iy * MAP_WIDTH + ix
    if MOVE_UP = move_dir AndAlso iy > 0 AndAlso 3 > board(idx - MAP_WIDTH) then
        iy = iy - 1
    elseif MOVE_DOWN = move_dir AndAlso iy < MAP_HEIGHT - 1 AndAlso 3 > board(idx + MAP_WIDTH) then
        iy = iy + 1
    elseif MOVE_LEFT = move_dir AndAlso ix > 0 AndAlso 3 > board(idx - 1) then
        ix = ix - 1
    elseif MOVE_RIGHT = move_dir AndAlso ix < MAP_WIDTH - 1 AndAlso 3 > board(idx + 1) then
        ix = ix + 1
    end if
    dim new_idx as long = iy * MAP_WIDTH + ix
    if 0 = eidx AndAlso idx <> new_idx AndAlso 1 = board(new_idx) then
        if found_key then
            found_key = false
            add_note("Unlocked!", YELLOW, 5.00)
            board(new_idx) = 2
            fbs_Play_Sound(snd_door)
        else
            add_note("Locked!", ORANGE, 5.00)
            new_idx = idx
        end if
    end if
    if idx <> new_idx then
        for i as integer = 1 to num_entities - 1
            if 0 > entities(i).skip_update AndAlso entities(i).block_movement AndAlso new_idx = entities(i).iy * MAP_WIDTH + entities(i).ix then
                if 0 = eidx AndAlso 0 > entities(eidx).cooldown then
                    entities(i).health = entities(i).health - 1
                    note.txt = "Hit Beast for 1 dmg!"
                    note.color__ = GRAY
                    note.timer = 5.00
                    entities(0).kx = ( ix - entities(eidx).ix ) * 8
                    entities(0).ky = ( iy - entities(eidx).iy ) * 8
                    entities(0).cooldown = 0.30
                    fbs_Play_Sound(snd_attack)
                    if 0 = entities(i).health then
                        entities(i).sprite = 39
                        entities(i).block_movement = false
                        note.txt = "Beast fell!"
                        note.color__ = LIGHTGRAY
                        note.timer = 5.00
                    end if
                end if
                ix = entities(eidx).ix
                iy = entities(eidx).iy
                exit for
            end if
        next
        entities(eidx).ix = ix
        entities(eidx).iy = iy
        if 0 = eidx then
            if iy * MAP_WIDTH + ix = win_idx then
                screen_shake = true
                fbs_Play_Sound(snd_cast)
            end if
        end if
    else
        if 0 = eidx AndAlso 0.10 > note.timer then
            add_note("Blocked!", BROWN, 3.00)
        end if
    end if
end sub


sub entity_spawn_monster(x as long, y as long, lvl as long)
    dim mx as long = lvl * 23 / 5
    if mx < 4 then
        mx = 4
    end if
    if mx > 23 then
        mx = 23
    end if
    dim sprite as long = 16 + util.rand_range(0, mx)
    entity_new(x, y, sprite, 1 + ( 1 + rnd() ) * lvl, lvl, int(( 0.20 + rnd() * 0.50 ) * lvl) + 1, int(( 0.20 + rnd() * 0.50 ) * lvl) + 1, true)
end sub

sub entity_update(eidx as long, t_delta as double)
    dim fps as single = 1 / t_delta
    if fps < 10 then
        entities(eidx).px = entities(eidx).ix
        entities(eidx).py = entities(eidx).iy
        key_delay = 0
    end if
    dim dx as single = entities(eidx).ix - entities(eidx).px
    if abs(dx) > 0.10 then
        entities(eidx).px = entities(eidx).px + dx * 0.50
    else
        entities(eidx).px = entities(eidx).ix
    end if
    dim dy as single = entities(eidx).iy - entities(eidx).py
    if abs(dy) > 0.10 then
        entities(eidx).py = entities(eidx).py + dy * 0.50
    else
        entities(eidx).py = entities(eidx).iy
    end if
    entities(eidx).cooldown = entities(eidx).cooldown - t_delta
end sub

sub entity_update_all()
    if intro_hold then
        return 
    end if
    dim t_delta as double = 1 / 60
    entity_update(0, t_delta)
    if screen_shake then
        return 
    end if
    if cbool(0 < entities(0).health) AndAlso cbool(entities(0).health < (entities(0).max_health * 0.31)) AndAlso not screen_shake AndAlso not game_win then	
        blip_timer = blip_timer - t_delta
        if 0 > blip_timer then
            blip_timer = 1.00
            fbs_Play_Sound(snd_blip)
        end if
    end if
    if magic_ball.active then
        magic_ball.px = magic_ball.px + magic_ball.vx * t_delta
        magic_ball.py = magic_ball.py + magic_ball.vy * t_delta
        dim px as long = util.to_int(magic_ball.px + 0.50)
        dim py as long = util.to_int(magic_ball.py + 0.50)
        dim idx as long = py * MAP_WIDTH + px
        if - 1 <> board(idx) then
            magic_ball.active = false
        end if
    end if
    if not game_win AndAlso not screen_shake then
        ambient_timer = ambient_timer - t_delta
        if 0 > ambient_timer then
            ambient_timer = 4 + 4 * rnd()
            dim snd as long = util.rand_range(0, 3)
            if 0 = snd then
                fbs_Play_Sound(snd_ambient_1)
            elseif 1 = snd then
                fbs_Play_Sound(snd_ambient_2)
            elseif 2 = snd then
                fbs_Play_Sound(snd_ambient_3)
            end if
        end if
    end if
    for i as integer = 1 to num_entities - 1
        if 0 < entities(i).health AndAlso magic_ball.active then
            dim dx as single = entities(i).px - magic_ball.px
            dim dy as single = entities(i).py - magic_ball.py
            if sqr(dx * dx + dy * dy) < 0.50 then
                dim dmg as long = 2 * entities(0).level
                entities(i).health = util.max(0, entities(i).health - dmg)
                note.txt = "Hit Beast for " + str(dmg) + " dmg!"
                note.color__ = GRAY
                note.timer = 5.00
                entities(0).cooldown = 0.30
                fbs_Play_Sound(snd_attack)
                if 0 = entities(i).health then
                    entities(i).sprite = 39
                    entities(i).block_movement = false
                    note.txt = "Beast fell!"
                    note.color__ = LIGHTGRAY
                    note.timer = 5.00
                end if
            end if
        end if
        if 0 < entities(i).health AndAlso 0 > entities(i).skip_update AndAlso 0 > entities(i).cooldown then
            if amort = i mod 4 then
                dim dx as single = entities(0).px - entities(i).px
                dim dy as single = entities(0).py - entities(i).py
                dim dist as single = sqr(dx * dx + dy * dy)
                if WANDER = entities(i).state AndAlso dist < 5.00 then
                    entities(i).state = CHASE
                elseif CHASE = entities(i).state AndAlso dist > 7 then
                    entities(i).state = WANDER
                end if
                if dist < 1.20 AndAlso rnd() < 0.50 AndAlso 0 < entities(0).health then
                    note.txt = "Beast hit for 1 dmg!"
                    note.color__ = RED
                    note.timer = 5.00
                    entities(i).cooldown = 0.70
                    entities(i).ix = entities(i).px
                    entities(i).iy = entities(i).py
                    entities(i).kx = dx * 8
                    entities(i).ky = dy * 8
                    entities(0).health = util.max(0, entities(0).health - 1)
                    fbs_Play_Sound(snd_hurt)
                    if 0 = entities(0).health then
                        fbs_Play_Sound(snd_dead)
                    end if
                end if
                if WANDER = entities(i).state AndAlso rnd() < 0.10 then
                    dim j as long = util.rand_range(0, 4)
                    if 0 = j then
                        entity_move(i, MOVE_UP)
                    elseif 1 = j then
                        entity_move(i, MOVE_DOWN)
                    elseif 2 = j then
                        entity_move(i, MOVE_LEFT)
                    elseif 3 = j then
                        entity_move(i, MOVE_RIGHT)
                    end if
                elseif CHASE = entities(i).state AndAlso rnd() < 0.10 then
                    if abs(dx) > abs(dy) then
                        if entities(i).px < entities(0).px then
                            entity_move(i, MOVE_RIGHT)
                        else
                            entity_move(i, MOVE_LEFT)
                        end if
                    else
                        if entities(i).py < entities(0).py then
                            entity_move(i, MOVE_DOWN)
                        else
                            entity_move(i, MOVE_UP)
                        end if
                    end if
                end if
            end if
        end if
        entity_update(i, t_delta)
    next
end sub

function gen_rooms() as boolean
    print "Generating Rooms"
	
	for i as integer = 0 to MAP_SZ - 1
		board(i) = -1
		board2(i) = -1
		board3(i) = -1
		dist(i) = -1
		dist2(i) = -1
		seen(i) = false
		known(i) = false
	next

	
    'redim rooms(0 to 0) as room_s
	num_rooms = 0
    
    keep_going = false
    dim w3 as long = MAP_WIDTH / 3
    dim h2 as long = MAP_HEIGHT / 2
    for j as integer = 0 to 6 - 1
        dim xx as long = 0
        dim yy as long = 0
        if 1 = j then
            yy = 1
        elseif 2 = j then
            xx = 1
            yy = 1
        elseif 3 = j then
            xx = 1
            yy = 0
        elseif 4 = j then
            xx = 2
            yy = 0
        elseif 5 = j then
            xx = 2
            yy = 1
        end if
        for k as integer = 0 to 200 - 1
            dim w as long = util.rand_range(4, 8)
            dim h as long = util.rand_range(4, 6)
            dim x as long = util.rand_range(( xx * w3 ), ( ( xx + 1 ) * w3 ) - w + 1)
            dim y as long = util.rand_range(( yy * h2 ), ( ( yy + 1 ) * h2 ) - h + 1)
            if check_room_plot(x, y, w, h) then
                gen_room_plot(x, y, w, h)
            end if
        next
    next
	
	dim taken(MAP_SZ) as boolean
	for i as integer = 0 to MAP_SZ - 1
		taken(i) = false
	next
	
	' phoenix room
    dim w as long = 6
    dim h as long = 6
    dim y as long = MAP_HEIGHT - 7
    dim x as long = 54 + util.rand_range(0, 15)
    phoenix_loc = ( y + 2 ) * MAP_WIDTH + x + 2
    gen_room_plot(x, y, w, h)
    for yy as integer = 0 to h - 1
        for xx as integer = 0 to w - 1
            dim idx as long = ( y + yy ) * MAP_WIDTH + x + xx
            taken(idx) = true
        next
    next
	
    for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim idx as long = y * MAP_WIDTH + x
            if -1 = board(idx) then
                board(idx) = 6
            end if
        next
    next
	
	
	for i as integer = 0 to num_rooms - 1 - 1
        gen_hallway(i, i + 1)
    next
	
    for i as integer = 0 to MAP_SZ - 1
        board2(i) = board(i)
    next
    for i as integer = 0 to MAP_SZ - 1
        board(i) = board2(i)
        if 4 = board2(i) then
            board(i) = - 1
        elseif - 1 = board2(i) then
            board(i) = 3
        end if
        board2(i) = board(i)
    next
    for x as integer = 0 to MAP_WIDTH - 1
        dim idx as long = 18 * MAP_WIDTH + x
        if - 1 = board(idx) then
            board2(idx) = 1
        end if
    next
	
	for y as integer = 0 to MAP_HEIGHT - 1 - 1
        for x as integer = 0 to MAP_WIDTH - 1 - 1
            dim idx as long = y * MAP_WIDTH + x
            if 6 <> board(idx) then
                continue for
            end if
            if 6 = board(idx + 1) AndAlso 6 = board(idx + MAP_WIDTH) AndAlso 6 = board(idx + MAP_WIDTH + 1) then
                board3(idx) = 13
            end if
        next
    next
    for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim idx as long = y * MAP_WIDTH + x
            if 6 <> board(idx) then
                continue for
            end if
            dim up__ as boolean = false
            dim down__ as boolean = false
            dim left__ as boolean = false
            dim right__ as boolean = false
            if x > 0 then
                if 6 = board(idx - 1) then
                    left__ = true
                end if
            end if
            if y > 0 then
                if 6 = board(idx - MAP_WIDTH) then
                    up__ = true
                end if
            end if
            if x < MAP_WIDTH - 1 then
                if 6 = board(idx + 1) then
                    right__ = true
                end if
            end if
            if y < MAP_HEIGHT - 1 then
                if 6 = board(idx + MAP_WIDTH) then
                    down__  = true
                end if
            end if
            dim yy as long = 8
            dim xx as long = 0
            if left__ then
                xx = xx + 4
            end if
            if right__ then
                yy = yy + 1
            end if
            if up__ then
                xx = xx + 1
            end if
            if down__ then
                xx = xx + 2
            end if
            board2(idx) = yy * 8 + xx
        next
    next
	
	for i as integer = 0 to MAP_SZ - 1
		board(i) = board2(i)
    next
	
	for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim idx as long = y * MAP_WIDTH + x
            if x < MAP_WIDTH - 1 AndAlso x > 0 then
				if 77 = board(idx - 1) AndAlso 77 = board(idx) AndAlso 77 = board(idx + 1) AndAlso rnd() < 0.80 then
                    board(idx) = 76
                end if
                if 78 = board(idx - 1) AndAlso 78 = board(idx) AndAlso 78 = board(idx + 1) AndAlso rnd() < 0.80 then
                    board(idx) = 76
                end if
            end if
            if y < MAP_HEIGHT - 1 AndAlso y > 0 then
                if 71 = board(idx - MAP_WIDTH) AndAlso 71 = board(idx) AndAlso 71 = board(idx + MAP_WIDTH) AndAlso rnd() < 0.80 then
                    board(idx) = 67
                end if
                if 75 = board(idx - MAP_WIDTH) AndAlso 75 = board(idx) AndAlso 75 = board(idx + MAP_WIDTH) AndAlso rnd() < 0.80 then
                    board(idx) = 67
                end if
            end if
        next
    next
	
    for i as integer = 0 to MAP_SZ - 1
        if 1 = board(i) then
            dist(i) = 0
        elseif - 1 <> board(i) then
            dist(i) = - 2
        end if
    next
	
    dim mindist as single = 9999999
    for y as integer = 0 to 13 - 1
        for x as integer = 0 to 13 - 1
            dim idx as long = y * MAP_WIDTH + x
            if - 1 <> board(idx) then
                continue for
            end if
            dim d as single = sqr(x * x + y * y)
            if d < mindist then
                mindist = d
                start_idx = idx
            end if
        next
    next
	
	win_idx = phoenix_loc + 1 + 2 * MAP_WIDTH
	
    dist(start_idx) = 1
	for i as integer = 0 to MAP_SZ - 1
		dist2(i) = dist(i)
	next
	
	dim cc as long = 0
    while true
        keep_going = false
		for i as integer = 0 to MAP_SZ - 1
			update_dist(i)
		next
		
		for i as integer = 0 to MAP_SZ - 1
			dist(i) = dist2(i)
		next
        
        if not keep_going then
            exit while
        end if
        cc = cc + 1
        if cc > 1000 then
            return false
        end if
    wend
	
    x = phoenix_loc mod MAP_WIDTH
    y = ( phoenix_loc - x ) / MAP_WIDTH
    for yy as integer = 0 to 3 - 1
        for xx as integer = 0 to 3 - 1
            if 1 = xx AndAlso 2 = yy then
                continue for
            end if
            dim idx as long = ( y + yy ) * MAP_WIDTH + x + xx
            board(idx) = 4
        next
    next
    dim key0 as long = 0
    dim key1 as long = 0
    dim key2 as long = 0
    dim maxdist as long = - 1
    for y as integer = 0 to 18 - 1
        for x as integer = 0 to 25 - 1
            dim idx as long = y * MAP_WIDTH + x
            dim d as long = dist(idx)
            if d > maxdist then
                maxdist = d
                key0 = idx
                taken(idx) = true
            end if
        next
    next
    x = key0 mod MAP_WIDTH
    y = ( key0 - x ) / MAP_WIDTH
    item_new(x, y, 6 * 8 + 7, GOLD, false, "Key", KEY)
    maxdist = - 1
    for y as integer = 0 to 18 - 1
        for x as integer = 0 to 50 - 1
            dim idx as long = ( 18 + y ) * MAP_WIDTH + x
            dim d as long = dist(idx)
            if d > maxdist then
                maxdist = d
                key1 = idx
                taken(idx) = true
            end if
        next
    next
    x = key1 mod MAP_WIDTH
    y = ( key1 - x ) / MAP_WIDTH
    item_new(x, y, 6 * 8 + 7, GOLD, false, "Key", KEY)
    maxdist = - 1
    for y as integer = 0 to 18 - 1
        for x as integer = 0 to 50 - 1
            dim idx as long = y * MAP_WIDTH + x + 25
            dim d as long = dist(idx)
            if d > maxdist then
                maxdist = d
                key2 = idx
                taken(idx) = true
            end if
        next
    next
    x = key2 mod MAP_WIDTH
    y = ( key2 - x ) / MAP_WIDTH
    item_new(x, y, 6 * 8 + 7, GOLD, false, "Key", KEY)
    maxdist = - 1
    for i as integer = 0 to MAP_SZ - 1
        dim d as long = dist(i)
        if d > maxdist then
            maxdist = d
        end if
    next
    dim arm0 as long = 0
    dim arm1 as long = 0
    dim arm2 as long = 0
    dim leg0 as long = 0
    dim leg1 as long = 0
    dim leg2 as long = 0
    dim rod0 as long = 0
    dim heart0 as long = 0
    dim heart1 as long = 0
    dim heart2 as long = 0
    dim potions(6) as long
    dim mana(2) as long
    dim v as vec2i
    for yy as integer = 0 to 2 - 1
        for xx as integer = 0 to 3 - 1
            dim mx as long = 1
            if 0 < xx then
                mx = mx + 1
                if 0 = yy then
                    mx = mx + 1
                end if
            end if
            if 1 < xx then
                mx = mx + 1
            end if
            for k as integer = 0 to mx - 1
                dim c as long = 0
                while true
                    c = c + 1
                    if 1000 = c then
                        exit while
                    end if
                    v.x = util.rand_range(1, 25) + xx * 25
                    v.y = util.rand_range(1, 18) + yy * 18
                    dim idx as long = v.y * MAP_WIDTH + v.x
                    if - 1 = board(idx) AndAlso not taken(idx) then
                        dim pass as boolean = true
                        for y as integer = 0 to 3 - 1
                            for x as integer = 0 to 3 - 1
                                dim idx0 as long = idx + ( y - 1 ) * MAP_WIDTH + x - 1
                                if - 1 <> board(idx0) OrElse taken(idx0) then
                                    pass = false
                                    exit for
                                end if
                            next
                            if not pass then
                                exit for
                            end if
                        next
                        if pass then
                            taken(idx) = true
							torches(num_torches) = v
							num_torches = num_torches + 1
                            exit for
                        end if
                    end if
                wend
            next
        next
    next
    while true
        dim x as long = util.rand_range(0, 25)
        dim y as long = util.rand_range(0, 18)
        if 0 = heart0 then
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                heart0 = idx
                item_new(x, y, 6 * 8 + 1, RED, false, "Heart Container", HEART)
                taken(idx) = true
            end if
        elseif 0 = heart1 then
            x = x + 25
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                heart1 = idx
                item_new(x, y, 6 * 8 + 1, RED, false, "Heart Container", HEART)
                taken(idx) = true
            end if
        elseif 0 = heart2 then
            x = x + 50
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                heart2 = idx
                item_new(x, y, 6 * 8 + 1, RED, false, "Heart Container", HEART)
                taken(idx) = true
            end if
        elseif 0 = arm0 then
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                arm0 = idx
                item_new(x, y, 5 * 8 + 0, VIOLET, false, "Shield", ARM_SHIELD)
                taken(idx) = true
            end if
        elseif 0 = arm1 then
            x = x + 25
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                arm1 = idx
                item_new(x, y, 5 * 8 + 1, VIOLET, false, "Helmet", ARM_HELMET)
                taken(idx) = true
            end if
        elseif 0 = arm2 then
            x = x + 50
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                arm2 = idx
                item_new(x, y, 5 * 8 + 2, VIOLET, false, "Mail", ARM_MAIL)
                taken(idx) = true
            end if
        elseif 0 = rod0 then
            x = x + 25
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                rod0 = idx
                item_new(x, y, 6 * 8 + 2, GREEN, false, "Rod", ROD)
                taken(idx) = true
            end if
        elseif 0 = leg0 then
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                leg0 = idx
                item_new(x, y, 5 * 8 + 3, BROWN, false, "Food", TURKEY_LEG)
                taken(idx) = true
            end if
        elseif 0 = leg1 then
            x = x + 25
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                leg1 = idx
                item_new(x, y, 5 * 8 + 3, BROWN, false, "Food", TURKEY_LEG)
                taken(idx) = true
            end if
        elseif 0 = leg2 then
            x = x + 50
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                leg2 = idx
                item_new(x, y, 5 * 8 + 3, BROWN, false, "Food", TURKEY_LEG)
                taken(idx) = true
            end if
        elseif 1 > potions(0) then
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                potions(0) = potions(0) + 1
                item_new(x, y, 6 * 8 + 3, RED, false, "Health Potion", POTION_HEALTH)
                taken(idx) = true
            end if
        elseif 2 > potions(1) then
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                potions(1) = potions(1) + 1
                item_new(x, y, 6 * 8 + 3, RED, false, "Health Potion", POTION_HEALTH)
                taken(idx) = true
            end if
        elseif 2 > potions(2) then
            x = x + 25
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                potions(2) = potions(2) + 1
                item_new(x, y, 6 * 8 + 3, RED, false, "Health Potion", POTION_HEALTH)
                taken(idx) = true
            end if
        elseif 2 > potions(3) then
            x = x + 25
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                potions(3) = potions(3) + 1
                item_new(x, y, 6 * 8 + 3, RED, false, "Health Potion", POTION_HEALTH)
                taken(idx) = true
            end if
        elseif 2 > potions(4) then
            x = x + 50
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                potions(4) = potions(4) + 1
                item_new(x, y, 6 * 8 + 3, RED, false, "Health Potion", POTION_HEALTH)
                taken(idx) = true
            end if
        elseif 1 > potions(5) then
            x = x + 50
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                potions(5) = potions(5) + 1
                item_new(x, y, 6 * 8 + 3, RED, false, "Health Potion", POTION_HEALTH)
                taken(idx) = true
            end if
        elseif 2 > mana(0) then
            y = y + 18
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                mana(0) = mana(0) + 1
                item_new(x, y, 6 * 8 + 4, GREEN, false, "Mana Potion", POTION_MANA)
                taken(idx) = true
            end if
        elseif 2 > mana(1) then
            x = x + 25
            dim idx as long = y * MAP_WIDTH + x
            if - 1 = board(idx) AndAlso not taken(idx) then
                mana(1) = mana(1) + 1
                item_new(x, y, 6 * 8 + 4, GREEN, false, "Mana Potion", POTION_MANA)
                taken(idx) = true
            end if
        else
            exit while
        end if
    wend
    
	dim px as long = start_idx mod MAP_WIDTH
    dim py as long = ( start_idx - px ) / MAP_WIDTH
    entity_new(px, py, 0, 10, 1, 1, 1, false)
    entities(0).mana = 5
    entities(0).max_mana = entities(0).mana
	
    for i as integer = 0 to 75 - 1
        dim c as long = 0
        while true
            c = c + 1
            if 1000 = c then
                exit while
            end if
            x = util.rand_range(0, MAP_WIDTH)
            dim y as long = util.rand_range(0, MAP_HEIGHT)
            dim dx as long = x - px
            dim dy as long = y - py
            dim dist as single = sqr(dx * dx + dy * dy)
            if dist < 8 then
                continue while
            end if
            if dist < 15 AndAlso rnd() < 0.50 then
                continue while
            end if
            if x < 25 AndAlso rnd() < 0.30 then
                continue while
            end if
            if x < 50 AndAlso rnd() < 0.30 then
                continue while
            end if
            dim idx as long = y * MAP_WIDTH + x
            if - 1 <> board(idx) OrElse taken(idx) then
                continue while
            end if
            taken(idx) = true
            dim lvl as long = ( dist / MAP_WIDTH ) * 4 + util.rand_range(0, 3)
            entity_spawn_monster(x, y, lvl)
            exit while
        wend
    next
	
    BeginTextureMode(ground_tex)
    ClearBackground(BLACK)
    for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim idx as long = y * MAP_WIDTH + x
            dim t as long = board(idx)
            if 0 > t then
                continue for
            end if
			dim tx as long = t mod 8
            dim ty as long = ( t - tx ) / 8
			dim r as long = 96
            dim g as long = 96
            dim b as long = 96
            if 3 = t then
                r = 64
                g = 48
                b = 32
            elseif 1 = t then
                r = 192
                g = 127
                b = 32
            end if
            if x < 26 AndAlso y < 19 then
                r = 0
            end if
            if x > 49 then
                r = r * 1.20
                g = g * 1.20
                b = b * 1.20
                if y > 18 then
                    r = 230
					g = 230
					b = 230
                end if
            end if
			DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, x * 8, y * 8, 8, 8, 0, 0, 0, r / 3, g / 3, b / 3, 255)
        next
    next
    EndTextureMode()
	
    BeginTextureMode(ceiling_tex)
    ClearBackground(BLANK)
    for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim idx as long = y * MAP_WIDTH + x
            dim t as long = board3(idx)
            if 0 > t then
                continue for
            end if
            dim tx as long = t mod 8
            dim ty as long = ( t - tx ) / 8
            dim r as long = 96 / 3
            dim g as long = 64 / 3
            dim b as long = 127 / 3
            if x < 26 AndAlso y < 19 then
                g = 127 / 3
                b = 96 / 3
                r = 64 / 3
                tx = 6 + ( x + y ) mod 2
                ty = ( x + y ) mod 2
            end if
            if x > 49 then
                r = r * 0.30
            end if
            DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, x * 8 + 4, y * 8 + 2, 8, 8, 0, 0, 0, r, g, b, 255)
        next
    next
    EndTextureMode()
	
    BeginTextureMode(pre_game_tex)
    ClearBackground(BLANK)
    for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim r as long = 255 * ( y / MAP_HEIGHT ) * 0.10
            dim b as long = 255 * ( 1 - y / MAP_HEIGHT ) * 0.30
            dim g as long = b * 0.70
            DrawTextureProRGBA(icons, 5 * 8, 8, 8, 8, x * 8, y * 8, 8, 8, 0, 0, 0, r, g, b, 255)
        next
    next
    EndTextureMode()
	
    return true
end function

sub update_dist(idx as long)
    if - 1 <> dist(idx) then
        return 
    end if
    dim x as long = idx mod MAP_WIDTH
    dim y as long = ( idx - x ) / MAP_WIDTH
    if x < 1 OrElse y < 1 OrElse x > MAP_WIDTH - 2 OrElse y > MAP_HEIGHT - 2 then
        return 
    end if
    dim up__ as long = dist(idx - MAP_WIDTH)
    dim down__ as long = dist(idx + MAP_WIDTH)
    dim left__ as long = dist(idx - 1)
    dim right__ as long = dist(idx + 1)
    dim d as long = util.max(util.max(util.max(up__, down__), left__), right__)
    if d > - 1 then
        dist2(idx) = d + 1
    end if
    keep_going = true
end sub

function check_room_plot(x as long, y as long, w as long, h as long) as boolean
    if 0 > x OrElse 0 > y then
        return false
    end if
    if MAP_WIDTH - 1 < x + w OrElse MAP_HEIGHT - 1 < y + h then
        return false
    end if
    for yy as integer = 0 to h - 1
        for xx as integer = 0 to w - 1
            dim i as long = ( yy + y ) * MAP_WIDTH + xx + x
            if - 1 <> board(i) then
                return false
            end if
        next
    next
    return true
end function

sub gen_room_plot(x as long, y as long, w as long, h as long)
    for yy as integer = 0 to h - 1
        for xx as integer = 0 to w - 1
            dim i as long = ( yy + y ) * MAP_WIDTH + xx + x
            if 0 = yy OrElse 0 = xx then
                board(i) = 6
            else
                board(i) = 4
            end if
        next
    next
    dim room as room_s
    room.x = x
    room.y = y
    room.w = w
    room.h = h
    room.cx = util.to_int(int(x + w / 2) + 1)
    room.cy = util.to_int(int(y + h / 2) + 1)
	rooms(num_rooms) = room
	num_rooms = num_rooms + 1
end sub

sub gen_hallway(r0_in as long, r1_in as long)
	dim r0 as long = r0_in
    dim r1 as long = r1_in
    if rooms(r1).cy < rooms(r0).cy then
        dim temp as long = r0
        r0 = r1
        r1 = temp
    end if
    dim y0 as long = rooms(r0).cy
    dim y1 as long = rooms(r1).cy
    if rooms(r0).cx < rooms(r1).x then
        dim x0 as long = rooms(r0).cx
        dim x1 as long = rooms(r1).cx
        if rnd() < 0.50 then
            for x as integer = x0 to x1 + 1 - 1
                dim idx as long = y0 * MAP_WIDTH + x
                board(idx) = 4
            next
            for y as integer = y0 to y1 + 1 - 1
                dim idx as long = y * MAP_WIDTH + x1
                board(idx) = 4
            next
        else
            for y as integer = y0 to y1 + 1 - 1
                dim idx as long = y * MAP_WIDTH + x0
                board(idx) = 4
            next
            for x as integer = x0 to x1 + 1 - 1
                dim idx as long = y1 * MAP_WIDTH + x
                board(idx) = 4
            next
        end if
    else
        dim x0 as long = rooms(r1).cx
        dim x1 as long = rooms(r0).cx
        if rnd() < 0.50 then
            for x as integer = x0 to x1 + 1 - 1
                dim idx as long = y0 * MAP_WIDTH + x
                board(idx) = 4
            next
            for y as integer = y0 to y1 + 1 - 1
                dim idx as long = y * MAP_WIDTH + x0
                board(idx) = 4
            next
        else
            for y as integer = y0 to y1 + 1 - 1
                dim idx as long = y * MAP_WIDTH + x1
                board(idx) = 4
            next
            for x as integer = x0 to x1 + 1 - 1
                dim idx as long = y1 * MAP_WIDTH + x
                board(idx) = 4
            next
        end if
    end if
end sub

sub draw_map()
    DrawTexturePro(ground_tex_tex, Rectangle(0, 0, MAP_WIDTH * 8, - MAP_HEIGHT * 8), Rectangle(shake_x, shake_y, MAP_WIDTH * SCALE_8, MAP_HEIGHT * SCALE_8), Vector2(0, 0), 0, WHITE)
    
	dim x as long = phoenix_loc mod MAP_WIDTH
    dim y as long = ( phoenix_loc - x ) / MAP_WIDTH
    dim frame as long = phoenix_frame
    if frame > 6 then
        frame = 6
    end if
    dim tx as long = frame mod 4
    dim ty as long = ( frame - tx ) / 4
    DrawTexturePro(reveal, Rectangle(tx * 24, ty * 24, 24, 24), Rectangle(x * SCALE_8, y * SCALE_8, SCALE * 24, SCALE * 24), Vector2(0, 0), 0, WHITE)
    
	dim ix as long = entities(0).ix
    dim iy as long = entities(0).iy
    
	dim idx as long = 0
    dim dx as long = 0
    dim dy as long = 0
    dim xx as long = 0
    dim yy as long = 0
    for y as integer = 0 to 15 - 1
        for x as integer = 0 to 15 - 1
            dx = x - 6
            dy = y - 6
            if dx * dx + dy * dy > 36 then
                continue for
            end if
            xx = ix + dx
            yy = iy + dy
            if xx >= 0 AndAlso xx < MAP_WIDTH AndAlso yy >= 0 AndAlso yy < MAP_HEIGHT then
                idx = yy * MAP_WIDTH + xx
                if dx * dx + dy * dy < 9 then
                    known(idx) = true
                end if
                if not seen(idx) then
                    continue for
                end if
                dim mag as single = sqr(dx * dx + dy * dy) / 6
                if mag > 1 then
                    mag = 1
                end if
                mag = 1 - mag
                dim t0 as long = board(idx)
                if 4 = t0 then
                    continue for
                end if
                if 0 < t0 then
                    dim tx as long = t0 mod 8
                    dim ty as long = ( t0 - tx ) / 8
                    dim r as long = 96
                    dim g as long = 96
                    dim b as long = 96
                    if 3 = t0 then
                        r = 64
                        g = 48
                        b = 32
                    elseif 1 = t0 then
                        r = 192
                        g = 127
                        b = 32
                    end if
                    r = util.min(255, 64 + r)
                    g = util.min(255, 32 + g)
                    if xx < 26 AndAlso yy < 19 then
                        r = 0
                    end if
                    if xx > 49 then
                        r = r * 1.20
                        g = g * 1.20
                        b = b * 1.20
                        if yy > 18 then
                            r = 242
							g = 242
							b = 242
                        end if
                    end if
                    dim rr as single = 0.33 + 0.66 * mag
                    r = r * rr
                    g = g * rr
                    b = b * rr
                    DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, xx * SCALE_8 + shake_x, yy * SCALE_8 + shake_y, SCALE_8, SCALE_8, 0, 0, 0, r, g, b, 255)
                end if
            end if
        next
    next
	
    for i as integer = 0 to num_torches - 1
        dim ix as long = torches(i).x
        dim iy as long = torches(i).y
        dim ofs as long = util.to_int(( t_flames * 12 + i )) mod 6
		
        for y as integer = 0 to 7 - 1
            for x as integer = 0 to 7 - 1
                dim dx as long = x - 3
                dim dy as long = y - 3
                dim delta as long = dx * dx + dy * dy
                dim xx as long = ix + dx
                dim yy as long = iy + dy
                if xx > - 1 AndAlso yy > - 1 AndAlso xx < MAP_WIDTH AndAlso yy < MAP_HEIGHT then
                    dim idx as long = yy * MAP_WIDTH + xx
                    if not seen(idx) then
                        continue for
                    end if
                    dim t as long = board(idx)
                    if 0 > t OrElse 4 = t then
                        continue for
                    end if
                    dim tx as long = t mod 8
                    dim ty as long = ( t - tx ) / 8
                    dim ratio as single = 1 - sqr(delta) / 3
                    if ratio > 1 then
                        ratio = 1
                    end if
                    if ratio < 0 then
                        ratio = 0
                    end if
                    dim r as long = 255
                    dim g as long = ( 128 + rnd() * 127 )
                    DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, xx * SCALE_8 + shake_x, yy * SCALE_8 + shake_y, SCALE_8, SCALE_8, 0, 0, 0, r, g, 0, ratio * 255)
                end if
            next
        next
    next
	
    DrawTexturePro(ceiling_tex_tex, Rectangle(0, 0, MAP_WIDTH * 8, - MAP_HEIGHT * 8), Rectangle(shake_x, shake_y, MAP_WIDTH * SCALE_8, MAP_HEIGHT * SCALE_8), Vector2(0, 0), 0, WHITE)
    
	idx = 0
    dx = 0
    dy = 0
    xx = 0
    yy = 0
    for y as integer = 0 to 15 - 1
        for x as integer = 0 to 15 - 1
            dx = x - 6
            dy = y - 6
            if dx * dx + dy * dy > 36 then
                continue for
            end if
            xx = ix + dx
            yy = iy + dy
            if xx >= 0 AndAlso xx < MAP_WIDTH AndAlso yy >= 0 AndAlso yy < MAP_HEIGHT then
                idx = yy * MAP_WIDTH + xx
                if not seen(idx) then
                    continue for
                end if
                dim mag as single = sqr(dx * dx + dy * dy) / 6
                if mag > 1 then
                    mag = 1
                end if
                mag = 1 - mag
                dim t3 as long = board3(idx)
                if 0 < t3 then
                    dim tx as long = t3 mod 8
                    dim ty as long = ( t3 - tx ) / 8
                    dim r as long = 127
                    dim g as long = 64
                    dim b as long = 96
                    if xx < 26 AndAlso yy < 19 then
                        g = 127
                        b = 96
                        r = 64
                        tx = 6 + ( xx + yy ) mod 2
                        ty = ( xx + yy ) mod 2
                    end if
                    if xx > 49 then
                        r = r * 0.30
                    end if
                    dim rr as single = 0.33 + 0.66 * mag
                    r = r * rr
                    g = g * rr
                    b = b * rr
                    DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, xx * SCALE_8 + 4 * SCALE + shake_x, yy * SCALE_8 + 2 * SCALE + shake_y, SCALE_8, SCALE_8, 0, 0, 0, r, g, b, 255)
                end if
            end if
        next
    next
	
    for y as integer = 0 to MAP_HEIGHT - 1
        for x as integer = 0 to MAP_WIDTH - 1
            dim idx as long = y * MAP_WIDTH + x
            if not seen(idx) then
                dim tx as long = 5
                dim ty as long = 1
                dim r as long = 127
                dim g as long = 64
                dim b as long = 96
                if x < 26 AndAlso y < 19 then
                    g = 127
                    b = 96
                    r = 64
                    tx = 6 + ( x + y ) mod 2
                    ty = ( x + y ) mod 2
                end if
                if x > 49 then
                    r = r * 0.40 * 1.50
                    b = b * 1.30 * 1.20
                end if
                if not known(idx) then
                    r = 96
                    g = 96
                    b = 96
                    tx = 3
                    ty = 0
                end if
                DrawTextureProRGBA(icons, tx * 8, ty * 8, 8, 8, x * SCALE_8 + 4 * SCALE + shake_x, y * SCALE_8 + 2 * SCALE + shake_y, SCALE_8, SCALE_8, 0, 0, 0, r / 3, g / 3, b / 3, 255)
            end if
        next
    next
	
    if intro_hold then
        DrawTexturePro(pre_game_tex_tex, Rectangle(0, 0, MAP_WIDTH * 8, - MAP_HEIGHT * 8), Rectangle(shake_x, shake_y, MAP_WIDTH * SCALE_8, MAP_HEIGHT * SCALE_8), Vector2(0, 0), 0, WHITE)
    end if
end sub

sub map_update_visibility()
    dim px as single = entities(0).ix
    dim py as single = entities(0).iy
    dim rx as single = 0.0
    dim ry as single = 0.0
    dim w as single = 0.30
    for i as integer = 0 to 45 - 1
        dim an as single = i * 8 * 3.141593 / 180
        dim dx as single = cos(an)
        dim dy as single = sin(an)
        for jj as integer = 0 to 20 - 1
            dim j as single = 0.50 + 0.35 * jj
            rx = px + dx * j
            ry = py + dy * j
            dim x0 as long = rx - w
            dim y0 as long = ry - w
            dim x1 as long = rx - w
            dim y1 as long = ry + w
            dim x2 as long = rx + w
            dim y2 as long = ry + w
            dim x3 as long = rx + w
            dim y3 as long = ry - w
            dim c as long = 0
            if x0 > - 1 AndAlso y0 > - 1 AndAlso x0 < MAP_WIDTH AndAlso y0 < MAP_HEIGHT then
                dim idx as long = y0 * MAP_WIDTH + x0
                if - 1 = board(idx) then
                    c = c + 1
                end if
            end if
            if x1 > - 1 AndAlso y1 > - 1 AndAlso x1 < MAP_WIDTH AndAlso y1 < MAP_HEIGHT then
                dim idx as long = y1 * MAP_WIDTH + x1
                if - 1 = board(idx) then
                    c = c + 1
                end if
            end if
            if x2 > - 1 AndAlso y2 > - 1 AndAlso x2 < MAP_WIDTH AndAlso y2 < MAP_HEIGHT then
                dim idx as long = y2 * MAP_WIDTH + x2
                if - 1 = board(idx) then
                    c = c + 1
                end if
            end if
            if x3 > - 1 AndAlso y3 > - 1 AndAlso x3 < MAP_WIDTH AndAlso y3 < MAP_HEIGHT then
                dim idx as long = y3 * MAP_WIDTH + x3
                if - 1 = board(idx) then
                    c = c + 1
                end if
            end if
            dim ix as long = rx
            dim iy as long = ry
            dim idx as long = iy * MAP_WIDTH + ix
            seen(idx) = true
            if 0 = c then
                exit for
            end if
        next
    next
end sub

sub item_new(x as long, y as long, sprite as long, color__ as RLColor, block_movement as boolean, name__ as string, kind as enumtype)
    dim i as item_s
    i.ix = x
    i.iy = y
    i.sprite = sprite
    i.color__ = color__
    i.block_movement = block_movement
    i.name__ = name__
    i.found = false
    i.kind = kind
    i.skip_update = - 1
	loot(num_loot) = i
	num_loot = num_loot + 1
end sub


sub item_draw_all()
    for i as integer = 0 to num_loot - 1
        if loot(i).found then
            continue for
        end if
        dim sprite as long = loot(i).sprite
        dim tx as long = sprite mod 8
        dim ty as long = ( sprite - tx ) / 8
        dim x as long = loot(i).ix
        dim y as long = loot(i).iy
        if not seen(y * MAP_WIDTH + x) then
            continue for
        end if
        dim dx as single = entities(0).px - x
        dim dy as single = entities(0).py - y
        dim dist as single = sqr(dx * dx + dy * dy)
        if dist < 7.00 then
            if dist < 5.00 then
                DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(x * SCALE_8 + shake_x, y * SCALE_8 + shake_y, SCALE_8, SCALE_8), Vector2(0, 0), 0, loot(i).color__)
            else
                DrawTexturePro(icons, Rectangle(tx * 8, ty * 8, 8, 8), Rectangle(x * SCALE_8 + shake_x, y * SCALE_8 + shake_y, SCALE_8, SCALE_8), Vector2(0, 0), 0, DARKDARKGRAY)
            end if
        end if
        if x = entities(0).ix AndAlso y = entities(0).iy then
            dim found_text as string = "Found " + loot(i).name__ + "!"
            if POTION_HEALTH = loot(i).kind then
                if 9 = inventory(0) then
                    continue for
                end if
                inventory(0) = inventory(0) + 1
                add_note(found_text, RED, 5.00)
            elseif POTION_MANA = loot(i).kind then
                if 9 = inventory(0) then
                    continue for
                end if
                inventory(1) = inventory(1) + 1
                add_note(found_text, GREEN, 5.00)
            elseif TURKEY_LEG = loot(i).kind then
                entities(0).power = entities(0).power + 1
                add_note(found_text, ORANGE, 5.00)
            elseif ARM_SHIELD = loot(i).kind then
                entities(0).defense = entities(0).defense + 1
                found_shield = true
                add_note(found_text, VIOLET, 5.00)
            elseif ARM_MAIL = loot(i).kind then
                entities(0).defense = entities(0).defense + 1
                found_mail = true
                add_note(found_text, VIOLET, 5.00)
            elseif ARM_HELMET = loot(i).kind then
                entities(0).defense = entities(0).defense + 1
                found_helmet = true
                add_note(found_text, VIOLET, 5.00)
            elseif KEY = loot(i).kind then
                found_key = true
                add_note(found_text, GOLD, 5.00)
            end if
            if ROD = loot(i).kind then
                found_rod = true
                add_note(found_text, GREEN, 5.00)
                fbs_Play_Sound(snd_cast)
            elseif HEART = loot(i).kind then
                note.txt = "LEVEL UP!"
                note.color__ = PURPLE
                note.timer = 5.00
                entities(0).level = entities(0).level + 1
                entities(0).max_health = entities(0).max_health * ( 1.30 + 0.30 * rnd() )
                entities(0).max_mana = entities(0).max_mana + 1
                entities(0).health = entities(0).max_health
                entities(0).mana = entities(0).max_mana
                fbs_Play_Sound(snd_levelup)
            else
                fbs_Play_Sound(snd_pickup)
            end if
            loot(i).found = true
        end if
    next
end sub


sub get_player_input()
    dim move_dir as enumtype = INVALID
    
	if IsKeyDown(KEY_ESCAPE) then
        quit_game = true
    end if
	
    if 0 >= entities(0).health then
        add_note("YOU DIED!", RED, 5.00)
        entities(0).block_movement = false
        entities(0).sprite = 47
        return 
    end if
	
    dim idx as long = entities(0).iy * MAP_WIDTH + entities(0).ix
    key_delay = key_delay - 1
    if 0 > key_delay AndAlso intro_hold then
        if IsKeyPressed(KEY_SPACE) then
            key_delay = 5
            if INTRO = menu then
                menu = CONTROLS
            elseif CONTROLS = menu then
                menu = GAME
                intro_hold = false
                fbs_Set_SoundMuted(snd_melody, true)
            end if
            fbs_Play_Sound(snd_hurt)
        end if
        return 
    end if
	
    if 0 > key_delay AndAlso game_win AndAlso WIN = menu then
        if IsKeyPressed(KEY_SPACE) then
            quit_game = true
        end if
        return 
    end if
	
    if not game_win AndAlso not screen_shake then
        if IsKeyDown(KEY_UP) then
            move_dir = MOVE_UP
        end if
        if IsKeyDown(KEY_DOWN) then
            move_dir = MOVE_DOWN
        end if
        if IsKeyDown(KEY_LEFT) then
            move_dir = MOVE_LEFT
        end if
        if IsKeyDown(KEY_RIGHT) then
            move_dir = MOVE_RIGHT
        end if
        if cbool(0 > key_delay) AndAlso found_rod AndAlso cbool(IsKeyDown(KEY_C)) AndAlso cbool(0 < entities(0).mana) AndAlso cbool(0 > entities(0).cooldown) then
            dim px as single = entities(0).px
            dim py as single = entities(0).py
            dim vx as single = 0.0
            dim vy as single = 0.0
            dim speed as single = 8
            if MOVE_UP = last_move then
                vy = - 1
            elseif MOVE_DOWN = last_move then
                vy = 1
            elseif MOVE_LEFT = last_move then
                vx = - 1
            elseif MOVE_RIGHT = last_move then
                vx = 1
            end if
            vx = vx * speed
            vy = vy * speed
            key_delay = 5
            entities(0).cooldown = 1.00
            magic_ball.px = px
            magic_ball.py = py
            magic_ball.vx = vx
            magic_ball.vy = vy
            magic_ball.active = true
            entities(0).mana = entities(0).mana - 1
            fbs_Play_Sound(snd_cast)
        end if
        if cbool(0 > key_delay) AndAlso cbool(0 < inventory(0)) AndAlso cbool(entities(0).health < entities(0).max_health) AndAlso IsKeyDown(KEY_H) then
            inventory(0) = inventory(0) - 1
            entities(0).health = entities(0).max_health
            fbs_Play_Sound(snd_potion)
        end if
        if cbool(0 > key_delay) AndAlso cbool(0 < inventory(1)) AndAlso cbool(entities(0).mana < entities(0).max_mana) AndAlso IsKeyDown(KEY_M) then
            inventory(1) = inventory(1) - 1
            entities(0).mana = entities(0).max_mana
            fbs_Play_Sound(snd_potion)
        end if
    end if
	
    if 0 > key_delay then
        if INVALID <> move_dir then
            last_move = move_dir
            entity_move(0, move_dir)
            key_delay = 4
            map_update_visibility()
        end if
    end if
	
    dim kx as long = entities(0).kx
    dim ky as long = entities(0).ky
    if kx < 0 then
        entities(0).kx = kx + 1
    end if
    if kx > 0 then
        entities(0).kx = kx - 1
    end if
    if ky < 0 then
        entities(0).ky = ky + 1
    end if
    if ky > 0 then
        entities(0).ky = ky - 1
    end if
end sub

