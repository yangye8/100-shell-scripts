#!/bin/bash

## Copyright (C) 2006-2015 Daniel Baumann <mail@daniel-baumann.ch>
##
## This program comes with ABSOLUTELY NO WARRANTY; for details see COPYING.
## This is free software, and you are welcome to redistribute it
## under certain conditions; see COPYING for details.

Netselect()
{
	if ! which netselect >/dev/null; then
		if [ ! -d netselect ];then
			git clone  -q https://github.com/apenwarr/netselect.git
			(cd netselect && make >/dev/null 2>&1 && make install >/dev/null 2>&1)
		fi
	fi
	netselect -s 2 http://mirrors.ustc.edu.cn/debian http://mirrors.163.com/debian
	rm -rf netselect
}
