#!/usr/bin/perl 
#Author: tanjiti
use Getopt::Long;
use Regexp::Common qw(net); 
use Term::ANSIColor qw(:constants);
use utf8;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my $help = q{};
my $ip = q{};
my $host = q{};

local $Term::ANSIColor::AUTORESET = 1;

GetOptions(
'help|h'=>\$help,
'ip=s'=>\$ip,
'host=s'=>\$host
);


if($help){
print <<__HELP__;
Notice: In order to run this script you must have to do steps as follows:

1. install Getopt::Long,Regexp::Common,Term::ANSIColor Modules
cpan -i Getopt::Long
cpan -i Regexp::Common
cpan -i Term::ANSIColor

2. download  GeoIP.dat,GeoLiteCity.dat,GeoIPASNum.dat into the specify filepath (any position is OK) 
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz
gunzip GeoIP.dat.gz
gunzip GeoLiteCity.dat.gz
gunzip GeoIPASNum.dat.gz

3. install geoip-bin
(1)install on debian: apt-get install geoip-bin
(2)install from source: 
wget http://geolite.maxmind.com/download/geoip/api/c/GeoIP.tar.gz
tar zxvf GeoIP.tar.gz 
cd GeoIP-1.4.8/
./configure
make
make install
echo '/usr/local/lib' > /etc/ld.so.conf.d/geoip.conf
ldconfig

4.modify the GeoIP.dat,GeoLiteCity.dat,GeoIPASNum.dat file path in  sub  geoiplookup{} 




Usage: $0 -ip xxx.xxxx.xxx -host xxx

where:
-ip : Specify the ip address to query
-host: Specify the host address to query

__HELP__
exit 0;

}

chomp $ip;
chomp $host;

die "You need to specify the ip address or hostname to query. Please run --help for more information " if  ($ip eq q{} and $host eq q{});

#query the specify ip geo information
geoiplookup($ip) if $ip ne q{};

#query the specify host geo information
if ($host){
   my @ips=hosttoIP($host); 

   print BOLD RED "$host GEO information: \n";
    
   map { geoiplookup($_)} @ips;
}




sub hosttoIP{
   my $host = shift;
   my $result = `host $host`;
   my @results = split("\n",$result);
   
   my @ips = map {  /($RE{net}{IPv4})/} @results;
   
   return @ips;
}

sub  geoiplookup{
   my $ip = shift;
    
   #NOTICE HERE: substitute your IP date file 
   my $country = `geoiplookup -f /usr/share/GeoIP/GeoIP.dat $ip`;
   my $city = `geoiplookup -f /usr/share/GeoIP/GeoLiteCity.dat $ip`;
   my $ASNum = `geoiplookup -f /usr/share/GeoIP/GeoIPASNum.dat $ip`;

   print BOLD BLUE "$ip GEO information: \n";
   print "\t",$country;
   print "\t",$city;
   print "\t",$ASNum;
}
