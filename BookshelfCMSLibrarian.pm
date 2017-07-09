package BookshelfCMSLibrarian;

# Bookshelf CMS is Copyright 2017 WereBooks Limited, and licensed for public use via the Apache License, Version 2.0
# See: https://opensource.org/licenses/Apache-2.0 for the terms, or the project license file: https://github.com/WereBooks/BookshelfCMS_Alpha/blob/master/LICENSE
# Replace "yoursite" and "yoursite.org" with your site
use strict;
use Exporter qw(import);
use POSIX qw(strftime);
use JSON;
use File::Path qw(mkpath);
use File::Spec;
use File::Copy;
use Template;
use Data::Dumper;

# Maintains a JSON 'database' for the entire site structure and provides hooks for the bookshelf-cms.pl

our $VERSION	= "0.00.01";
our @ISA		= qw(Exporter);
our @EXPORT		= qw(version debug libfile status author title subtitle chapter loadLibrary updateLibrary initChapter writeChapter writeBook writeAuthor getHTML getHeader getFooter setSiteroot setSite setSitecopy setLogo setImagepath setStylepath getStylesheet getMetadata getType getAuthor getTitle getSubtitle getChapter getSubchapter getDivider getGenre1 getGenre2 getGenre3 getGenre4 getRelated getFiction getCopyright getBlurb setTwitter useIndex moveFile moveDir);

# Semi-private vars
our $_date			= strftime "%Y-%m-%d", localtime;
our $_debug			= 'OFF';
our $_libfile		= 'BookshelfCMS-library.json';		
our $_status		= '';
our $_siteroot		= 'https://';
our $_site			= 'Default Site';
our $_logo			= 'logo.png';
our $_sitecopy		= "All text and graphics on this site are Copyright &copy; $_site";
our $_stylepath		= 'css/';
our $_imagepath		= 'images/';
our $_rootstyle		= $_siteroot . $_stylepath . 'yoursite-core.css';
our $_stylesheet	= $_stylepath . 'book.css';
our $_metadata		= '';
our $_metabook		= '';
our $_type			= 'book';
our $_author		= 'default-author';
our $_about			= 'author bio';
our $_authorport	= 'author.png';
our $_twitter		= '@handle';
our $_cover         = 'cover.png';
our $_title			= 'default-book';
our $_subtitle		= '';
our $_chapter		= '1';
our $_chapname		= 'Chapter 1';
our $_subchapter	= '';
our $_divider		= '';
our $_genre1		= 'Adventure';
our $_genre2		= '';
our $_genre3		= '';
our $_genre4		= '';
our $_fiction		= 1; #0 is false, non-zero is true
our @_related		= qw(default-author default-author2);
our $_maxlatest		= 3;
our $_blurb			= '';
our $_useindex		= '1';
our $_copyright;
our %_library;
our %_config;
our %_book;



#print "bookshelf-cms-librarian.pm version: $VERSION\n";

# Blocks
sub debug			{ $_debug		= uc($_[0]);	printf "DEBUG set to $_debug\n"; 			return $_debug;		}
sub libfile			{ $_libfile		= $_[0];		printf "Libfile set to $_libfile\n";		return $_libfile;	}
sub version			{ printf "BookshelfCMS Version: $VERSION\n";								return $VERSION;	}
sub status			{ printf "Status: $_status\n";												return $_status;	}
sub setSite			{ $_site		= $_[0];		printf "Site set to $_site\n";				return $_site;		}
sub setLogo			{ $_logo		= $_[0];		printf "Logo set to $_logo\n";				return $_logo;		}
sub setSitecopy		{ $_sitecopy	= $_[0];		printf "Site Copyright set to $_sitecopy\n";return $_sitecopy;	}
sub setSiteroot		{ $_siteroot	= $_[0];		printf "Site Root set to $_siteroot\n";		return $_siteroot;	}
sub setStylepath	{ $_stylepath	= $_[0];		printf "Stylepath set to $_stylepath\n";	return $_stylepath;	}
sub setImagepath	{ $_imagepath	= $_[0];		printf "Imagepath set to $_imagepath\n";	return $_imagepath;	}
sub setTwitter		{ $_twitter		= $_[0];		printf "Twitter set to $_twitter\n";		return $_twitter;	}
sub useIndex		{ $_useindex	= $_[0];		printf "Use Index set to $_useindex\n";		return $_useindex;	}
sub getRootstyle	{ return $_rootstyle; 	}
sub getStylesheet	{ return $_stylesheet; 	}
sub getMetadata		{ return $_metadata; 	}
sub getType			{ return $_type; 		}
sub getAuthor		{ return $_author; 		}
sub getTitle		{ return $_title; 		}
sub getSubtitle		{ return $_subtitle; 	}
sub getChapter		{ return $_chapter; 	}
sub getSubchapter	{ return $_subchapter; 	}
sub getDivider		{ return $_divider; 	}
sub getGenre1		{ return $_genre1; 		}
sub getGenre2		{ return $_genre2; 		}
sub getGenre3		{ return $_genre3; 		}
sub getGenre4		{ return $_genre4; 		}
sub getRelated		{ return @_related; 	}
sub getFiction		{ return $_fiction; 	}
sub getCopyright	{ return $_copyright; 	}
sub getBlurb		{ return $_blurb; 		}



sub initChapter {
	my $__bookfile = @_[0];
	open my $__fh, '<', $__bookfile or die "Error opening file $__bookfile: $!";	
	# Grab the JSON config from the 1st line
	readConfig( <$__fh> );
	close $__fh;
	
	# Doing a concat so that we can, theoretically, handle unix or windows output paths. Also different if useindex: chapter-1.html or chapter-1/index.html
	if( $_useindex == 1 ){
	    my $__path;
		if( $_config{'book'}{'chapter'} =~ /^[+-]?\d+$/ ){
			$__path = File::Spec->catfile($_config{'book'}{'url'}, "chapter-$_config{'book'}{'chapter'}");
			$_config{'book'}{'current'}{'filename'} = File::Spec->catfile($__path, "index.html");
			$_config{'book'}{'current'}{'url'} = "$__path/";
			#print "Path = $__path\n";
		}
		else{ 
			$__path = File::Spec->catfile($_config{'book'}{'url'}, "$_config{'book'}{'chapter'}");
			$_config{'book'}{'current'}{'filename'}  = File::Spec->catfile($__path, "index.html");
			$_config{'book'}{'current'}{'url'} = "$__path/";
			#print "Path = $_config{'book'}{'url'} \n";
		}
		$_book{'chapters'}{$_config{'book'}{'order'}}{'url'} = $_config{'book'}{'current'}{'url'};
		$_book{'chapters'}{$_config{'book'}{'order'}}{'chapname'} = $_config{'book'}{'chapname'};
		$_book{'chapters'}{$_config{'book'}{'order'}}{'subchapter'} = $_config{'book'}{'subchapter'}; 
		
		
		
		# If the path doesn't exist, try to create it
		
		if( -d $__path ){ return 1; }
		else{ mkpath $__path or die "Unable to create book directory $__path: $!"; }
	}
	else{  
		if( $_config{'book'}{'chapter'} =~ /^[+-]?\d+$/ ){ $_config{'book'}{'current'}{'filename'} = File::Spec->catfile($_config{'book'}{'url'}, "chapter-$_config{'book'}{'chapter'}.html");}
		else{ $_config{'book'}{'current'}{'filename'} = File::Spec->catfile($_config{'book'}{'url'}, "$_config{'book'}{'chapter'}.html"); }
		
		$_book{'chapters'}{$_config{'book'}{'order'}}{'url'} = $_config{'book'}{'current'}{'filename'};
		$_config{'book'}{'current'}{'url'} = $_config{'book'}{'current'}{'filename'};
		$_book{'chapters'}{$_config{'book'}{'order'}}{'chapname'} = $_config{'book'}{'chapname'};
		
		# If the path doesn't exist, try to create it
		if( -d $_config{'book'}{'url'} ){ return 1; }
		else{ mkpath $_config{'book'}{'url'} or die "Unable to create book directory $_config{'book'}{'url'}: $!"; }
	}
	return \%_config;
}

sub moveDir {
	opendir( INDIR, @_[0] ) or die "Cannot open directory @_[0]: $!\n";
	my @__files = readdir( INDIR );
	my $__file;
	closedir( INDIR );
	foreach $__file ( @__files ){ moveFile(@_[0], $__file); }
}

sub moveFile {
	# Check to see if we're passed a file or a directory reference
	my $__input = File::Spec->catfile(@_[0], @_[1]);
	if( -d $__input ){ return; } 
	
	my $__newurl = "./";
	if( $_config{'book'}{'url'} ne "" ){ $__newurl = $_config{'book'}{'url'}; }
	else{ $__newurl = $_config{'author'}{'url'}; }
	
	my ($__output, $__path);
	if( lc($__input) =~ m/png|gif|jpg/ ){
		$__path = File::Spec->catfile($__newurl, $_config{'imagepath'});
		$__output = File::Spec->catfile($__path, @_[1]);
		if( -d $__path ){} 
		else{ mkpath $__path or die "Unable to create image directory $__path: $!"; }
	}
	elsif( lc($__input) =~ m/css/ ){
		$__path = File::Spec->catfile($__newurl, $_config{'stylepath'});
		$__output = File::Spec->catfile($__path, @_[1]);
		if( -d $__path ){} 
		else{ mkpath $__path or die "Unable to create image directory $__path: $!"; }
	}
	copy $__input, $__output or die "Unable to copy $__input to $__output: $!"; 
	print "$__input -> to $__output\n";
}

sub writeChapter {
	my $__bookfile = @_[0];
	my $__body;
	# Confirm we can read the file and file config
	initChapter($__bookfile);
	
	# Make sure this is actually a chapter page, not an author page or something
	if( $_config{'type'} eq 'author' ){ print "Skipping writeChapter, this is type $_config{'type'}\n"; return(); }
	
	open my $__fh, '<', $__bookfile or die "Error opening file $__bookfile: $!";
	<$__fh>;
	while (<$__fh>){
		my $__story = getHTML($_);
		#print $__story;
		$__body = $__body . $__story;
	}
	
	$_config{'book'}{'body'} = $__body;
	my @__teaser = split/<\!-- TEASER_END -->/,$_config{'book'}{'body'};
	# Seems to be slightly faster than doing a =~ with discard
	$_book{'chapters'}{$_config{'book'}{'order'}}{'teaser'} =  $__teaser[0];
	if( $__teaser[1] ne "" ){ $_book{'chapters'}{$_config{'book'}{'order'}}{'more'} = 1;} 
	$_book{'front'}{'url'} = $_book{'chapters'}{'0'}{'url'};
	
	# Cheesy hack for it not allowing me to use $__order -1 inside the ref
	my $__order = $_config{'book'}{'order'} -1;
	
	if( defined $_book{'chapters'}{$__order} ){ 
		$_config{'book'}{'prev'}{'url'} 		= $_book{'chapters'}{$__order}{'url'};
		$_config{'book'}{'prev'}{'chapname'} 	= $_book{'chapters'}{$__order}{'chapname'};
	}
	else{
		$_config{'book'}{'prev'}{'url'}  		= $_config{'book'}{'url'};
		$_config{'book'}{'prev'}{'chapname'} 	= $_config{'book'}{'title'};
	}

	$__order = $_config{'book'}{'order'} +1;
	if( defined $_book{'chapters'}{$__order} ){ 
		$_config{'book'}{'next'}{'url'} 		= $_book{'chapters'}{$__order}{'url'};
		$_config{'book'}{'next'}{'chapname'} 	= $_book{'chapters'}{$__order}{'chapname'};
	}
	else{
		$_config{'book'}{'next'}{'url'}  		= $_config{'author'}{'url'};
		$_config{'book'}{'next'}{'chapname'} 	= $_config{'author'}{'Author page'};
	}
	
	#print "Order = $_config{'book'}{'order'}, Next = $_config{'book'}{'next'}{'url'}, prev = $_config{'book'}{'prev'}{'url'}\n";
	
	# Stylesheet is presumed to be book relative, so if it's not canonical, we need to go up a level
	my $__style;
	if( $_config{'stylesheet'} =~ m/$_siteroot/ ){ $__style = $_config{'stylesheet'}; }
	else{ $__style = "../$_config{'stylesheet'}"; }
	
	my $__template = Template->new();
	my $__vars = { config => \%_config, book => \%_book, library => \%_library, date => $_date, style => $__style };
	
	print "Writing: $_config{'book'}{'current'}{'filename'} with template $_type.tmpl\n";
	$__template->process("$_type.tmpl", $__vars, $_config{'book'}{'current'}{'filename'}) || die $__template->error();
	#print Dumper $_book{'chapters'};
}

sub writeBook {
	# Make sure this is actually a chapter page, not an author page or something
	if( $_config{'type'} eq 'author' ){ print "Skipping writeBook, this is type $_config{'type'}\n"; return; }
	
	my $__bookfile = File::Spec->catfile($_config{'book'}{'url'},"index.html");
	print "Now looping through chapters to print main book site\n";
	
	#print Dumper $_book{'chapters'};
	# Setting up Next/Prev to go to the right spots
	$_config{'book'}{'next'}{'url'} 		= $_book{'chapters'}{'0'}{'url'};
	$_config{'book'}{'next'}{'chapname'} 	= $_config{'book'}{'title'};
	$_config{'book'}{'prev'}{'url'}  		= $_config{'author'}{'url'};
	$_config{'book'}{'prev'}{'chapname'} 	= "Author Page";
	$_config{'book'}{'copyright'}			= $_copyright;
	
	# Stylesheet is presumed to be book relative
	my $__style = $_config{'stylesheet'};

	my $__template = Template->new();
	my $__vars = { config => \%_config, book => \%_book, library => \%_library, date => $_date, style => $__style };
	print "Writing to book: $__bookfile\n";
	$__template->process("book.tmpl", $__vars, $__bookfile) || die $__template->error();
	
	# Update author page is done from the calling script
	# 
}

sub writeAuthor {
	updateLibrary();
	my $__authorfile = File::Spec->catfile($_config{'author'}{'url'},"index.html");
	print "Now updating main author site\n";
	print Dumper $_library{$_author};
	
	# Stylesheet is presumed to be relative
	print "Style = $_config{'stylesheet'}, author style = $_library{$_author}{'stylesheet'}\n";
	my $__style = $_library{$_author}{'stylesheet'};
	my %__genres;
	my @__titles = keys %{$_library{$_author}{'books'}};
	foreach ( @__titles ){ $__genres{$_library{$_author}{'books'}{$_}{'genre1'}}{$_} = $_; }
	#print Dumper %__genres;

	my $__template = Template->new();
	my $__vars = { config => \%_config, author => \%{$_library{$_author}}, genres=> \%__genres, library => \%_library, date => $_date, style => $__style };
	print "Writing to author site: $__authorfile\n";
	$__template->process("author.tmpl", $__vars, $__authorfile) || die $__template->error();
}

sub getHTML {
	# Skip lines wrapped in HTML tags
	if( $_ =~ m/^</ ){}
	else{ s/^/<p>/g; }
	if( $_ =~ m/\r/ ){ s/\r/<\/p>/g; }
	elsif( $_ =~ m/^*>$/ ){}
	else{ s/$/<\/p>/g; }
	# Remove a </html> tag, since we close it ourselves
	s/<\/html>//g;
	s/<\/p>\n<\/p>/<\/p>\n/g;
	s/\`/'/g;
	s/\‘/'/g;
	s/\’/'/g;
	s/  / /g;
	
	# Clean up empty paragraph tags
	s/<p><\/p>/<br \/>/g;
	s/<p> <\/p>/<br \/>/g;
	s/^<p>$/<br \/>/g;
	
	s/\”/"/g;
	s/\“/"/g;
	s/\:—/\&mdash;/g;
	s/—/\&mdash;/g;
	s/--/\&mdash;/g;
	s/<!&mdash;/<!--/g;
	s/&mdash;>/-->/g;
	s/\&mdash;\&mdash/\&mdash;/g;
	s/,&mdash;/\&mdash;/g;
	s/\.\.\.\./.\&nbsp;.\&nbsp;./g;
	s/\.\.\./.\&nbsp;.\&nbsp;./g;
	s/\. \. \. /.\&nbsp;.\&nbsp;./g;
	s/ .\&nbsp;.\&nbsp;./.\&nbsp;.\&nbsp;./g;
	s/\…/.\&nbsp;.\&nbsp;./g;
	s/\…\./.\&nbsp;.\&nbsp;./g;
			
	# Some common Unicode to reformat
	s/\ï/\&iuml;/g;
	s/\ä/\&auml;/g;
	s/\à/\&agrave;/g;
	s/\ö/\&ouml;/g;
	s/\é/\&eacute;/g;
	s/\è/\&egrave;/g;
	s/\ë/\&euml;/g;
	s/\æ/\&aelig;/g;
	s/\ê/\&ecirc;/g;
	s/\â/\&acirc;/g;
	s/\ñ/\&ntilde;/;
	
	#Some pet peeves
	s/to-night/tonight/g;
	s/To-night/Tonight/g;
	s/to-morrow/tomorrow/g;
	s/To-morrow/Tomorrow/g;
	s/to-day/today/g;
   	s/To-day/Today/g;
   	s/ shew / show /g;
   	s/ shewed / showed /g;
	s/1st/1<sup>st<\/sup>/g;
	s/2nd/2<sup>nd<\/sup>/g;
	s/3rd/3<sup>rd<\/sup>/g;
	s/4th/4<sup>th<\/sup>/g;
	s/5th/5<sup>th<\/sup>/g;
	s/6th/6<sup>th<\/sup>/g;
	s/7th/7<sup>th<\/sup>/g;
	s/8th/8<sup>th<\/sup>/g;
	s/9th/9<sup>th<\/sup>/g;
	s/0th/0<sup>th<\/sup>/g;
	s/11th/11<sup>th<\/sup>/g;
	s/12th/12<sup>th<\/sup>/g;
	s/13th/13<sup>th<\/sup>/g;
	s/Necronomicon/<i>Necronomicon<\/i>/g;	
	s/"Senor, /"Se&ntilde;or, /g;
	s/ Senor, / Se&ntilde;or, /g;
	s/ Senor / Se&ntilde;or /g;
	s/"Senor /"Se&ntilde;or /g;
	s/ senor/ se&ntilde;or/g;
	s/ Dona / don&ntilde; /g;
	s/ Don Quixote/ don Quixote/g;
	s/\. don Quixote/\. Don Quixote/g;
	return $_;
}

sub readConfig {
	# Read the JSON formatted document config
	# Example config:
	#our %_config		= (	'book' => { 
	#						'url'		=> 'default-author/book-1',
	#						'title'		=> 'Book 1',
	#						'chapter'	=> 1,
	#						'subchapter'=> 'Bad Beginning',
	#						'divider'	=> 'divider1.png',
	#						'genre1'	=> 'adventure',
	#						'genre2'	=> 'fantasy',
	#						'copyright'	=> 'Copyright 2017 Author. <br /> All rights reserved',
	#						},
	#					'author'=> {
	#						'name'		=> 'Author 1',
	#						'url'		=> 'default-author',
	#						'font'		=> 'Rye',
	#						'books'		=> { 'Book 1' => 'book-1', 'And More Books' => 'and-more-books'},
	#						'related' 	=> [ 'Yes Another Author', 'Default Author' ]
	#						},
	#				  );
	# There is capability for both an author and a site twitter tag - but there's no point in tracking them seperately anywhere outside the $_config
	# Make sure these are up to date
	
	my $__json = decode_json (@_[0]);
	%_config = %{$__json};
	$_rootstyle		= $_siteroot . $_stylepath . 'yoursite-core.css';
	
	if( defined $_config{'type'} ){ 					$_type 			= $_config{'type'}; }
	if( defined $_config{'rootstyle'} ){				$_rootstyle		= $_config{'rootstyle'}; 	}else{ $_config{'rootstyle'} = $_rootstyle; }
	if( defined $_config{'stylepath'} ){				$_stylepath		= $_config{'stylepath'}; 	}else{ $_config{'stylepath'} = $_stylepath; }
	if( defined $_config{'imagepath'} ){				$_imagepath		= $_config{'imagepath'}; 	}else{ $_config{'imagepath'} = $_imagepath; }
	if( defined $_config{'stylesheet'} ){				$_stylesheet 	= $_config{'stylesheet'}; 	}else{ $_config{'stylesheet'} = $_stylesheet; }
	if( defined $_config{'divider'} ){					$_divider		= $_config{'divider'}; }
	if( defined $_config{'metadata'} ){					$_metadata 		= $_config{'metadata'}; }
	if( defined $_config{'author'} ){
		if( defined $_config{'author'}{'name'} ){		$_author 		= $_config{'author'}{'name'}; }
		if( defined $_config{'author'}{'portrait'} ){	$_authorport	= $_config{'author'}{'portrait'}; }
		if( defined $_config{'author'}{'related'} ){	@_related 		= $_config{'author'}{'related'}; }else{ $_config{'author'}{'related'} = $_library{$_author}{'related'}; }
		if( defined $_config{'author'}{'about'} ){		$_about 		= $_config{'author'}{'about'}; }
		if( defined $_config{'author'}{'twitter'} ){	$_twitter 		= $_config{'author'}{'twitter'}; }else{ $_config{'author'}{'twitter'} = $_twitter; }
	}
	if( defined $_config{'book'} ){
		if( defined $_config{'book'}{'cover'} ){		$_cover 		= $_config{'book'}{'cover'}; }
		if( defined $_config{'book'}{'title'} ){		$_title 		= $_config{'book'}{'title'}; }
		if( defined $_config{'book'}{'subtitle'} ){		$_subtitle		= $_config{'book'}{'subtitle'}; }
		if( defined $_config{'book'}{'chapter'} ){		$_chapter		= $_config{'book'}{'chapter'}; }
		if( defined $_config{'book'}{'chapname'} ){		$_chapname		= $_config{'book'}{'chapname'}; }else{ $_config{'book'}{'chapname'} = "Chapter $_chapter"; }
		if( defined $_config{'book'}{'subchapter'} ){	$_subchapter	= $_config{'book'}{'subchapter'}; }
		if( defined $_config{'book'}{'genre1'} ){		$_genre1 		= $_config{'book'}{'genre1'}; }
		if( defined $_config{'book'}{'genre2'} ){		$_genre2 		= $_config{'book'}{'genre2'}; }
		if( defined $_config{'book'}{'genre3'} ){		$_genre3 		= $_config{'book'}{'genre3'}; }
		if( defined $_config{'book'}{'genre4'} ){		$_genre4 		= $_config{'book'}{'genre4'}; }
		if( defined $_config{'book'}{'fiction'} ){		$_fiction 		= $_config{'book'}{'fiction'}; }
		if( defined $_config{'book'}{'copyright'} ){	$_copyright		= $_config{'book'}{'copyright'}; }
		if( defined $_config{'book'}{'blurb'} ){		$_blurb 		= $_config{'book'}{'blurb'}; }
		if( defined $_config{'book'}{'metadata'} ){		$_metabook 		= $_config{'book'}{'metadata'}; }
	}
	
	# Set the full canonical for root stylesheet if it's not already set, and make sure that stylesheet uses stylepath if set
	if( $_rootstyle =~ m/$_siteroot/ ){}
	else{ $_config{'rootstyle'} = $_siteroot . $_stylepath . $_rootstyle; $_rootstyle = $_config{'rootstyle'}; }
	if( $_stylepath eq '' ){$_config{'stylesheet'} = $_stylepath . $_stylesheet; $_stylesheet = $_config{'stylesheet'};}
	$_config{'site'} = $_site;
	$_config{'siteroot'} = $_siteroot;
	$_config{'twitter'} = $_twitter; 

	
	# Update copyright if it wasn't set explicitly
	# this mode doesn't validate right: if( $_copyright eq '' ){ $_config{'book'}{'copyright'} = '<figure><a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" class="logo" width="80" src="'. $_siteroot . '/' . $_imagepath . '/cc-by-sa.svg" /></a></figure><p><i><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">' . $_config{'book'}{'title'} . '</span></i> <br /><a xmlns:cc="http://creativecommons.org/ns#" href="' . $_config{'book'}{'url'} .'" property="cc:attributionName" rel="cc:attributionURL">' . $_site . ' Edition</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>. <br />Based on a Public Domain work by <a href="' . $_config{'author'}{'url'} . '">'. $_config{'author'}{'name'} . '</a></p>'; $_copyright = $_config{'book'}{'copyright'}; }
	if( $_copyright eq '' ){ 
		$_config{'book'}{'copyright'} = '<figure><a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" class="logo" width="80" src="'. $_siteroot . '/' . $_imagepath . '/cc-by-sa.svg" /></a></figure><p><i><span>' . $_config{'book'}{'title'} . '</span></i> <br /><a href="' . $_config{'book'}{'url'} .'" property="cc:attributionName" rel="cc:attributionURL">' . $_site . ' Edition</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>. <br />Based on a Public Domain work by <a href="' . $_config{'author'}{'url'} . '">'. $_config{'author'}{'name'} . '</a></p>'; 
		$_copyright = $_config{'book'}{'copyright'}; 
	}

	return %_config;
}

sub loadLibrary {
	# Import JSON library from disk if it exists, will call updateLibrary to create if missing
	# Used to keep track of 'related' books, a given author's books, most recently added, etc.
	# Example structure of library:
	#our %_library		= (	'Default Author' => { 
	#							'url'		=> 'default-author/',
	#							'font'		=> 'Rye',
	#							'books'		=> { 'Book 1' => 'book-1', 'Book 2' => 'book-2'},
	#							'related' 	=> [ 'Another Author', 'Yet Another Author' ]
	#							},
	#						'Another Author'=> {
	#							'name'		=> 'author1',
	#							'font'		=> 'Some-Other-Font',
	#							'books'		=> { 'Some Other Book' => 'book-3', 'And More Books' => 'and-more-books'},
	#							'related' 	=> [ 'Yes Another Author', 'Default Author' ]
	#							},
	#					  );
	%_library = "";
	if( -e $_libfile ){
		open my $__fh, '<', $_libfile or die "Error opening file $_libfile: $!";
		read $__fh, my $__file_contents, -s $__fh;
		my $__json = decode_json ($__file_contents);
		%_library = %{$__json};
		close $__fh;
		print "Library $_libfile opened\n";
	}
	else{ print "Library $_libfile missing. Creating.\n"; updateLibrary(); }
	$_siteroot = $_library{'siteroot'};
	$_site = $_library{'site'};
	$_twitter = $_library{'twitter'};
	$_logo = $_library{'logo'};
	return %_library;
}

sub updateLibrary {
	# Updates the JSON library on disk, or creates if missing
	open my $__fh, '>', $_libfile or die "Error opening file $_libfile: $!";
	$_library{'version'} = $VERSION;
	$_library{'site'} = $_site;
	$_library{'siteroot'} = $_siteroot;
	$_library{'twitter'} = $_twitter;
	$_library{'logo'} = $_logo;
	$_library{'sitecopy'} = $_sitecopy;

	if( $_config{'type'} eq 'author' ){
		$_library{$_author}{'twitter'} 					= $_config{'author'}{'twitter'};
		$_library{$_author}{'url'} 						= $_config{'author'}{'url'};
		$_library{$_author}{'portrait'} 				= $_config{'author'}{'portrait'};
		$_library{$_author}{'stylesheet'} 				= $_config{'stylesheet'};
		$_library{$_author}{'name'} 					= $_author;
		$_library{$_author}{'related'} 					= $_config{'author'}{'related'};
		$_library{$_author}{'about'} 					= $_about;
		$_library{$_author}{'copyright'} 				= $_config{'author'}{'copyright'};
	}
	if( $_config{'type'} ne 'author' ){
		$_library{$_author}{'book'}{$_title}{'added'} 		= $_date;
		$_library{$_author}{'book'}{$_title}{'author'} 		= $_author;
		$_library{$_author}{'book'}{$_title}{'cover'} 		= $_cover;
		$_library{$_author}{'book'}{$_title}{'title'} 		= $_title;
		$_library{$_author}{'book'}{$_title}{'subtitle'} 	= $_subtitle;
		$_library{$_author}{'book'}{$_title}{'genre1'} 		= $_genre1;
		$_library{$_author}{'book'}{$_title}{'genre2'} 		= $_genre2;
		$_library{$_author}{'book'}{$_title}{'genre3'} 		= $_genre3;
		$_library{$_author}{'book'}{$_title}{'genre4'} 		= $_genre4;
		$_library{$_author}{'book'}{$_title}{'fiction'} 	= $_fiction;
		$_library{$_author}{'book'}{$_title}{'related'} 	= @_related;
		$_library{$_author}{'book'}{$_title}{'copyright'} 	= $_copyright;
		$_library{$_author}{'book'}{$_title}{'coverstyle'}	= $_config{'book'}{'coverstyle'};
		$_library{$_author}{'book'}{$_title}{'blurb'} 		= $_blurb;
		$_library{$_author}{'book'}{$_title}{'url'} 		= $_config{'book'}{'url'};
		$_library{$_author}{'books'}{$_title}{'url'}		= $_config{'book'}{'url'};
		$_library{$_author}{'books'}{$_title}{'hover'}		= $_config{'book'}{'hover'};
		$_library{$_author}{'books'}{$_title}{'genre1'}		= $_config{'book'}{'genre1'};
		if( defined $_config{'book'}{'link'} ){
			# This is to allow off-site book links from the author page 
			$_library{$_author}{'books'}{$_title}{'link'}	= $_config{'book'}{'link'};
			print "Link = $_config{'book'}{'link'}\n";
		}
		if( $_config{'book'}{'hover'} eq '' ){ $_library{$_author}{'books'}{$_title}{'hover'} = "$_title ($_genre1)"; }
		
		#print "Coverstyle = $_library{$_author}{'book'}{$_title}{'coverstyle'}\n";
	}

	my $__json = encode_json \%_library;
	print $__fh $__json;
	close $__fh;
	printf "Library $_libfile updated\n";
	return 1;
}
	

# Loaded OK
1;

