#!/usr/bin/perl

use Time::Piece;
use Date::Language;

print "DROP TABLE IF EXISTS log;\n";
print "CREATE TABLE log (DATUM DATETIME);\n";

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

	print "insert into log values ('" . $date . "');\n"
}

print "SELECT 
		date(DATUM, '-15 Minute' ),
		count(*),
		cast(ROUND(count(*) /.24,0) as int) || '%'  
	FROM log 
	GROUP BY date( DATUM, '-15 Minute')
	ORDER BY date( DATUM) ASC ;\n"
