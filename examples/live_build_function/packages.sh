#!/bin/bash

Check_package ()
{
	PACKAGE="${1}"

	Check_installed "${PACKAGE}"

	case "${INSTALL_STATUS}" in
		1)
			Echo_error "You need to install %s (run \"sudo apt install %s\") on your host system." "${PACKAGE}" "${PACKAGE}"
			exit 1
			;;
	esac
}

Check_installed ()
{
	PACKAGE="${1}"

	if which dpkg-query > /dev/null 2>&1
	then
		if dpkg-query -s ${PACKAGE} 2> /dev/null | grep -qs "Status: install"
		then
			INSTALL_STATUS=0
		else
			INSTALL_STATUS=1
		fi
	fi
}

Image_installer()
{
if ! which etcher-electron >/dev/null; then
	#https://github.com/resin-io/etcher
	echo "deb https://dl.bintray.com/resin-io/debian stable etcher" | sudo tee /etc/apt/sources.list.d/etcher.list
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
	sudo apt-get update
	echo y | sudo apt-get install etcher-electron
fi
etcher-electron
}
