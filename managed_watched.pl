#!/usr/bin/perl -w

use strict;
use JSON::RPC::LWP;
use Data::Dumper;
use Getopt::Std;
use File::Copy;
use File::Basename;
use Encode;

my $XBMC_JSON_API_URL = "http://127.0.0.1:8080/jsonrpc";
my $DEFAULT_PATH = "/media/daten1/Neu";
my $SOURCE_PREFIX = "nfs://192.168.6.3";

my $WATCHED_PATH = "/home/xbmc/Neu/angesehen";
my $WATCH_LIST_CACHE = "/home/xbmc/etc/watch-list.cache";
# time after which the file will be moved after the files was watched
# one day = 86400 seconds
my $MOVE_WAIT_TIME = 86400;
#my $MOVE_WAIT_TIME = 10;
# time after which a file gets deleted 14 days
my $DELETE_WAIT_TIME = 1209600;
#my $DELETE_WAIT_TIME = 10;


my $optString = 'eh';
my %opt = ();
getopts ($optString, \%opt);
binmode STDOUT, ":utf8";

sub usage {
  print "$0 [-e]\n";
}


# param: cache file path
# returns: hashtable of moved files with move time
#   { $filename => $time }
sub loadCache {
  if ($#_ != 0) {
    return undef;
  }
  my $cacheFile = shift;
  my %cache = ();
  return %cache if ( !-e $cacheFile);
  open(CACHE_FILE, "<".$cacheFile) or die("Could not open cache file: ".$cacheFile);
  binmode CACHE_FILE, ":utf8";
  while (my $line = <CACHE_FILE>) {
    next if ($line =~ /^$/);
    # line format
    # 1417779604,filename
    chomp($line);
    my $date = substr($line, 0, 10);
    my $filename = substr($line, 11);
    $cache{$filename} = $date;
  }
  close(CACHE_FILE);
  return %cache;
}

# save the cache
# param: cache file
# param: cache hash reference
sub saveCache {
  if ($#_ != 1) {
    return -1;
  }
  my $cacheFile = shift;
  my $cache_ptr = shift;
  my %cache = %$cache_ptr;
  open(CACHE_FILE, ">".$cacheFile) or die("Could not write file: ".$cacheFile);
  binmode CACHE_FILE, ":utf8";
  foreach my $key(keys %cache) {
    print CACHE_FILE $cache{$key} . "," . $key . "\n";
    print $cache{$key} . "," . $key . "\n";
  }
  close(CACHE_FILE);
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

# load cache
my %cache = loadCache($WATCH_LIST_CACHE);

# http://htpc:8080/jsonrpc?request={%22jsonrpc%22:%222.0%22,%22id%22:1,%22method%22:%22Files.GetDirectory%22,%22params%22:{%22directory%22:%22/home/xbmc/Neu%22,%22media%22:%22video%22}}

# http://htpc:8080/jsonrpc?request={"jsonrpc":"2.0","id":1,"method":"Files.GetDirectory","params":{"directory":"/home/xbmc/Neu","media":"video"}}

my $rpc = JSON::RPC::LWP->new();
my $res = $rpc->call(
    $XBMC_JSON_API_URL,
    'Files.GetDirectory', $SOURCE_PREFIX . $path, "video", ["title", "playcount", "file" ]
    #'{ "directory":"' . $path . '", "media":"video", "properties",[ "title", "playcount", "file" ] }'
  );

my @result = $res->result;

#print Dumper \@result;

my %a1 = %{$result[0]};

my @a2 = @{$a1{"files"}};


# loop through already moved files and delete after wait time has expired
opendir(DIR, $WATCHED_PATH) || die "Can't open directory $WATCHED_PATH: $!";
my @dir = grep !/^\.\.?$/, readdir(DIR);
$_ = decode( 'utf8', $_ ) for ( @dir );
closedir DIR;

foreach my $file (@dir) {
  chomp($file);
  if ( exists $cache{$file} ) {
    my $date = $cache{$file};
    if ( time() - $date >= $DELETE_WAIT_TIME ) {
      print "unlink($WATCHED_PATH . \"/\" . $file)\n";
      unlink($WATCHED_PATH . "/" . $file) if ($execute);
      delete($cache{$file}) if ($execute);
    } else {
      print "wait delete: $file\n";
    }
  } else {
    $cache{$file} = time();
    print "new delete: $file\n";
  }
}

# loop through the new files
# watched files will be moved after wait time has expired
foreach my $file (@a2) {
  my %file = %{$file};
  my $name = $file{"file"};
  my $type = $file{"filetype"};
  if ( $type eq "file" ) {
    my $count = $file{"playcount"};
    if ( defined $count && $count >= 1 ) {
      # remix the source prefix from the filename to map to local directory
      $name =~ s/$SOURCE_PREFIX//g;
      my $basename = basename($name);
      if ( exists $cache{$basename} ) {
        my $date = $cache{$basename};
        if ( time() - $date >= $MOVE_WAIT_TIME ) {
          # move file to watched dir after wait time
          print "move($name, $WATCHED_PATH)\n";
          move($name, $WATCHED_PATH) if ($execute);
          $cache{$basename} = time() if ($execute);
        } else {
          print "wait: $name\n";
        }
      } else {
        $cache{$basename} = time();
        print "new: $name\n";
      }
    }
  }
}

saveCache($WATCH_LIST_CACHE, \%cache);
