''-----------------------------------------------------------------------------
'' Guess the number game by Syn9
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
function to_int(value as string) as integer
	return valint(value)
end function

end namespace
''-----------------------------------------------------------------------------


randomize

''-----------------------------------------------------------------------------
'' Entry Point
''-----------------------------------------------------------------------------

dim as long tries = 6
dim as long secret = util.rand_range(1, 19 + 1)

while tries > 0
    print "Enter a guess between 0 and 20, " + str(tries) + " tries remaining"
    
    dim as long guess = util.to_int(util.console_input())
    if guess < secret then
        print "Too Small"
    elseif guess > secret then
        print "Too Large"
    else
        print "You Win!"
        tries = 0
    end if
    
    tries = tries - 1
    if 0 = tries then
        print "Game Over"
    end if
wend
