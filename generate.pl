#!/usr/bin/env perl

use strict;

use Time::Piece;
use Date::Language;
use SVG::Graph;
use SVG::Graph::Data;
use SVG::Graph::Data::Datum;
use DBI;


my $dbh = DBI->connect( 
	"dbi:SQLite:dbname=:memory:",
	"",                          
	"",                          
	{ RaiseError => 1 },         
) or die $DBI::errstr;

$dbh->do("DROP TABLE IF EXISTS log");
$dbh->do("CREATE TABLE log (ID INTEGER PRIMARY KEY, DATUM DATETIME)");

my $lang = Date::Language->new('English');
my $date;

while ( <> )
{	
	chomp;
	if ( /\d{5,}:\ \ ===\ sync/)
	{
		s/:\ \ ===\ sync//;
		$date = localtime($_)->strftime('%Y-%m-%dT%H:%M:%S')
	}
	elsif ( /^Date:\ \ \ /)
	{
		s/^Date:\ \ \ //;
		$date = localtime($lang->str2time($_))->strftime('%Y-%m-%dT%H:%M:%S')
	}
	else
	{
		next
	}

	$dbh->do("insert into log (DATUM) values ('" . $date . "')");
}

my $sth = $dbh->prepare("
		select 
			count(*) c, 
			cast (round((julianday(a.DATUM) - julianday(b.DATUM)) * 24 , 10) as int) m
		from 
			log a,
			log  b
		where 
			a.id = b.id + 1
		group by 
			cast (round((julianday(b.DATUM) - julianday(a.DATUM)) * 24 , 10 ) as int) 
		having  
			cast (round((julianday(a.DATUM) - julianday(b.DATUM)) * 24 , 0 ) as int) < 5 * 
				(
				select 
					avg(cast (round((julianday(c.DATUM)- julianday(d.DATUM)) * 24 , 0 ) as int)) 
				from 
					log c , log  d 
				where 
					c.id = d.id +1 
				) 
		order by 
			2; 
");

$sth->execute();
my $all = $sth->fetchall_arrayref();
my @scat = ();
foreach my $row (@$all) {
	my ($c, $m) = @$row;
	push @scat, SVG::Graph::Data::Datum->new(x=>$m,y=>$c);
}

$dbh->disconnect();

my $graph = SVG::Graph->new(width=>1000,height=>1000,margin=>30);
my $frame = $graph->add_frame;
my $data = SVG::Graph::Data->new(data => \@scat);
$frame->add_data($data);
$frame->add_glyph('axis',
	'x_absolute_ticks' => 60,
	'y_absolute_ticks' => 100,
	'stroke'           => 'black',
	'stroke-width'     => 1,
  );

$frame->add_glyph('scatter',
	'stroke' => 'red',
	'fill'   => 'red',
	'fill-opacity' => 0.5,
);

print $graph->draw;


