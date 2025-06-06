''-----------------------------------------------------------------------------
'' Tic-Tac-Toe game by Syn9
'' Tested with FreeBASIC-1.10.1-winlibs-gcc-9.3.0
''-----------------------------------------------------------------------------

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
declare function to_int overload (value as string) as integer

function to_int(value as string) as integer
	return valint(value)
end function


end namespace
''-----------------------------------------------------------------------------


randomize

''-----------------------------------------------------------------------------
'' Global Enumeration
''-----------------------------------------------------------------------------

enum enumtype
    ENUM_COMPUTER
    ENUM_EMPTY
    ENUM_PLAYER
end enum


''-----------------------------------------------------------------------------
'' Function Declarations
''-----------------------------------------------------------------------------

declare function check_win(who as enumtype) as boolean
declare sub draw_board()
declare sub draw_cell(idx as long)
declare sub get_player_input()
declare sub get_computer_input()

''-----------------------------------------------------------------------------
'' Entry Point
''-----------------------------------------------------------------------------

dim shared as long SZ = 9
dim shared as enumtype board(9)
for i as integer = 0 to 9 - 1
    board(i) = ENUM_EMPTY
next

print "Let's play Tic-Tac-Toe!"
print "-----------------------------------------------------"

while true
    draw_board()
    get_player_input()
    if check_win(ENUM_PLAYER) then
        exit while
    end if
    get_computer_input()
    if check_win(ENUM_COMPUTER) then
        exit while
    end if
wend
draw_board()

''-----------------------------------------------------------------------------
'' Function Definitions
''-----------------------------------------------------------------------------

function check_win(who as enumtype) as boolean
    dim as boolean ret = false
    dim as long idx = 0
	
    for row as integer = 0 to 3 - 1
        idx = row * 3
        if who = board(idx) AndAlso who = board(idx + 1) AndAlso who = board(idx + 2) then
            ret = true
        end if
    next
	
    for col as integer = 0 to 3 - 1
        idx = col
        if who = board(idx) AndAlso who = board(idx + 3) AndAlso who = board(idx + 6) then
            ret = true
        end if
    next
	
    if who = board(4) then
        if who = board(0) AndAlso who = board(8) then
            ret = true
        elseif who = board(2) AndAlso who = board(6) then
            ret = true
        end if
    end if
	
    if ret then
        if ENUM_PLAYER = who then
            print "Player Wins!"
        else
            print "Computer Wins!"
        end if
    else
        for i as integer = 0 to SZ - 1
            if ENUM_EMPTY = board(i) then
                exit for
            end if
            if 8 = i then
                ret = true
                print "DRAW!"
            end if
        next
    end if
    return ret
end function

sub draw_board()
    print "/-----------\ "
    print "| ";
    draw_cell(0)
    print " | ";
    draw_cell(1)
    print " | ";
    draw_cell(2)
    print " | "
    print "|---|---|---|"
    print "| ";
    draw_cell(3)
    print " | ";
    draw_cell(4)
    print " | ";
    draw_cell(5)
    print " | "
    print "|---|---|---|"
    print "| ";
    draw_cell(6)
    print " | ";
    draw_cell(7)
    print " | ";
    draw_cell(8)
    print " | "
    print "\-----------/"
end sub

sub draw_cell(idx as long)
    if ENUM_EMPTY = board(idx) then
        print str(( idx + 1 ));
    elseif ENUM_PLAYER = board(idx) then
        print "X";
    elseif ENUM_COMPUTER = board(idx) then
        print "O";
    end if
end sub

sub get_player_input()
    while true
        print "Enter the # for your choice (X)"
        dim as long temp = util.to_int(util.console_input())
        if temp > 0 AndAlso temp < 10 then
            if ENUM_EMPTY = board(temp - 1) then
                board(temp - 1) = ENUM_PLAYER
                exit while
            end if
        end if
        print "Invalid choice."
    wend
end sub

sub get_computer_input()
    while true
        dim as long choice = util.rand_range(0, SZ)
        if ENUM_EMPTY = board(choice) then
            board(choice) = ENUM_COMPUTER
            exit while
        end if
    wend
end sub

