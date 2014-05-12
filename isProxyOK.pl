#!/usr/local/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use feature qw(switch say);
use Getopt::Long;
use Carp;
use Term::ANSIColor qw(:constants);
use Time::HiRes qw(time);
use URI::Split qw(uri_split);
local $Term::ANSIColor::AUTORESET = 1;

my $help = q{};
my $proxy = q{};
my $fileout = q{};
my $url = "http://www.baidu.com";
my $host = q{};
my $logpath = "/var/log/lighttpd/access.log";
my $moreInfo = q{};
my $ip = q{};


GetOptions(
    'help|h'=>\$help,
    'proxy=s'=>\$proxy,
    'out=s'=>\$fileout,
    'url=s'=>\$url,
    'host|=s'=>\$host,
    'logpath=s'=>\$logpath,
    'vv'=>\$moreInfo,
    'ip=s'=>\$ip,
);

if($help){
    print <<__HELP__;

Notice: In order to run this script you must have those modules installed

cpan -i LWP::UserAgent
cpan -i Getopt::Long
cpan -i Term::ANSIColor
cpan -i LWP::Protocol::https
cpan -i LWP::Protocol::socks
cpan -i URI::Split


######## GET Basic Information about the  proxy ####################
1. is Live or not 
2. the connection spend time

Usage: $0 -proxy http://xxx.xxx.xxx.:7808 [-out xxx] [-url http://www.baidu.com]  or
	   $0 -proxy proxyfile [-out xxx] [-url http://www.baidu.com] 

-proxy: Specify the proxy,it can ben a proxy string like "http://23.228.65.132:7808" or proxy list filename

-out: Specify the filename to storage good proxy

-url: Specify the url for test proxy connection time, default is http://www.baidu.com

####### GET More Information about the proxy ######################
1. is Live or not 
2. the connection spend time
3. proxy Anonymous degree
(1)High Anonymity Proxy :No VIA , NO X_Forwarded_For headers
(2)Anonymity Proxy: hide your ip
(3)Transparent Proxy: have proxy server info in via header and your ip in x_forwarded_for headers

Preconditions:
1. Install Web server: Lighttpd or Apache or Nginx or tomcat or IIS
2. usable domain/Internet IP  with the web server

Usage: $0 -vv -proxy http://xxx.xxx.xxx.:7808 [-out xxx] -url http://YOUR DOMAIN -ip xxx.xxx.xxx  [-host YourDomain] [-logpath Your Web Server Log path]
       $0  -vv -proxy proxyfile [-out xxx] -url http://YOUR DOMAIN -ip xxx.xxx.xxx [-host YourDomain] [-logpath Your Web Server Log path]
-vv: Specify get proxy Anonymous degree
-url: Specify the domain bind your web server e.g. http://www.tanjiti.com 
-host: Specify the hostname for Host header , default value is split from url
-logpath: Specify the web server log path e.g. /var/log/lighttpd/access.log for default lighttpd log path
-ip: Specify the server ip

-h: For more help
__HELP__

	exit 0;
}

chomp $fileout;
chomp $proxy;
chomp $fileout;
chomp $url;
chomp $host;
chomp $logpath;
chomp $ip;

croak "You need to specify the proxy(proxyfile) \n Please run --help for more informations \n" if $proxy eq q{};
croak "$logpath is not readable " unless -r $logpath;
croak "You need to specify the url and the server ip \n Please run --help for more informations \n" if $moreInfo and ($url eq "http://www.baidu.com" or $ip eq q{});
##################################################################
##  readFromFile(): storage the file contents into an array     ##
##  parameter: $filename                                         ##
##  return: @contents(array)                                     ##
##################################################################
sub readFromFile{
    my $filename = shift;
    open my ($FH), "<", $filename or die "cannot open $filename for reading:  $! \n";
    my @contents = ();

    while(<$FH>){
        chomp $_;
        push @contents, $_;
    }
    close $FH;
    return @contents;
}
##################################################################
## writeToFile(): write the array datas into the specify file
## parameters: $content_ref, $filename
## return: no return
#################################################################
sub writeToFile{
	my ($content_ref, $filename)= @_;
	my @contents = @$content_ref;

	open my ($FH), ">", $filename or die "cannot open $filename for writing:  $! \n";
	select $FH;

	foreach (@contents){

		say  $_;
	}
	select STDOUT;
	close $FH;


}
#################################################################
## isProxyLive: determine the proxy is live or not
## parameters: $proxy,$url,$host
## return: $isLive(boolean), $timeCost(number)
#################################################################
sub isProxyLive{
    my ($proxy,$url,$host) = @_;

    my ($scheme,$auth,$path,$query,$frag) = uri_split($url);

    $host = $auth if defined $auth and $host eq q{};

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0");
    $ua->timeout(10);
    $ua->default_headers->push_header('Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8');
    $ua->default_headers->push_header('Accept-Encoding'=>'gzip,deflate,sdch');
    $ua->default_headers->push_header('Host' => $host);
    $ua->default_headers->push_header('Connection' => 'keep-alive');
    $ua->proxy([qw/http https/] => $proxy);
    $ua->show_progress(1);
    my $start = time();
    my $response = $ua->get($url);
    my $end = time();
    my $timeCost = $end - $start;
    my $isLive = $response->code == 200 ? 1: 0;
    return ($isLive,$timeCost);

}

#################################################################
## getProxyType: determine the proxy type
## parameters: $logpath, $ip
## return: $ProxyType string (High Anonymity,Anoymity,Transparent)
#################################################################
sub getProxyType{
    my($logpath, $ip) = @_;

    my $log = `tail -1 $logpath`;

    my $ProxyType = q{};

    if ($log =~ /"\s+?"([-0-9.,a-zA-Z]+)"\s+?"(.+)"$/){
        my $x_forwarded_for = $1;
        my $via = $2;

        #$isExposeIP == -1 : hide your ip 
        #$isExposeIP != -1 : expose your ip
        
        
        my $isExposeIP = index($x_forwarded_for, $ip) ; 


        if($via eq "-" and $x_forwarded_for eq "-"){
            $ProxyType = "High Anonymity Proxy ! No VIA , NO X_Forwarded_For include ip list ";
        }elsif($isExposeIP != -1){
            $ProxyType = "Transparent Proxy !  $via ";
        }else{
            $ProxyType = "Anonymity Proxy ! Hide your real IP !";
        }
        
        
    }
    return $ProxyType;
}

my @proxys = -r $proxy ? readFromFile($proxy) : $proxy;

#@ok_proxys: storage the live proxy 
my @ok_proxys = ();

foreach  (@proxys){
    my ($isLive, $timeCost) = isProxyLive($_,$url,$host);

	if ($isLive){
    	
        my $ProxyDegree = getProxyType($logpath,$ip) if $moreInfo ne q{};
    	push @ok_proxys, $_ if $isLive;

        my $proxyInfo = $moreInfo ? "[Proxy] $_ [TIME]: $timeCost [ProxyInfo]: $ProxyDegree" : "[Proxy] $_ [TIME]: $timeCost";

        say BOLD RED $proxyInfo;

    }else{
    	say BOLD YELLOW "Proxy: $_ NOT OK";
    }
    	
}

if (-r $proxy or $fileout){
	$fileout = $proxy."_out" unless $fileout;
	writeToFile(\@ok_proxys,$fileout);
}
