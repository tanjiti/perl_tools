#!/usr/bin/perl 
#author: tanjiti
use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;
use utf8;
use HTML::Encoding 'encoding_from_http_message';
use Carp;
use Encode qw(encode decode);
use JSON;
use List::MoreUtils qw(uniq);
use autodie;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');


use Term::ANSIColor qw(:constants);

local $Term::ANSIColor::AUTORESET = 1;

my $file = q{};
my $host = q{};
my $help = q{};

GetOptions(
    'help|h'=>\$help,
    'f=s'=>\$file,
    'host=s'=>\$host,
);

if($help){
    print <<__HELP__;
Notice: In order to run this script you must have Bundle::LWP,Getopt::Long,List::MoreUtils,HTML::Encoding installed

Usage: $0 -f=filename

where:
-f : Specify the file include hostlist for analyze
-host : Specify the host for analyze

__HELP__
    exit 0;
}

die "You must specify the file include hostlist for analyze or the hostname
for analyze .Please run --help for more information.\n" if ($file eq q{} and $host eq q{});


my $str = $host."\t".getResponse($host,0)."\n";
print  $str if $host ne q{};

if ($file ne q{}){
    my @HOST = readHostFromFile($file);
     
    foreach (@HOST){
       my %tmp = %$_;
       my $title = getResponse($tmp{"host"},$tmp{"number"});
       #print $tmp{"host"}."\t".$tmp{"number"}."\t".$title."\n";
       print  $tmp{"host"}."\t".$title."\n";
       
    }
}




sub readHostFromFile{
    my $file = shift;
    my @HOST = ();
    open FH,'<:encoding(UTF-8)',$file or die "cannot open $file for reading: $! \n";
    while(<FH>){
        chomp;
        #if ($_ =~ /(\S+?)\s+?(\d+?)\z/msx){
            my %info = ();
            #$info{"host"} = $1;
            #$info{"number"} = $2;
            $info{"host"} = $_;
            $info{"number"} = 0;
            push(@HOST,\%info);
        #}
        
    }   
    close FH;
    return @HOST;
}


sub getResponse{
    my ($host, $number) = @_;
    

    my $browser = LWP::UserAgent->new();

    my $UA = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0";
    
    $browser->agent($UA);
    
    $browser->timeout(10);

    my $url = "http://".$host;
    
    my $response = $browser->get($url);
    
    my $status_line=$response->status_line;
    
    my $title = "no title";

    if($response->is_success){
        $title = readTitle($response,$host,$number); 
           
    }
    elsif($status_line =~  /https/){
        $browser->ssl_opts("verify_hostname" => 1); 
        $url = "https://".$host."\n";
        $response = $browser->get($url);
       
        if($response->is_success){
               $title = readTitle($response,$host,$number);
        }

    }else{
        $title = $status_line;
    }
    return $title;

}

sub readTitle{
    
    my $title = "no title";

    my ($response, $host, $number) = @_;

    my $enco = encoding_from_http_message($response);
   
    my $content = $response->decoded_content();
    

    if (defined $enco and $content){
        
        $content = decode($enco=>$response->content) or warn "cannot decode $host use $enco :  $! \n" ;
    }
    
    if (defined $content and $content =~ /<title[\s\S]*?>(.*?)<\/title>/imxs){
        
        $title = $1;
        
    }

    return $title;
}


