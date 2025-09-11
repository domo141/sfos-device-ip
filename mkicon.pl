#!/usr/bin/perl
# -*- mode: cperl; cperl-indent-level: 4 -*-
# $ mkicon.pl $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2022 Tomi Ollila
#	    All rights reserved
#
# Created: Sun 15 Aug 2021 15:17:41 EEST too  (for pwpingen)
# Created: Fri 10 Jun 2022 00:48:21 EEST too
# Last modified: Sat 13 Sep 2025 16:27:01 +0300 too

use 5.8.1;
use strict;
use warnings;

# w/ constant, same ref is always returned. sub c () { [ ... ] } returns new...
use constant
{
 oooo  =>  [   0,   0,   0,   0 ],
 Black =>  [   0,   0,   0, 255 ],
 White =>  [ 205, 192, 176, 255 ],
 Orange => [ 230, 110,  60, 255 ]
#Orange => [ 240, 140,  70, 255 ]
};

# from /usr/share/X11/rgb.txt
#250 235 215             AntiqueWhite
#255 239 219             AntiqueWhite1
#238 223 204             AntiqueWhite2
#205 192 176             AntiqueWhite3
#139 131 120             AntiqueWhite4


my @pa; push @pa, [ (oooo) x 344 ] foreach (1..344);
#my @pa; push @pa, [ ([0,0,0,0]) x 344 ] foreach (1..344);

# test line: half-alpha black background (from full alpha)
#$pa[0][0][3] = 127; # works with (oooo) x 344 case

# while White is constant, the array behind ref can be modified (but don't :)
#my $x = White; $x->[2] = 0;

for my $r (1..128) {
    for (1..629) { # with 1 no sin nor cos get value of 1
	my $xd = int(cos($_/400) * $r);
	my $yd = int(sin($_/400) * $r);
	$pa[171 - $yd][171 - $xd] = Black;
	$pa[171 - $yd][172 + $xd] = Black;
	$pa[172 + $yd][171 - $xd] = Black;
	$pa[172 + $yd][172 + $xd] = Black;
    }
}

for my $r (128..170) {
    for (1..629) { # with 1 no sin nor cos get value of 1
	my $xd = int(cos($_/400) * $r);
	my $yd = int(sin($_/400) * $r);
	$pa[171 - $yd][171 - $xd] = Orange;
	$pa[171 - $yd][172 + $xd] = Orange;
	$pa[172 + $yd][171 - $xd] = Orange;
	$pa[172 + $yd][172 + $xd] = Orange;
    }
}

sub mpx4x4($$$)
{
    my ($l, $y) = ($_[0], $_[1]);

    for (split "\n", $_[2]) {
	my $x = $l;
	for (split '', $_) {
	    #print $_;
	    if ($_ eq 'x') {
		for(0..3) {
		    $pa[$y+$_][$x+0] = White; $pa[$y+$_][$x+1] = White;
		    $pa[$y+$_][$x+2] = White; $pa[$y+$_][$x+3] = White;
		}
	    }
	    $x += 4;
	}
	#print "\n";
	$y += 4;
    }
}

mpx4x4 100, 108, <<EOF;
xxxxxxxxxxxx    xxxxxxxxxxxxxxxx
xxxxxxxxxxxx    xxxxxxxxxxxxxxxx
xxxxxxxxxxxx    xxxxxxxxxxxxxxxx
xxxxxxxxxxxx    xxxxxxxxxxxxxxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxxxxxxxxxx
    xxxx            xxxxxxxxxxxx
    xxxx            xxxxxxxxxxxx
    xxxx            xxxxxxxxxxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
    xxxx            xxxx
xxxxxxxxxxxx    xxxxxxxxxxxx
xxxxxxxxxxxx    xxxxxxxxxxxx
xxxxxxxxxxxx    xxxxxxxxxxxx
xxxxxxxxxxxx    xxxxxxxxxxxx
EOF

for my $r (21..36) {
    for (1..629) { # with 1 no sin nor cos get value of 1
	my $xd = int(cos($_/400) * $r);
	my $yd = int(sin($_/400) * $r);
	$pa[143 - $yd][224 + $xd] = White;
	$pa[144 + $yd][224 + $xd] = White;
    }
}

open O, '>', 'icon344.wip';

my ($width, $height) = (344, 344);

my $size = $width * $height * 4;

# bmp header:        wh     s    rgba
print O pack 'ccVx4VVVVcxcxVVVVx8VVVVccccx48',
  0x42, 0x4d, 122 + $size, 122, 108, $width, $height, 1, 32, 3, $size,
  2835, 2835, 0xff, 0xff << 8, 0xff << 16, 0xff << 24, 0x20, 0x6e, 0x69, 0x57;

foreach (reverse @pa) {
    foreach (@$_) {
	print O pack 'CCCC', @$_;
    }
}
close O or die;

rename 'icon344.wip', 'icon344.bmp';
print "Wrote 'icon344.bmp' - continuing to create optimized 86x86 image...\n";

exec qw/sh -c/, <<'EOF'

set -euf
die () { printf '%s\n' "$@"; exit 1; } >&2
x () { printf '+ %s\n' "$*" >&2; "$@"; }
x_exec () { printf '+ %s\n' "$*" >&2; exec "$@"; }

for c in convert optipng
do command -v $c >/dev/null || die "'$c': command not found"
done

x convert icon344.bmp -scale 86x86 icon86-wip.png
#x pngquant -f -o "$ofile.wip" "$ifile"
x optipng --strip all -o9 icon86-wip.png
x mv icon86-wip.png icon86.png
x_exec ls -l icon86.png
EOF
