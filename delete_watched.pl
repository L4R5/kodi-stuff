#!/usr/bin/perl -w

use strict;
use JSON::RPC::LWP;
use Data::Dumper;
use Getopt::Std;

my $XBMC_JSON_API_URL = "http://127.0.0.1:8080/jsonrpc";
my $DEFAULT_PATH = "/home/xbmc/Neu";


my $optString = 'p:eh';
my %opt = ();
getopts ($optString, \%opt);

sub usage {
  print "$0 [-p <path>] [-e]\n";
}

my $path = $opt{p};
my $execute = $opt{e};
my $help = $opt{h};

if (defined $help) {
  usage();
  exit 0;
}

if (!defined $path) {
  $path = $DEFAULT_PATH;
}

if (!-d $path) {
  print "path does not exist or is not a directory\n";
  usage();
}

# http://htpc:8080/jsonrpc?request={%22jsonrpc%22:%222.0%22,%22id%22:1,%22method%22:%22Files.GetDirectory%22,%22params%22:{%22directory%22:%22/home/xbmc/Neu%22,%22media%22:%22video%22}}

# http://htpc:8080/jsonrpc?request={"jsonrpc":"2.0","id":1,"method":"Files.GetDirectory","params":{"directory":"/home/xbmc/Neu","media":"video"}}

my $rpc = JSON::RPC::LWP->new();
my $res = $rpc->call(
    $XBMC_JSON_API_URL,
    'Files.GetDirectory', $path, "video", ["title", "playcount", "file" ]
    #'{ "directory":"' . $path . '", "media":"video", "properties",[ "title", "playcount", "file" ] }'
  );

my @result = $res->result;

#print Dumper \@result;

my %a1 = %{$result[0]};

my @a2 = @{$a1{"files"}};

binmode STDOUT, ":utf8";
foreach my $file (@a2) {
  my %file = %{$file};
  my $name = $file{"file"};
  my $type = $file{"filetype"};
  if ( $type eq "file" ) {
    my $count = $file{"playcount"};
    #print $name .": " . $count . "\n";
    if ( defined $count && $count >= 1 ) {
      print $name . "\n";
      if ($execute) {
        unlink $name
      }
    }
  }
}

