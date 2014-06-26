#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use utf8;
use Encode;# qw(encode decode);
use HTML::Encoding 'encoding_from_http_message';
use feature qw(say);

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my $uri = shift;

my $UserAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0";
my $timeout = 180;
my $redirect = 30;
my $browser = LWP::UserAgent->new();
$browser->agent($UserAgent);
$browser->timeout($timeout);
$browser->ssl_opts(verify_hostname => 1);
$browser->max_redirect($redirect);
$browser->show_progress(1);

$uri = 'http://'.$uri unless($uri =~ /https?:\/\/([^\/\\]+)/);
    
my $response = $browser->get($uri);

#get html encode
my $enco = "";

#get first code
$enco = $1 if ($response->as_string and $response->as_string =~  /<meta\s+http-equiv\s*=\s*"?content-type"?\s+content\s*=\s*"?text\/html;\s*charset\s*=\s*([-\w]+)"?/i);
    
#get second code
$enco = $1 if $enco eq "" and ($response->as_string and $response->as_string =~/<meta\s+charset\s*=\s*"?([-\w]+)"?/i);
   
$enco = encoding_from_http_message($response) if $enco eq "";
    
$enco = "" if not defined $enco;
$enco = uc($enco) if $enco ne "";
    
my @is_support_code = qw(UTF-8 UTF8 GB2312 GBK  GB_2312-80 US-ASCII);
    
my $is_ugly = 1;

foreach (@is_support_code){
	if($enco eq $_){
            $is_ugly = 0;
        }
        last;
} 
    
#if code is not in supported code set to GB2312 
$enco = "GB2312" if $is_ugly == 1;
    
my $content = decode($enco,$response->as_string);

say $content;

    
