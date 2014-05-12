#!/usr/local/bin/perl
#Author: tanjiti
use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use utf8;
use JSON;
use feature qw{ switch };
use Term::ANSIColor qw(:constants);
use Regexp::Common qw(net);

no warnings 'experimental::smartmatch';

local $Term::ANSIColor::AUTORESET = 1;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');



my $help =q{};
my $ip = q{};
my $option = 0;

GetOptions(
    'help|h'=>\$help,
    'ip=s'=>\$ip,
    'o=i'=>\$option,
);

if($help){
    print <<__HELP__;
Notice: In order to run this script you must have Bundle::LWP,Getopt::Long,Regexp::Common Term::ANSIColor installed
cpan -i Bundle::LWP
cpan -i Getopt::Long
cpan -i Term::ANSIColor
cpan -i Regexp::Common
for install the depended module

This script is a on_line ip info query use these APIs interface as follows:
1. ipinfo.io
2. ip-api.com
3. ip-taobao.com (chinese)
4. www.cz88.net (chinese)
5. ip.chinaz.com (chinese)


Usage: $0 -ip xxx.xxx.xxx.xxx [-t x]

where:
-ip : Specify the ip for query
-t : Specify the IP DB Interface 
    1  ipinfo.io
    2  ip-api.com
    3  ip-taobao.com
    4  www.cz88.net
    5  ip.chinaz.com
    no parameter means use all Interfaces , is the default options

-h : For more help

__HELP__
    exit 0;




}

chomp $ip;
chomp $option;

die "You need to specify the ip for query. Please run --help for more information. \n" if ($ip eq q{});


die "Invalid IP format" if $ip !~ /$RE{net}{IPv4}/;

given ($option){
    when (1) { getResult($ip,1); break;}
    when (2) { getResult($ip,2); break;}
    when (3) { getResult($ip,3); break;} 
    when (4) { getResult($ip,4); break;}
    when (5) { getResult($ip,5); break;}
    default { 
        getResult($ip,1); 
        getResult($ip,2); 
        getResult($ip,3); 
        getResult($ip,4); 
        getResult($ip,5); 
    }


}


sub queryIPINFO{
    my $content = shift;
    my $content_ref = decode_json($content);

    print BOLD MAGENTA "******************IP INFO from ipinfo.io************** \n";
    my %datas = %$content_ref;
    
    foreach (keys %datas){
        print  $_." : ".$datas{$_}."\n" if defined $datas{$_};
                                                      
    }
    return;
}

sub queryIPAPI{
    my $content = shift;
    my $content_ref = decode_json($content);
    
    print BOLD BLUE "**********************IP INFO from ip-api.com**************\n";
    
    if(exists $content_ref->{"status"} and $content_ref->{"status"} eq "success"){
        my %datas = %$content_ref;

        foreach (keys %datas){
            print  $_." : ".$datas{$_}."\n";
        }
     return;
     }
    
}

sub queryTAOBAO{
    my $content = shift;
    my $content_ref = decode_json($content);

    print BOLD RED "***********************IP INFO from taobao淘宝*******************\n";

    if(exists $content_ref->{"code"} and $content_ref->{"code"} == 0){
        my $data_ref = $content_ref->{"data"};
        my %datas = %$data_ref;
        foreach (keys %datas){
            print  $_." : ".$datas{$_}."\n";
        }
        return;
    }
}

sub queryCZ88{
    my $content = shift;

    print BOLD YELLOW "********************IP INFO from chunzhen 纯真*****************\n";

     if ($content =~ /<span id="InputIPAddrMessage">(.*?)<\/span><\/div>/i){
        print $1,"\n";
     }
     return;

}

sub queryCHINAZ{
    my $content = shift;

    print BOLD CYAN "***********************IP INFO from chinaz 站长之家**********************\n";

    if  ($content =~ /<strong class="red">(.*?)<\/strong><br \/>/i){
        print $1,"\n";
    }
    return;
}


sub getResult{
    my ($ip, $option) = @_;

    my $browser = LWP::UserAgent->new();

    $browser->default_headers->push_header('Accept-Encoding'=>'gzip,deflate,sdch');

    my $UA = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0";

    $browser->timeout(10);

    $browser->agent($UA);
    
    my $url = q{};

    given ($option){
        when (1) { $url = "http://ipinfo.io/${ip}/json"; break;}
        when (2) { $url = "http://ip-api.com/json/${ip}"; break;}
        when (3) { $url = "http://ip.taobao.com/service/getIpInfo.php?ip=${ip}"; break;}
        when (4) { $url = "http://www.cz88.net/ip/index.aspx?ip=${ip}"; break;}
        when (5) { $url = "http://ip.chinaz.com/?IP=${ip}"; break;}
        default {print BOLD BLUE "Wrong Options \n"; break;}
    
    }

    my $response = $browser->get($url);
    
    if($response->is_success){
        my $content = $response->decoded_content;

        given ($option){
            when (1) { queryIPINFO($content); break;}
            when (2) { queryIPAPI($content); break;}
            when (3) { queryTAOBAO($content); break;}
            when (4) { queryCZ88($content); break;}
            when (5) { queryCHINAZ($content); break;}
            default {print BOLD BLUE "Wrong Options \n"; break;}
        }
    }
    else{
        print STDERR $url,"\t",$response->status_line,"\n";
    }


}
