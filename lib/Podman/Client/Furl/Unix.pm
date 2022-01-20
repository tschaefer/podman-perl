package Podman::Client::Furl::Unix;

##! #[ignore(item)]

use strict;
use warnings;

use base qw(Furl::HTTP);

use Carp qw(croak);

use IO::Socket;

sub connect :method {
    my $self = shift;

    my $Socket;
    my $Retries = 3;

    while () {
        $Socket = IO::Socket::UNIX->new(
            TYPE => SOCK_STREAM(),
            Peer => $self->{socket},
        );
        last if $Socket;
        last if !--$Retries;

        sleep 1;
    }

    croak('Connection failed: ' . $IO::Socket::errstr) if !$Socket;

    return $Socket;
}

1;
