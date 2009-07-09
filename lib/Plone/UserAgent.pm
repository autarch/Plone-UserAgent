package Plone::UserAgent;

use strict;
use warnings;

our $VERSION = '0.01';

use Config::INI::Reader;
use File::HomeDir;
use HTTP::Cookies;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::NonMoose;
use URI;

extends 'LWP::UserAgent';

has username =>
    ( is        => 'rw',
      isa       => 'Str',
      predicate => '_has_username',
      writer    => '_set_username',
    );

has password =>
    ( is        => 'rw',
      isa       => 'Str',
      predicate => '_has_password',
      writer    => '_set_password',
    );

my $uri = subtype as class_type('URI');
coerce $uri
    => from 'Str'
    => via { URI->new( $_ ) };

has base_uri =>
    ( is       => 'ro',
      isa      => $uri,
      required => 1,
      coerce   => 1,
    );

has config_file =>
    ( is      => 'ro',
      isa     => 'Str',
      lazy    => 1,
      default => sub { File::HomeDir->my_home() . '/.plone-useragentrc' },
    );

has _config_data =>
    ( is      => 'ro',
      isa     => 'HashRef',
      lazy    => 1,
      builder => '_build_config_data',
    );


sub BUILD
{
    my $self = shift;

    unless ( $self->_has_username && $self->_has_password )
    {
        my $config = $self->_config_data();

        die 'Must provide a username and password or a valid config file'
            unless $config && $config->{'-'}{username} && $config->{'-'}{password};

        $self->_set_username( $config->{'-'}{username} );
        $self->_set_password( $config->{'-'}{password} );
    }

    $self->cookie_jar( HTTP::Cookies->new() )
        unless $self->cookie_jar();
}

sub _build_config_data
{
    my $self = shift;

    my $file = $self->config_file();

    return {} unless -f $file;

    return Config::INI::Reader->read_file($file) || {};
}

sub login
{
    my $self = shift;

    my $uri = $self->make_uri( '/logged_out' );

    my $response =
        $self->post( $uri,
                     { __ac_name     => $self->username(),
                       __ac_password => $self->password(),
                       submit        => 'Log in',
                     },
                   );

    die "Could not log in to $uri"
        unless $response->is_success();
}

sub make_uri
{
    my $self = shift;
    my $path = shift;

    my $uri = $self->base_uri()->clone();

    $uri->path( $uri->path() . $path );

    return $uri;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Plone::UserAgent - The fantastic new Plone::UserAgent!

=head1 SYNOPSIS

XXX - change this!

    use Plone::UserAgent;

    my $foo = Plone::UserAgent->new();

    ...

=head1 DESCRIPTION

=head1 METHODS

This class provides the following methods

=head1 AUTHOR

Dave Rolsky, E<gt>autarch@urth.orgE<lt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plone-useragent@rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
