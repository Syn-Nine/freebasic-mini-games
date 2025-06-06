''-----------------------------------------------------------------------------
'' Catfish Bouncer - Raylib minigame by Syn9
'' Tested with FreeBASIC-1.10.1-winlibs-gcc-9.3.0
''-----------------------------------------------------------------------------

#include "raylib.bi"  ' v5.0 bindings from: https://github.com/WIITD/raylib-freebasic/tree/main

randomize

''-----------------------------------------------------------------------------
'' Structure Definitions
''-----------------------------------------------------------------------------

' game data
type game_data_s
    ' clock
    t_prev as double
    t_base as double
    t_delta as double
    
    ' ball
    ball_x as single
    ball_y as single
    ball_dx as single
    ball_dy as single
    ball_speed as single
    
    ' mouse
    mx as long
    my as long
    prev_mx as long
    prev_my as long
    dmx as single
    dmy as single
    
    ' state
    YUM_MAX as single
    yumY as single
    fish as long
    newBall as boolean
end type


''-----------------------------------------------------------------------------
'' Function Declarations
''-----------------------------------------------------------------------------

declare sub draw_game_board()
declare sub update_game_state()
declare sub main()

''-----------------------------------------------------------------------------
'' Entry Point
''-----------------------------------------------------------------------------

' window res
const XRES = 800
const YRES = 600
const XRES_HALF = XRES / 2
const YRES_HALF = YRES / 2

' entity colors
#define BG_COLOR RAYWHITE
#define CAT_COLOR ORANGE
#define TXT_COLOR LIGHTGRAY
#define YUM_COLOR SKYBLUE
#define BALL_COLOR SKYBLUE
#define PADDLE_COLOR GRAY

' game constants
const START_SPEED as single = 300
const INC_SPEED as single = 20
const BALL_RADIUS as long = 20
const FEED_RADIUS as single = 50
const PADDLE_W as long = 50
const PADDLE_H as long = 10

' global game data structure
dim shared game_data as game_data_s


main()

sub main()

    ' setup
    InitWindow(XRES, YRES, "Catfish Bouncer")
    SetTargetFPS(60)

    game_data.YUM_MAX = 100
    game_data.t_prev = timer
    game_data.t_base = timer

    ' game loop
    while true
        update_game_state()
        draw_game_board()
        
        if WindowShouldClose() then
            exit while
        end if
    wend

    CloseWindow()
end sub


''-----------------------------------------------------------------------------
'' Function Definitions
''-----------------------------------------------------------------------------

sub draw_game_board()
    BeginDrawing()
    ClearBackground(BG_COLOR)
        ' testing text output
        DrawText("Catfish Bouncer!", 20, 20, 20, TXT_COLOR)
        DrawText("fps: " + str(int( 1 / game_data.t_delta )), 20, 40, 20, TXT_COLOR)
        DrawText("clock: " + str(( timer - game_data.t_base )), 20, 60, 20, TXT_COLOR)
        DrawCircle(XRES_HALF, YRES_HALF, 30, CAT_COLOR)
        
        ' draw cat
        dim w as single = 15
        dim h as single = 50
        DrawTriangle(vector2(XRES_HALF, YRES_HALF), vector2(XRES_HALF - w, YRES_HALF - h), vector2(XRES_HALF - w - w, YRES_HALF), CAT_COLOR)
        DrawTriangle(vector2(XRES_HALF, YRES_HALF), vector2(XRES_HALF + w + w, YRES_HALF), vector2(XRES_HALF + w, YRES_HALF - h), CAT_COLOR)
        
        ' draw fish
        for i as integer = 0 to game_data.fish - 1
            DrawCircle(XRES_HALF + ( i - ( game_data.fish - 1.00 ) / 2 ) * 12, YRES_HALF + 50, 5, YUM_COLOR)
        next
        
        ' draw ball
        if not game_data.newBall then
            DrawCircle(game_data.ball_x, game_data.ball_y, BALL_RADIUS, BALL_COLOR)
        end if
        
        ' draw yum text
        game_data.yumY = game_data.yumY - game_data.t_delta
        if game_data.yumY > 0 then
            DrawText("YUM!", XRES_HALF - 50, YRES_HALF - 50 - game_data.YUM_MAX * ( 1 - game_data.yumY ), 40, YUM_COLOR)
        end if
        
        ' draw paddles
        DrawRectangle(game_data.mx - PADDLE_W, 0, PADDLE_W * 2, PADDLE_H, PADDLE_COLOR)
        DrawRectangle(game_data.mx - PADDLE_W, YRES - PADDLE_H, PADDLE_W * 2, PADDLE_H, PADDLE_COLOR)
        DrawRectangle(0, game_data.my - PADDLE_W, PADDLE_H, PADDLE_W * 2, PADDLE_COLOR)
        DrawRectangle(XRES - PADDLE_H, game_data.my - PADDLE_W, PADDLE_H, PADDLE_W * 2, PADDLE_COLOR)
    EndDrawing()
end sub

' game logic
sub update_game_state()
    ' mouse delta for moving paddles and applying friction
    game_data.prev_mx = game_data.mx
    game_data.prev_my = game_data.my
    game_data.mx = GetMouseX()
    game_data.my = GetMouseY()
    game_data.dmx = game_data.dmx * 0.80 + ( game_data.mx - game_data.prev_mx ) * ( 1 - 0.80 )
    game_data.dmy = game_data.dmy * 0.80 + ( game_data.my - game_data.prev_my ) * ( 1 - 0.80 )
    
    ' time delta for animation
    dim t_clock as double = timer
    game_data.t_delta = ( t_clock - game_data.t_prev )
    game_data.t_prev = t_clock
    
    ' is ball outside of game board?
    if ( game_data.yumY < 0 AndAlso game_data.newBall ) OrElse PADDLE_H > game_data.ball_x OrElse XRES - PADDLE_H < game_data.ball_x OrElse PADDLE_H > game_data.ball_y OrElse YRES - PADDLE_H < game_data.ball_y then
        
        ' intialize position
        game_data.ball_x = 100 + rnd() * ( XRES_HALF - 200 )
        if rnd() < 0.50 then
            game_data.ball_x = XRES_HALF + game_data.ball_x
        end if
        game_data.ball_y = 100 + rnd() * ( YRES - 200 )
        
        ' initialize velocity
        game_data.ball_speed = START_SPEED
        dim angle as single = rnd() * 3.141593 * 2.00
        game_data.ball_dx = game_data.ball_speed * cos(angle)
        game_data.ball_dy = game_data.ball_speed * sin(angle)
        game_data.newBall = false
    end if
    
    ' update ball state
    if not game_data.newBall then
        ' integrate ball location
        game_data.ball_x = game_data.ball_x + game_data.ball_dx * game_data.t_delta
        game_data.ball_y = game_data.ball_y + game_data.ball_dy * game_data.t_delta
        
        ' top/bottom bounce
        if game_data.ball_x > game_data.mx - PADDLE_W AndAlso game_data.ball_x < game_data.mx + PADDLE_W then
            if game_data.ball_y - BALL_RADIUS < PADDLE_H OrElse game_data.ball_y + BALL_RADIUS > YRES - PADDLE_H then
                game_data.ball_dy = - game_data.ball_dy
                game_data.ball_y = PADDLE_H + BALL_RADIUS
                if sgn(game_data.ball_dy) < 0 then
                    game_data.ball_y = YRES - PADDLE_H - BALL_RADIUS
                end if
                game_data.ball_dx = game_data.ball_dx + game_data.dmx * game_data.ball_speed / 20
                game_data.ball_speed = game_data.ball_speed + INC_SPEED
            end if
        end if
        
        ' left/right bounce
        if game_data.ball_y > game_data.my - PADDLE_W AndAlso game_data.ball_y < game_data.my + PADDLE_W then
            if game_data.ball_x - BALL_RADIUS < PADDLE_H OrElse game_data.ball_x + BALL_RADIUS > XRES - PADDLE_H then
                game_data.ball_dx = - game_data.ball_dx
                game_data.ball_x = PADDLE_H + BALL_RADIUS
                if sgn(game_data.ball_dx) < 0 then
                    game_data.ball_x = XRES - PADDLE_H - BALL_RADIUS
                end if
                game_data.ball_dy = game_data.ball_dy + game_data.dmy * game_data.ball_speed / 20
                game_data.ball_speed = game_data.ball_speed + INC_SPEED
            end if
        end if
        
        ' check for feed
        if game_data.yumY < 0 AndAlso game_data.ball_x > XRES_HALF - FEED_RADIUS AndAlso game_data.ball_x < XRES_HALF + FEED_RADIUS AndAlso game_data.ball_y > YRES_HALF - FEED_RADIUS AndAlso game_data.ball_y < YRES_HALF + FEED_RADIUS then
            game_data.yumY = 1.00
            game_data.newBall = true
            game_data.fish = game_data.fish + 1
        end if
    end if
end sub

