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
use Data::Dumper;
use JSON;

my $help = q{};
my $proxy = q{};
my $fileout = q{};
my $url = "http://www.tanjiti.com/proxy.php";
my $host = "www.tanjiit.com";
my $moreInfo = q{};
my $ip = q{};
my $http_retry = 3;
my $ms = 200;

GetOptions(
    'help|h'=>\$help,
    'proxy=s'=>\$proxy,
    'out=s'=>\$fileout,
    'vv'=>\$moreInfo,
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
(2)Anonymity Proxy: hide your ip or fake a ip
(3)Transparent Proxy: have proxy server info in via header and your ip in x_forwarded_for headers


Usage: $0 -vv -proxy http://xxx.xxx.xxx.:7808 [-out xxx]   
       $0  -vv -proxy proxyfile [-out xxx]   
-vv: Specify get proxy Anonymous degree
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
chomp $ip;

croak "You need to specify the proxy(proxyfile) \n Please run --help for more informations \n" if $proxy eq q{};

sub getInternalIPv4{
my $command = "hostname --all-ip-addresses";
my $result = `$command`;
die "execute $command failed \n " if $? != 0;
my @ips = split /\s/, $result;
#print Dumper(\@ips);
return \@ips;


}

sub getExteranlIPv4{
my $command = "curl -s ipinfo.io";
my $result = `$command`;
die "execute $command failed \n " if $? != 0;
my $ip = "";
$ip = $1 if $result =~ /\"ip\":\s\"([^\"]+)\"/;

return $ip;
}

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
    $ua->timeout(100);
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

    my $codeStart = substr $response->code,0,1;
    my $number_get_retry = 0;

    while(($codeStart eq "5") and ($number_get_retry < $http_retry)){

        $start = time();
        $response = $ua->get($url);
        $end = time();
        $timeCost = $end - $start;
        $codeStart =  substr $response->code,0,1;
        
        $number_get_retry = $number_get_retry +1;
        usleep($ms);


    }
    my $isLive = $response->code == 200 ? 1: 0;
    


    my $response_content = "";
    $response_content = $response->decoded_content if $isLive;
    return ($isLive,$timeCost, $response_content);

}

#################################################################
## getProxyType: determine the proxy type
## parameters: $logpath, $ip
## return: $ProxyType string (High Anonymity,Anoymity,Transparent)
#################################################################
sub getProxyType{
        
    
    my $response_content = shift;
    say $response_content if $moreInfo;

    my @ips_no_proxy = qw();
    my $ips_internal_ref = getInternalIPv4();
    my $ip_external = getExteranlIPv4();
    push  @ips_no_proxy,$ip_external  if $ip_external;
    push @ips_no_proxy, @$ips_internal_ref  if @$ips_internal_ref and length(@$ips_internal_ref) >=1;
    
    my $json_content_ref = decode_json $response_content;

    my $proxy_type = "";
    if($json_content_ref->{"PROXY_TYPE"}){
        $proxy_type = $json_content_ref->{"PROXY_TYPE"};
        if($proxy_type eq "transparent"){
            my $http_x_forwarded_for = $json_content_ref->{"HTTP_X_FORWARDED_FOR"};

            my $is_fraud_ip = 1;
            if($http_x_forwarded_for){
                foreach my $item (@ips_no_proxy){
                    my $pos = index $http_x_forwarded_for, $item;
                    if($pos != -1){
                        $is_fraud_ip = 0;
                        last;
                    }


                }

            }

            $proxy_type = "fraud proxy" if $is_fraud_ip == 1;

        }
    }

        

    
    return $proxy_type;
}

my @proxys = -r $proxy ? readFromFile($proxy) : $proxy;

#@ok_proxys: storage the live proxy 
my @ok_proxys = ();

foreach  (@proxys){
    my ($isLive, $timeCost, $response_content) = isProxyLive($_,$url,$host);

	if ($isLive){
    	
        my $ProxyDegree = getProxyType($response_content) if $moreInfo ne q{};
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
