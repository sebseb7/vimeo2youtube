#!/usr/bin/perl

#40 videos in yt before

use LWP::Simple;
use strict;

my $vimeo_userid = 'sebseb7';

my $vimeo = get('http://vimeo.com/'.$vimeo_userid.'/videos');


my $videos_per_page = 12;

my $pages;

if($vimeo =~ /data-title\=\"(\d+) Videos\"/)
{

	$pages = (int $1/12);

}

my @videos;

do {

	while($vimeo =~ /id\=\"clip_(\d+)\"/g)
	{
		push @videos,$1;
		warn "vdieo $1";
	}

	warn "get page ".($pages+1);
	$vimeo = get('http://vimeo.com/'.$vimeo_userid.'/videos/page:'.($pages+1).'/sort:date') if $pages > 0;

}until(! $pages--);

open feed,'>feed.xml_';

print feed "<feed xmlns=\"http://www.w3.org/2005/Atom\">\n\n	<title>Vimeo: Seb's FPV Videos</title>\n	<link rel=\"alternate\" type=\"text/html\" href=\"http://vimeo.com/sebseb7\"/>\n";

my $logo_ok = 0;

@videos = reverse sort @videos;

for(0..$#videos)
{
	print "{id,$videos[$_]}";

	my $id = $videos[$_];

	my $info = get('http://vimeo.com/api/v2/video/'.$videos[$_].'.xml');
	

	my $title;
	my $desc;
	my $date;
	my $logo;

	my $filetype;
	my $yt;


	my $file = `curl -H "X-Requested-With: XMLHttpRequest" -e http://vimeo.com/$id http://vimeo.com/$id\?action=download`;

	if($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>Original \.MP4 file\<\/a\>/)
	{
		$filetype='.mp4';
		if(! -f $id.'.mp4')
		{
			`wget -O $id.mp4 'www.vimeo.com$1'`;
		}
	}elsif($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>Original \.MOV file\<\/a\>/)
	{
		$filetype='.mov';
		if(! -f $id.'.mov')
		{
			`wget -O $id.mov 'www.vimeo.com$1'`;
		}
	}elsif($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>Original \.M4V file\<\/a\>/)
	{
		$filetype='.m4v';
		if(! -f $id.'.m4v')
		{
			`wget -O $id.m4v 'www.vimeo.com$1'`;
		}
	}elsif($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>Original \.AVI file\<\/a\>/)
	{
		$filetype='.avi';
		if(! -f $id.'.avi')
		{
			`wget -O $id.avi 'www.vimeo.com$1'`;
		}
	}elsif($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>Original \.VID file\<\/a\>/)
	{
		$filetype='.vid';
		if(! -f $id.'.vid')
		{
			`wget -O $id.vid 'www.vimeo.com$1'`;
		}
	}elsif($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>HD \.MP4 file\<\/a\>/)
	{
		$filetype='.mp4';
		if(! -f $id.'.mp4')
		{
			`wget -O $id.mp4 'www.vimeo.com$1'`;
		}
	}elsif($file =~ /\<a href\=\"([^\"]*)\" download\=\"([^\"]*)\" rel\=\"nofollow\"\>SD \.MP4 file\<\/a\>/)
	{
		$filetype='.mp4';
		if(! -f $id.'.mp4')
		{
			`wget -O $id.mp4 'www.vimeo.com$1'`;
		}
	}else
	{
		warn $file;
	}


	if($info =~ /\<title\>(.*)\<\/title\>/)
	{
		$title = $1;
	}
	if($info =~ /\<description\>(.*)\<\/description\>/)
	{
		$desc = $1;
	}
	if($info =~ /\<upload_date\>(.*)\<\/upload_date\>/)
	{
		$date = $1;
		$date =~ s/ /T/;
		$date.=".000Z";
	}
	if($info =~ /\<thumbnail_large\>(.*)\<\/thumbnail_large\>/)
	{
		$logo = $1;
	}

#	<link rel="logo" type="image/jpeg" href="http://i.ytimg.com/vi/cGn6EgcNs9I/default.jpg"/>
#	<logo>http://i.ytimg.com/vi/cGn6EgcNs9I/hqdefault.jpg</logo>
#	<link rel="	payment" href="https://flattr.com/submit/auto?user_id=Astro&amp;url=https://www.youtube.com/watch?v=cGn6EgcNs9I&amp;feature=youtube_gdata_player&amp;title=LEDWall%20Animations%20at%20C3D2"/>
#	<updated>2011-10-28T19:21:00.000Z</updated>


	if(! $logo_ok)
	{
		$logo_ok = 1;
		
		if($info =~ /\<user_portrait_huge\>(.*)\<\/user_portrait_huge\>/)
		{
			print feed "	<logo>$1</logo>\n";
		}
		
	}
	
	my $filename = $videos[$_].$filetype;



	if(! -f 'youtube_ok'.$filename)
	{
		my $desc2 = $desc;
		$desc2 =~  s/\&lt\;br \/\&gt\;/\n/go;
		use HTML::Entities;
		use Encode;
		$desc2 =  decode_entities($desc2);
		$desc2 =  encode_entities($desc2);
		warn Encode::encode("ISO-8859-1", $desc2);
		my $title2 =  decode_entities($title);
		my $title2 =  encode_entities($title2);
		my $return  =	`google youtube post --category Sports --title \'$title2\' --summary \'Vimeo: http://vimeo.com/$id (higher Quality)\nTorrent: http://bitlove.org/sebseb7/vimeo/$filename.torrent\n(highest Quality; original File)\n\n$desc2\' $filename 2>&1`;
		open  outfile,'>youtube_ok'.$filename;
		print outfile $return;
		close outfile;
		warn length($return);
		die if length($return) != 102;
		if($return =~ /uploaded\: http\:\/\/www\.youtube\.com\/watch\?v\=([^\&]+)\&feature/)
		{
			warn $1;
			$yt = 'http://www.youtube.com/watch?v='.$1;
		};
	}
	else
	{
		open infile,'youtube_ok'.$filename;
		local $/ = undef;
		my $file = <infile>;
		close infile;
		
		if($file =~ /uploaded\: http\:\/\/www\.youtube\.com\/watch\?v\=([^\&]+)\&feature/)
		{
			warn $1;
			$yt = 'http://www.youtube.com/watch?v='.$1;
			if(! get('http://www.youtube.com/watch?v='.$1))
			{
				warn 'not there';
				#unlink 'youtube_ok'.$filename;
			};
		}
	}


	print feed "

	<entry>
		<title>$title</title>
		<published>$date</published>
		<summary type=\"html\">$desc</summary>
		<link rel=\"logo\" type=\"image/jpeg\" href=\"$logo\"/>
		<logo>$logo</logo>
		<link rel=\"alternate\" type=\"text/html\" href=\"http://vimeo.com/".$videos[$_]."\"/>
		<link rel=\"alternate\" type=\"text/html\" href=\"$yt\"/>
		<link rel=\"enclosure\" href=\"http://video.exse.net/vimeo/".$videos[$_].$filetype."\"/>
		<link rel=\"alternate\" type=\"text/html\" href=\"$yt\"/>
		<link rel=\"payment\" href=\"https://flattr.com/submit/auto?user_id=sebseb7&amp;url=http://vimeo.com/".$videos[$_]."\"/>
	</entry>

";	


}


print feed "</feed>";
close feed;

rename "feed.xml_" , "feed.xml";