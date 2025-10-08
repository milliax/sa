FROM debian:trixie

RUN apt update && apt install -y \
    curl jq iproute2 wget git htop iputils-ping net-tools coreutils bash binutils \
    sudo vim grep gawk rsync tmux diffutils file less man manpages manpages-dev shellcheck

ENV SHELL=/bin/sh
WORKDIR /root

# docker build -t hw1 .
# docker run --rm -it -v $(pwd):/root hw1 /bin/sh