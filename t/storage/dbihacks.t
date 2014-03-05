use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib qw(t/lib);
use DBICTest;

my $schema = DBICTest->init_schema( sqlite_use_file => 1 );

lives_ok( sub {
    $schema->resultset('CD')->search({
        -and => [
            \[
                "LOWER(me.title) LIKE ?",
                [
                    'plain_value',
                    '%spoon%',
                ]
            ],
#            [
#                #{ 'artist.name' => 'Caterwauler McCrae' },
#                { 'me.title' => 'Spoonful of bees' },
#            ],
        ],
    }, {
        #join => 'artist',
        #join => {},
        #prefetch => 'tracks',
        #prefetch => [],
        order_by => [ 'me.title' ],
        page => 2,
        rows => 2,
    })->all;
    }, 'nested arrayrefs ok');

done_testing;
