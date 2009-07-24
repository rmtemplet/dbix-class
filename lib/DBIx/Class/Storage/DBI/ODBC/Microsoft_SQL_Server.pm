package DBIx::Class::Storage::DBI::ODBC::Microsoft_SQL_Server;
use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBI::MSSQL/;
use mro 'c3';

use Carp::Clan qw/^DBIx::Class/;
use List::Util();
use Scalar::Util ();

__PACKAGE__->mk_group_accessors(simple => qw/
  _using_dynamic_cursors
/);

=head1 NAME

DBIx::Class::Storage::DBI::ODBC::Microsoft_SQL_Server - Support specific
to Microsoft SQL Server over ODBC

=head1 DESCRIPTION

This class implements support specific to Microsoft SQL Server over ODBC.  It is
loaded automatically by by DBIx::Class::Storage::DBI::ODBC when it detects a
MSSQL back-end.

Most of the functionality is provided from the superclass
L<DBIx::Class::Storage::DBI::MSSQL>.

=head1 MULTIPLE ACTIVE STATEMENTS

The following options are alternative ways to enable concurrent executing
statement support. Each has its own advantages and drawbacks.

=head2 connect_call_use_dynamic_cursors

Use as:

  on_connect_call => 'use_dynamic_cursors'

in your L<DBIx::Class::Storage::DBI/connect_info> as one way to enable multiple
concurrent statements.

Will add C<< odbc_cursortype => 2 >> to your DBI connection attributes. See
L<DBD::ODBC/odbc_cursortype> for more information.

Alternatively, you can add it yourself and dynamic cursor will be automatically
enabled.

This will not work with CODE ref connect_info's and will do nothing if you set
C<odbc_cursortype> yourself.

B<WARNING:> this will break C<SCOPE_IDENTITY()>, and C<SELECT @@IDENTITY> will
be used instead, which on SQL Server 2005 and later will return erroneous
results on tables which have an on insert trigger that inserts into another
table with an C<IDENTITY> column.

=cut

sub connect_call_use_dynamic_cursors {
  my $self = shift;

  if (ref($self->_dbi_connect_info->[0]) eq 'CODE') {
    croak 'cannot set DBI attributes on a CODE ref connect_info';
  }

  my $dbi_attrs = $self->_dbi_connect_info->[-1];

  unless (ref($dbi_attrs) && Scalar::Util::reftype($dbi_attrs) eq 'HASH') {
    $dbi_attrs = {};
    push @{ $self->_dbi_connect_info }, $dbi_attrs;
  }

  if (not exists $dbi_attrs->{odbc_cursortype}) {
    # turn on support for multiple concurrent statements, unless overridden
    $dbi_attrs->{odbc_cursortype} = 2;
    my $connected = defined $self->_dbh;
    $self->disconnect;
    $self->ensure_connected if $connected;
    $self->_set_dynamic_cursors;
  }
}

sub _set_dynamic_cursors {
  my $self = shift;
  $self->_using_dynamic_cursors(1);
  $self->_identity_method('@@identity');
}

sub _rebless {
  no warnings 'uninitialized';
  my $self = shift;

  if (ref($self->_dbi_connect_info->[0]) ne 'CODE' &&
      eval { $self->_dbi_connect_info->[-1]{odbc_cursortype} } == 2) {
    $self->_set_dynamic_cursors;
    return;
  }

  $self->_using_dynamic_cursors(0);
}

=head2 connect_call_use_server_cursors

Use as:

  on_connect_call => 'use_server_cursors'

May allow multiple active select statements. See
L<DBD::ODBC/odbc_SQL_ROWSET_SIZE> for more information.

Takes an optional parameter for the value to set the attribute to, default is
C<2>.

B<WARNING>: this does not work on all versions of SQL Server, and may lock up
your database!

=cut

sub connect_call_use_server_cursors {
  my $self            = shift;
  my $sql_rowset_size = shift || 2;

  $self->_dbh->{odbc_SQL_ROWSET_SIZE} = $sql_rowset_size;
}

=head2 connect_call_use_mars

Use as:

  on_connect_call => 'use_mars'

Use to enable a feature of SQL Server 2005 and later, "Multiple Active Result
Sets". See L<DBD::ODBC::FAQ/Does DBD::ODBC support Multiple Active Statements?>
for more information.

B<WARNING>: This has implications for the way transactions are handled.

=cut

sub connect_call_use_mars {
  my $self = shift;

  my $dsn = $self->_dbi_connect_info->[0];

  if (ref($dsn) eq 'CODE') {
    croak 'cannot change the DBI DSN on a CODE ref connect_info';
  }

  if ($dsn !~ /MARS_Connection=/) {
    $self->_dbi_connect_info->[0] = "$dsn;MARS_Connection=Yes";
    my $connected = defined $self->_dbh;
    $self->disconnect;
    $self->ensure_connected if $connected;
  }
}

1;

=head1 AUTHOR

See L<DBIx::Class/CONTRIBUTORS>.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
# vim: sw=2 sts=2
