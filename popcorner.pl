#!/usr/bin/perl

use strict;
use Term::ANSIColor;
use Cwd 'abs_path';

our $SILENT = 0;
our $SELF 	= abs_path($0);
our $ARCH 	= 1;
our $FNAME 	= 1;
our @page 	= ();
our $URL 	= 1;
our $INSTALLED;
our $AUTO_UPDATE;

if ( $ARGV[0] =~ /--update.*/ ) {

	$SILENT = 1 if ( $ARGV[0] eq '--updateSilent' );

	_dieRed("No popcorn installation detected") if ( !-d '/opt/Popcorn-Time/' );
	getCurrentInstallation();

	_printGreen( "Detecting arch" );
	_getArch();
	_printGreen( "Arch detected: " . $ARCH . "bit" );
	_printGreen( "Getting popcorn web page" );
	getPopcornPage();
	getPopcornUrlFromPage();

	if ( $URL eq $INSTALLED ) {

		_printGreen("Popcorn-Time already installed and latest version");
		exit(0);

	}

	getFileName();
	_printGreen( "Downloading tarball" );
	_mkdir( "/tmp/popcorn" ) or _dieRed("Failed to create folder: /tmp/popcorn");
	downloadTarball();
	_printGreen( "Extracting tarball" );
	untarTarball() or _dieRed("Failed to extract /tmp/popcorn/$FNAME to /tmp/popcorn/");
	_delete( "/tmp/popcorn/$FNAME" ) or _dieRed( "Failed to delete /tmp/popcorn/$FNAME" );
	_printGreen("Downloading icon");
	downloadIcon();
	_printGreen("Beginning installation");
	_mkdir( "/opt/Popcorn-Time", 1 ) or _dieRed("Failed to create folder: /opt/Popcorn-Time");
	_copy( "/tmp/popcorn/*", "/opt/Popcorn-Time", 0, 1 ) or _dieRed("Failed to copy: /tmp/popcorn/* -> /opt/Popcorn-Time");
	createMenuEntry();
	_copy( "/tmp/popcorn/popcorntime.desktop", "/usr/share/applications/", 0, 1 ) or _dieRed("Failed to copy: /tmp/popcorn/popcorntime.desktop -> /usr/share/applications/");
	_printGreen("Do you want to auto update popcorn, when there is a new release? [y/n]: ", 0, 1);
	autoUpdate();

	if ( $AUTO_UPDATE == 1 ) {

		createTmpDataFile();
		_copy( "/tmp/popcorn/data", "/opt/Popcorn-Time/data", 0, 1 );

	}

	_printGreen("Cleaning temporary files");
	_delete("/tmp/popcorn/") or _dieRed("Failed to delete /tmp/popcorn/");
	_printGreen("Popcorn-Time installed successfully!");

	exit(0);

}

_printGreen( "Detecting arch" );
_getArch();
_printGreen( "Arch detected: " . $ARCH . "bit" );
_printGreen( "Getting popcorn web page" );
getPopcornPage();
getPopcornUrlFromPage();
getFileName();
_printGreen( "Downloading tarball" );
_mkdir( "/tmp/popcorn" ) or _dieRed("Failed to create folder: /tmp/popcorn");
downloadTarball();
_printGreen( "Extracting tarball" );
untarTarball() or _dieRed("Failed to extract /tmp/popcorn/$FNAME to /tmp/popcorn/");
_delete( "/tmp/popcorn/$FNAME" ) or _dieRed( "Failed to delete /tmp/popcorn/$FNAME" );
_printGreen("Downloading icon");
downloadIcon();
_printGreen("Beginning installation");
_mkdir( "/opt/Popcorn-Time", 1 ) or _dieRed("Failed to create folder: /opt/Popcorn-Time");
_copy( "/tmp/popcorn/*", "/opt/Popcorn-Time", 0, 1 ) or _dieRed("Failed to copy: /tmp/popcorn/* -> /opt/Popcorn-Time");
createMenuEntry();
_copy( "/tmp/popcorn/popcorntime.desktop", "/usr/share/applications/", 0, 1 ) or _dieRed("Failed to copy: /tmp/popcorn/popcorntime.desktop -> /usr/share/applications/");
_printGreen("Do you want to auto update popcorn, when there is a new release? [y/n]: ", 0, 1);
autoUpdate();

if ( $AUTO_UPDATE == 1 ) {

	createTmpDataFile();
	_copy( "/tmp/popcorn/data", "/opt/Popcorn-Time/data", 0, 1 );
	saveTmpCronFile();
	_copy( $SELF, "/usr/local/bin/popcorner", 0, 1 ) or _dieRed("Failed to copy: $SELF -> /usr/local/bin/popcorner");
	modifyTmpCronFile();
	system("sudo crontab /tmp/popcorn/cron");

}

_printGreen("Cleaning temporary files");
_delete("/tmp/popcorn/") or _dieRed("Failed to delete /tmp/popcorn/");
_printGreen("Popcorn-Time installed successfully!");

exit(0);


#=== SUBS =======================================================================

sub _printGreen{

	return 1 if ( $SILENT == 1 );

	my $string = shift;
	my $wait = shift || 0;
	my $newline = shift || 0;
	print color 'bold green';
	print $string;

	if ( $newline == 0 ) {

		print "\n";

	}

	print color 'reset';
	sleep($wait);
	return 1;
}

sub _printRed{
	my $string = shift;
	my $wait = shift || 0;
	print color 'bold red';
	print $string . "\n";
	print color 'reset';
	sleep($wait);
	return 1;
}

sub _dieRed{

	die(1) if ( $SILENT == 1 );

	my $string = shift;
	my $wait = shift || 0;
	print color 'bold red';
	print $string . "\n";
	print color 'reset';
	sleep($wait);
	exit(0);
}

sub _mkdir {

	my $target 	= shift;
	my $sudo 	= shift || 0;

	if ( -d $target ) {

		return 1;

	}

	my $command = "";

	if ( $sudo == 1 ) {

		$command .= "sudo ";

	}

	$command .= "mkdir \"$target\"";

	if ( system( $command ) != 0 ) {

		return 0;

	}

	return 1;

}

sub _delete {

	my $target 		= shift;
	my $verbose 	= shift || 0;

	my $command = "rm -rf";

	if ( $verbose == 1 ) {

		$command .= "v";

	}

	$command .= " \"$target\"";

	if ( system( $command ) != 0 ) {

		return 0;

	}

	return 1;

}

sub _copy {

	my $source 		= shift;
	my $target 		= shift;
	my $verbose 	= shift || 0;
	my $sudo 		= shift || 0;

	my $command = "";

	if ( $sudo == 1 ) {

		$command .= "sudo ";

	}

	$command .= "cp -rf";

	if ( $verbose == 1 ) {

		$command .= "v";

	}

	$command .= " $source $target";

	if ( system( $command ) != 0 ) {

		return 0;

	}

	return 1;

}

sub _getArch {

	my $output = `uname -m`;
	chomp( $output );

	if ( $output eq "x86_64" ) {

		$ARCH = 64;

	} elsif ( $output eq "i386" || $output eq "i486" || $output eq "i586" || $output eq "i686" ) {

		$ARCH = 32;

	}

	_printRed( "Failed to detect the system's arch" ) if ( $ARCH == 1 );

}

sub getPopcornPage {

	@page = `curl -s http://popcorntime.io/`;

	_dieRed("Failed to fetch popcorn's page") if ( scalar( @page ) < 30 );

}

sub getPopcornUrlFromPage {

	foreach my $line ( @page ) {
		
		if ( $line =~ /downloadUrl" : "(\S+Linux$ARCH.tar.xz)/ ) {

			$URL = $1;

		}

	}

	_dieRed("Failed to detect a download url. Not possible to recover from this") if ( $URL == 1 );

}

sub getFileName {

	if ( $URL =~ /.*\/(.*)$/ ) {

		$FNAME = $1;

	}

	_dieRed("Failed to detect the file name. Not possible to recover from this") if ( $FNAME == 1 );

}

sub downloadTarball {

	my $absPath = "/tmp/popcorn/" . $FNAME;

	system("curl \"$URL\" -o $absPath");

	_dieRed("Download Error") if ( !-e $absPath );

}

sub createMenuEntry {

	open my $fh, '>', '/tmp/popcorn/popcorntime.desktop' or _dieRed("Failed to write in /tmp");

	print $fh "[Desktop Entry]\n";
	print $fh "Name=Popcorn Time\n";
	print $fh "Comment=Stream movies from torrents. Skip the downloads. Launch, click, watch\n";
	print $fh "Exec=/opt/Popcorn-Time/Popcorn-Time\n";
	print $fh "Terminal=false\n";
	print $fh "Icon=/opt/Popcorn-Time/popcorntime.png\n";
	print $fh "Type=Application\n";
	print $fh "Categories=AudioVideo;\n";
	print $fh "StartupNotify=true\n";

	close $fh;

}

sub untarTarball {

	if ( system("tar xf /tmp/popcorn/$FNAME -C /tmp/popcorn/") != 0 ) {

		return 0;

	}

	return 1;

}

sub downloadIcon {

	my $out = system("curl -o /tmp/popcorn/popcorntime.png http://popcorntime.io/images/logo-valentines.png");

	if ( $out != 0 ) {

		_dieRed("Failed to fetch icon");

	}

	if ( !-e "/tmp/popcorn/popcorntime.png" ) {

		_dieRed("Icon file, was not detected in folder: /tmp/popcorn/");

	}

}

sub autoUpdate {

	my $response = <STDIN>;
	chomp( $response );

	if ( $response =~ /y/i ) {

		$AUTO_UPDATE = 1;

	} elsif ( $response =~ /n/i ) {

		$AUTO_UPDATE = 0;

	} else {

		$AUTO_UPDATE = 0;
		_printRed("Don't know what you mean. Assuming no, and continue");

	}

}

sub createTmpDataFile {

	open my $fh, '>', '/tmp/popcorn/data' or _dieRed("Failed to create: /tmp/popcorn/data");

	print $fh $URL . "\n";

	close $fh;

}

sub getCurrentInstallation {

	_dieRed("No data file detected in installation") if ( !-e '/opt/Popcorn-Time/data' );

	open my $fh, '<', '/opt/Popcorn-Time/data' or _dieRed("Failed to parse /opt/Popcorn-Time/data");

	my @data = <$fh>;

	close $fh;

	my $current = $data[0];
	chomp( $current );

	if ( $current !~ /.*cdn.popcorntime.io.*Linux.*.tar.xz$/ ) {

		_dieRed("Corrupted data detected in /opt/Popcorn-Time/data");

	}

	$INSTALLED = $current;

}

sub saveTmpCronFile {

	system("sudo crontab -l > /tmp/popcorn/cron 2> /dev/null");

	if ( !-e '/tmp/popcorn/cron' ) {

		_dieRed("Failed to detect temporary root crontab at: /tmp/popcorn/cron");

	}

}

sub modifyTmpCronFile {

	open my $fh, '>>', '/tmp/popcorn/cron' or _dieRed("Failed to access: /tmp/popcorn/cron");

	print $fh "\n# Popcorn Time Entry\n";
	print $fh "1 0 * * * /usr/bin/perl /usr/local/bin/popcorner --updateSilent\n";

	close $fh;

}
