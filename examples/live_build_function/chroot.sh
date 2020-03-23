#!/bin/bash

Chroot ()
{
	CHROOT="${1}"; shift
	COMMANDS="${@}"

	# Executing commands in chroot
	Echo_message "Executing: %s" "${COMMANDS}"

	${_LINUX32} sudo chroot "${CHROOT}" /usr/bin/env -i HOME="/root" PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" TERM="${TERM}" DEBCONF_NONINTERACTIVE_SEEN="true" DEBCONF_NOWARNINGS="true" ${COMMANDS}

	return "${?}"
}
