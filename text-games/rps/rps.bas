''-----------------------------------------------------------------------------
'' Rock, Paper, Scissors game by Syn9
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

end namespace
''-----------------------------------------------------------------------------


randomize

''-----------------------------------------------------------------------------
'' Entry Point
''-----------------------------------------------------------------------------

dim as long p_score = 0
dim as long c_score = 0
dim as long tries = 3
dim as long max = tries
dim as long ROCK = 0
dim as long PAPER = 1
dim as long SCISSORS = 2
dim as long INVALID = 3
dim as long TIE = 0
dim as long PLAYER_WIN = 1
dim as long COMPUTER_WIN = 2

print "Let's play Rock-Paper-Scissors!"

while tries > 0
    print "Best out of " + str(max) + ", " + str(tries) + " tries remaining. ";
    print "What is your guess? [r]ock, [p]aper, or [s]cissors?"
    
    dim as long guess = INVALID
    while true
        dim as string s = util.console_input()
        if "r" = s then
            guess = ROCK
        elseif "p" = s then
            guess = PAPER
        elseif "s" = s then
            guess = SCISSORS
        else
            print "input invalid."
        end if
        if INVALID <> guess then
            exit while
        end if
    wend
	
    dim as string choice
    if ROCK = guess then
        choice = "Rock"
    elseif PAPER = guess then
        choice = "Paper"
    elseif SCISSORS = guess then
        choice = "Scissors"
    end if
    print "Player: " + choice
    
    dim as long comp = util.rand_range(0, 3)
    if ROCK = comp then
        choice = "Rock"
    elseif PAPER = comp then
        choice = "Paper"
    elseif SCISSORS = comp then
        choice = "Scissors"
    end if
    print "Computer: " + choice
    
    dim as long result = TIE
    if ( ROCK = comp AndAlso SCISSORS = guess ) OrElse ( SCISSORS = comp AndAlso PAPER = guess ) OrElse ( PAPER = comp AndAlso ROCK = guess ) then
        result = COMPUTER_WIN
    elseif ( ROCK = guess AndAlso SCISSORS = comp ) OrElse ( SCISSORS = guess AndAlso PAPER = comp ) OrElse ( PAPER = guess AndAlso ROCK = comp ) then
        result = PLAYER_WIN
    end if
    
    tries = tries - 1
    if TIE = result then
        print "Tie!"
        tries = tries + 1
    elseif COMPUTER_WIN = result then
        print "Computer Score!"
        c_score = c_score + 1
    elseif PLAYER_WIN = result then
        print "Player Score!"
        p_score = p_score + 1
    end if
    print "Score: Player: " + str(p_score) + ", Computer: " + str(c_score)
wend

if p_score = c_score then
    print "GAME TIED!"
elseif p_score > c_score then
    print "PLAYER WINS GAME!"
else
    print "COMPUTER WINS GAME!"
end if
