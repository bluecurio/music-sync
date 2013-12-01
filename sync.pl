#!/usr/bin/perl
# --------------------------------------------------------------------------
#
#  sync.pl - a script by drenfro to sync music to an android phone w/ssh/rsync
#
#
#
# TODO
# 
# - add a help/usage() method for when the script is run with no options
# - 
#
#
#

# Modules
use warnings;
use strict;
use File::Copy;
use File::Basename;
use Cwd;
use Getopt::Long;
use Pod::Usage;

# Global variables
our $help = 0;
our $playlist = "";
our $location = "";
our $replace = 1;
our $verbose = 0;

sub verbose {
	my $message = shift;
	if ( $verbose ) {
		print $message;
	}
}

# Parse things from the command-line
GetOptions(
	'p|playlist=s' => \$playlist,
	'l|location=s' => \$location,
	'r|replace!'   => \$replace,
	'v|verbose'    => \$verbose,
	'h|?|help'     => \$help,
);

if ( $help ) {
	pod2usage( 3 );
}
if ( !$playlist ) {
	print STDERR  "No --playlist given\n\n";
	pod2usage( 2 );
}
if ( !$location ) {
	print STDERR  "No --location given\n\n";
	pos2usage( 2 );
}
if ( !-e $playlist ) {
	print STDERR  "Bad path for --playlist\n\n";
	exit( 1 );
}
if ( !-e $location ) {
	print STDERR  "Bad path for --location\n\n";
	exit( 1 );
}
if ( !-d $location ) {
	print STDERR  "The --location path is not a directory\n\n";
	exit( 1 );
}
if ( !-w $location ) {
	print STDERR  "The --location path is not writable!\n\n";
	exit( 1 );
}

# Get the name of the playlist - it will be a directory 
my( $filename, $directories, $suffix ) = fileparse( $playlist );
my $directoryName = $filename;
$directoryName =~ s/\.[Mm]3[Uu]$//;

verbose( "Directory name will be \"$directoryName\"\n" );

# Check if we want to completely blow away the old directory for this playlist
my $directoryPath = $location . "/" . $directoryName;
if ( $replace ) {
	if ( -d $directoryPath ) {
		verbose( "Removing $directoryPath for replacement\n" );
		unlink( $directoryPath );
	}
}
else {
	verbose( "Not replacing $directoryPath\n" );
}

# Create a directory for this playlist
if ( ! -d $directoryPath ) {
	verbose( "Creating $directoryPath\n" );
	mkdir( $directoryPath );
}

# Do the actual copying
open( my $fh, '<', $playlist ) or die "Cannot read $playlist:$!";
while (<$fh>) {
	next if /^#/;
	chomp;
	copy( $_, $directoryPath ) or die "Copy failed: $!";

	if ( $verbose ) {
		verbose(
			sprintf( "%s --> %s\n", $_, $directoryPath . "/" . $_ )
		);
	}
	else {
		print $_ . "\n";
	}
}

close( $fh );

__END__

=head1 NAME

sync.pl - Copy files from a playlist to a location

=head1 SYNOPSIS

sync.pl [options] --playlist [path] --location [path]

 Options:
   -p, --playlist     The path to a *.m3u playlist
   -l, --location     Where to copy the files to
   -r, --replace      If a directory exists with the name of the playlist,
                       remove the directory first, essentially replacing it.
		               (On by default. Use --noreplace to turn off.)
   -h, --help         Show this help
   -v, --verbose      Be more verbose
