use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Plone::UserAgent;


{
    throws_ok( sub { Plone::UserAgent->new( base_uri => 'http://example.com' ) },
               qr/\QMust provide a username and password or a valid config file/,
               'cannot create a new ua without a username & password' );

    no warnings 'redefine';
    local *Plone::UserAgent::_build_config_data = sub
    {
        return { '-' => {} };
    };

    throws_ok( sub { Plone::UserAgent->new( base_uri => 'http://example.com' ) },
               qr/\QMust provide a username and password or a valid config file/,
               'cannot create a new ua without a username & password' );
}

{
    my $ua = Plone::UserAgent->new( base_uri => 'http://example.com',
                                    username => 'foo',
                                    password => 'bar',
                                  );

    is( $ua->_make_uri('/whatever'),
        'http://example.com/whatever',
        '_make_uri uses base uri' );
}

{
    my $ua = Plone::UserAgent->new( base_uri => 'http://example.com',
                                    username => 'foo',
                                    password => 'bar',
                                  );

    my @post;
    my $rc = 200;

    no warnings 'redefine';
    local *LWP::UserAgent::post = sub { shift; @post = @_; return HTTP::Response->new($rc); };

    $ua->login();

    is_deeply( \@post,
               [ 'http://example.com/logged_out',
                 { __ac_name     => 'foo',
                   __ac_password => 'bar',
                   submit        => 'Log in',
                 },
               ],
               'login method makes expected post' );

    $rc = 500;
    throws_ok( sub { $ua->login() },
               qr{\QCould not log in to http://example.com/logged_out},
               'throws an error when login fails' );
}

