#!/bin/sh

# env setup

ENDPOINT="http://192.168.255.69"
stuid="529"
terminal=$(tty)
next_possible=""

# define a function for getting dictionary
get_dictionary() {
    # check if dictionary.txt exists
    if [ ! -f dictionary.txt ]; then
        echo "dictionary.txt not found, downloading..."
        curl -o "dictionary.txt" "$ENDPOINT/dictionary"
        echo "dictionary.txt downloaded"
    else
        echo "dictionary.txt already exists"
    fi
}

get_next_possible(){
    # get the next possible word from dictionary.txt according to previous guesses and result
    # echo "$1"

    # if $1 is null return water
    if [ -z "$1" ]; then
        echo "No previous guesses, returning water" > "$terminal"
        next_possible="water"
        return
    fi
    # return the next possible word

    # trim $1 the last semicolon
    # history=$(echo "$1" | sed 's/;$//')
    # echo "History: $history" > "$terminal"

    # read dictionary, and filter the words according to history
    possible_words=$(cat dictionary.txt)
    
    fixed_1=""
    fixed_2=""
    fixed_3=""
    fixed_4=""
    fixed_5=""

    excluded_1=""
    excluded_2=""
    excluded_3=""
    excluded_4=""
    excluded_5=""

    useless_letters=""
    required_letters=""

    # go throught the history if there is any A, then store in fixed_1~5, and find if a letter is useless store in useless_letters
    guesses=$1
    IFS=';'
    set -- $guesses

    for i in "$@"; do
        guess=$(echo "$i" | cut -d':' -f1)
        result=$(echo "$i" | cut -d':' -f2)

        # echo "Guess: $guess, Result: $result" > "$terminal"

        idx=0

        while [ $idx -lt 5 ]; do
            idx=$((idx + 1))

            # echo "Checking letter $((idx))" > "$terminal"

            letter=$(echo "$guess" | cut -c $((idx)))
            res_letter=$(echo "$result" | cut -c $((idx)))

            case $res_letter in
                A) case $idx in
                        1) fixed_1="$letter" ;;
                        2) fixed_2="$letter" ;;
                        3) fixed_3="$letter" ;;
                        4) fixed_4="$letter" ;;
                        5) fixed_5="$letter" ;;
                   esac
                   ;;
                B)
                   # letter is in the word but wrong position
                   # track which position it can't be at
                   case $idx in
                       1) excluded_1="$excluded_1$letter" ;;
                       2) excluded_2="$excluded_2$letter" ;;
                       3) excluded_3="$excluded_3$letter" ;;
                       4) excluded_4="$excluded_4$letter" ;;
                       5) excluded_5="$excluded_5$letter" ;;
                   esac
                   # add to required letters
                   if ! echo "$required_letters" | grep -q "$letter"; then
                       required_letters="$required_letters$letter"
                   fi
                   ;;
                X) # letter is not in the word
                   # add letter to useless_letters if not already there
                   if ! echo "$useless_letters" | grep -q "$letter"; then
                       useless_letters="$useless_letters$letter"
                   fi
                   ;;
            esac
        done
    done

    echo "Fixed letters: $fixed_1 $fixed_2 $fixed_3 $fixed_4 $fixed_5" > "$terminal"
    echo "Useless letters: $useless_letters" > "$terminal"

    # usable letters are a-z excluding useless letters
    if [ -z "$useless_letters" ]; then
        useable_letters="abcdefghijklmnopqrstuvwxyz"
    else
        useable_letters=$(echo "abcdefghijklmnopqrstuvwxyz" | tr -d "$(echo "$useless_letters" | fold -w1 | sort -u | tr -d '\n')")
    fi

    # using regex to filter possible_words
    regex="^"
    
    # deal with first letter
    if [ -n "$fixed_1" ]; then
        regex="$regex$fixed_1"
    else
        allowed="$useable_letters"
        if [ -n "$excluded_1" ]; then
            allowed=$(echo "$allowed" | tr -d "$(echo "$excluded_1" | fold -w1 | sort -u | tr -d '\n')")
        fi
        if [ -n "$allowed" ]; then
            regex_temp="[$allowed]"
            regex="$regex$regex_temp"
        else
            regex="$regex."
        fi
    fi

    # deal with second letter
    if [ -n "$fixed_2" ]; then
        regex="$regex$fixed_2"
    else
        allowed="$useable_letters"
        if [ -n "$excluded_2" ]; then
            allowed=$(echo "$allowed" | tr -d "$(echo "$excluded_2" | fold -w1 | sort -u | tr -d '\n')")
        fi
        if [ -n "$allowed" ]; then
            regex_temp="[$allowed]"
            regex="$regex$regex_temp"
        else
            regex="$regex."
        fi
    fi

    # deal with third letter
    if [ -n "$fixed_3" ]; then
        regex="$regex$fixed_3"
    else
        allowed="$useable_letters"
        if [ -n "$excluded_3" ]; then
            allowed=$(echo "$allowed" | tr -d "$(echo "$excluded_3" | fold -w1 | sort -u | tr -d '\n')")
        fi
        if [ -n "$allowed" ]; then
            regex_temp="[$allowed]"
            regex="$regex$regex_temp"
        else
            regex="$regex."
        fi
    fi

    # deal with fourth letter
    if [ -n "$fixed_4" ]; then
        regex="$regex$fixed_4"
    else
        allowed="$useable_letters"
        if [ -n "$excluded_4" ]; then
            allowed=$(echo "$allowed" | tr -d "$(echo "$excluded_4" | fold -w1 | sort -u | tr -d '\n')")
        fi
        if [ -n "$allowed" ]; then
            regex_temp="[$allowed]"
            regex="$regex$regex_temp"
        else
            regex="$regex."
        fi
    fi

    # deal with fifth letter
    if [ -n "$fixed_5" ]; then
        regex="$regex$fixed_5"
    else
        allowed="$useable_letters"
        if [ -n "$excluded_5" ]; then
            allowed=$(echo "$allowed" | tr -d "$(echo "$excluded_5" | fold -w1 | sort -u | tr -d '\n')")
        fi
        if [ -n "$allowed" ]; then
            regex_temp="[$allowed]"
            regex="$regex$regex_temp"
        else
            regex="$regex."
        fi
    fi

    regex="$regex$"

    echo "Regex: $regex" > "$terminal"
    echo "Required letters: $required_letters" > "$terminal"

    # filter possible_words with regex
    possible_words=$(echo "$possible_words" | grep -E "$regex")

    # filter to ensure all required letters (from B results) are present
    if [ -n "$required_letters" ]; then
        for letter in $(echo "$required_letters" | fold -w1 | sort -u); do
            possible_words=$(echo "$possible_words" | grep "$letter")
        done
    fi

    # get first word that hasn't been guessed yet
    next_possible=$(echo "$possible_words" | head -n 1)
    while echo "$guesses" | grep -q ":$next_possible:" && [ -n "$next_possible" ]; do
        possible_words=$(echo "$possible_words" | grep -v "^$next_possible$")
        next_possible=$(echo "$possible_words" | head -n 1)
    done

    echo "Next possible word: $next_possible" > "$terminal"

    # next_possible="apple"
    return    
}

get_next_possible_for_quad(){
    echo "Getting next possible for quad with history: $1" > "$terminal"
    
    # if $1 equals "|||", then return water
    if [ "$1" = "|||" ]; then
        echo "No previous guesses, returning water" > "$terminal"
        next_possible="water"
        return
    fi

    # get the last guess
    IFS='|'
    set -- $1
    guess_history_1=$1
    guess_history_2=$2
    guess_history_3=$3
    guess_history_4=$4

    correct_1=0
    correct_2=0
    correct_3=0
    correct_4=0

    if [ -n "$guess_history_1" ]; then
        if echo "$guess_history_1" | grep -q ":AAAAA;"; then
            correct_1=1
        fi
    fi

    if [ -n "$guess_history_2" ]; then
        if echo "$guess_history_2" | grep -q ":AAAAA;"; then
            correct_2=1
        fi
    fi

    if [ -n "$guess_history_3" ]; then
        if echo "$guess_history_3" | grep -q ":AAAAA;"; then
            correct_3=1
        fi
    fi

    if [ -n "$guess_history_4" ]; then
        if echo "$guess_history_4" | grep -q ":AAAAA;"; then
            correct_4=1
        fi
    fi

    # prioritize the first one if not solved yet

    if [ $correct_1 -eq 0 ]; then
        get_next_possible "$guess_history_1"
        return
    fi

    if [ $correct_2 -eq 0 ]; then
        get_next_possible "$guess_history_2"
        return
    fi

    if [ $correct_3 -eq 0 ]; then
        get_next_possible "$guess_history_3"
        return
    fi

    if [ $correct_4 -eq 0 ]; then
        get_next_possible "$guess_history_4"
        return
    fi
}

## get parameter tag -t SYS_INFO
while getopts ":t:h" opt
do
    case $opt in
        h)
        # echo help message to stderr
        echo "hw1.sh -t TASK_TYPE [-h]" >&2
        echo "" >&2
        echo "Available Options:" >&2
        echo "-t SYS_INFO | WORDLE | QUORDLE : Task type" >&2
        echo "-h : Show the script usage" >&2
            exit 0
        ;;

        t) TAG=$OPTARG
        
        # if $TAG === SYS_INFO, then print system information
        if [ "$TAG" = "SYS_INFO" ]; then
            # example output
            # OS: Debian GNU/Linux 13 (trixie) x86_64
            # Kernel: 6.12.41+deb13-amd64
            # Shell: sh
            # Terminal: /dev/pts/0
            # CPU: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
            echo "OS: $(lsb_release -d | cut -f2)"
            echo "Kernel: $(uname -r)"
            echo "Shell: $SHELL"
            echo "Terminal: $(tty)"
            echo "CPU: $(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')"
            exit 0
        fi

        # if TAG is WORDLE
        if [ "$TAG" = "WORDLE" ]; then
            # request an http request to server
            # echo "Requesting a new wordle game..."

            get_dictionary
            ### Request a wordle task from server with json parameters

            response=$(curl -s -X POST "$ENDPOINT/tasks" -H "Content-Type: application/json" -d '{"stuid": "'"$stuid"'", "type": "WORDLE"}')
            # echo "Response from server:"
            echo "$response"

            guess_times=0
            correct=0

            # get task id
            id="$(echo "$response" | jq -r '.id')"
            echo "Task ID: $id"

            guess_history="" # it is a string, format: "GUESS1:RESULT1;GUESS2:RESULT2;..."

            # guess until guess_times >= 10, or response is correct
            while [ $guess_times -lt 10 ] && [ $correct -eq 0 ]; do

                echo ""
                echo "Guess times: $((guess_times + 1))"
                echo "Guess history: $guess_history"

                get_next_possible "$guess_history"
                # echo "Next guess: $next_possible"

                # if next_possible is empty, then exit 1
                if [ -z "$next_possible" ]; then
                    echo "No possible word found, exiting..."
                    exit 1
                fi

                url="$ENDPOINT/tasks/$id/submit"
                # echo "Submitting guess '$next_possible' to $url"

                response=$(curl -s -X POST "$url" -H "Content-Type: application/json" -d '{"answer": "'"$next_possible"'"}')
                echo "Response from server:"
                echo "$response"

                guess_result="$(echo "$response" | jq -r '.problem')"

                # store the guess and result to guess_history
                guess_history="$guess_history$next_possible:$guess_result;"

                # if guess result is AAAAA, then correct=1
                if [ "$guess_result" = "AAAAA" ]; then
                    correct=1
                    echo "Got the Answer!"
                fi

                guess_times=$((guess_times + 1))
            done


            exit 0
        fi

        if [ "$TAG" = "QUORDLE" ]; then
            # request an http request to server
            echo "Requesting a new quordle game..."

            get_dictionary

            ### Request a quordle task from server with json parameters
            response=$(curl -s -X POST "$ENDPOINT/tasks" -H "Content-Type: application/json" -d '{"stuid": "'"$stuid"'", "type": "QUORDLE"}')

            guess_times=0

            # get task id
            id="$(echo "$response" | jq -r '.id')"
            echo "Task ID: $id"

            guess_1_correct=0
            guess_2_correct=0
            guess_3_correct=0
            guess_4_correct=0

            guess_all_correct=0

            guess_history_1="" # it is a string, format: "GUESS1:RESULT1;GUESS2:RESULT2;..."
            guess_history_2="" # it is a string, format: "GUESS1:RESULT1;GUESS2:RESULT2;..."
            guess_history_3="" # it is a string, format: "GUESS1:RESULT1;GUESS2:RESULT2;..."
            guess_history_4="" # it is a string, format: "GUESS1:RESULT1;GUESS2:RESULT2;..."

            while [ $guess_times -lt 20 ] && [ $guess_all_correct -eq 0 ]; do

                echo ""
                echo "Guess times: $((guess_times + 1))"
                echo "Guess history 1: $guess_history_1"
                echo "Guess history 2: $guess_history_2"
                echo "Guess history 3: $guess_history_3"
                echo "Guess history 4: $guess_history_4"

                guess_times=$((guess_times + 1))

                get_next_possible_for_quad "$guess_history_1|$guess_history_2|$guess_history_3|$guess_history_4"

                # if any of next_possible is empty, then exit 1
                if [ -z "$next_possible" ] ; then
                    echo "No possible word found, exiting..."
                    exit 1
                fi

                url="$ENDPOINT/tasks/$id/submit"
                echo "Submitting guesses '$next_possible' to $url"

                response=$(curl -s -X POST "$url" -H "Content-Type: application/json" -d '{"answer": "'"$next_possible"'"}')
                echo "Response from server:"
                echo "$response"

                guess_result_1="$(echo "$response" | jq -r '.problem1')"
                guess_result_2="$(echo "$response" | jq -r '.problem2')"
                guess_result_3="$(echo "$response" | jq -r '.problem3')"
                guess_result_4="$(echo "$response" | jq -r '.problem4')"

                # store the guess and result to guess_history
                guess_history_1="$guess_history_1$next_possible:$guess_result_1;"
                guess_history_2="$guess_history_2$next_possible:$guess_result_2;"
                guess_history_3="$guess_history_3$next_possible:$guess_result_3;"
                guess_history_4="$guess_history_4$next_possible:$guess_result_4;"

                if [ "$guess_result_1" = "AAAAA" ]; then
                    guess_1_correct=1
                    echo "Got the Answer for problem 1!"
                fi
                if [ "$guess_result_2" = "AAAAA" ]; then
                    guess_2_correct=1
                    echo "Got the Answer for problem 2!"
                fi
                if [ "$guess_result_3" = "AAAAA" ]; then
                    guess_3_correct=1
                    echo "Got the Answer for problem 3!"
                fi
                if [ "$guess_result_4" = "AAAAA" ]; then
                    guess_4_correct=1
                    echo "Got the Answer for problem 4!"
                fi

                guess_all_correct=$((guess_1_correct & guess_2_correct & guess_3_correct & guess_4_correct))
            done

            exit 0
        fi

        if [ "$TAG" = "TEST" ]; then
            # request an http request to server with no body and print the result
            response=$(curl -s "$ENDPOINT/")
            echo "$response"

            message="$(echo "$response" | jq '.message')"

            echo "Message from server: $message"

            exit 0
        fi

        echo "$TAG is not implemented yet" >&2

        exit 1
        ;;


        ?) echo "hw1.sh -t TASK_TYPE [-h]">&2
            echo "">&2
            echo "Available Options:" >&2
            echo "-t SYS_INFO | WORDLE | QUORDLE : Task type" >&2
            echo "-h : Show the script usage" >&2
            exit 1
        ;;


    esac

    shift
done

# if no parameter is given, print usage
if [ -z "$TAG" ]; then
    echo "hw1.sh -t TASK_TYPE [-h]" >&2
    echo "" >&2
    echo "Available Options:" >&2
    echo "-t SYS_INFO | WORDLE | QUORDLE : Task type" >&2
    echo "-h : Show the script usage" >&2
    exit 1
fi