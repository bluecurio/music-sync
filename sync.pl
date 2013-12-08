#!/usr/bin/perl
# --------------------------------------------------------------------------
#
#  sync.pl - a script by drenfro to sync music to an android phone w/ssh/rsync
#

# Modules
use 5.012;     # So readdir assigns $_ in a lone while test
use warnings;
use strict;
use File::Copy;
use File::Spec;
use Env qw/ HOME /;
use Cwd;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

# Are you suffering from buffering?
$| = 1;

# Global variables
our $help              = 0;
our $playlist          = "";
our $directory_to_copy = "";
our $location          = "";
our $include_playlist  = 1;
our $verbose           = 0;
our $debug             = 0;
our $replace           = 0;
our $path_to_music     = $ENV{'HOME'} . '/Music/iTunes/iTunes Music/';

sub verbose {
	my $message = shift;
	if ( $verbose ) {
		print $message;
	}
}

# Parse things from the command-line
GetOptions(
	'p|playlist=s'        => \$playlist,
	'l|location=s'        => \$location,
	'd|directory=s'       => \$directory_to_copy,
	'i|include-playlist!' => \$include_playlist,
    'm|music=s'           => \$path_to_music,
	'r|replace!'          => \$replace,
	'v|verbose'           => \$verbose,
	'h|?|help'            => \$help,
	'D|debug'             => \$debug,
);

if ( $help ) {
	pod2usage( 3 );
}
if ( !$playlist && !$directory_to_copy ) {
	print STDERR  "No --playlist or --directory given\n\n";
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
if ( $playlist && $directory_to_copy ) {
	print STDERR "Please set --playlist or --directory, but not both\n\n";
	pod2usage( 2 );
}
if ( $playlist && !-e $playlist ) {
	print STDERR  "Bad path for --playlist\n\n";
	exit( 1 );
}
if ( $directory_to_copy ) {
	if ( !-d $directory_to_copy ) {
		print STDERR "The path for --directory is not a directory\n\n";
		exit( 1 );
	}
	if ( !-R $directory_to_copy ) {
		print STDERR "The path for --directory is not a readable\n\n";
		exit( 1 );
	}
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
verbose( "Playlist is: $playlist\n" ) if $playlist;
verbose( "Directory is: $directory_to_copy\n" ) if $directory_to_copy;
verbose( "Location is: $location\n" );
verbose( "Music can be found in: $path_to_music\n" );

# Handle the playlist file itself
my $playlistsDiretoryHandle;
if ( $playlist ) {
	my $playlistsDiretory = $location . '/playlists/';
	if ( $include_playlist && !$debug ) {

		# Create a place to put our playlist
		if ( ! -d $playlistsDiretory ) {
			verbose( "Creating playlist directory...$playlistsDiretory\n" );
			if ( !-d $playlistsDiretory ) {
				mkdir $playlistsDiretory or die "mkdir failed: $!" unless $debug;
			}
			else {
				verbose( "Found playlist directory...$playlistsDiretory\n" );
			}
		}

		# Open a filehandle for writing our playlist
		my ( $root, $directories, $playlistFilename ) = File::Spec->splitpath( $playlist );
		my $playlistPath = $playlistsDiretory . '/' . $playlistFilename;
		open( $playlistsDiretoryHandle, '>', $playlistPath ) or die "Could not open file for writing: $!";

		# Don't buffer the playlist stream
		select $playlistsDiretoryHandle;
		$| = 1;
		select STDOUT;
	}
}

# The list of files to copy over, including directory structure
my @files_to_copy = ();
if ( $playlist ) {
	open( my $fh, '<', $playlist ) or die "Cannot read $playlist:$!";
	while ( <$fh> ) {
		# Skip comments, blank lines, etc.
		next if /^#/;
		next if /^$/;
		next if /^\s+$/;
		push @files_to_copy, $_;
	}
	close( $fh );
}
if ( $directory_to_copy ) {
	opendir( my $dh, $directory_to_copy );
	while ( readdir $dh ) {
		next if /^\./;
		my $path = "$directory_to_copy/$_";
		next if !-f $path;
		push @files_to_copy, $path;
	}
	close( $dh );
}

# The loop
my %directories_already_made;
foreach my $_ ( @files_to_copy ) {
	chomp;

	# The line from the playlist, a path to our local file
	my $localPath = $_;

	# The path structure that we need to mirror on the device
	my $subDirectory = $localPath;
	$subDirectory =~ s/^$path_to_music//;

	# Break up the directory structure into managable pieces
	my ( $root, $directories, $filename ) = File::Spec->splitpath( $subDirectory );
	my @directories = ();
	if ( $directories ) {
		@directories = File::Spec->splitdir( $directories );
	}

	# The path to the mirrored directory structure
	my $filePath = $location . $subDirectory;

	# Helps find files when the cache is stale or over SSHFS/SMB
	#my  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $filePath;
	stat $filePath;

	if ( !-e $filePath || $replace ) {
		my $path = $location;
		foreach my $directory ( @directories ) {
			next unless $directory;
			$path .=  "/$directory";
			if ( !exists $directories_already_made{ $path } ) {
				if ( !-d $path ) {
					verbose( "Creating subdirectory...$path\n"  );
					mkdir $path or die "mkdir failed: $!" unless $debug;
				}
				$directories_already_made{ $path } = 1;
			}
		}
		verbose( "Coping $localPath to $path\n" );
		copy( $localPath, $path ) or die "Copy failed: $!" unless $debug;
		print "Copied $subDirectory\n";
	}
	else {
		print "Found $subDirectory\n";
	}
	if ( !$debug && $playlist && $include_playlist ) {
		my $line = "../$subDirectory";
		print $playlistsDiretoryHandle "$line\n";
	}
	sleep 1 if $debug; # for realistic effect :)
}

close( $playlistsDiretoryHandle ) if $playlist && $include_playlist;

__END__

=head1 NAME

sync.pl - Copy files from a playlist to a location

=head1 SYNOPSIS

sync.pl [options] --playlist [path] --location [path]

 Options:
   -p, --playlist             The path to a *.m3u playlist
   -d, --directory            A directory to copy over
   -l, --location             Where to copy the files to

   -i, --include-playlist     Copy the playlist file to the playlists/ directory. (On by default)
   -m, --music                Path to the "iTunes Music" directory. Defaults to the one in the 
                              running user's $HOME. ($HOME/Music/iTunes/iTunes Music/)
   -r, --replace              Replace files, (Off by default to save resources.)

   -h, --help                 Show this help
   -v, --verbose              Be more verbose
   -D, --debug                Fake copying/etc.
