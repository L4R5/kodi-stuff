#!/usr/bin/perl -w
# this script will download all files of a youtube user
# it will also use the cache file to not download files twice

use strict;

# use for atom feeds, which are used by youtube web api
use XML::FeedPP;

#my $source = "http://gdata.youtube.com/feeds/api/playlists/2E696FFCD74D1970";

my $YOUTUBE_FEEDS_CACHE = "/home/xbmc/etc/youtube_feeds.cache";
my $TARGET_DIR = ".";
my $DEBUG = 1;
my $YT_USER_URL = "http://gdata.youtube.com/feeds/api/users/%USER%/uploads?max-results=50&start-index=%INDEX%";

# returns youtube api url with username and start-index
sub getYoutubeApiUrl
{
	my $username = shift;
	my $startIndex = shift;
	my $url = $YT_USER_URL;
	$url =~ s/%USER%/$username/g;
	$url =~ s/%INDEX%/$startIndex/g;
	return $url;
}

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


if ($#ARGV != 0) {
	print "specify youtube username.\n";
	exit 1;
}

my $username = $ARGV[0];

print "DEBUG: username $username\n" if ($DEBUG);

# read cache
#my %cache = readCache($YOUTUBE_FEEDS_CACHE);
my %cache = ();


my $indexCounter = 1;
my $hasAdditionalVideos = 1;

while ($hasAdditionalVideos) {
	my $feedUrl = getYoutubeApiUrl($username, $indexCounter);
	my $feed = XML::FeedPP->new($feedUrl);
	my @items = $feed->get_item();
	my $noItems = $#items + 1;
	if ( $#items < 0 ) {
		$hasAdditionalVideos = 0;
	}
	print "no items:" . $noItems . "\ncounter: " . $indexCounter . "\n";
	$indexCounter += 50;

#	print "Title: ", $feed->title(), "\n";
#	print "Date: ", $feed->pubDate(), "\n";
	foreach my $item ( @items ) {
		my $title = $item->title();
		my $url = $item->link();
		if (exists $cache{$url}) {
			print "DEBUG: s: $url already downloaded\n" if ($DEBUG);
			next;
		}
		else {
			#chomp($type);
			print "DEBUG: youtube url: $url\n" if ($DEBUG);
			# clean up title from unwanted characters
			$title =~ s/\//\-/g;
			$title =~ s/\"/\\\"/g;
			print "DEBUG: title: $title\n" if ($DEBUG);
			#my $rc = system("wget -O \"$TARGET_DIR/$title.$type\" \"$video_url\"");
			#my $rc = system("get_flash_videos -y -r 720p -f \"" . $title. ".mp4\" \"$url\"");
			my $rc = system("get_flash_videos -y -r 1080p \"$url\"");
			if ($rc == 0) {
				# add to cache
				$cache{$url} = 1;
				# save cache after each download
				#saveCache($YOUTUBE_FEEDS_CACHE, \%cache);
			}
			#print "Video URL: $video_url\n";
			#print "type: $type\n";
		}

	}
}


#saveCache($YOUTUBE_FEEDS_CACHE, \%cache);
#print "rc: $rc\n";
