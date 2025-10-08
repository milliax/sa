#/bin/sh

# env setup

ENDPOINT="http://192.158.255.69"

## get parameter tag -t SYS_INFO
while getopts t: opt
do
    case $opt in
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
        fi

        if [ "$TAG" = "TEST" ]; then
            # request an http request to server with no body and print the result
            curl -X GET "$ENDPOINT/"
            exit 0
        fi

        echo "$TAG is not implemented yet"
        ;;
        ?) echo "unknown parameter";;
    esac
done