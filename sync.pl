#!/usr/bin/perl
# --------------------------------------------------------------------------
#
#  sync.pl - a script by drenfro to sync music to an android phone w/ssh/rsync
#

# Modules
use warnings;
use strict;
use File::Copy;
use File::Spec;
use Env qw/ HOME /;
use Cwd;
use Getopt::Long;
use Pod::Usage;

# Are you suffering from buffering?
$| = 1;

# Global variables
our $help             = 0;
our $playlist         = "";
our $location         = "";
our $include_playlist = 1;
our $verbose          = 0;
our $debug            = 0;
our $replace          = 0;
our $path_to_music    = $ENV{'HOME'} . '/Music/iTunes/iTunes Music/';

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
	'i|include-playlist!'   => \$include_playlist,
    'm|music=s' => \$path_to_music,
	'r|replace!' => \$replace,
	'v|verbose'    => \$verbose,
	'h|?|help'     => \$help,
	'd|debug'      => \$debug,
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
else {
	if ( $location !~ /\/$/ ) {
		$location .= '/';
	}
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
if ( !-d $path_to_music ) {
	print STDERR "The local iTunes music path (\"$path_to_music\") is invalid!\n\n";
	exit( 1 );
}

# Debug means verbose, too.
$verbose = 1 if $debug;
verbose( "DEBUG MODE IS ON!\n" ) if $debug;
verbose( "Playlist is: $playlist\n" );
verbose( "Location is: $location\n" );
verbose( "Music can be found in: $path_to_music\n\n" );

# Handle the playlist file itself
my $playlistsDiretory = $location . '/playlists/';
my $playlistsDiretoryHandle;
if ( $include_playlist ) {

	# Create a place to put our playlist
	if ( ! -d $playlistsDiretory ) {
		verbose( "mkdir( $playlistsDiretory )\n" );
		if ( !-d $playlistsDiretory ) {
			mkdir $playlistsDiretory or die "mkdir failed: $!" unless $debug;
		}
		else {
			verbose( "Found $playlistsDiretory\n" );
		}
	}

	# Open a filehandle for writing our playlist
	my ( $root, $directories, $playlistFilename ) = File::Spec->splitpath( $playlist );
	my $playlistPath = $playlistsDiretory . '/' . $playlistFilename;
	verbose( "open( \$handle, '>', $playlistPath )\n" );
	open( $playlistsDiretoryHandle, '>', $playlistPath ) or die "Could not open file for writing: $!";
}

# The loop
my %directories_already_made;
open( my $fh, '<', $playlist ) or die "Cannot read $playlist:$!";
while (<$fh>) {

	# Skip comments, blank lines, etc.
	next if /^#/;
	next if /^$/;
	next if /^\s+$/;
	chomp;

	my $localPath = $_;
	my $subDirectory = $localPath;
	$subDirectory =~ s/^$path_to_music//;

	my ( $root, $directories, $filename ) = File::Spec->splitpath( $subDirectory );
	my @directories = ();
	if ( $directories ) {
		@directories = File::Spec->splitdir( $directories );
	}

	if ( !$replace ) {
		my $filePath = $location . $subDirectory;
		print $filePath . "\n";
		if ( -e $filePath ) {
			verbose( "Already found $filePath\n" );  
			next;
		}
	}

	my $path = $location;
	foreach my $directory ( @directories ) {
		next unless $directory;
		$path .=  "/$directory";
		if ( !exists $directories_already_made{ $path } ) {
			verbose( "Creating subdirectory...mkdir( $path )\n"  );
			if ( !-d $path ) {
				mkdir $path or die "mkdir failed: $!" unless $debug;
			}
			else {
				verbose( "Found $path\n" );
			}
			$directories_already_made{ $path } = 1;
		}
	}

	verbose( "copy( $localPath, $path )\n" );
	copy( $localPath, $path ) or die "Copy failed: $!" unless $debug;

	if ( $include_playlist ) {
		print $playlistsDiretoryHandle "$subDirectory/$filename\n";
	}

	print $filename . "\n";
	sleep 1 if $debug; # for realistic effect :)
}

close( $playlistsDiretoryHandle ) if $include_playlist;
close( $fh );

__END__

=head1 NAME

sync.pl - Copy files from a playlist to a location

=head1 SYNOPSIS

sync.pl [options] --playlist [path] --location [path]

 Options:
   -p, --playlist             The path to a *.m3u playlist
   -l, --location             Where to copy the files to
   -i, --include-playlist     Copy the playlist file to the playlists/ directory. (On by default)
   -m, --music                Path to the "iTunes Music" directory. Defaults to the one in the 
                              running user's $HOME. ($HOME/Music/iTunes/iTunes Music/)
   -r, --replace              Replace files, (Off by default to save resources.)

   -h, --help                 Show this help
   -v, --verbose              Be more verbose
   -d, --debug                Fake copying/etc.
