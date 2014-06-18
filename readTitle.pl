#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;
use utf8;
use HTML::Encoding 'encoding_from_http_message';
use Encode qw(encode decode);
use feature qw(say);

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');




die "You must specify the file include hostlist for analyze or the hostname
for analyze .\n" if ($#ARGV != 0);
my $host = shift;

if(-e $host){
    
    #open file include hostlist
    my $out = $host."_out";
    open my $FH, "<:encoding(UTF-8)", $host or die "cannot open $host for reading $!";
    open my $OUT, ">:encoding(UTF-8)", $out or die "cannot open $out for writing $!";

    while(<$FH>){
        say $OUT getTitle($_);

    }
    close $FH;
    close $OUT;




}else{
    say getTitle($host) if $host ne q{};


}



sub getTitle{
    my $uri = shift;

    #set browser
    my $UserAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0";
    my $timeout = 180;
    my $redirect = 30;
    my $browser = LWP::UserAgent->new();
    $browser->timeout($timeout);
    $browser->ssl_opts(verify_hostname => 1);
    $browser->max_redirect($redirect);
    
    my $host = $uri;
    if($uri =~ /https?:\/\/(\S+)/){
      $host = $1;  
    }else{
      $uri = 'http://'.$uri;
    } 
    $browser->default_headers->push_header('Host' => $host);

    my $response = $browser->get($uri);
   
    my $enco = $1 if ($response->decoded_content =~ /charset\s*=\s*"?([-\w]+)"?/);

    my $title = $response->title;    
    
    if($response->is_success){

        unless( $title){
            $title = $1 if $response->decoded_content =~  /<title>(.*?)<\/title>/imxs ;
        } 

    
    }else{
        $title =  $response->status_line unless $title;
    
    }

    $title = $enco ? decode($enco, $title) : $title;

    $title = "no title" unless $title;

    return $uri."\t".$title;
    

}



