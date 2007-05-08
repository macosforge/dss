#!/usr/bin/perl

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