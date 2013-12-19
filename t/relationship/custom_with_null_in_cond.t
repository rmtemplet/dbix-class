use strict;
use warnings;

# see https://rt.cpan.org/Ticket/Display.html?id=91375

use Test::More;

use lib 't/lib';
use DBICTest;

my $schema = DBICTest->init_schema();

my $artist_rs = $schema->resultset('Artist');

my $rel_rs = $artist_rs->search_related(cds_without_genre => { artist => 1 }, { order_by => 'cdid' });

is_deeply(
  $rel_rs->all_hri,
  [
    {
      artist => 1,
      cdid => 2,
      genreid => undef,
      single_track => undef,
      title => "Forkful of bees",
      year => 2001
    },
    {
      artist => 1,
      cdid => 3,
      genreid => undef,
      single_track => undef,
      title => "Caterwaulin' Blues",
      year => 1997
    },
  ]
);

done_testing;
