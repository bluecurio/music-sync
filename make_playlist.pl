#!/usr/bin/perl -w

#--------------------------------------------------------
# make_playlist.pl - Creates a useable playlist of files
# 
# (1.) Export an iTunes playlist as an .m3u file
# (2.) Convert the Windows-style newlines to Mac with:
#      $ perl -pe 's/\r/\n/g' -i _______.m3u
# (3.) Create a new folder, cd into it
# (4.) Pipe the .m3u file to this script like this:
#      $ cat ________.m3u | make_playlist.pl
#-------------------------------------------------------

use strict;
use File::Copy;
use Cwd;

my $cwd = getcwd;

while (<>) {
	next if /^#/;
	chomp;
	copy( $_, $cwd ) or die "Copy failed: $!";
	print $_ . "\n";
}
