#!/usr/bin/env bash

# Runtime Environment
set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

all_num=10
thread_num=5

https://www.cnblogs.com/f-ck-need-u/p/7048359.html

a=$(date +%H%M%S)
seq 1 ${all_num} | xargs -n 1 -P ${thread_num} bash -c "sleep 10"
b=$(date +%H%M%S)
echo -e "startTime:\t$a"
echo -e "endTime:\t$b"
exit
# Check on Requirements
function require  {
	command -v "${1}" >/dev/null 2>&1 || e_error "$(printf "Program '%s' required, but it's not installed" "${1}")"
}

require xargs
require curl
require wget
require git

# Number of xargs processes to run in parallel
declare xargs_processes=0

if [ "$#" -eq 0 ]; then
	echo "Usage: "
	echo "$0 [cmd] <urls>"
	echo;
	echo "[cmd]"
	echo "curl -O"
	echo "git clone --depth 1"
	echo;
	echo "Parameters:"
	echo "<urls> File with base URLs"
	echo;
	exit 1
fi

# Formatting stuff
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_ORANGE=$(tput setaf 3)
readonly C_BLUE='\033[1;34m'
readonly NC='\033[0m' # No Color

# Error message and error exit, redirecting stdout to stderr
function e_error {
	echo -e >&2 "${C_RED}✘ Error:${NC} ${*-}";
	exit 1;
}

function e_info {
	echo -e "${C_BLUE}❱ Info:${NC} ${*-}"
}

function e_warning {
	echo -e "${C_ORANGE}❱ Warning:${NC} ${*-}"
}

function e_success () {
	echo -e "${C_GREEN}✔ Success:${NC} ${*-}"
}

tldr xargs

# Parameters for CMD with xargs.

declare -a xargs_arguments=()
xargs_arguments+=( -P ${xargs_processes} )
xargs_arguments+=( -I{} )
xargs_arguments+=( $1 )
xargs_arguments+=( {} )

echo
e_info "xargs ${xargs_arguments[@]} < " 
cat -n $2;echo;

e_info "starting..."
if ! xargs "${xargs_arguments[@]}" < "$2"; then
    e_error "exit.";
else
    e_success "Finished.";
fi
