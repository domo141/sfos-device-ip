#!/usr/bin/perl
# -*- mode: cperl; cperl-indent-level: 4 -*-
# $ tsync.pl - sync files for test purposes - not extensively verified... $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
# Created: Thu 17 Jul 2025 19:09:49 EEST too
# Last modified: Sat 19 Jul 2025 17:30:21 +0300 too

# SPDX-License-Identifier: BSD 2-Clause "Simplified" License

use 5.8.1;
use strict;
use warnings;

die "Usage: $0 'ssh-cmdline' rdir files [xdir/ files [xdir/ files]...]\n"
  unless @ARGV >= 3;

my $ssh = shift;
my $rdir = shift;
die qq[$0: char ' in "$rdir"\n] if index($rdir, "'") >= 0;

my (@sfiles, @tfiles);
my $cdir = '';

foreach (@ARGV) {
    print("Skipping '$_'...\n"), next if /^#/;
    die "$0: unexpected chars in '$_'\n" if /[ \0-$ &-* ;<>? [-^ ` {-~ ]/x;
    $cdir = $_, next if /\/$/;
    if (-f $_) {
	die "File '$_' too large\n" if -s $_ > 1024 * 1024;
	die "File '$_' unreadable\n" unless -r $_;
	push @sfiles, $_;
	s:.*/::;
	$_ = $cdir . $_;
	die "Filename '$_' too long\n" if length > 99; #0ld tar format easiest
	push @tfiles, $_;
	next
    }
    print "'$_': no such source file - skipping\n"
}

#print "s $_\n" foreach (@sfiles);
#print "t $_\n" foreach (@tfiles);

my @tsums;
# note: needs /bin/sh style shell on remote; w/o set -euf; may work on [t]csh
open P, '-|', 'ssh', (split ' ', $ssh), "set -euf
echo USER: \$USER; cd '$rdir'; stat -c stat:%F:%U:%n @tfiles
exec md5sum @tfiles" or die $!;

my $ruser;
while (<P>) {
    next unless /^USER:\s+(\S+)/;
    $ruser = $1;
    last
}
my $e = 0;
while (<P>) {
    if (/^stat:(.*?):(.*?):(.*)/) {
	$e = 1, warn "'$3' is not 'regular file' (is '$1')\n"
	  if $1 ne 'regular file';
	$e = 1, warn "'$3' is not owned by $ruser (owner is $2)\n"
	  if $2 ne $ruser;
	next
    }
    last
}
exit 1 if $e;
my %hash;
do {
    my ($sum, $file) = split ' ', $_, 3; # 3 (instead of 2) for no chomp.
    $hash{$file} = $sum
} while (<P>);
close P;

foreach (@tfiles) {
    $e = 1, warn "file '$_' not found in remote\n" unless $hash{$_}
}
exit 1 if $e;

open P, '-|', 'md5sum', @sfiles or die $!;
$e = 0;
while (<P>) {
    my ($sum, $file) = split ' ', $_, 3; # 3 (instead of 2) for no chomp.
    if ($sum eq $hash{$tfiles[$e]}) {
	print "'$tfiles[$e]' ($file) not modified: copy skipped\n";
	$tfiles[$e] = ''
    }
    $e++;
}
close P;

$e = 0;
for (@tfiles) {
    #print "x $_\n";
    $e++ if $_;
}
print("No files to copy (all files up to date).\n"), exit 0 if $e == 0;
print "Copying...\n";
open P, '|-', 'ssh', (split ' ', $ssh),
  "set -euf; cd '$rdir'; tar --overwrite -xvvf -" or die $!;

$e = 0;
for (@tfiles) {
    $e++, next unless $_;
    my $sfile = $sfiles[$e++];
    my @st = stat $sfile;
    warn("stat '$sfile' failed: $!\n"), next unless @st;
    # do old style tar header #
    my $name = pack('a100', $_);
    my $mode = sprintf("%07o\0", $st[2]);
    my $uid = sprintf("%07o\0", 0);
    my $gid = sprintf("%07o\0", 0);
    my $size = sprintf("%011o\0", $st[7]);
    my $mtime = sprintf("%011o\0", $st[9]);
    my $checksum = '        ';
    my $pad = pack('a356', '');
    my $hdr;
    $hdr = join '', $name, $mode, $uid, $gid, $size, $mtime, $checksum, $pad;

    my $sum = 0;
    foreach (split //, $hdr) {
	$sum = $sum + ord $_;
    }
    $checksum = sprintf "%06o\0 ", $sum;
    $hdr = join '', $name, $mode, $uid, $gid, $size, $mtime, $checksum, $pad;
    open I, '<', $sfile or die $!;
    read I, $_, $st[7];
    $pad = (511 & length) ? ("\0" x (512 - (511 & length))): '';
    close I;
    die "Could not read $st[7] bytes of '$sfile'\n" unless length == $st[7];
    print P $hdr, $_, $pad;
}
print P "\0" x 1024;
close P or die $!;
