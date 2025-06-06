''-----------------------------------------------------------------------------
'' Asylum - A text adventure by Syn9
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

end namespace
''-----------------------------------------------------------------------------


''-----------------------------------------------------------------------------
'' Global Enumeration
''-----------------------------------------------------------------------------

enum enumtype
    ENUM_QUIT_GAME
    ENUM_ROOM_CLOSET
    ENUM_ROOM_DIED_DRUGS
    ENUM_ROOM_DIED_FALL
    ENUM_ROOM_DIED_HOBO
    ENUM_ROOM_ENTRANCE
    ENUM_ROOM_FOYER
    ENUM_ROOM_HALLWAY
    ENUM_ROOM_HOBO
    ENUM_ROOM_OFFICE
    ENUM_ROOM_ROOF
    ENUM_ROOM_STAIRWELL
    ENUM_ROOM_WIN
end enum


''-----------------------------------------------------------------------------
'' Function Declarations
''-----------------------------------------------------------------------------

declare function room_name() as string
declare function perform_action(opt as string) as boolean
declare function room_options() as string
declare function room_description() as string

''-----------------------------------------------------------------------------
'' Entry Point
''-----------------------------------------------------------------------------

print "Asylum"
print "------------------------"
print "A text adventure by Syn9"

dim shared as enumtype room = ENUM_ROOM_ENTRANCE
dim shared as boolean flags(10)
for i as integer = 0 to 10 - 1
    flags(i) = false
next

while true
    print 
    print room_name() + ":"
    print "------------------------"
    print room_description()
	
    if room = ENUM_ROOM_DIED_DRUGS OrElse room = ENUM_ROOM_DIED_HOBO OrElse room = ENUM_ROOM_DIED_FALL OrElse room = ENUM_ROOM_WIN then
        exit while
    end if
	
    print 
    print "What do you do?"
    print 
    print "Options:"
    print room_options()
    print " [x] exit game"
	
    while true
        dim as string s = util.console_input()
        if perform_action(s) then
            sleep(1000)
			exit while
        end if
        print "Try Again:"
    wend
    
    if room = ENUM_QUIT_GAME then
        exit while
    end if
wend

''-----------------------------------------------------------------------------
'' Function Definitions
''-----------------------------------------------------------------------------

function room_name() as string
    select case room
    case ENUM_ROOM_ENTRANCE
        return "Dirt Path"
    case ENUM_ROOM_FOYER
        return "Foyer"
    case ENUM_ROOM_HALLWAY
        return "Hallway"
    case ENUM_ROOM_HOBO
        return "Dark Corner"
    case ENUM_ROOM_OFFICE
        return "Office"
    case ENUM_ROOM_CLOSET
        return "Closet"
    case ENUM_ROOM_STAIRWELL
        return "Stairwell"
    case ENUM_ROOM_ROOF
        return "Roof"
    case ENUM_ROOM_WIN
        return "YOU ESCAPE!"
    case ENUM_ROOM_DIED_HOBO
        return "Game Over"
    case ENUM_ROOM_DIED_DRUGS
        return "Game Over"
    case ENUM_ROOM_DIED_FALL
        return "Game Over"
    end select
    return "Invalid Room Enum"
end function

function perform_action(opt as string) as boolean
    select case room
    case ENUM_ROOM_ENTRANCE
        if "g" = opt then
            print chr(10) + "You climb your way through a small opening in the broken glass door."
            room = ENUM_ROOM_FOYER
            return true
        end if
    case ENUM_ROOM_FOYER
        if "c" = opt then
            print chr(10) + "You slowly make your way down the dark hallway."
            room = ENUM_ROOM_HALLWAY
            return true
        end if
    case ENUM_ROOM_HALLWAY
        if "b" = opt then
            print chr(10) + "You jimmy open the old wooden door."
            room = ENUM_ROOM_OFFICE
            return true
        elseif "o" = opt then
            print chr(10) + "The door creeks loudly as you open it."
            room = ENUM_ROOM_CLOSET
            return true
        elseif "i" = opt then
            print chr(10) + "You slowly walk toward a faint groaning sound in the dark corner."
            room = ENUM_ROOM_HOBO
            return true
        elseif "s" = opt then
            if not flags(4) then
                print chr(10) + "You try to open the stairwell door, but it won't budge!"
                return true
            else
                print chr(10) + "The door is locked. You use the keys and with a some force it cracks open just enough to slide through."
                room = ENUM_ROOM_STAIRWELL
                return true
            end if
        elseif "g" = opt then
            print "Maybe it's better to head back to the Foyer."
            room = ENUM_ROOM_FOYER
            return true
        end if
    case ENUM_ROOM_OFFICE
        if not flags(0) then
            if "l" = opt then
                print chr(10) + "The door is stuck, but you pull with all your weight to bust it open." + chr(10) + "It's full of office supplies and, strangely, a metal bat on the bottom shelf."
                flags(0) = true
                return true
            end if
        elseif flags(0) AndAlso not flags(1) then
            if "t" = opt then
                print chr(10) + "You grab the old dirty bat."
                flags(1) = true
                return true
            end if
        end if
        if "g" = opt then
            print chr(10) + "You head back to the Hallway."
            room = ENUM_ROOM_HALLWAY
            return true
        end if
    case ENUM_ROOM_CLOSET
        if "l" = opt then
            if not flags(5) then
                print chr(10) + "The shelves are full of cleaning chemicals, however you do find a long length of rope."
                flags(2) = true
            else
                print chr(10) + "There is nothing else here that you can use."
            end if
            return true
        elseif "t" = opt then
            if flags(2) AndAlso not flags(5) then
                print chr(10) + "You grab the rope."
                flags(5) = true
                return true
            end if
        elseif "p" = opt then
            print chr(10) + "The cat lets out a shreek and bites you! That's gonna leave a mark."
            return true
        elseif "g" = opt then
            print chr(10) + "You head back to the Hallway."
            room = ENUM_ROOM_HALLWAY
            return true
        end if
    case ENUM_ROOM_HOBO
        if not flags(3) then
            if "a" = opt then
                if flags(1) then
                    print chr(10) + "In sheer terror, you swing the bat wildly, knocking the hobo to the ground."
                    flags(3) = true
                    return true
                end if
            elseif "r" = opt then
                print chr(10) + "You turn and attempt to run away!"
                room = ENUM_ROOM_DIED_HOBO
                return true
            end if
        else
            if not flags(4) then
                if "t" = opt then
                    print chr(10) + "You find some keys."
                    flags(4) = true
                    return true
                end if
            end if
            if "g" = opt then
                print chr(10) + "You head back to the Hallway"
                room = ENUM_ROOM_HALLWAY
                return true
            end if
        end if
    case ENUM_ROOM_STAIRWELL
        if "u" = opt then
            print chr(10) + "You start climbing the stairs, let's find the roof!"
            room = ENUM_ROOM_ROOF
            return true
        elseif "r" = opt then
            print chr(10) + "You find some old porno mags and what looks like it might be drugs."
            flags(6) = true
            return true
        elseif flags(6) AndAlso "t" = opt then
            print chr(10) + "You grab the drugs and pop them in your mouth. What the hell, you only live once..."
            room = ENUM_ROOM_DIED_DRUGS
            return true
        elseif "g" = opt then
            print chr(10) + "Maybe it's better to head back"
            room = ENUM_ROOM_HALLWAY
            return true
        end if
    case ENUM_ROOM_ROOF
        if "c" = opt then
            if not flags(5) then
                print chr(10) + "You lean over the edge and try to make your way down."
                room = ENUM_ROOM_DIED_FALL
                return true
            else
                print chr(10) + "You lean over the edge and try to make your way down. Thankfully, you have this rope!"
                room = ENUM_ROOM_WIN
                return true
            end if
        elseif "g" = opt then
            print chr(10) + "Maybe you'd rather look around some more and head back"
            room = ENUM_ROOM_STAIRWELL
            return true
        end if
    end select

    if "x" = opt then
        print chr(10) + "You decide this adventure is enough for today."
        room = ENUM_QUIT_GAME
        return true
    end if
	
    return false
end function

function room_options() as string
    select case room
    case ENUM_ROOM_ENTRANCE
        return " [g] go inside"
    case ENUM_ROOM_FOYER
        return " [c] check out hallway"
    case ENUM_ROOM_HALLWAY
        return " [i] investigate sound" + chr(10) + " [b] break into office" + chr(10) + " [o] open unmarked door" + chr(10) + " [s] stairwell door" + chr(10) + " [g] go back"
    case ENUM_ROOM_OFFICE
        dim as string ret
        if not flags(0) then
            ret = " [l] look in cabinet" + chr(10)
        elseif flags(0) AndAlso not flags(1) then
            ret = " [t] take bat" + chr(10)
        end if
        ret = ret + " [g] go back"
        return ret
    case ENUM_ROOM_CLOSET
        dim as string ret = " [l] look through shelves" + chr(10) 
        if flags(2) AndAlso not flags(5) then
            ret = ret + " [t] take rope" + chr(10) 
        end if
        ret = ret + " [p] pet the cat" + chr(10) + " [g] go back"
        return ret
    case ENUM_ROOM_HOBO
        dim as string ret
        if not flags(3) then
            if flags(1) then
                ret = " [a] attack with bat" + chr(10) 
            end if
            ret = ret + " [r] run away"
        else
            if not flags(4) then
                ret = " [t] take the shiny object" + chr(10) 
            end if
            ret = ret + " [g] go back"
        end if
        return ret
    case ENUM_ROOM_STAIRWELL
        dim as string ret = " [u] up to the roof" + chr(10) + " [r] rummage through trash" + chr(10) 
        if flags(6) then
            ret = ret + " [t] take drugs" + chr(10) 
        end if
        ret = ret + " [g] go back"
        return ret
    case ENUM_ROOM_ROOF
        return " [c] climb down to friends" + chr(10) + " [g] go back"
    end select
	
    return "Invalid Room Enum"
end function

function room_description() as string
    select case room
    case ENUM_ROOM_ENTRANCE
        return "Wandering the night with your friends along an old dirt path, you come upon an abandoned building." + chr(10) + "One of your friends says, " + chr(34) + "I bet you won't go inside and check it out..." + chr(34) 
    case ENUM_ROOM_FOYER
        return "It's dark, through the moonlight you can see a hallway at the end of the room."
    case ENUM_ROOM_HALLWAY
        return "Grungy, old broken tiles, moon light shines in, you see a door that says office and another that is unmarked." + chr(10) + "You hear a faint groaning sound in the corner by the stairwell door."
    case ENUM_ROOM_OFFICE
        return "You see papers everywhere, a desk, waiting bench, and an old rusty storage cabinet."
    case ENUM_ROOM_CLOSET
        return "You see floor to ceiling shelves. The room smells of death, a cat howls at you from the top of the shelves."
    case ENUM_ROOM_STAIRWELL
        return "Blegh, you find trash everywhere with the smell of vomit and shit."
    case ENUM_ROOM_ROOF
        return "Thankful to see the moonlight and smell the fresh air. See your friends below."
    case ENUM_ROOM_WIN
        return "Happy to see your friends, you swear you'll never take a bet again."
    case ENUM_ROOM_DIED_HOBO
        return "The hobo lunges at you with a knife, burying it into your neck. As you lay on the ground, bleeding to death," + chr(10) + "you wonder how this could have happened to someone like you."
    case ENUM_ROOM_DIED_DRUGS
        return "Colors and sounds take hold of your body, the drugs take hold of your mind," + chr(10) + "your body convulses as you accidentally overdose in incredible pain and die."
    case ENUM_ROOM_DIED_FALL
        return "You attempt to jump down, you didn't realize you were so high up, trying to grab hold of something as you fall," + chr(10) + "you smash your head on the ground and die."
    case ENUM_ROOM_HOBO
        if not flags(3) then
            return "Suddenly a deranged hobo jumps to his feet, thrusting a knife at you in an incoherent rage."
        else
            dim as string ret = "The hobo lies on the ground unconscious."
            if not flags(4) then
                ret = ret + " You see something glinting on the floor."
            end if
            return ret
        end if
    end select
	
    return "Invalid Room Enum"
end function

