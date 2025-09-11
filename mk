#!/bin/sh
#
# Make things (with or without make(1) being around)
#
# SPDX-License-Identifier: Unlicense
#
# Created: Mon 02 Aug 2021 18:04:22 EEST too (for pkexec-reboot)
# Created: Sat 11 Jun 2022 17:12:54 +0300 too (devdev.sh)
# Created: Sun 24 Aug 2025 23:08:33 +0300 too (from multitool-tmpl3s.sh)
# Last Modified: Sun 14 Sep 2025 19:54:31 +0300 too

case ${BASH_VERSION-} in *.*) set -o posix; shopt -s xpg_echo; esac
case ${ZSH_VERSION-} in *.*) emulate ksh; esac

set -euf  # hint: (z|ba|da|'')sh -x thisfile [args] to trace execution

die () { printf '%s\n' '' "$@" ''; exit 1; } >&2

x () { printf '+ %s\n' "$*" >&2; "$@"; }
x_bg () { printf '+ %s\n' "$*" >&2; "$@" & }
x_env () { printf '+ %s\n' "$*" >&2; env "$@"; }
x_eval () { printf '+ %s\n' "$*" >&2; eval "$*"; }
x_exec () { printf '+ %s\n' "$*" >&2; exec "$@"; exit not reached; }

if test "$0${1-}" = mk./.
then
	bn0=$2
	shift 2
else
	bn0=${0##*/}
fi

usage () { die "Usage: $bn0 $cmd $@"; }

cmds=


cmds=$cmds'
cmd_rpm  do the (noarch) rpm pkg (to build-rpms/)'
cmd_rpm ()
{
	export SOURCE_DATE_EPOCH=`git log -1 --format=%ct HEAD`
	exec ./rrpmbuild.pl -D _buildhost' 'buildhost -D _rpmdir' 'build-rpms \
		--target=noarch-meego-linux -bb device-ip.spec
}

cmds=$cmds'
cmd_ssht  make 1d persistent ssh tunnel (useful with tsync & run)...'
cmd_ssht ()
{
	test $# = 0 && usage "destination [user@host ...]" '' \
			     "MyWay; $bn0 ssht , defaultuser@192.168.2.15"
	echo Checking/creating persistent connection for $1
	set -x; z=`ssh -O check "$1" 2>&1` && {
	  ssh $1 -O exit to exit if so desired; exit
	} || case $z in 'Control socket connect'*) ;; *)
		printf '%s\n(in ~/.ssh/config)\n' "${z%?}"
		exit 1
	     esac
	z=${z%)*}; z=${z#*\(};
	test -e "$z" && rm "$z";
	shift
	exec ssh -oControlPath=$z -M -oControlPersist=1d "$@" date; date
}

appdir=/usr/share/device-ip

ssh_dest_usage () {
	usage	"${1+$1 }[ssh args] destination  (remember $bn0 ssht)" '' \
		"MyWay; $bn0 $cmd ${1+$1 },"

}

cmds=$cmds'
cmd_tsync  test-sync files to device, for testing dev versions'
cmd_tsync ()
{
	test $# = 0 && ssh_dest_usage
	x_exec ./tsync.pl "$*" $appdir qml/ device-ip.qml device-ip.py
}

cmds=$cmds'
cmd_tchwn  test-chown defaultuser files - for tsync'
cmd_tchwn ()
{
	test $# = 0 && ssh_dest_usage
	exec ssh -t "$@" \
	  'set -ex; cd '"$appdir"'; devel-su chown $LOGNAME `find . -type f`'
}

cmds=$cmds'
cmd_run  sailfish-qml device-ip on device '"('I': with invoker)"
cmd_run ()
{
	test "${1-}" = I && {
		shift
		mayinv='invoker -vv --single-instance --type=silica-qt5'
	} ||	mayinv=
	test $# = 0 && ssh_dest_usage '[I]'
	exec echo ssh -t "$@" $mayinv sailfish-qml device-ip
}

cmds=$cmds'
cmd_feh  run feh(1) to view (zoomed) image'
cmd_feh ()
{
	test $# -gt 1 || usage '(1-9) files...'
	case $1 in [1-9]) ;; *) die "'$1': not in [1-9] (zoom level)" ;; esac
	z=$1; shift
	for f
	do test -f "$f" || die "'$f': no such file"
	done
	# more opts? e.g. -B black (optionally?)
	x_exec feh --title='%wx%h %z %f' --zoom $z''00 --force-aliasing "$@"
}

cmds=$cmds'
cmd_cls  clear screen, stty sane'
cmd_cls ()
{
	printf '\033c'
	exec stty sane
}

cmds=$cmds'
cmd_clean  clean'
cmd_clean ()
{
	x_exec rm -rf build-rpms
}

# ---

ifs=$IFS; readonly ifs
IFS='
'
test $# = 0 && {
	echo
	echo Usage: $0 '{command} [args]'
	echo
	echo Commands " ($bn0 '..' cmd(pfx) to view source):"
	set -- $cmds
	IFS=' '
	echo
	for cmd
	do	set -- $cmd; cmd=${1#cmd_}; shift
		case $cmd in *_*) cmd=${cmd%_*}-${cmd#*_}; esac
		printf ' %-9s  %s\n' $cmd "$*"
	done
	echo
	echo Command can be abbreviated to any unambiguous prefix.
	echo
	exit 0
}
cm=$1; shift

case $#/$cm
in 1/..)
	set +x
	# $1 not sanitized but that should not be too much of a problem...
	exec sed -n "/^cmd_$1/,/^}/p; \${g;p}" "$0"
;; */..) cmd=..; usage cmd-prefix

;; */rpms) cm=rpm
#;; */d) cm=diff
#;; *-*-*) die "'$cm' with too many '-'s"
#;; *-*) cm=${cm%-*}_${cm#*-}
esac

cc= cp=
for m in $cmds
do
	m=${m%% *}; m=${m#cmd_}
	case $m in
		$cm) cp= cc=1 cmd=$cm; break ;;
		$cm*) cp=$cc; cc=$m${cc:+, $cc}; cmd=$m
	esac
done
IFS=$ifs

test "$cc" || die "$0: $cm -- command not found."
test "$cp" && die "$0: $cm -- ambiguous command: matches $cc."

unset cc cp cm
#set -x
cmd'_'$cmd "$@"
exit
