#! /usr/bin/perl

# Bookshelf CMS is Copyright 2017 WereBooks Limited, and licensed for public use via the Apache License, Version 2.0
# See: https://opensource.org/licenses/Apache-2.0 for the terms, or the project license file: https://github.com/WereBooks/BookshelfCMS_Alpha/blob/master/LICENSE
# Replace "yoursite and yoursite.org" with your site and info
use lib './';
use strict;
use POSIX;
use Getopt::Long;
use BookshelfCMSLibrarian;
use JSON;
use Roman;

my $usage = "BookshelfCMS requires at least the name of a file to format. \nPass directories or filenames to import \n--help for this message, or --version to get the current version";
if ( $#ARGV < 0 ){
	die "$usage";
}

my($help, $ver, $inpath);
GetOptions(
	"help|?"			=> \$help,
	"version|about|V"	=> \$ver,
);
if( defined($ver)  ){ version(); exit; }
if( defined($help) ){ print "$usage\n" ; exit; }

my %result = loadLibrary();
if ( $result{'version'} eq "" ){ die( "Library issue: $!"); }

# Set these values as required for the site
setSiteroot('https://yoursite.org/');
setTwitter('@yoursite');
setSite('yoursite');
setLogo('yourlogo.svg');
setSitecopy('<figure><a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img class="logo" alt="Creative Commons License" src="https://yoursite.org/images/cc-by-sa.svg" width="80"></a>
</figure><p><a property="cc:attributionName" href="https://yoursite.org">yoursite.org Editions</a><br>are licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.');
setStylepath('css/');
setImagepath('images/');
useIndex(1);

# Get the config and prepare the filesystem to write out our chapter
foreach my $dir ( @ARGV ){
	#print "Is $dir a directory or a file?\n";
	if( -d $dir ){
		opendir( INDIR, $dir ) or die "Cannot open $dir: $!\n";
		my @files = readdir( INDIR );
		my $file;
		closedir( INDIR );
		# Process the actual files first to get things like style/image/author paths etc
		foreach $file ( sort(@files) ){
			my $path = File::Spec->catfile($dir, $file);
			if( -d $path ){ next; }
			elsif( $file =~ m/txt|html/ ){				
				print "Importing $path\n";
				if( !initChapter($path) ){ die "Unable to create chapter: $!"; }
				#writeChapter($path);
			}
		}
		foreach $file ( @files ){
			my $path = File::Spec->catfile($dir, $file);
			if( -d $path ){ next; }
			elsif( $file =~ m/txt|html/ ){				
				print "Writing $path\n";
				writeChapter($path);
			}
		}
		foreach $file ( @files ){
			# This will pass files and directories to moveFile if they are the right sort
			my $path = File::Spec->catfile($dir, $file);
			if( $file =~ m/.jpg|.gif|.png|.svg|css|image|style/ ){
				if( -d $path ){ moveDir($path); }
				else{ moveFile($dir, $file); }
			}
		}
	}
	else{
		foreach( sort(@ARGV) ){
			print "Processing $_\n";
			if( !initChapter($_) ){ die "Unable to create chapter: $!"; }
		}
		foreach( @ARGV ){
			print "Writing $_\n";
			writeChapter($_);
		}
		foreach ( @ARGV ){
			# This will pass files and directories to moveFile if they are the right sort
			my $path = File::Spec->catfile($dir, $_);
			if( $_ =~ m/.jpg|.gif|.png|.svg|css|image|style/ ){
				if( -d $path ){ moveDir($path); }
				else{ moveFile($dir, $_); }
			}
		}
	}

}

	
if( writeBook() ){ print "Site written\n"; }
if( !writeAuthor() ){ die( "Unable to update the author site: $!"); }
if( !updateLibrary() ){ die( "Unable to save changes to library: $!"); }


