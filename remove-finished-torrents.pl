#!/usr/bin/perl -w

use strict;

sub deleteTorrent {
  my $torrent = shift;
  system("deluge-console rm $torrent");
  return 1;
}

open (my $CMD, "/usr/bin/deluge-console info |") or die "Could not execute deluge-console\n";


my $id = "";
my $state = "";
while (my $line = <$CMD>) {
  #print "line: $line";
  if ($line =~ /ID:\ ([a-z\d]+)/) {
    $id = $1;
    #print "ID: $id\n";
  } elsif ($line =~ /State:\ (\w+)/) {
    $state = $1;
    #print "State: $state\n";
    #if ( $state eq "Seeding" || $state eq "Paused" ) {
    if ( $state eq "Seeding" ) {
      if (qx(grep $id /home/xbmc/etc/deluge-whitelist.conf) eq "$id\n" ) {
        print "ignore torrent (whitelist): $id\n";
        next;
      } else {
        print "delete torrent: $id\n";
        deleteTorrent($id);
      }
    } else {
      print "ignore torrent (still downloading): $id\n";
    }
  }
}

close($CMD);
