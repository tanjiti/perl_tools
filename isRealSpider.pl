#!/usr/bin/perl
#author: tanjiti
use strict;
use warnings;
use Getopt::Long;
use Regexp::Common qw /net/;




my $help = q{};
my $ip = q{};
my $file = q{};



GetOptions(
    'help|h'=>\$help,
    'ip=s'=>\$ip,
    'file=s'=>\$file,

);


if($help){
    print <<__HELP__;
Notice: In order to run this script you must have Getopt::Long and
Regexp::Common installed

Usage: $0 [-file filename] [-ip xxx.xxx.xxx.xxx]

where:
-file : Specify the file include ip list
-ip : Specify the ip

__HELP__
    exit 0;

}

die "You need specify the ip or the file of iplist for query. Please run
--help for more information.\n" if ($file eq q{} and $ip eq q{});

print isRealSpider($ip) if $ip ne q{};

readFromFile($file) if $file ne q{};


sub readFromFile{
    my $file = shift;
    my @ips = ();
    open FH,$file or die "cannot open $file for reading: $! \n";

    while(<FH>){
        chomp;
        if ($_ =~ /$RE{net}{IPv4}{-keep}/){
            print isRealSpider($1);
        }
    
    }

    close FH;

    return @ips;

}


sub isRealSpider{
    my $ip = shift;
    my $isspider = "cannot determine";
    return "$ip is a google spider \n" if isGoogleSpider($ip);
    return "$ip is a baidu spider \n" if isBaiduSpider($ip);
    return "$ip is a bing or msn spider \n" if isBingSpider($ip);
    return "$ip is a yahoo spider \n" if isYahooSpider($ip);
    return "$ip  $isspider \n";
    

}



sub isGoogleSpider{
    my $ip = shift;
    my $result = `host $ip`;
    my $isspider = 0;
    $isspider = 1 if ($result =~ /googlebot\.com/);

    return $isspider;
}


sub isBaiduSpider{
    my $ip = shift;
    my $result = `host $ip`;
    my $isspider = 0;
    $isspider = 1 if ( ($result =~ /crawl\.baidu\.jp/) or ($result =~
            /crawl\.baidu\.com/));

    return $isspider;
}

sub isBingSpider{
    my $ip = shift;
    my $result = `host $ip`;
    my $isspider = 0;
    $isspider = 1 if ($result =~ /search\.msn\.com/);
    
    return $isspider;
}

sub isYahooSpider{
    my $ip = shift;
    my $result = `host $ip`;
    my $isspider;
    $isspider = 1 if ($result =~ /yahoo\.com/);

    return $isspider;
}



