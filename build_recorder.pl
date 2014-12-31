#!/usr/bin/perl -T
#
# Read arguments from stdin and write them to a file.
# The QUERY_STRING should have the following information:
# Host, Platform, Build, Date, Compile status, Check status, Install status
# 

$ENV{PATH} = "";
$ENV{IFS} = "" if $ENV{IFS};
$ENV{BASH_ENV} = ''; # Needed for Perl 5.6.0 on Linux

use strict;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

# Build the string that encodes the info
my $OK_CHARS='-a-zA-Z0-9_.:'; # A restrictive list of metacharacters
my(%info);
foreach my $p (param()) {
    $info{$p} = param($p);
    $info{$p} =~ s/[^$OK_CHARS]/_/go;
}

# It would be easy to add 'time' here too, but the resulting records
# would require a modifiecation to the build_reader.pl script. Might
# be worthwhile so that this could then me used for CI - multiple builds
# per day. jhrg 12/31/14
my $result = "Build: $info{'build'}, Platform: $info{'platform'}, Date: $info{'date'}, Compile: $info{'compile'}, Check: $info{'check'}, Install: $info{'install'}, Distcheck: $info{'distcheck'}, RPM: $info{rpm}, PKG: $info{pkg}, Host: $info{'host'}"; 

print header;
print start_html("Build Recorder Result");

# write to the 'return value' of the script.

print $result, "\n";

# append to a served file 

if (open FILE, ">> /home/sites/builds/build_info.txt") {
    # Lock the file
    flock FILE, 2;
    print FILE $result, "\n";
    # unlock the file
    flock FILE, 8;
    close FILE;
}
else {
    print "<p>Could not open build_info.txt</p>";
}

print end_html;

