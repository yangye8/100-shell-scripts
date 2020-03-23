#!/bin/bash

COLOR_BLACK="$(tput setaf 0)"
COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_YELLOW=$(tput setaf 3)
COLOR_LIME_YELLOW=$(tput setaf 190)
COLOR_POWDER_BLUE=$(tput setaf 153)
COLOR_BLUE=$(tput setaf 4)
COLOR_MAGENTA=$(tput setaf 5)
COLOR_CYAN=$(tput setaf 6)
COLOR_WHITE=$(tput setaf 7)
COLOR_BRIGHT=$(tput bold)
COLOR_NORMAL=$(tput sgr0)
COLOR_BLINK=$(tput blink)
COLOR_REVERSE=$(tput smso)
COLOR_UNDERLINE=$(tput smul)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

logfile=$DIR/$(date +%F-%T).log
git_repo_file=$DIR/git_repo.log
abs_src="/home/yangye/opengrok/XRT"

usage()
{
    printf "%s" "${COLOR_RED}"
    echo "Usage: $0 [tag|update|repo|init]"
    printf "%s" "${COLOR_NORMAL}"
}

clean()
{
    find . -maxdepth 1 -type f -name "*.log" -exec rm -f {} \;
}

update()
{
    clean
    for dir in $(find -- "${PWD}"/* -name ".git" -type d | sed -e "s/\/.git//")
    do
        printf "%s" "${COLOR_UNDERLINE}"
        printf "[%s]\t%-70s %5s"  "$(date +%T)" "$dir" "$(du -sh "$dir" | awk '{print $1}')"
        if (cd "$dir" && \
            git remote -v  >> "$logfile" 2>&1 && \
            git checkout . >> "$logfile" 2>&1 && \
            git clean -fxd >> "$logfile" 2>&1 && \
            git pull >> "$logfile" 2>&1)
        then
            stat=$'\e[32m✔'
            ((pass+=1))
        else
            stat=$'\e[31m✖'
            ((fail+=1))
        fi
        printf ' %20s\e[m \n' "$stat"
        printf "%s" "${COLOR_NORMAL}"
    done

    comp="Completed $((fail+pass)) tests. ${pass:-0} passed, ${fail:-0} failed."
    printf '%s\n%s\n\n' "${comp//?/-}" "$comp"
}

get_git_repo()
{
    clean
    for dir in $(find -- * -name "*.git" -type d | sed -e 's/\/.git//')
    do
        printf "%s" "${COLOR_BLUE}"
        #(cd "$dir" && git remote -v 2>/dev/null | head -n 1| awk '{print $2}' | sed 's/^/git clone &/g' | tee -a "$git_repo_file")
        (cd "$dir" && git remote -v 2>/dev/null | head -n 1| awk '{print $2}' | tee -a "$git_repo_file")
        printf "%s" "${COLOR_NORMAL}"
    done
}

git_pro_create()
{
    [ -e "$git_repo_file" ] || { echo "can not find $git_repo_file file, exit ";exit 1;}
    start=$(date +%s)
    git config --global core.compression -1
    git config --global http.postBuffer 1048576000
    git config --global https.postBuffer 1048576000
    git config --global --unset http.proxy
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999
    git config --list
    xargs -I{} -P 0 git clone -q --depth 1 {} < "$git_repo_file"
    end=$(date +%s)
    diffsec=$(( end - start ))
    echo | awk -v D=$diffsec '{printf "Eplased time: %02dh:%02dm:%02ds\n",D/(60*60),D%(60*60)/60,D%60}'
}

code_index()
{
    if ! whereis tomcat8
    then
        sudo apt install tomcat8 || exit
    fi
    curl -L https://github.com/oracle/opengrok/releases/download/1.1-rc31/opengrok-1.1-rc31.tar.gz | tar xz -C /home/yangye
    #wget -c https://github.com/oracle/opengrok/releases/download/1.1-rc31/opengrok-1.1-rc31.tar.gz -O - | tar xz -C /tmp
    cd /home/yangye/opengrok-1.1-rc31/bin
    sudo OPENGROK_TOMCAT_BASE=/var/lib/tomcat8 ./OpenGrok deploy
    start=$SECONDS
    time sudo OPENGROK_DISABLE_RENAMED_FILES_HISTORY=1 OPENGROK_TOMCAT_BASE=/var/lib/tomcat8 ./OpenGrok index "$abs_src" 
    end=$SECONDS
    duration=$(( end - start ))
    echo "runtime $duration seconds"
}

case "$1" in
    update) 
        update
        ;;
    repo) 
        get_git_repo
        ;;
    init)
        git_pro_create
        ;;
    tag)
        code_index
        ;;
    *)
        >&2 echo "invalid argument"
        usage && exit 1
        ;;
esac
