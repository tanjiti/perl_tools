#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;
use utf8;
use Encode;# qw(encode decode);
use HTML::Encoding 'encoding_from_http_message';
use feature qw(say);
use Try::Tiny;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');




die "You must specify the file include hostlist for analyze or the hostname
for analyze .\n" if ($#ARGV != 0);
my $host = shift;

if(-e $host){# read hosts list from file
    
    #open file include hostlist
    my $out = $host."_out";
    open my $FH, "<:encoding(UTF-8)", $host or die "cannot open $host for reading $!";
    open my $OUT, ">:encoding(UTF-8)", $out or die "cannot open $out for writing $!";

    while(<$FH>){
        chomp;
        say $OUT getTitle($_) if $_;

    }
    close $FH;
    close $OUT;


}else{
    say getTitle($host) if $host ne q{};


}



sub getTitle{
    my $uri = shift;
    chomp $uri;
   
    #send http request and get response
    my $UserAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0";
    my $timeout = 180;
    my $redirect = 30;
    my $browser = LWP::UserAgent->new();
    $browser->agent($UserAgent);
    $browser->timeout($timeout);
    $browser->ssl_opts(verify_hostname => 1);
    $browser->max_redirect($redirect);
    
    $uri = 'http://'.$uri unless($uri =~ /https?:\/\/([^\/\\]+)/);
    
    my $response = $browser->get($uri);

    #get html encode
    my $enco = "";

    #get first code
    $enco = $1 if ($response->as_string and $response->as_string =~  /<meta\s+http-equiv\s*=\s*"?content-type"?\s+content\s*=\s*"?text\/html;\s*charset\s*=\s*([-\w]+)"?/i);
    
    #get second code
    $enco = $1 if $enco eq "" and ($response->as_string and $response->as_string =~/<meta\s+charset\s*=\s*"?([-\w]+)"?/i);
   
    #get title
    my $title = "";
    $title = $response->title;    

    $title = "" if not defined $title;


    #if title not set, read from html or response status line
    if($response->is_success){
          if ( $title eq ""){
              #get title from regex
            $title = $1 if $response->as_string and $response->as_string =~  /<title>(.*?)<\/title>/imxs ;
        } 

    
    }else{
        $title =  $response->status_line if $title eq "";
    
    }
    #get code from http message if not setting
    
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
    #encode title
    
    try{$title = decode($enco, $title);};
    

    $title =~ s/\r\n//g if $title ne "";

    $title = "no title" if $title eq "";


    return $uri."\t".$title;
    
}



