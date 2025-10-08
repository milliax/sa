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
    history=$(echo "$1" | sed 's/;$//')
    # echo "History: $history" > "$terminal"

    # read dictionary, and filter the words according to history
    possible_words=$(cat dictionary.txt)
    
    fixed_1=""
    fixed_2=""
    fixed_3=""
    fixed_4=""
    fixed_5=""

    useless_letters=""
    useable_letters=""

    # go throught the history if there is any A, then store in fixed_1~5, and find if a letter is useless store in useless_letters
    guesses=$1
    IFS=';'
    set -- $guesses

    for i in "$@"; do
        guess=$(echo "$i" | cut -d':' -f1)
        result=$(echo "$i" | cut -d':' -f2)

        echo "Guess: $guess, Result: $result" > "$terminal"

        for j in $(seq 1 5); do
            echo "Hola" > "$terminal"
            echo "Checking letter $((j))" > "$terminal"

            letter=$(echo "$guess" | cut -c$((j)))
            res_letter=$(echo "$result" | cut -c$((j)))

            case $res_letter in
                A) case $j in
                        0) fixed_1="$letter" ;;
                        1) fixed_2="$letter" ;;
                        2) fixed_3="$letter" ;;
                        3) fixed_4="$letter" ;;
                        4) fixed_5="$letter" ;;
                   esac
                   ;;
                B) 
                # append the letter into useable_letters if not already there
                     if ! echo "$useable_letters" | grep -q "$letter"; then
                            useable_letters="$useable_letters$letter"
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

    # using regex to filter possible_words
    regex="^"
    for i in $(seq 0 4); do
        case $i in
            0) if [ -n "$fixed_1" ]; then
                    regex="$regex$fixed_1"
                else
                    regex="$regex."
                fi
                ;;
            1) if [ -n "$fixed_2" ]; then
                    regex="$regex$fixed_2"
                else
                    regex="$regex."
                fi
                ;;
            2) if [ -n "$fixed_3" ]; then
                    regex="$regex$fixed_3"
                else
                    regex="$regex."
                fi
                ;;
            3) if [ -n "$fixed_4" ]; then
                    regex="$regex$fixed_4"
                else
                    regex="$regex."
                fi
                ;;
            4) if [ -n "$fixed_5" ]; then
                    regex="$regex$fixed_5"
                else
                    regex="$regex."
                fi
                ;;
        esac
    done

    regex="$regex$"

    echo "Regex: $regex" > "$terminal"

    # filter possible_words with regex and useless_letters
    for letter in $(echo "$useless_letters" | fold -w1 | sort -
u); do
        possible_words=$(echo "$possible_words" | grep -v "$letter")
    done

    # get the first word that matches the regex
    next_possible=$(echo "$possible_words" | grep -E "$regex" | head -n 1)
    echo "Next possible word: $next_possible" > "$terminal"

    # next_possible="apple"
    return    
}

## get parameter tag -t SYS_INFO
while getopts "aht:" opt
do
    case $opt in
        a) echo "hw1.sh -t TASK_TYPE [-h]"
            echo ""
            echo "Available Options:"
            echo "-t SYS_INFO | WORDLE | QUORDLE : Task type"
            echo "-h : Show the script usage"
           exit 1
        ;;
        h)
        # echo help message to stderr
        echo "hw1.sh -t TASK_TYPE [-h]" >&2
        echo "" >&2
        echo "Available Options:" >&2
        echo "-t SYS_INFO | WORDLE | QUORDLE : Task type" >&2
        echo "-h : Show the script usage" >&2
            exit 1
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


        ?)
        echo "hw1.sh -t TASK_TYPE [-h]" >&2
        echo "" >&2
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