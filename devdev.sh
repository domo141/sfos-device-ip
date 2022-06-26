#!/bin/sh
#
# $ devdev.sh $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2022 Tomi Ollila
#	    All rights reserved
#
# Created: Mon 02 Aug 2021 18:04:22 EEST too (for pkexec-reboot)
# Created: Sat 11 Jun 2022 17:12:54 +0300 too
# Last modified: Mon 20 Jun 2022 23:04:53 +0300 too

# Note: Started with Makefile, but got "make: not found" (minimal deps FTW).
#       I would change emphasis of this script elsewhere but naming is hard...

# SPDX-License-Identifier: 0BSD


case ${BASH_VERSION-} in *.*) set -o posix; shopt -s xpg_echo; esac
case ${ZSH_VERSION-} in *.*) emulate ksh; esac

set -euf  # hint: sh -x thisfile [args] to trace execution

saved_IFS=$IFS; readonly saved_IFS

die () { printf '%s\n' '' "$@" ''; exit 1; } >&2
x () { printf '+ %s\n' "$*" >&2; "$@"; }
x_exec () { printf '+ %s\n' "$*" >&2; exec "$@"; }


if test $# = 0
then echo "
Develop on Device (and more)
----------------------------

Commands:

   links  -- /usr/share/test -> \$PWD     (uses devel-su)
             and device-ip-* -> qml/
   ulink  -- remove /usr/share/test      (uses devel-su)

   test   -- \"invoke\" sailfish-qml test  (run current code under development)

 grep devdev $0 ;: to see '('undocumented')' commands
"
 if test "${SSH_CONNECTION-}"
 then
	set -- $SSH_CONNECTION
	test $# = 4 || exit 0
	test "$4" != 22 && p=" -p $4" || p=
	d=${PWD#$HOME/}
	echo To access current directory, execute e.g. the following on remote:
	echo
	echo ' ' test -d mnt || mkdir mnt/
	echo ' ' sshfs$p $USER@$3:$d mnt/
	echo
 fi
 exit
fi

devdev_cmd_links ()
{
	lpwd=`readlink /usr/share/test` || :
	test "$lpwd" = "$PWD" || {
		echo Creating /usr/share/test using devel-su ...
		devel-su sh -xc "rm /usr/share/test
			test -e /usr/share/test && exit 1
			ln -s '$PWD' /usr/share/test"
	}
	test -d qml || {
		x rm -rf qml
		x mkdir qml
	}
	x ln -fs ../device-ip.qml qml/test.qml
	: > qml/this-dir-not-in-repo
	echo to test, execute
	echo '  ' $0 test
}

devdev_cmd_ulink ()
{
	echo
	if test -e qml
	then
		ls -lF qml/ | sed -e '/^total/d' -e 's/.* ..:.. /  .\/qml\//'
		printf '\n: left ./qml/ around; rm -rf ./qml/ ;: not done\n\n'
	fi
	test -L /usr/share/test && x devel-su rm -v /usr/share/test || :
}

devdev_cmd_test ()
{
	# hmm why this cd is needed..?
	bn0=${0##*/}
	test -f "$bn0" && test "$bn0" -ef "$0" || cd "${0%/*}"
	x_exec invoker --single-instance --type=silica-qt5 sailfish-qml test
	# interestingly ctrl-c over ssh connection does not exit application
}


devdev_cmd_sshp ()      # create persistent ssh connection...
{
	test $# -ge 4 || {
		case $0 in ./*) n=$0 ;; *) n=${0##*/} ;; esac
		rest='[[user]@]{host} [command [args]]'
		die "Usage: ${0##*/} $1 {name} {time}(s|m|h|d|w) $rest" \
		'' ": Hint; $n $1 .15 4h nemo@192.168.2.15 date; date" \
		'' ': Then; ssh .15 date; date'
	}
	echo "Checking/creating persistent connection lasting $2"
	z=`ssh -O check "$2" 2>&1` &&
	{ printf '%s\n%s\n' "$z" "(ssh $2 -O exit to exit)"; exit 0; } ||
	case $z in 'No ControlPath specified'*)
		echo $z
		exit 1
	esac
	z=${z%)*}; z=${z#*\(}
	test -e "$z" && rm "$z"
	so=-oControlPath=$z\ -M\ -oControlPersist=$3
	case $4 in @*) userathost=${4#?}
		;; *@*) userathost=$4
		;; *) userathost=nemo@$4
	esac
	shift 4
	echo ssh $so $userathost "$@" >&2
	TERM=xterm \
	exec ssh $so $userathost "$@"
	exit not reached
}

devdev_cmd_rpmbuild ()  # using podman / sailfishos-platform-sdk-aarch64
{
	test -f device-ip.spec
	test -d noarch || mkdir noarch
	script -ec 'set -x
	podman run --pull=never --rm -it --privileged -v $PWD:$PWD -w $PWD \
		sailfishos-platform-sdk-aarch64:latest sudo \
		rpmbuild --build-in-place -D "%_rpmdir $PWD" -bb device-ip.spec
	' noarch/typescript-rpmbuild
	set +f
	ls -l noarch/*
}

# -- rest are for icon development -- usually on desktop/laptop computer -- #

devdev_cmd_v ()         # view image file (scaled) using feh(1)
{
	fp=${2:-icon344.bmp}
	color=black
	#color=white
	wh=${3:-688}
	#wh=1032
	wxh=$wh''x''$wh
	x_exec feh --title='%w %f' -B $color --force-aliasing -s -Z -g $wxh $fp
}


devdev_cmd_pp ()        # postprocess to 86x86
{
	fp=${2-icon344.bmp}; fp=${fp%.*}
	test -f $fp.png && s=png || s=bmp
	op=${fp%344}86
	set -- `stat -c %Y $fp.$s $op.png` 0
	test "$1" -lt "$2" || {
		x convert $fp.$s -scale 86x86 $op-wip.png
		x optipng --strip all -o9 $op-wip.png
		x mv $op-wip.png $op.png
	}
	opts='-B blue'
	x_exec feh ${opts-} $op.png
}


de'vd'ev_cmd_$1 "$@"


# Local variables:
# mode: shell-script
# sh-basic-offset: 8
# tab-width: 8
# End:
# vi: set sw=8 ts=8
