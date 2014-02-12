use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;
use lib qw(t/lib);
use DBICTest;

my $schema = DBICTest->init_schema();

my $base_rs = $schema->resultset('Artist')->search({ 'me.artistid' => 4 });
my $mo_rs = $base_rs->related_resultset('cds')->search(
  undef,
  {
    prefetch => [
      { tracks     => { cd_single => 'tracks' } },
      { cd_to_producer => 'producer' }
    ],

    result_class => 'DBIx::Class::ResultClass::HashRefInflator',

    order_by => [qw/cds.cdid tracks.title/],
  }
);

$schema->resultset('Artist')->create(
  {
    name => 'mo',
    rank => '1337',
    cds  => [
      {
        title  => 'Song of a Foo',
        year   => '1999',
        tracks => [
          { title  => 'Foo Me Baby One More Time' },
          { title  => 'Foo Me Baby One More Time II' },
          { title  => 'Foo Me Baby One More Time III' },
          { title  => 'Foo Me Baby One More Time IV', cd_single => {
            artist => 1, title => 'MO! Single', year => 2021, tracks => [
              { title => 'singled out' },
              { title => 'still alone' },
            ]
          } }
        ],
        cd_to_producer => [
          { producer => { name => 'riba' } },
          { producer => { name => 'sushi' } },
        ]
      },
      {
        title  => 'Song of a Foo II',
        year   => '2002',
        tracks => [
          { title  => 'Quit Playing Games With My Heart' },
          { title  => 'Bar Foo' },
          { title  => 'Foo Bar', cd_single => {
            artist => 2, title => 'MO! Single', year => 2020, tracks => [
              { title => 'singled out' },
              { title => 'still alone' },
            ]
          } }
        ],
        cd_to_producer => [
          { producer => { name => 'riba' } },
          { producer => { name => 'sushi' } },
        ],
      }
    ],
    artwork_to_artist => [
      { artwork => { cd_id => 1 } },
      { artwork => { cd_id => 2 } }
    ]
  }
);

my $mo = $mo_rs->next;

ok( $mo_rs->_resolved_attrs->{_ordered_for_collapse}, 'checks okay for ordered_for_collapse' );

cmp_deeply( $mo, {
  artist => 4,
  cd_to_producer => [
    {
      attribute => undef,
      cd => 6,
      producer => {
        name => 'riba',
        producerid => 4
      }
    },
    {
      attribute => undef,
      cd => 6,
      producer => {
        name => 'sushi',
        producerid => 5
      }
    }
  ],
  cdid => 6,
  genreid => undef,
  single_track => undef,
  title => 'Song of a Foo',
  tracks => [
    {
      cd => 6,
      cd_single => undef,
      last_updated_at => undef,
      last_updated_on => undef,
      position => 1,
      title => 'Foo Me Baby One More Time',
      trackid => 19
    },
    {
      cd => 6,
      cd_single => undef,
      last_updated_at => undef,
      last_updated_on => undef,
      position => 2,
      title => 'Foo Me Baby One More Time II',
      trackid => 20
    },
    {
      cd => 6,
      cd_single => undef,
      last_updated_at => undef,
      last_updated_on => undef,
      position => 3,
      title => 'Foo Me Baby One More Time III',
      trackid => 21
    },
    {
      cd => 6,
      cd_single => {
        artist => 1,
        cdid => 7,
        genreid => undef,
        single_track => 22,
        title => 'MO! Single',
        tracks => [
          {
            cd => 7,
            last_updated_at => undef,
            last_updated_on => undef,
            position => 1,
            title => 'singled out',
            trackid => 23
          },
          {
            cd => 7,
            last_updated_at => undef,
            last_updated_on => undef,
            position => 2,
            title => 'still alone',
            trackid => 24
          }
        ],
        year => '2021'
      },
      last_updated_at => undef,
      last_updated_on => undef,
      position => 4,
      title => 'Foo Me Baby One More Time IV',
      trackid => 22
    }
  ],
  year => '1999'
});

done_testing;
