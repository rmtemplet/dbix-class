use strict;
use warnings;

# see https://rt.cpan.org/Ticket/Display.html?id=91375

use Test::More;

use lib 't/lib';
use DBICTest;
use DBIC::SqlMakerTest;
use DBICTest::RunMode;

my $schema = DBICTest->init_schema();

use DBICTest::Schema::Artist;

my $artist_rs = $schema->resultset('Artist');

my $rel_rs = $artist_rs->search_related(cds_with_genre => { artist => 1 });

is_deeply(
    $rel_rs->all_hri,
    [
        {
          'year' => '1999',
          'single_track' => undef,
          'genreid' => 1,
          'artist' => 1,
          'title' => 'Spoonful of bees',
          'cdid' => 1
        },
    ],
    'query ran successfully',
);

done_testing;
