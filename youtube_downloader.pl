#!/usr/bin/perl -w

use strict;

# use for atom feeds, which are used by youtube web api
use XML::FeedPP;

#my $source = "http://gdata.youtube.com/feeds/api/playlists/2E696FFCD74D1970";

# use relative path for testing
my $YOUTUBE_FEEDS_CFG = "/home/xbmc/etc/youtube_feeds.cfg";
my $YOUTUBE_FEEDS_CACHE = "/home/xbmc/etc/youtube_feeds.cache";
# replaced by get_flash_video
#my $GET_YOUTUBE_VIDEO_URL = "/var/lib/mldonkey/get_youtube_video_url.php";
my $TARGET_DIR = "/media/daten1/Neu";
my $DEBUG = 1;



# needed parameters
# 1: cache file
# returns: hashtable of already downloaded titles
sub readCache
{
        if ($#_ != 0)
        {
                return undef;
        }
        my $cacheFile = shift;
        my %cache = ();
        return %cache if ( !-e $cacheFile);
		open(CACHE_FILE, "<".$cacheFile) or die("Could not open cache file: ".$cacheFile);
        while (my $line = <CACHE_FILE>)
        {
                chomp($line);
                $cache{$line} = "1";
        }
        close(CACHE_FILE);
        return %cache;
}

# parameters
# 1: cache file
# 2: cache hash
sub saveCache
{
		
		print "args: " . $#_ . "\n";
        if ($#_ != 1) {
                return -1;
        }
        my $cacheFile = shift;
	my $cache_ptr = shift;
	my %cache = %$cache_ptr;
        open(CACHE_FILE, ">".$cacheFile) or die("Could not write file: ".$cacheFile);
        foreach my $key(keys %cache)
        {
		#print "$key\n";
                print CACHE_FILE $key."\n";
        }
        close(CACHE_FILE);
}




if ( !-r "$YOUTUBE_FEEDS_CFG")
{
	print "cannot read $YOUTUBE_FEEDS_CFG. Exiting...\n";
	exit (1);
}

# read feeds from config file
my @feeds = ();
open(FEEDS, "<$YOUTUBE_FEEDS_CFG") or die ("coud not read $YOUTUBE_FEEDS_CFG\n");
while (my $line = <FEEDS>) {
	# remove lines starting with #
	if ($line !~ /^#/ && $line !~ /^$/) {
		push(@feeds, $line);
	}
}
close (FEEDS);

# read cache
my %cache = readCache($YOUTUBE_FEEDS_CACHE);




# iterate through feeds
foreach my $feed_url (@feeds) {
	my $feed = XML::FeedPP->new($feed_url);

	print "Title: ", $feed->title(), "\n";
#	print "Date: ", $feed->pubDate(), "\n";

	foreach my $item ( $feed->get_item() ) {
		my $title = $item->title();
		my $url = $item->link();
		print "title: $title -> url: $url\n";
		if (exists $cache{$url}) {
			print "DEBUG: s: $url already downloaded\n" if ($DEBUG);
			next;
		}
		else {
			#print "download $title via wget here\n";
			# clean up title from unwanted characters
			$title =~ s/\//\-/g;
			$title =~ s/\"/\\\"/g;
			$title =~ s/\´//g;
			$title =~ s/\`//g;

			my $channelTitle = $feed->title();
			$channelTitle =~ s/Uploads\ by\ //ig;
			my $cmd_opts = "";
			if ($feed_url =~ /gdata\.youtube\.com/) {
				$cmd_opts = "-r 1080p"
			} elsif ($feed_url =~ /zdf\.de/) {
				$cmd_opts = "-r high"
			} elsif ($feed_url =~ /ardmediathek\.de/) {
				$cmd_opts = "-r high"
			}
			my $rc = system("get_flash_videos -y " . $cmd_opts . " -f \"" . $TARGET_DIR . "/" . $channelTitle . " - " . $title. ".mp4\" \"$url\"");
			print ("get_flash_videos -y " . $cmd_opts . " -f \"" . $TARGET_DIR . "/" . $channelTitle . " - " . $title. ".mp4\" \"$url\"\n");
			if ($rc == 0 || $feed_url =~ /zdf\.de/) {
				print "DEBUG: add to download cache: $url\n";
				# add to cache
				$cache{$url} = 1;
				# save cache after each download
				saveCache($YOUTUBE_FEEDS_CACHE, \%cache);
			}
			#print "Video URL: $video_url\n";
			#print "type: $type\n";
			#print ("$GET_YOUTUBE_VIDEO_URL \"$url\"\n");
		}

	}
}


saveCache($YOUTUBE_FEEDS_CACHE, \%cache);
#print "rc: $rc\n";
