#!/bin/bash


# Deine all spinnaker icons / colours
function stylesheet()
{
    TEXT_STONE_600='\e[38;2;87;83;78m'
    TEXT_AMBER_300='\e[38;2;252;211;77m'
    TEXT_YELLOW_300='\e[38;2;253;224;71m'
    TEXT_GRAY_500='\e[38;2;107;114;128m'
    RESET_TEXT='\e[39m'
    ICON_ROCKET=🚀
    ICON_HOUSE=🏠
    ICON_FADE_200=░
    ICON_CMD=⌘
    ICON_ARROW_N=↑
    ICON_ARROW_S=↓
    ICON_CIRCLE=●
    BORDER_SKY_400='\e[38;2;56;189;248m'
    BORDER_EMERALD_400='\e[38;2;52;211;153m'
    BORDER_PINK_400='\e[38;2;244;114;182m'
}

# Run options with input values.
MENU='
    {
    "select": {
    "clear": false,
    "clear_before_command": false,
    "icon": "ICON_FADE_200",
    "hide_message": true,
    "display_help": true,
    "reset_loop": false,
    "options": [
        {
            "title": "${ICON_ROCKET} Export Volume Contents to local tar.gz",
            "title_style": "",
            "description": "Export",
            "description_style": "TEXT_GRAY_500",
            "command": "vump ",
            "bullet": "BORDER_SKY_400"
        },
        {
            "title": "${ICON_HOUSE} Import tar.gz into a Volume",
            "title_style": "Import",
            "description": "uname -a",
            "description_style": "TEXT_GRAY_500",
            "command": "uname -a",
            "bullet": "BORDER_EMERALD_400"
        },
        {
            "title": "${ICON_CMD} Save contents of Volume to a backup Image",
            "title_style": "",
            "description": "Save",
            "description_style": "TEXT_GRAY_500",
            "command": "uname",
            "bullet": "BORDER_PINK_400"
        },
        {
            "title": "${ICON_CMD} Load contents of backup Image to a Volume",
            "title_style": "",
            "description": "Load",
            "description_style": "TEXT_GRAY_500",
            "command": "ls",
            "bullet": "BORDER_PINK_400"
        }
    ]
    }
}'




# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║                           START - JSON PASING CODE                           ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝


# ┌─────────────────────────────────────┐
# │                                     │
# │       JSON Get particular key       │
# │                                     │
# └─────────────────────────────────────┘
#source $SPINNAKER_TOOLS_FOLDER/utils/json_get_key.sh

#https://github.com/dominictarr/JSON.sh/issues/37
#function to get value of specified key
#returns empty string if not found
#warning - does not validate key format (supplied as parameter) in any way, simply returns empty string for malformed queries too
#usage: VAR=$(getkey foo.bar) #get value of "bar" contained within "foo"
#       VAR=$(getkey foo[4].bar) #get value of "bar" contained in the array "foo" on position 4
#       VAR=$(getkey [4].foo) #get value of "foo" contained in the root unnamed array on position 4
function getkey {
    #reformat key string (parameter) to what JSON.sh uses
    KEYSTRING=$(sed -e 's/\[/\"\,/g' -e 's/^\"\,/\[/g' -e 's/\]\./\,\"/g' -e 's/\./\"\,\"/g' -e '/^\[/! s/^/\[\"/g' -e '/\]$/! s/$/\"\]/g' <<< "$@")
    #extract the key value
    FOUT=$(grep -F "$KEYSTRING" <<< "$JSON_PARSED")
    FOUT="${FOUT#*$'\t'}"
    FOUT="${FOUT#*\"}"
    FOUT="${FOUT%\"*}"
    echo "$FOUT"
}


# ┌─────────────────────────────────────┐
# │                                     │
# │      JSON Get length of array       │
# │                                     │
# └─────────────────────────────────────┘
#source $SPINNAKER_TOOLS_FOLDER/utils/json_get_array_length.sh

#function returning length of array
#returns zero if key in parameter does not exist or is not an array
#usage: VAR=$(getarrlen foo.bar) #get length of array "bar" contained within "foo"
#       VAR=$(getarrlen) #get length of the root unnamed array
#       VAR=$(getarrlen [2].foo.bar) #get length of array "bar" contained within "foo", which is stored in the root unnamed array on position 2
function getarrlen {
    #reformat key string (parameter) to what JSON.sh uses
    # KEYSTRING=$(sed -e '/^\[/! s/\[/\"\,/g' -e 's/\]\./\,\"/g' -e 's/\./\"\,\"/g' -e '/^$/! {/^\[/! s/^/\[\"/g}' -e '/^$/! s/$/\"\,/g' -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/\,/\\\,/g' -e '/^$/ s/^/\\\[/g' <<< "$@")
    KEYSTRING=$(sed -e '/^\[/! s/\[/\"\,/g' -e 's/\]\./\,\"/g' -e 's/\./\"\,\"/g' -e '#^$#! {/^\[/! s/^/\[\"/g}' -e '/^$/! s/$/\"\,/g' -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/\,/\\\,/g' -e '/^$/ s/^/\\\[/g' <<< "$@")
    #extract the key array length - get last index
    LEN=$(grep -o "${KEYSTRING}[0-9]*" <<< "$JSON_PARSED" | tail -n -1 | grep -o "[0-9]*$")
    #increment to get length, if empty => zero
    if [ -n "$LEN" ]; then
        LEN=$(($LEN+1))
    else
        LEN="0"
    fi
    echo "$LEN"
}


# ┌─────────────────────────────────────┐
# │                                     │
# │            Parse Classes            │
# │                                     │
# └─────────────────────────────────────┘
#source $SPINNAKER_TOOLS_FOLDER/utils/parse_classes_func.sh

# Parses a class list string
# Returns an array of keys and values
# 
# e.g. 
# takes two parameters:
# 1. A prefix name "BOX"
# 2. A single string "TEXT_RED_400 BG_EMERALD_100 BORDER_BLUE_800 PX_4 PT_4 EDGE_FINE EDGE_DUAL_B EDGE_DUAL_L EDGE_DUAL_BL"
# 
# The function then sets the global variables:
# BOX_TEXT_COLOUR=TEXT_RED_400
# BOX_BG_COLOUR=BG_EMERALD_100
# BOX_BORDER_COLOUR=BORDER_BLUE_800
# BOX_PX=PX_4
# BOX_PT=PT_4
# BOX_EDGE=EDGE_FINE
# BOX_EDGE_B=EDGE_DUAL_B
# BOX_EDGE_L=EDGE_DUAL_L
# BOX_EDGE_BL=EDGE_DUAL_BL
#
# These are then used within the original function to override any defaults.
#

function parse_classes()
{
    # Name to prefix all variable names with
    PREFIX=$1


    # String of class names
    CLASSES=$2
    # set inter-field separator (IFS) to a space and loop
    # through each class name and create a CLASS variable
    # The class will be something like "TEXT_GREEN_100"
    export IFS=" "
    for CLASS in $CLASSES; do

        # Split by underscores and assign each part to a variable
        IFS="_" read PARAMETER PRIMARY SECONDARY <<< "$CLASS"

        # ╭──────────────────────────╮
        # │                          │
        # │        🎨 COLOURS        │
        # │                          │
        # ╰──────────────────────────╯
        # create new variable TEXT_COLOUR, BG_COLOUR, BORDER_COLOUR, etc...
        if  [[ $PARAMETER == 'TEXT' ]] || 
            [[ $PARAMETER == 'BG' ]] || 
            [[ $PARAMETER == 'BORDER' ]]; then

            export declare "${PREFIX}_${PARAMETER}_COLOUR"=${!CLASS}
        fi


        # ╭──────────────────────────╮
        # │                          │
        # │        ⬛ PADDING        │
        # │                          │
        # ╰──────────────────────────╯
        if  [[ $PARAMETER == PX* ]] || 
            [[ $PARAMETER == PY* ]] || 
            [[ $PARAMETER == PT* ]] || 
            [[ $PARAMETER == PR* ]] || 
            [[ $PARAMETER == PB* ]] || 
            [[ $PARAMETER == PL* ]]; then

            export declare "${PREFIX}_$PARAMETER"=${!CLASS}
        fi 
        

        # ╭───────────────────────╮
        # │                       │
        # │        🚀 EDGE        │
        # │                       │
        # ╰───────────────────────╯
        # If this is a "EDGE_DUAL" or "EDGE_FINE", it doesn't have $SECONDARY set.
        # So set all or the edges to the same thickness.
        if  [[ $PARAMETER == EDGE* ]] && [[ $SECONDARY == "" ]] ; then
            VAR="${PARAMETER}_${PRIMARY}_TL"; export declare "${PREFIX}_${PARAMETER}_TL"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_T";  export declare "${PREFIX}_${PARAMETER}_T"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_TR"; export declare "${PREFIX}_${PARAMETER}_TR"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_R";  export declare "${PREFIX}_${PARAMETER}_R"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_BR"; export declare "${PREFIX}_${PARAMETER}_BR"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_B";  export declare "${PREFIX}_${PARAMETER}_B"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_BL"; export declare "${PREFIX}_${PARAMETER}_BL"=${!VAR}
            VAR="${PARAMETER}_${PRIMARY}_L";  export declare "${PREFIX}_${PARAMETER}_L"=${!VAR}
        fi 

        # If it DOES have $SECONDARY set, it'll be something like "EDGE_WIDE_B"
        # Define the variable name to equal the class with a prefix. "BOX_EDGE_FINE_TL"
        if [[ $PARAMETER == EDGE* ]] && ! [[ $SECONDARY == "" ]] ; then
            VAR="${CLASS}"; export declare "${PREFIX}_${PARAMETER}_${SECONDARY}"=${!VAR}
        fi

        # ╭──────────────────────────╮
        # │                          │
        # │         → WIDTHS         │
        # │         ↑ HEIGHTS        │
        # │                          │
        # ╰──────────────────────────╯
        # create new variable W_, etc...
        if  [[ $PARAMETER == 'W' ]]; then
            export declare "${PREFIX}_${PARAMETER}"=${!CLASS}
        fi    
        
        if  [[ $PARAMETER == 'H' ]]; then
            export declare "${PREFIX}_${PARAMETER}"=${!CLASS}
        fi

        # ╭──────────────────────────╮
        # │                          │
        # │        TEXT ALIGN        │
        # │                          │
        # ╰──────────────────────────╯
        # create new variable TEXT_COLOUR, BG_COLOUR, BORDER_COLOUR, etc...
        if  [[ $PARAMETER == 'ALIGN' ]]; then
            export declare "${PREFIX}_${PARAMETER}"=${!CLASS}
        fi

    done
}



# ┌─────────────────────────────────────┐
# │                                     │
# │           Select Options            │
# │                                     │
# └─────────────────────────────────────┘
#source $SPINNAKER_TOOLS_FOLDER/select/select_options.sh

# https://unix.stackexchange.com/questions/146570/arrow-key-enter-menu
# https://stackoverflow.com/questions/49531797/bash-submenu-with-arrowkeys

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
function select_option {
    
    HEIGHT=3
    FOOTER_HEIGHT=2

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")                                                               # Escape sequence for ANSI control characters
    cursor_blink_on()  { printf "$ESC[?25h"; }                                          # Turn Cursor blink on
    cursor_blink_off() { printf "$ESC[?25l"; }                                          # Turn Cursor blink off
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }                                   # Position the Cursor: [LINE;COLUMNH (H at end.)
    
    ref_to_content()   {
        VARNAME=$1
        REFERENCE=${!VARNAME}
        echo "${REFERENCE}"
    }

    ref_to_ref_to_content()   {
        VARNAME=$1
        REFERENCE=${!VARNAME}
        OUTPUT=${!REFERENCE}
        echo "${OUTPUT}"
    }

    print_option()     {                                                                # Print Text
        TEXT=$1
        LOOP_INDEX=$2

        TITLE=$( ref_to_content "SELECT_ARRAY_TITLE_${LOOP_INDEX}" )
        TITLE_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_TITLE_STYLE_${LOOP_INDEX}")
        DESCRIPTION=$(ref_to_content "SELECT_ARRAY_DESCRIPTION_${LOOP_INDEX}")
        DESCRIPTION_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_DESCRIPTION_STYLE_${LOOP_INDEX}")

        TITLE=$(eval "printf \"${TITLE}\"")
        DESCRIPTION=$(eval "printf \"${DESCRIPTION}\"")

        OPTION_TEXT=''
        OPTION_TEXT+="  "
        OPTION_TEXT+="${TITLE_STYLE}"
        OPTION_TEXT+="${TITLE}\n"
        OPTION_TEXT+="${RESET_TEXT}"
        OPTION_TEXT+="  "
        OPTION_TEXT+="${DESCRIPTION_STYLE}"
        OPTION_TEXT+="${DESCRIPTION}"
        OPTION_TEXT+="${RESET_ALL}"

        printf "$OPTION_TEXT"; 
    }               

    invert_selected()  {                                                                # Selected Text
        TEXT=$1
        LOOP_INDEX=$2

        TITLE=$( ref_to_content "SELECT_ARRAY_TITLE_${LOOP_INDEX}" )
        TITLE_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_TITLE_STYLE_${LOOP_INDEX}")
        DESCRIPTION=$(ref_to_content "SELECT_ARRAY_DESCRIPTION_${LOOP_INDEX}")
        DESCRIPTION_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_DESCRIPTION_STYLE_${LOOP_INDEX}")
        SIDEBAR_STYLE=$(ref_to_ref_to_content "SELECT_ARRAY_SIDEBAR_STYLE_${LOOP_INDEX}")
        SIDEBAR_ICON=$(ref_to_content "$SELECT_ARRAY_SIDEBAR_ICON")

        TITLE=$(eval "printf \"${TITLE}\"")
        DESCRIPTION=$(eval "printf \"${DESCRIPTION}\"")

        OPTION_TEXT=''
        OPTION_TEXT+="${SIDEBAR_STYLE}"
        OPTION_TEXT+="${SIDEBAR_ICON} "
        OPTION_TEXT+="${TITLE_STYLE}"
        OPTION_TEXT+="${TITLE}\n"
        OPTION_TEXT+="${RESET_TEXT}"
        OPTION_TEXT+="${SIDEBAR_STYLE}"
        OPTION_TEXT+="${SIDEBAR_ICON} "
        OPTION_TEXT+="${DESCRIPTION_STYLE}"
        OPTION_TEXT+="${DESCRIPTION}"
        OPTION_TEXT+="${RESET_ALL}"

        printf "$OPTION_TEXT"; 

    }                                  

    get_terminal_height()   {                                                           # Get the number of terminal rows
        IFS=';'                                                                         # Split by ';'. 
        read -sdR -p $'\E[6n' ROW COL;                                                  # Read cursor position into two variables ROW and COL
        echo ${ROW#*[};                                                                 # Print everything before the [ bracket in ROW
    }             

    key_input()        { read -s -n3 key 2>/dev/null >&2                                # Read the key input
                            if [[ $key = $ESC[A ]]; then echo up;    fi                 # If the UP key is pressed, echo up
                            if [[ $key = $ESC[B ]]; then echo down;  fi                 # If the DOWN key is pressed, echo down
                            if [[ $key = ""     ]]; then echo enter; fi; }              # If the any key is pressed, echo enter


    # initially print empty new lines (scroll down if at bottom of screen)
    NEWLINE_COUNT=$(( ( $# * $HEIGHT ) ))
    for (( c=1; c<=$NEWLINE_COUNT; c++)) ; do printf "\n" ; done

    # printf "$TEXT_STONE_600 $ICON_ARROW_N up $ICON_CIRCLE $ICON_ARROW_S down $ICON_CIRCLE enter choose $RESET_TEXT";

    # determine current screen position for overwriting the options
    local lastrow=$(get_terminal_height)                                                # lastrow is the bottom of the terminal

    TOTAL_LINES=$(( $# * $HEIGHT ))                                                     # Number of lines = number of options * height of each

    local STARTING_ROW=$(( $lastrow - $TOTAL_LINES ))                                   # STARTING_ROW is where to start printing text..
    #echo "STARTING_ROW: $STARTING_ROW" # 14

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2                              # Catch a CTRL-C
    cursor_blink_off                                                                    # Turn any cursor blinking off.

    local selected=0                                                                    # Initialise current selected value
    while true; do                                                                      # Loop forever

            # print options by overwriting the last lines
            local LINE_OFFSET=0                                                               # Start cursor at bottom (0)

            for opt; do                                                                       # "$@" if no array provided. Loop through every option.

                cursor_to $(( $STARTING_ROW + $LINE_OFFSET )) 0                               # STARTING_ROW = bottom of terminal - height of all lines. (20 - 6) = 14. LINE_OFFSET = 0, 0 Columns.

                if [ $LINE_OFFSET -eq $(( $selected * $HEIGHT)) ]; then                       # If the current line is same as offset...
                    invert_selected "$opt" "$selected"                                        # Invert option
                else
                    INDEX=$(( $LINE_OFFSET / $HEIGHT ))
                    print_option "$opt" "$INDEX"                                              # print normal option
                fi
                (( LINE_OFFSET = LINE_OFFSET + $HEIGHT  ))                                    # +-HEIGHT to line offset
            done

            # user key control
            case `key_input` in                                                               # Wait for user input
                enter) break;;                                                                # Break loop if 'enter' is pressed

                up)    ((selected = selected - 1)); 
                    if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;                   # loop to top if passed bottom

                down)  ((selected = selected + 1));                                           # ++ if down arrow pressed,
                    if [ $selected -ge $# ]; then selected=0; fi;;                            # loop back to beginning if passed top
            esac

    done

    # # Once loop is broken, cursor position back to normal
    cursor_to $lastrow                                                                        
    printf "\n"
    cursor_blink_on

    # Return the selected value.
    return $selected
}



# ┌─────────────────────────────────────┐
# │                                     │
# │             Parse JSON              │
# │                                     │
# └─────────────────────────────────────┘
#source $SPINNAKER_TOOLS_FOLDER/utils/parse_json.sh

function parse_json()
{

    throw() {
        echo "$*" >&2
        exit 1
    }

    BRIEF=0
    LEAFONLY=0
    PRUNE=0
    NO_HEAD=0
    NORMALIZE_SOLIDUS=0

    usage() {
        echo
        echo "Usage: JSON.sh [-b] [-l] [-p] [-s] [-h]"
        echo
        echo "-p - Prune empty. Exclude fields with empty values."
        echo "-l - Leaf only. Only show leaf nodes, which stops data duplication."
        echo "-b - Brief. Combines 'Leaf only' and 'Prune empty' options."
        echo "-n - No-head. Do not show nodes that have no path (lines that start with [])."
        echo "-s - Remove escaping of the solidus symbol (straight slash)."
        echo "-h - This help text."
        echo
    }

    parse_options() {

        set -- "$@"
        local ARGN=$#
        while [ "$ARGN" -ne 0 ]
        do
        case $1 in
            -h) usage
                exit 0
            ;;
            -b) BRIEF=1
                LEAFONLY=1
                PRUNE=1
            ;;
            -l) LEAFONLY=1
            ;;
            -p) PRUNE=1
            ;;
            -n) NO_HEAD=1
            ;;
            -s) NORMALIZE_SOLIDUS=1
            ;;
            ?*) echo "ERROR: Unknown option."
                usage
                exit 0
            ;;
        esac
        shift 1
        ARGN=$((ARGN-1))
        done
    }

    awk_egrep () {
        local pattern_string=$1

        gawk '{
        while ($0) {
            start=match($0, pattern);
            token=substr($0, start, RLENGTH);
            print token;
            $0=substr($0, start+RLENGTH);
        }
        }' pattern="$pattern_string"
    }

    tokenize () {
        local GREP
        local ESCAPE
        local CHAR

        if echo "test string" | egrep -ao --color=never "test" >/dev/null 2>&1
        then
        GREP='egrep -ao --color=never'
        else
        GREP='egrep -ao'
        fi

        if echo "test string" | egrep -o "test" >/dev/null 2>&1
        then
        ESCAPE='(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
        CHAR='[^[:cntrl:]"\\]'
        else
        GREP=awk_egrep
        ESCAPE='(\\\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})'
        CHAR='[^[:cntrl:]"\\\\]'
        fi

        local STRING="\"$CHAR*($ESCAPE$CHAR*)*\""
        local NUMBER='-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?'
        local KEYWORD='null|false|true'
        local SPACE='[[:space:]]+'

        # Force zsh to expand $A into multiple words
        local is_wordsplit_disabled=$(unsetopt 2>/dev/null | grep -c '^shwordsplit$')
        if [ $is_wordsplit_disabled != 0 ]; then setopt shwordsplit; fi
        $GREP "$STRING|$NUMBER|$KEYWORD|$SPACE|." | egrep -v "^$SPACE$"
        if [ $is_wordsplit_disabled != 0 ]; then unsetopt shwordsplit; fi
    }

    parse_array () {
        local index=0
        local ary=''
        read -r token
        case "$token" in
        ']') ;;
        *)
            while :
            do
            parse_value "$1" "$index"
            index=$((index+1))
            ary="$ary""$value" 
            read -r token
            case "$token" in
                ']') break ;;
                ',') ary="$ary," ;;
                *) throw "EXPECTED , or ] GOT ${token:-EOF}" ;;
            esac
            read -r token
            done
            ;;
        esac
        [ "$BRIEF" -eq 0 ] && value=$(printf '[%s]' "$ary") || value=
        :
    }

    parse_object () {
        local key
        local obj=''
        read -r token
        case "$token" in
        '}') ;;
        *)
            while :
            do
            case "$token" in
                '"'*'"') key=$token ;;
                *) throw "EXPECTED string GOT ${token:-EOF}" ;;
            esac
            read -r token
            case "$token" in
                ':') ;;
                *) throw "EXPECTED : GOT ${token:-EOF}" ;;
            esac
            read -r token
            parse_value "$1" "$key"
            obj="$obj$key:$value"        
            read -r token
            case "$token" in
                '}') break ;;
                ',') obj="$obj," ;;
                *) throw "EXPECTED , or } GOT ${token:-EOF}" ;;
            esac
            read -r token
            done
        ;;
        esac
        [ "$BRIEF" -eq 0 ] && value=$(printf '{%s}' "$obj") || value=
        :
    }

    parse_value () {
        local jpath="${1:+$1,}$2" isleaf=0 isempty=0 print=0
        case "$token" in
        '{') parse_object "$jpath" ;;
        '[') parse_array  "$jpath" ;;
        # At this point, the only valid single-character tokens are digits.
        ''|[!0-9]) throw "EXPECTED value GOT ${token:-EOF}" ;;
        *) value=$token
            # if asked, replace solidus ("\/") in json strings with normalized value: "/"
            [ "$NORMALIZE_SOLIDUS" -eq 1 ] && value=$(echo "$value" | sed 's#\\/#/#g')
            isleaf=1
            [ "$value" = '""' ] && isempty=1
            ;;
        esac
        [ "$value" = '' ] && return
        [ "$NO_HEAD" -eq 1 ] && [ -z "$jpath" ] && return

        [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 0 ] && print=1
        [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && [ $PRUNE -eq 0 ] && print=1
        [ "$LEAFONLY" -eq 0 ] && [ "$PRUNE" -eq 1 ] && [ "$isempty" -eq 0 ] && print=1
        [ "$LEAFONLY" -eq 1 ] && [ "$isleaf" -eq 1 ] && \
        [ $PRUNE -eq 1 ] && [ $isempty -eq 0 ] && print=1
        [ "$print" -eq 1 ] && printf "[%s]\t%s\n" "$jpath" "$value"
        :
    }

    parse () {
        read -r token
        parse_value
        read -r token
        case "$token" in
        '') ;;
        *) throw "EXPECTED EOF GOT $token" ;;
        esac
    }

    # IF removed to convert script to function.
    # if ([ "$0" = "$BASH_SOURCE" ] || ! [ -n "$BASH_SOURCE" ]);
    # then
        parse_options "$@"
        tokenize | parse
    # fi

    # vi: expandtab sw=2 ts=2
}


# ┌─────────────────────────────────────┐
# │                                     │
# │            Usage Message            │
# │                                     │
# └─────────────────────────────────────┘
function usage(){
    printf "${TEXT_RED_500}Illegal number of parameters\n"
    printf "${TEXT_GREEN_500}usage:\n"
    printf "\t${TEXT_GRAY_200}$0 ${TEXT_SKY_500}<config-file.yaml>\n"
    exit 1
}


# ┌─────────────────────────────────────┐
# │                                     │
# │           Create Options            │
# │                                     │
# └─────────────────────────────────────┘
function options(){

    # Take first arg as Config file
    CONFIG_FILE=$1

    # Run file through the parser
    # JSON_PARSED=$(cat ${CONFIG_FILE} | parse_json -l )
    JSON_PARSED=$(echo $MENU | parse_json -l)

    # Store the length of select array
    JSON_SELECT_LENGTH=$(getarrlen select.options)
    CLEAR_SCREEN=$(getkey select.clear)
    CLEAR_BEFORE_COMMAND_SCREEN=$(getkey select.clear_before_command)
    declare SELECT_ARRAY_SIDEBAR_ICON=$(getkey select.icon)
    HIDE_MESSAGE=$(getkey select.hide_message)
    DISPLAY_HELP=$(getkey select.display_help)
    RESET_LOOP=$(getkey select.reset_loop)

    # if $CLEAR_SCREEN; then clear; fi

    SELECT_ARRAY=()
    # Loop through select object to get each array
    for (( LOOP=0; LOOP<${JSON_SELECT_LENGTH}; LOOP++ ))
    do 

        # Create the variables
        declare LOOP_SELECT_INDEX=$LOOP
        declare LOOP_SELECT_TITLE=$(getkey select.options[$LOOP].title)
        declare LOOP_SELECT_TITLE_STYLE=$(getkey select.options[$LOOP].title_style)
        declare LOOP_SELECT_DESCRIPTION=$(getkey select.options[$LOOP].description)
        declare LOOP_SELECT_DESCRIPTION_STYLE=$(getkey select.options[$LOOP].description_style)
        declare LOOP_SELECT_COMMAND=$(getkey select.options[$LOOP].command)
        declare LOOP_SELECT_HEIGHT=$(getkey select.options[$LOOP].height)
        declare LOOP_SELECT_SIDEBAR_STYLE=$(getkey select.options[$LOOP].bullet)

        # Remove the forward escape slashes in the command field
        LOOP_SELECT_COMMAND=${LOOP_SELECT_COMMAND//\\/}  


        # DEFAULT STYLES
        TITLE_STYLE_TEXT_COLOUR="${TEXT_GRAY_100}"
        DESCRIPTION_STYLE_TEXT_COLOUR="${TEXT_GRAY_400}"
        SIDELINE_STYLE_BORDER_COLOUR="${BORDER_GRAY_900}"

        # OVERRIDES
        #
        # run the parse_classes script.
        # This will override any default variables
        # by setting them to supplied user values.
        #
        # @return $PREFIX_VARIABLE
        parse_classes "TITLE_STYLE" "${LOOP_SELECT_TITLE_STYLE}"
        parse_classes "DESCRIPTION_STYLE" "${LOOP_SELECT_DESCRIPTION_STYLE}"

        # Add to array
        SELECT_ARRAY+=("")

        # Create environment variables of results
        declare SELECT_ARRAY_INDEX_$LOOP="${LOOP_SELECT_INDEX}"
        declare SELECT_ARRAY_TITLE_$LOOP="${LOOP_SELECT_TITLE}"
        declare SELECT_ARRAY_TITLE_STYLE_$LOOP="${LOOP_SELECT_TITLE_STYLE}"
        declare SELECT_ARRAY_DESCRIPTION_$LOOP="${LOOP_SELECT_DESCRIPTION}"
        declare SELECT_ARRAY_DESCRIPTION_STYLE_$LOOP="${LOOP_SELECT_DESCRIPTION_STYLE}"
        declare SELECT_ARRAY_COMMAND_$LOOP="${LOOP_SELECT_COMMAND}"
        declare SELECT_ARRAY_HEIGHT_$LOOP="${LOOP_SELECT_HEIGHT}"
        declare SELECT_ARRAY_SIDEBAR_STYLE_$LOOP="${LOOP_SELECT_SIDEBAR_STYLE}"

    done

    # Show the arrows help message
    if $DISPLAY_HELP; then
        printf "$TEXT_STONE_500 $ICON_ARROW_N $TEXT_STONE_600 up $ICON_CIRCLE $TEXT_STONE_500 $ICON_ARROW_S $TEXT_STONE_600 down $ICON_CIRCLE $TEXT_STONE_500 enter $TEXT_STONE_600 choose $RESET_TEXT\n\n";
    fi

    select_option "${SELECT_ARRAY[@]}"
    choice=$?
    # echo "Choosen index = $choice"

    COMMAND_NAME="SELECT_ARRAY_COMMAND_$choice"

    COMMAND="${!COMMAND_NAME}"

    if ! $HIDE_MESSAGE; then
        printf '%s' "Running command:${TEXT_EMERALD_300} ${COMMAND} ${RESET_TEXT}"
    fi

    if $CLEAR_BEFORE_COMMAND_SCREEN; then clear; fi
    eval "${COMMAND}"

    if $RESET_LOOP; then
        options $@
    fi

}

stylesheet
options "$MENU"
