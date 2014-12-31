#!/usr/bin/perl -T
#
# The CGI now returns a table where the background color is light red
# for any entry where one of the build operations failed. The CGI takes
# two parameters: 'show' which is a regex; if not null, return only matching
# lines. If show is set to "current", then show the current date's entries.
# The second param is 'sort'. If sort is "yes", then run the filtered result
# through a sorter.
# 

$ENV{PATH} = "";
$ENV{IFS} = "" if $ENV{IFS};
$ENV{BASH_ENV} = ''; # Needed for Perl 5.6.0 on Linux

use strict;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

my $builds = "/home/sites/builds";
my $www_builds = "/builds";
my $db = "build_info.txt";
my $logs = "logs";
my $date = "/bin/date";
my $OK_CHARS='a-zA-Z0-9.'; # A restrictive list of characters

# Build the string that encodes the info

print header;
print start_html("Build Information");

open FILE, "$builds/$db";
# lock the file
flock FILE, 2;

# grab the 'show' parameter, if used. If show is "current", look for the
# current date. But sanitize first...
my $show = param('show');
$show =~ s/[^$OK_CHARS]/_/go;
if ($show ne param('show')) {
    # If the sanitized param is not equal to the original, something's wrong.
    # Exit without much comment.
    print "No data.\n";
    print end_html;
    exit 0;
}

if ($show && $show eq "current") {
    $show = `$date +%Y.%m.%d`;
    chop $show;
}
elsif  (!$show) {
    $show = "";
}

my @lines;

while(<FILE>) {
   if (/$show/) {
        # a,b,c, ... are dummy values.
        my ($a,$pkg,$b,$platform,$c,$date,$e,$compile,$f,$check,$g,$install,$h,$distcheck,$i,$rpm,$j,$osxpkg,$k,$OS) 
            = split /[:,\n]/;

	# There are two kinds of 'records' in the file, one with
	# distcheck rpm and one without. In the latter case, 'Host:'
	# will be in $h and the OS info will be in $distcheck. A third
	# form was added after 10/11/10 where osx packages are also
	# reported. To descriminate between lines with only RPMs and
	# lines with both RPMs and PKGs, test for host appearing in in
	# $j.

	# The different kinds of records in the DB:
	# Build: libdap, Platform: i386-apple-darwin8.11.1, Date: 2010.03.05, Compile: 0, Check: 2, Install: 0, Host: OSX-Intel-Shrew_idoru
	# Build: libdap, Platform: i386-apple-darwin8.11.1, Date: 2010.03.05, Compile: 0, Check: 0, Install: 0, Distcheck: 0, RPM: N_A, Host: OSX-Intel-Shrew-1.6_idoru
	# Build: libdap, Platform: i386-apple-darwin8.11.1, Date: 2010.03.05, Compile: 0, Check: 0, Install: 0, Distcheck: 0, RPM: N_A, PKG: N_A, Host: OSX-Intel-Shrew-1.6_idoru

	# print "<p>Debug: h: $h; j: $j; k: $k<br/>\n";
	# print "distcheck: $distcheck; rpm: $rpm; pkg: $osxpkg; host $OS</p>\n";

	$h =~ s/ //;
	if ($h eq "Host") {
	    $OS = $distcheck;
	    $distcheck = "N_A";
	    $rpm = "N_A";
	    $osxpkg = "N_A";
	}

	$j =~ s/ //;
	if ($j eq "Host") {
	    $OS = $osxpkg;
	    $osxpkg = "N_A";
	}

	# Now remove leading spaces from these.
	$pkg =~ s/ //;
	$platform =~ s/ //;
	$date =~ s/ //;
	$OS =~ s/ //;
	$check =~ s/ //;
	$distcheck =~ s/ //;
	$rpm =~ s/ //;
	$osxpkg =~ s/ //;

	my $log_name = "";
        my $color = "#ffffff";  # White
        if ($compile != 0 || $install != 0) {
            $color = "#f39377";    # light red
	}
	if ($check != 0 && $check ne "N_A") {
            $color = "#f39377";    # light red
	}
	if ($distcheck != 0 && $distcheck ne "N_A") {
            $color = "#f39377";    # light red
	}
	if ($rpm != 0 && $rpm ne "N_A") {
            $color = "#f39377";    # light red
	}
	if ($osxpkg != 0 && $osxpkg ne "N_A") {
            $color = "#f39377";    # light red
	}
	 
	# NB: $builds and $logs are defined at the top of the script. 
	my $test_name = "$builds/$logs/${OS}.$platform.$pkg.all.$date";
	$log_name = "$www_builds/$logs/${OS}.$platform.$pkg.all.$date";

	if (! -e $test_name) {
	    $log_name = "";
	}

        # Hack the values because using functions that return strings makes
        # for a really ugly call to push.
        to_word($compile);
        to_word($install);
        to_word($check);
        to_word($distcheck);
        to_word($rpm);
	to_word($osxpkg);

	if ($log_name eq "") {
	    push(@lines, "<tr bgcolor=\"$color\">\
                          <td>$pkg</td> \
                          <td>$date</td> \
                          <td>$OS ($platform)</td> \
                          <td align=\"center\">$compile</td> \
                          <td align=\"center\">$check</td> \
                          <td align=\"center\">$install</td> \
                          <td align=\"center\">$distcheck</td> \
                          <td align=\"center\">$rpm</td></td> \
                          <td align=\"center\">$osxpkg</td></tr>\n");
        }
	else {
	    push(@lines, "<tr bgcolor=\"$color\">\
                          <td>$pkg</td> \
                          <td><a href=\"$log_name\">$date</a></td> \
                          <td>$OS ($platform)</td> \
                          <td align=\"center\">$compile</td> \
                          <td align=\"center\">$check</td> \
                          <td align=\"center\">$install</td> \
                          <td align=\"center\">$distcheck</td> \
                          <td align=\"center\">$rpm</td></td> \
                          <td align=\"center\">$osxpkg</td></tr>\n");
	}
    }
}

# It might be overkill to sanitize this, but that is better than underkill...
my $sort = param('sort');
$sort =~ s/[^$OK_CHARS]/_/go;
if ($sort ne param('sort')) {
    # If the sanitized param is not equal to the original, something's wrong.
    # Exit without much comment.
    print "No data.\n";
    print end_html;
    exit 0;
}

if ($sort && $sort eq "yes") {
    @lines = sort(@lines);
}

print "<table border=\"2\" caption=\"Nightly Build Results\">\n";
print "<th>Package</th><th>Date</th><th>Host & Platform</th>\
       <th>Compiled</th><th>Tests Passed</th><th>Installed</th><th>Dist Check</th><th>RPM</th><th>PKG</th>\n";
       
print @lines;

print"</table>";

# unlock the file
flock FILE, 8;
close FILE;

print end_html;

exit 0;

# In Perl, scalars are passed by reference, so this modifies the value of the
# actual parameter. See p.116 of Wall.
sub to_word {
    if ($_[0] eq "N_A" || $_[0] eq "") {
        $_[0] = "N/A";
    }
    elsif ($_[0] == 0) {
        $_[0] = "yes";
    }
    else {
        $_[0] = "no($_[0])";
    }
}
