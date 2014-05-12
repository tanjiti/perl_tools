#!/usr/local/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use feature qw(switch say);
use Getopt::Long;
use Carp;
use Term::ANSIColor qw(:constants);

local $Term::ANSIColor::AUTORESET = 1;

my $help = q{};
my $proxy = q{};
my $fileout = q{};

GetOptions(
    'help|h'=>\$help,
    'proxy=s'=>\$proxy,
    'out=s'=>\$fileout,
);

if($help){
    print <<__HELP__;

Notice: In order to run this script you must have those modules installed

cpan -i LWP::UserAgent
cpan -i Getopt::Long
cpan -i Term::ANSIColor
cpan -i LWP::Protocol::https
cpan -i LWP::Protocol::socks

Usage: $0 -proxy http://xxx.xxx.xxx.:7808 [-out xxx]  or
	   $0 -proxy proxyfile [-out xxx] 

-proxy: Specify the proxy,it can ben a proxy string like "http://23.228.65.132:7808" or proxy list filename

-out: Specify the filename to storage good proxy

-h: For more help
__HELP__

	exit 0;
}
chomp $fileout;
chomp $proxy;

croak "You need to specify the proxy(proxyfile) \n Please run --help for more informations \n" if $proxy eq q{};

##################################################################
##  readFromFile(): storage the file contents into an array     ##
##  parameter: filename                                         ##
##  return: @contents array                                     ##
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

sub writeToFile{
	my ($content_ref, $filename)= @_;
	my @contents = @$content_ref;

	open my ($FH), ">", $filename or die "cannot open $filename for reading:  $! \n";
	select $FH;

	foreach (@contents){

		say  $_;
	}
	select STDOUT;
	close $FH;


}

sub isProxyOK{
    my $proxy = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0");
    $ua->timeout(10);
    $ua->default_headers->push_header('Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8');
    $ua->default_headers->push_header('Accept-Encoding'=>'gzip,deflate,sdch');
    $ua->default_headers->push_header('Host' => "www.baidu.com");
    $ua->default_headers->push_header('Connection' => 'keep-alive');
    $ua->proxy([qw/http https/] => $proxy);
    $ua->show_progress(1);
    my $response = $ua->get('http://www.baidu.com');
    return $response->code == 200 ? 1: 0;

}

my @proxys = -r $proxy ? readFromFile($proxy) : $proxy;


my @ok_proxys = ();

foreach  (@proxys){
    my $result = isProxyOK($_);

	if ($result){
    	say BOLD RED "Proxy: $_ OK";
    	push @ok_proxys, $_ if $result;
    }else{
    	say BOLD YELLOW "Proxy: $_ NOT OK";
    }
    	
}

if (-r $proxy or $fileout){
	$fileout = $proxy."_out" unless $fileout;
	writeToFile(\@ok_proxys,$fileout);
}
