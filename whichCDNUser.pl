#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);

die "Please specify the hostname or the filename include hostlist for query CDN user ! \n" unless $#ARGV == 0;
my $hostname = shift;
chomp $hostname;



#cdn ip range
my @ips_cdn_cloudflare = qw(199.27.128.0/21
173.245.48.0/20
103.21.244.0/22
103.22.200.0/22
103.31.4.0/22
141.101.64.0/18
108.162.192.0/18
190.93.240.0/20
188.114.96.0/20
197.234.240.0/22
198.41.128.0/17
162.158.0.0/15
104.16.0.0/12);

my @ips_cdn_360 = qw(183.136.133.0-183.136.133.255
220.181.55.0-220.181.55.255
101.226.4.0-101.226.4.255
180.153.235.0-180.153.235.255
122.143.15.0-122.143.15.255
27.221.20.0-27.221.20.255
202.102.85.0-202.102.85.255
61.160.224.0-61.160.224.255
112.25.60.0-112.25.60.255
182.140.227.0-182.140.227.255
221.204.14.0-221.204.14.255
222.73.144.0-222.73.144.255
61.240.144.0-61.240.144.255
113.17.174.0-113.17.174.255
125.88.189.0-125.88.189.255
125.88.190.0-125.88.190.255
120.52.18.1-120.52.18.255);

my @ips_cdn_jiasule = qw(119.188.35.0-119.188.35.255
61.155.222.0-61.155.222.255
218.65.212.0-218.65.212.255
116.211.121.0-116.211.121.255
103.15.194.0-103.15.194.255
61.240.149.0-61.240.149.255
222.240.184.0-222.240.184.255
112.25.16.0-112.25.16.255
59.52.28.0-59.52.28.255
211.162.64.0-211.162.64.255
180.96.20.0-180.96.20.255
103.1.65.0-103.1.65.255);

my @ips_cdn_anquanbao = qw(220.181.135.1-220.181.135.255 115.231.110.1-115.231.110.255
124.202.164.1-124.202.164.255 58.30.212.1-58.30.212.255 117.25.156.1-117.25.156.255
36.250.5.1-36.250.5.255 183.60.136.1-183.60.136.255 183.61.185.1-183.61.185.255
14.17.69.1-14.17.69.255 120.197.85.1-120.197.85.255 183.232.29.1-183.232.29.255
61.182.141.1-61.182.141.255 182.118.12.1-182.118.12.255 182.118.38.1-182.118.38.255
61.158.240.1-61.158.240.255 42.51.25.1-42.51.25.255 119.97.151.1-119.97.151.255
58.49.105.1-58.49.105.255 61.147.92.1-61.147.92.255 69.28.58.1-69.28.58.255
176.34.28.1-176.34.28.255 54.178.75.1-54.178.75.255 112.253.3.1-112.253.3.255
119.167.147.1-119.167.147.255 123.129.220.1-123.129.220.255
223.99.255.1-223.99.255.255 117.34.72.1-117.34.72.255
117.34.91.1-117.34.91.255 123.150.187.1-123.150.187.255
221.238.22.1-221.238.22.255 125.39.32.1-125.39.32.255
125.39.191.1-125.39.191.255 125.39.18.1-125.39.18.255
14.136.130.1-14.136.130.255 210.209.122.1-210.209.122.255
111.161.66.1-111.161.66.255);

my @ips_cdn_incapsula = qw(199.83.128.0/21
198.143.32.0/19
149.126.72.0/21
103.28.248.0/22
45.64.64.0/22
185.11.124.0/22 
192.230.64.0/18);

#TDO
my @ips_cdn_yundun = qw();


my @ips_cdn_yunjiasu_2 = qw(222.216.190.0-222.216.190.255 61.155.149.0-61.155.149.255
119.188.14.0-119.188.14.255 61.182.137.0-61.182.137.255 117.34.28.0-117.34.28.255
119.188.132.0-119.188.132.255 42.236.7.0-42.236.7.255 183.60.235.0-183.60.235.255
117.27.149.0-117.27.149.255 216.15.172.0/24 119.167.246.0/24);


my @ips_cdn_yunjiasu_3 = qw(119.167.246.0-119.167.246.254 117.27.149.1-117.27.149.254 124.95.168.129-124.95.168.254 183.61.236.0-183.61.236.254 59.51.81.0-59.51.81.254 199.27.128.1-199.27.135.254 173.245.48.1-173.245.63.254 103.21.244.1-103.21.247.254 103.22.200.1-103.22.203.254 103.31.4.1-103.31.7.254 141.101.64.1-141.101.127.254 108.162.192.1-108.162.255.254 190.93.240.1-190.93.255.254 188.114.96.1-188.114.111.254 197.234.240.1-197.234.243.254 198.41.128.1-198.41.255.254 162.158.0.1-162.159.255.254 104.16.0.1-104.31.255.254);

if (-e $hostname){
	my $out = $hostname."_cdnprovider";
	open my $FH, "<:encoding(UTF-8)",$hostname or die "cannot open $hostname for reading $! \n";
	open my $OUT, ">:encoding(UTF-8)",$out or die "cannot open $out for writing $! \n";

	while(<$FH>){
	    chomp;
	    say $OUT whichCDNUser($_) if $_;
	}
	close $FH;
	close $OUT;
}else{
    say whichCDNUser($hostname);
}

sub whichCDNUser{
    my $hostname = shift;
    chomp $hostname;
    if ($hostname =~ /^(?:https?:\/\/)([-.\d\w]+)/i){
	$hostname = $1;
    }
    my $result = qw();
    if(isCDNUser($hostname,\@ips_cdn_cloudflare)){
      $result = "$hostname\tcloudflare";
    }elsif(isCDNUser($hostname,\@ips_cdn_360)){
      $result =  "$hostname\t360wangzhanweishi";
    }elsif(isCDNUser($hostname,\@ips_cdn_jiasule)){
      $result =  "$hostname\tjiasule";
    }elsif(isCDNUser($hostname,\@ips_cdn_yunjiasu_2)){
      $result = "$hostname\tyunjiasu_2";
    }elsif(isCDNUser($hostname,\@ips_cdn_yunjiasu_3)){
      $result = "$hostname\tyunjiasu_3";
    }elsif(isCDNUser($hostname,\@ips_cdn_anquanbao)){
      $result = "$hostname\tanquanbao";
    }elsif(isCDNUser($hostname,\@ips_cdn_incapsula)){
      $result = "$hostname\tincapsula";
    }else{
      $result =  "$hostname\tnone";
    }
    return $result;
}

sub isCDNUser{
    my ($hostname,$ips_cdn_ref) = @_;
    my @ips_cdn = @$ips_cdn_ref;
    my $isCDNUser = 0;
    my @ips_dig = getIPFromStr(getDNS($hostname));
    
    foreach my $host_ip (@ips_dig){ 
        foreach my $cdn_ip (@ips_cdn) {
            my $result = ipv4_in_range($host_ip,$cdn_ip); 
            if ($result == 1) {
                $isCDNUser = 1;
                last; 
            }
        }
    }
    
    return $isCDNUser;

}

sub getIPFromStr{
    my $string = shift;
    chomp $string;
    my @ips = ($string =~ /[.\w\d]+\s+\d+\s+IN\s+A\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g);
    return @ips;
}


sub getDNS{
    my $hostname = shift;
    my $result = `dig $hostname \@114.114.114.114`; #you can choose your own dns address
    return $result;
}

sub ipv4_in_range{
    my $ip = shift;
    my $range = shift;
    
    if (index($range,'/') != -1){
        #range is in IP/NETMASK format
        my ($range, $netmask) = split('/',$range,2);
        my $ip_dec = ip2long($ip);
        my $range_dec = ip2long($range);
        my $netmask_dec = 0;
        if(index($netmask,'.') != -1 ){
            #netmask is a 255.255.0.0 format
            $netmask = str_replace('*','0',$netmask);
            $netmask_dec = ip2long($netmask);
      
        }else{
            #netmask is a CIDR size block like 1.2.3.4/24
            my ($a,$b,$c,$d) = split('.',$range,4);
            $range = sprintf("%s.%s.%s.%s",$a?$a:'0',$b?$b:'0',$c?$c:'0',$d?$d:'0');

            my $wildcard_dec = 2 ** (32 - $netmask) -1;
            $netmask_dec = (~$wildcard_dec);

        }
        return (($ip_dec & $netmask_dec) == ($range_dec & $netmask_dec)) ? 1:0;


    }else{
        # range might be 255.255.*.* or 1.2.3.0-1.2.3.255
        if(index($range,'*') != -1){
            #Just convert to A-B format by setting * to 0 for A and 255 for B
            my $lower = str_replace('*','0',$range);
            my $upper = str_replace('*','255',$range);
            $range = $lower.'-'.$upper;
        }
        
        if(index($range,'-') != -1){ 
            my ($lower,$upper) = split('-',$range,2);
            my $lower_dec = ip2long($lower);
            my $upper_dec = ip2long($upper);
            my $ip_dec = ip2long($ip);
            return 1 if $ip_dec >= $lower_dec and $ip_dec <= $upper_dec;
        }
        return 0;
     }

}

sub ip2long{

    my $ip = shift;
    my $long = unpack('N',(pack('C4',(split(/\./,$ip)))));
    return $long;
}

sub long2ip{
    my $ip_dec = shift;
    my @ip_parts = unpack('C4',(pack('N',$ip_dec)));
    my $ip = join "\.",@ip_parts;
    return $ip;
}

sub str_replace{
    my ($from, $to, $string) = @_;

    my $length = length($from);

    my $p = 0;

    while ( ($p = index($string,$from,$p)) >= 0){
        substr($string,$p,$length) = $to;
    }
    return $string;


}




