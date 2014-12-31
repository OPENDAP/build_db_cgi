#!/usr/bin/perl
#
# CGI script that creates a fill-out form
# and echoes back its values.

$ENV{PATH} = "";
$ENV{IFS} = "" if $ENV{IFS};
$ENV{BASH_ENV} = ''; # Needed for Perl 5.6.0 on Linux

use strict;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

my $builds = "/home/sites/builds";
my $logs   = "$builds/logs";

my $OK_CHARS='-a-zA-Z0-9_.'; # A restrictive list of metacharacters

print header, start_html('Log file upload'), h1('Log file upload'),
  start_multipart_form, "Destination file name: ", textfield('name'), p,
  filefield(
             -name      => 'uploaded_file',
             -default   => 'starting value',
             -size      => 50,
             -maxlength => 80
  ),
  p, submit, end_form, hr;

if ( param() ) {
    my $fh = upload('uploaded_file');
    # Do not filter $fh since that will filter the contents of the file.
    defined $fh or die("The uploaded file could not be opened");

    print "The filename is ", em( $fh ), p;

    # Copy a binary file to somewhere safe
    my $outfile_name = param('name');
    $outfile_name =~ s/[^$OK_CHARS]/_/go; # sanitize
    if ($outfile_name =~ /^([$OK_CHARS]+)$/) {
	$outfile_name = $1;
    }
    else {
	die("Bad data in outfile_name");
    }

    print "The destination file is: $outfile_name", p, hr;

    open( OUTFILE, ">$builds/logs/$outfile_name" )
      or die("Could not open $outfile_name");    

    my $buffer;
    my $bytesread;
    while ( $bytesread = read( $fh, $buffer, 1024 ) ) {
        print OUTFILE $buffer;
    }

    close OUTFILE;

    # Once this is set working for a few days, duplicate the log rotation
    # code in build.sh
    &delete_files("$builds/logs", 5);
}

end_html;

exit;

sub delete_files {
    my ($dir, $days) = @_;
    
    print "Directory: $dir; Days: $days\n";
    
    opendir DIR, $dir or die("Could not open $dir\n");
    my @files = grep !/^\./, readdir DIR;     # read all but dot files
    my $file;
    foreach $file (@files) {
        if (-f "$dir/$file" && -M "$dir/$file" > 10) {
            unlink "$dir/$file" or die("Could not delete $dir/$file");
        }
    }
}
