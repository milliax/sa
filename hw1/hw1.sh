#/bin/sh

# env setup

ENDPOINT="http://192.168.255.69"
stuid="529"

## get parameter tag -t SYS_INFO
while getopts "ht:" opt
do
    case $opt in
        h) echo "Help message"
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
            echo "Terminal: $TERM"
            echo "CPU: $(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')"
            exit 0
        fi

        # if TAG is WORDLE
        if [ "$TAG" = "WORDLE" ]; then
            # request an http request to server
            echo "Requesting a new wordle game..."

            ### Request a wordle task from server with json parameters

            response=$(curl -s -X POST "$ENDPOINT/tasks" -H "Content-Type: application/json" -d '{"stuid": "'"$stuid"'", "type": "WORDLE"}')
            echo "Response from server:"
            echo "$response"

            # remove quotes from id
            id="$(echo "$response" | jq -r '.id')"
            echo "Task ID: $id"

            ### submit a wordle guess to server
            guess="WATER"

            url="$ENDPOINT/tasks/$id/submit"
            echo "Submitting guess '$guess' to $url"

            response=$(curl -s -X POST "$url" -H "Content-Type: application/json" -d '{"answer": "'"$guess"'"}')
            echo "Response from server:"
            echo "$response"

            exit 0
        fi

        if [ "$TAG" = "QUORDLE" ]; then
            # request an http request to server
            echo "Requesting a new quordle game..."

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

        echo "$TAG is not implemented yet"
        ;;

        
        ?) echo "unknown parameter"
        exit 1
        ;;

        
    esac

    shift
done

# if no parameter is given, print usage
if [ -z "$TAG" ]; then
    echo "Usage: $0 -t TAG"
    echo "TAG can be SYS_INFO, WORDLE, TEST"
fi