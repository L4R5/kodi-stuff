#!/usr/bin/perl -w
#
use strict;
use Expect;
use LWP::UserAgent;

########################################################
# Modify here 
########################################################
my $configFile = "/var/lib/mldonkey/rss_feeds.cfg";
my $cacheFile = "/var/lib/mldonkey/rss_feed_cache";
my $telnet = "/usr/bin/telnet";
my $wget = "/usr/bin/wget";
my $server = "localhost";
my $port = "4000";
my $mailAddress = "mldonkey";

# TODO
# check if internet connectivity is available
my $DEBUG = 0;


########################################################
# Do not modify here
########################################################
my $username = "rss";
my $password = "RsS74vG8a";
my $timeout = 5;

my %feedUrls = readFeeds($configFile);
my %cache = readCache($cacheFile);

# loop through all shows, extract the feeds, links and download the new stuff
foreach my $feedUrl(keys %feedUrls)
{
	my $feedType = $feedUrls{$feedUrl};
	my @feedContent = getFeedContent($feedUrl);
	my @links = extractLinks(@feedContent);

	# loop through all extracted links and add new downloads
	foreach my $link (@links)
	{
		# check if we already downloaded this one
		if (exists $cache{$link})
		{
			print "DEBUG: s: $link already downloaded\n" if ($DEBUG);
			next;
		}
		else
		{
			# add download
			if (addDlLinks($server, $port, $username, $password, $link, $feedType))
			{
				# add to cache
				$cache{$link} = 1;
			}
			else
			{
				sendMail($mailAddress, "RSS feed reader download error", "There was an error while adding the following url: ".$link);
			}
		}
	}	
	print "done: $feedUrl\n";
}

saveCache($cacheFile);

##########################################################
# sub routines
##########################################################

# needed parameters
# 1: configuration file with feed addresses and feed type
# return: list fo feed urls
sub readFeeds
{
	print "DEBUG: reading feeds\n" if ($DEBUG);
	if ($#_ != 0)
	{
		return undef
	}
	my $file = shift;
	open(FILE, "<".$file) or die("Could not open configuration file: ".$file);
	my %feedUrls = ();
	while (my $line = <FILE>)
	{
			chomp($line);
			# get the url
			if ($line =~ /^\#|^$/)	# ignore the hash sign
			{
				next;
			}

			my ($type, $link) = split(/\|/, $line);
			if ($link =~ /^http:\/\/.*/)
			{
				$feedUrls{$link} = $type;
			}
			else
			{
				# something is wrong in the configuration file
				sendMail($mailAddress, "RSS feed reader configuration error", "The following line in ".$file." contains an error:\n\n".$line);
			}
	}
	close(FILE);
	return %feedUrls;

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
	open(CACHE_FILE, "<".$cacheFile) or die("Could not open cache file: ".$cacheFile);
	while (my $line = <CACHE_FILE>)
	{
		chomp($line);
		$cache{$line} = "1";
	}
	close(CACHE_FILE);
	return %cache;
}

# needed parameters
# 1: server
# 2: port
# 3: username
# 4: password
# 5: links
# 6: feed type
sub addDlLinks
{
	if ($#_ < 4)
	{
		return -1;
	}
	my ($server, $port, $username, $password, $link, $feedType) = @_;
	my @params = ($server, $port);
	my $authString = "auth ".$username." ".$password."\r";
	print "debug: feedtype: $feedType\n";

	my $exp = new Expect;
	$exp->raw_pty(1);
	$exp = Expect->spawn($telnet, @params) or die("Could not spawn: $telnet @params\n");

	$exp->send($authString);

	my $match = $exp->expect($timeout, "Full access enabled");

	if (defined $match)	# if authentification was successful, add the download link
	{
		# the feed type is also the correct command
		$exp->send($feedType . " \"".$link."\"\r");
		my $matchDl = $exp->expect($timeout, "Parsing HTTP url : ".$link);
		if (!defined $matchDl)
		{
			return -1;
		}
	}
	else
	{
		# something went wrong during authentification
		return -1;
	}


	$exp->send("quit\r");
	$exp->soft_close();
	return 1;

}

# parameters needed:
# # 1: address
# # 2: subject
# # 3: text
sub sendMail
{
	return -1 if ($#_ != 2);
	my ($address, $subject, $text) = @_;
	return system("echo \"".$text."\" | mail -s \"".$subject."\" ".$address);
}


# parameters
# 1: http link
sub getFeedContent
{
	print "DEBUG: getFeedContent\n" if ($DEBUG);


	if ($#_ != 0)
	{
		return undef;
	}
	my $link = shift;
	my $browser = LWP::UserAgent->new;
	$browser->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; en) Opera 9.00");
	my $request = HTTP::Request->new(GET => $link);
	my $response = $browser->request($request);
	if ($response->is_success)
	{
		print "DEBUG: returncode: ".$response->code."\n" if ($DEBUG);
		#print "DEBUG: feedcontent: ".$response->content."\n" if ($DEBUG);
		my $content = $response->content;
		$content =~ s/></>\n</g;
		return split(/\n/, $content);
	}
	else
	{
		# TODO send error mail
		print "DEBUG: http request failed\n" if ($DEBUG);
		return undef;
	}

	
}

# parameters
# 1: array with feed content
sub extractLinks
{
	return undef if ($#_ < 0);
	my @content = @_;
	my @links = ();

	foreach my $line(@content)
	{
		if ($line =~ /<enclosure\ url=\"(http:\/\/[\w;\/\.\[\]\?=&\-]+)\"/)
		{
			my $link = $1;
			$link =~ s/amp;//g;
			push (@links, $link);
			print "DEBUG: link: $1\n" if ($DEBUG);
		}
		if ($line =~ /<enclosure\ \S+\ url=\"(http:\/\/[\w;\/\.\[\]\?=&\-]+)\"/)
		{
			my $link = $1;
			$link =~ s/amp;//g;
			push (@links, $link);
			print "DEBUG: link: $1\n" if ($DEBUG);
		}
	}
	return @links;
}

# parameters
# 1: cache file
sub saveCache
{
	if ($#_ != 0)
	{
		return -1;
	}
	my $cacheFile = shift;
	open(CACHE_FILE, ">".$cacheFile) or die("Could not write file: ".$cacheFile);
	foreach my $key(keys %cache)
	{
		print CACHE_FILE $key."\n";
	}
	close(CACHE_FILE);
}
