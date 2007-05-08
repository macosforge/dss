# cgi-lib.pl
# Common functions for writing http headers
#----------------------------------------------------------
#
# @APPLE_LICENSE_HEADER_START@
#
# Copyright (c) 1999-2003 Apple Computer, Inc.  All Rights Reserved.
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
#
#---------------------------------------------------------

package cgilib;
# init days and months

my $ssl = $ENV{"HTTPS"};

@weekday = ( "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" );
@month = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" );

%status = ( '200' => "OK",
			'302' => "Temporarily Unavailable",
			'401' => "Unauthorized",
			'403' => "Forbidden",
			'404' => "File Not Found",
		  );
			

# PrintOKTextHeader(servername, cookie)
# changed 7/25/01 by JAA to add support for cookies
sub PrintOKTextHeader {
	my $datestr = HttpDate(time());
	my $charsetstr = '';
	
	if($ENV{"LANGUAGE"} eq "ja") {
		$charsetstr = ';charset=Shift_JIS';
	}
	
	my $headerstr = "HTTP/1.0 200 OK\r\nServer: $_[0]\r\nContent-Type: text/html$charsetstr\r\nConnection:close\r\n";
	
	$headerstr .= "Set-Cookie: $_[1]\r\n" if ($_[1] ne "");

	# Safari cache control
	$headerstr .= "Expires: Mon, 26 Jul 1997 05:00:00 GMT\r\n";
	$headerstr .= "Last-Modified: $datestr\r\n";
	$headerstr .= "Cache-Control: no-store, no-cache, must-revalidate\r\n";
	$headerstr .= "Cache-Control: post-check=0, pre-check=0, false\r\n";
	$headerstr .= "Pragma: no-cache\r\n";
	
	$headerstr .= "\r\n";
	print $headerstr;
}

# PrintFileDownloadHeader(servername)
# added 4/25/02 by JAA to allow content downloads
sub PrintFileDownloadHeader {
	my $datestr = HttpDate(time());
	my $charsetstr = '';
	
	if($ENV{"LANGUAGE"} eq "ja") {
		$charsetstr = ';charset=Shift_JIS';
	}
	
	my $headerstr = "HTTP/1.0 200 OK\r\nDate: $datestr\r\nServer: $_[0]\r\nContent-Type: application/octet-stream\r\nConnection:close\r\n";
	print $headerstr;
}

# PrintRedirectHeader(servername, redirectpath)
# changed from PrintRedirectHeader(servername, serverip, serverport, redirectpage)
sub PrintRedirectHeader {
	my $datestr = HttpDate(time());
	print "HTTP/1.0 302 Temporarily Unavailable\r\nDate: $datestr\r\nServer: $_[0]\r\n"
		. "Location: $_[1]\r\nConnection:close\r\n\r\n";
}


# PrintChallengeHeader(servername, challengeheader)
sub PrintChallengeHeader {
	my $datestr = HttpDate(time());
	print "HTTP/1.0 401 Unauthorized\r\nDate: $datestr\r\nServer: $_[0]\r\n"
			. "Content-Type: text/html\r\nConnection:close\r\n$_[1]\r\n\r\n";
}

# PrintChallengeResponse(servername, challengeheader, messageHash)
sub PrintChallengeResponse {
	PrintChallengeHeader($_[0], $_[1]);
	PrintUnauthorizedHtml($_[2]);
}

# PrintForbiddenHeader(servername)
sub PrintForbiddenHeader {
	my $datestr = HttpDate(time());
	print "HTTP/1.0 403 Forbidden\r\nDate: $datestr\r\nServer: $_[0]\r\nContent-Type: text/html\r\nConnection:close\r\n\r\n";
}

# PrintForbiddenResponse(servername, filename, messageHash)
sub PrintForbiddenResponse {
	PrintForbiddenHeader($_[0]);
	PrintForbiddenHtml($_[1], $_[2]);
}

# PrintForbiddenHtml(filename, messageHash)
sub PrintForbiddenHtml {
	my $messHash = $_[1];
	my %messages = %$messHash;
	
 	print "<HTML><HEAD><TITLE>$messages{'Http403Status'}</TITLE></HEAD>" 
 					. "<BODY><H1>$messages{'Http403Status'}</H1><P>$messages{'Http403Body'} : $_[0]</P></BODY></HTML>";
}

# PrintNotFoundHeader(servername)
sub PrintNotFoundHeader {
	my $datestr = HttpDate(time());
	print "HTTP/1.0 404 File Not Found\r\nDate: $datestr\r\nServer: $_[0]\r\nContent-Type: text/html\r\nConnection:close\r\n\r\n";
}

# PrintNotFoundResponse(servername, filename, messageHash)
sub PrintNotFoundResponse {
	PrintNotFoundHeader($_[0]);
	PrintNotFoundHtml($_[1], $_[2]);
}

# PrintNotFoundHtml(filename, messageHash)
sub PrintNotFoundHtml {
	my $messHash = $_[1];
	my %messages = %$messHash;
 	print "<HTML><HEAD><TITLE>$messages{'Http404Status'}</TITLE></HEAD>" 
 					. "<BODY><H1>$messages{'Http404Status'}</H1><P>$messages{'Http404Body'} : $_[0]</P></BODY></HTML>";
}

# PrintStatusLine(num) 
sub PrintStatusLine {
	print "HTTP/1.0 $_[0] $status{$_[0]}\r\n"; 
}

# PrintDateAndServerStr(server)
sub PrintDateAndServerStr {
	my $datestr = HttpDate(time());
	print "Date: $datestr\r\nServer: $_[0]\r\n";
}

# PrintTextTypeAndCloseStr()
sub PrintTextTypeAndCloseStr {
	print "Content-Type: text/html\r\nConnection: close\r\n\r\n";
}

# PrintUnauthorizedHeader(servername, realm)
sub PrintUnauthorizedHeader {
	my $datestr = HttpDate(time());
 	print "HTTP/1.0 401  Unauthorized\r\nServer:$_[0]\r\nDate: $datestr\r\n"
 					. "WWW-authenticate: Basic realm=\"$_[1]\"\r\n"
 					. "Content-Type: text/html\r\nConnection: close\r\n\r\n";
}

# PrintServerNotRunningHtml(messageHash)
sub PrintServerNotRunningHtml {
	my $messHash = $_[0];
	my %messages = %$messHash;
 	print "<HTML><HEAD><TITLE>$messages{'ServerNotRunningMessage'}</TITLE></HEAD>" 
 					. "<BODY><BR><H3>&nbsp;&nbsp;$messages{'StartServerMessage'}</H3>"
 					. "</BODY></HTML>";
}

# PrintUnauthorizedHtml(messageHash)
sub PrintUnauthorizedHtml {
	my $messHash = $_[0];
	my %messages = %$messHash;
 	print "<HTML><HEAD><TITLE> $messages{'Http401Status'}</TITLE></HEAD>" 
 					. "<BODY><H1> $messages{'Http401Status'}</H1><P> $messages{'Http401Body'}.\n"
 					. "</P></BODY></HTML>";
}

# PrintUnauthorizedResponse(servername, realm, messageHash)
sub PrintUnauthorizedResponse {
	PrintUnauthorizedHeader($_[0], $_[1]);
 	PrintUnauthorizedHtml($_[2]);
}

# HttpDate(timeinsecfrom1970)
sub HttpDate {
    local @tm = gmtime($_[0]);
    return sprintf "%s, %d %s %d %2.2d:%2.2d:%2.2d GMT",
    $weekday[$tm[6]], $tm[3], $month[$tm[4]], $tm[5]+1900,
    $tm[2], $tm[1], $tm[0];
}

1; #return true  



