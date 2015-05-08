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

# 160          mp4        256x144    DASH video  110k , 15fps, video only, 3.84MiB
# 278          webm       256x144    DASH video  117k , webm container, VP9, 15fps, video only, 3.17MiB
#
# 133          mp4        426x240    DASH video  251k , 30fps, video only, 8.62MiB
# 242          webm       426x240    DASH video  279k , 30fps, video only, 6.67MiB
#
# 243          webm       640x360    DASH video  541k , 30fps, video only, 12.28MiB
# 134          mp4        640x360    DASH video  606k , 30fps, video only, 15.28MiB
#
# 244          webm       854x480    DASH video  984k , 30fps, video only, 21.24MiB
# 135          mp4        854x480    DASH video 1111k , 30fps, video only, 30.05MiB
#
# 247          webm       1280x720   DASH video 2111k , 30fps, video only, 42.44MiB
# 136          mp4        1280x720   DASH video 2221k , 30fps, video only, 59.09MiB
#
# 302          webm       1280x720   DASH video 3295k , VP9, 60fps, video only, 31.27MiB
# 298          mp4        1280x720   DASH video 3317k , h264, 60fps, video only, 40.35MiB
#
# 248          webm       1920x1080  DASH video 3892k , 30fps, video only, 78.31MiB
# 137          mp4        1920x1080  DASH video 4199k , 30fps, video only, 117.84MiB
#
# 299          mp4        1920x1080  DASH video 5520k , h264, 60fps, video only, 70.71MiB
# 303          webm       1920x1080  DASH video 5565k , VP9, 60fps, video only, 58.85MiB

my @VIDEO_PREFS = ( 299, 303, 137, 248, 298, 302, 136, 247, 135, 244, 134, 243 );
# 171 webm       audio only DASH audio  118k , audio@128k (44100Hz), 3.83MiB
# 140 m4a        audio only DASH audio  129k , m4a_dash container, aac  @128k (44100Hz), 4.52MiB
# 141 m4a        audio only DASH audio  255k , m4a_dash container, aac  @256k (44100Hz), 8.97MiB
my @AUDIO_PREFS = ( 141, 140 );



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
                        my $cmd = "";
			my $cmd_opts = "";
			if ($feed_url =~ /youtube\.com/) {
				my $v = 0;
				my $vm = -1;
				my $a = 0;
				my $am = -1;
				# get available formats
				open(CMD, "/home/xbmc/bin/youtube-dl -F \"$url\" |");
				while(my $line = <CMD>) {
          #print "cmd out: " . $line;
					if ( $line =~ /^(\d+)/) {
						my $format = $1;
						#print "available format detected: $format\n";
						for (my $i = 0; $i <= $#VIDEO_PREFS; $i++) {
							#print "i: $i\n";
							if ($VIDEO_PREFS[$i] == $format) {
								if($v == 0) {
									$v = $format;
									$vm = $i;
									#print "select video: $v\n";
									$i = $#VIDEO_PREFS + 1;
								} elsif ($vm > $i) {
									$v = $format;
									$vm = $i;
									#print "select better video: $v\n";
									$i = $#VIDEO_PREFS + 1;
								}
							}
						}
						
						for (my $i = 0; $i <= $#AUDIO_PREFS; $i++) {
							if ($AUDIO_PREFS[$i] == $format) {
								if($a == 0) {
									$a = $format;
									$am = $i;
									#print "select audio: $a\n";
									$i = $#AUDIO_PREFS + 1;
								} elsif ($am > $i) {
									$a = $format;
									$am = $i;
									#print "select better audio: $a\n";
									$i = $#AUDIO_PREFS + 1;
								}
							}
						}
					}
				}
				close(CMD);
				if ($a == 0 || $v == 0) {
					$a = "bestaudio";
					$v = "bestvideo";
				}

				$cmd = "/home/xbmc/bin/youtube-dl -f \"$v+$a\" -o \"" . $TARGET_DIR . "/%(uploader)s - %(title)s.%(ext)s\" --merge-output-format mkv \"$url\"";
			} elsif ($feed_url =~ /zdf\.de/) {
				$cmd_opts = "-r high";
				$cmd = "get_flash_videos -y " . $cmd_opts . " -f \"" . $TARGET_DIR . "/" . $channelTitle . " - " . $title. ".mp4\" \"$url\"";
			} elsif ($feed_url =~ /ardmediathek\.de/) {
				$cmd_opts = "-r high";
				$cmd = "get_flash_videos -y " . $cmd_opts . " -f \"" . $TARGET_DIR . "/" . $channelTitle . " - " . $title. ".mp4\" \"$url\"";
			}

			print ($cmd . "\n");
			my $rc = system($cmd);
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
