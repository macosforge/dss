#!/usr/bin/perl
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

use CGI;

$q = new CGI;

my $error = $q->cgi_error;
if ($error) {
	print $q->header(-status=>$error),
		  $q->start_html('Problems'),
		  $q->h2('Request not processed'),
		  $q->strong($error);
	exit 0;
}

$url = $q->param('url');

if ($url eq '') {
	print $q->header(-status=>'404 File Not Found'),
		  $q->start_html('404 File Not Found'),
		  $q->h2('404 File Not Found'),
		  $q->strong('404 File Not Found');	
	exit 0;
}

print $q->header('video/quicktime'),
	  "rtsptext\rrtsp://$url";
	  
exit 0;
