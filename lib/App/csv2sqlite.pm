# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of App-csv2sqlite
#
# This software is copyright (c) 2012 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package App::csv2sqlite;
{
  $App::csv2sqlite::VERSION = '0.001';
}
# git description: ed5cc95

BEGIN {
  $App::csv2sqlite::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Import CSV files into a SQLite database

use Moo 1;

use DBI 1.6 ();
use DBD::SQLite 1 ();
use DBIx::TableLoader::CSV 1.100 (); # catch csv errors
use Getopt::Long 2.34 ();

sub new_from_argv {
  my ($class, $args) = @_;
  $class->new( $class->getopt($args) );
}

has csv_files => (
  is         => 'ro',
  coerce     => sub { ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ] },
);

has csv_options => (
  is         => 'ro',
  default    => sub { +{} },
);

has dbname => (
  is         => 'ro',
);

has dbh => (
  is         => 'lazy',
);

sub _build_dbh {
  my ($self) = @_;
  my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->dbname, undef, undef, {
    RaiseError => 1,
    PrintError => 0,
  });
  return $dbh;
}

sub help { Getopt::Long::HelpMessage(2); }

sub getopt {
  my ($class, $args) = @_;
  my $opts = {};

  {
    local @ARGV = @$args;
    my $p = Getopt::Long::Parser->new(
      config => [qw(pass_through auto_help auto_version)],
    );
    $p->getoptions($opts,
      'csv_files|csv_file|csvfiles|csvfile|csv=s@',
      # TODO: 'csv_option|csvoption|o=%',
      # TODO: tableloader options like 'drop' or maybe --no-create
      'dbname|database=s',
    ) or $class->help;
    $args = [@ARGV];
  }

  # last arguments
  $opts->{dbname} ||= pop @$args;

  # first argument
  if( @$args ){
    push @{ $opts->{csv_files} ||= [] }, @$args;
  }

  return $opts;
}

sub load_tables {
  my ($self) = @_;

  # TODO: option for wrapping the whole loop in a transaction rather than each table

  foreach my $file ( @{ $self->csv_files } ){
    DBIx::TableLoader::CSV->new(
      %{ $self->csv_options },
      file => $file,
      dbh  => $self->dbh,
    )->load;
  }

  return;
}

sub run {
  my $class = shift || __PACKAGE__;
  my $args = @_ ? shift : [@ARGV];

  my $self = $class->new_from_argv($args);
  $self->load_tables;
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO CSV csv sqlite cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan

=head1 NAME

App::csv2sqlite - Import CSV files into a SQLite database

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  csv2sqlite doggies.csv kitties.csv pets.sqlite

=head1 DESCRIPTION

Import CSV files into a SQLite database
(using L<DBIx::TableLoader::CSV>).

Each csv file specified on the command line
will became a table in the resulting sqlite database.

=for Pod::Coverage new_from_argv
help
getopt
load_tables
run
csv_files
csv_options
dbname
dbh

=head1 TODO

=over 4

=item *

csv options

=item *

various L<DBIx::TableLoader> options

=item *

confirm using a pre-existing database?

=item *

more tests

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::csv2sqlite

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-csv2sqlite>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-csv2sqlite>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-csv2sqlite>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-csv2sqlite>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-csv2sqlite>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::csv2sqlite>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-csv2sqlite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-csv2sqlite>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/App-csv2sqlite>

  git clone https://github.com/rwstauner/App-csv2sqlite.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
