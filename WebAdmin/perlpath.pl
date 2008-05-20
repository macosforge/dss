#
# @APPLE_LICENSE_HEADER_START@
#
#
# Copyright (c) 1999-2008 Apple Inc.  All Rights Reserved.
#
# This file contains Original Code and/or Modifications of Original Code
# as defined in and that are subject to the Apple Public Source License
# Version 2.0 (the 'License'). You may not use this file except in
# compliance with the License. Please obtain a copy of the License at
# http://www.opensource.apple.com/apsl/ and read it before using this
# file.
#
# The Original Code and all software distributed under the License are
# distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
# EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
# INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
# Please see the License for the specific language governing rights and
# limitations under the License.
#
# @APPLE_LICENSE_HEADER_END@
#

# perlpath.pl
# This script gets run only from Install script on darwin unix platforms
# in order to replace the 
# #!/usr/local/bin/perl line at the start of scripts with the real path to perl

$ppath = $ARGV[0];
if ($ARGV[1] eq "-") {
    @files = <STDIN>;
    chop(@files);
}
else {
    # Get files from command line
    @files = @ARGV[1..$#ARGV];
}

foreach $f (@files) {
    open(IN, $f);
    @lines = <IN>;
    close(IN);
        if ($lines[0] =~ /^#!\/\S*perl\S*(.*)/) {
	    open(OUT, "> $f");
	    print OUT "#!$ppath$1\n";
	    for($i=1; $i<@lines; $i++) {
		print OUT $lines[$i];
	    }
	    close(OUT);
	}
}
