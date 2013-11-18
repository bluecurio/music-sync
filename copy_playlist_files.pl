#!/usr/bin/perl -w

# Modules
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

sub error {
	my ( $error, $retval ) = @_;
	print STDERR $error . "\n";
	exit( $retval );
}

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
	pod2usage( 1 );
}
if ( !$playlist ) {
	error( "No --playlist given", 1 );
}
if ( !$location ) {
	error( "No --location given", 1 );
}
if ( !-e $playlist ) {
	error( "Bad path for --playlist", 1 );
}
if ( !-e $location ) {
	error( "Bad path for --location", 1 );
}
if ( !-d $location ) {
	error( "The --location path is not a directory", 1 );
}
if ( !-w $location ) {
	error( "The --location path is not writable!", 1 );
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

copy_playlist_files.pl - Copy files from a playlist to a location

=head1 SYNOPSIS

copy_playlist_files.pl [options] --playlist [path] --location [path]

 Options:
   -p, --playlist     The path to a *.m3u playlist
   -l, --location     Where to copy the files to
   -r, --replace      If a directory exists with the name of the playlist,
                       remove the directory first, essentially replacing it.
		               (On by default. Use --noreplace to turn off.)
   -h, --help         Show this help
   -v, --verbose      Be more verbose
