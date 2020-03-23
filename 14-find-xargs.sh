#!/usr/bin/env bash

export char

get_char(){
    SAVEDSTTY=$(stty -g)
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty "$SAVEDSTTY"
}

wait_char() {
    read -rp "Press any key to continue!" char
}

find . -maxdepth 1 -name "*.sh" | xargs -I{} -P 0 echo {} && wait_char

find . -name "*.sh" | xargs -I{} -P 0 cp {} /tmp && wait_char

find . -maxdepth 1  -name "*.sh" | xargs -I{} -P 0 sh -c "echo $$ " && wait_char

xargs -I{} -P 0 git clone -q --depth 1 {} < "$git_repo_file"
