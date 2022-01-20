package Podman::Client::Furl;

##! #[ignore(item)]

use strict;
use warnings;

use base qw(Furl);

use Furl::HTTP;
use Podman::Client::Furl::Unix;

sub http {
    my $class = shift;

    bless \(
        Furl::HTTP->new(
            header_format => Furl::HTTP::HEADERS_AS_HASHREF(),
            @_
        )
    ), $class;
}

sub unix {
    my $class = shift;

    bless \(
        Podman::Client::Furl::Unix->new(
            header_format => Furl::HTTP::HEADERS_AS_HASHREF(),
            @_
        )
    ), $class;
}

1;
