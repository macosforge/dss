#!/usr/bin/perl -w
use strict;

# This was used to update copyright/license text.  It should be executed from the base DSS directory.
# The script expects the @APPLE_LICENSE_HEADER_START@ and @APPLE_LICENSE_HEADER_END@ tags and will
# replace the content with the text defined below.

# Text to use for filetypes that support multi-line documentation:
my $new_text = q! *
 * Copyright (c) 1999-2008 Apple Inc.  All Rights Reserved.
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
!;

# Text to use for Perl:
my $new_text_perl = q!#
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
!;

sub is_code_file {
	my $file = shift;
	if ($file =~ /(\.s|\.m|\.cpp|\.h|\.c|\.pl|\.py|\.cgi)$/) {
		return 1;
	}
	return 0;
}

sub process_file {
	my $file = shift;
	#print "DEBUG: $file\n";
	my $ret = `grep APPLE_LICENSE_HEADER_START "$file"`;
	if ($ret eq "") {
		print "$file: Apple Header not found\n";
		return;
	}

	open(F, "<$file") || die "Cannot open file $file";
	my @lines = <F>;
	close(F);
	open(F, ">$file.license-update") || die "Cannot create file $file";
	my $replaced = 0;
	my $done = 0;
	foreach my $line (@lines) {
		if ($line =~ "\@APPLE_LICENSE_HEADER_START\@") {
			print F $line;
			if ($file =~ /(\.cgi|\.pl)$/) {     # assumes that .cgi is a Perl script
				print F $new_text_perl;
			} else {
				print F $new_text;
			}
			$replaced = 1;
			next;
		}
		if ($replaced == 1 && $done == 0) {
			if ($line =~ "\@APPLE_LICENSE_HEADER_END\@") {
				print F $line;
				$done = 1;
				next;
			} else {
				next;
			}
		}
		print F $line;
	}	
	close(F);
	my $cmd = "mv -vf \"$file.license-update\" \"$file\"";
	system($cmd);
}

sub process_dir {
	my $dir = shift;
	opendir(D, $dir) || die "can't open dir $dir";
	my @files = readdir(D);
	closedir(D);
	foreach my $file (@files) {
		if ($file eq "." || $file eq ".." || $file eq ".svn" || $file eq "CVS") {
			next;
		}
		my $full_filename = "$dir/$file";
		if (-d $full_filename) {
			&process_dir($full_filename);
		} else {
			if (&is_code_file($full_filename)) {
				&process_file($full_filename);
			}
		}
	}
}

#### MAIN
&process_dir(".");
print "Finished updating.\n";
