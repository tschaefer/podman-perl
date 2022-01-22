package Podman::Container;

use strict;
use warnings;
use utf8;

use Moose;

use Scalar::Util;

use Podman::Client;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is       => 'ro',
    isa      => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### Image identifier, short identifier or name.
has 'Id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### Create new named container of given image with given command.
sub Create {
    my ( $Package, $Name, $Image, $Command, $Client ) = @_;

    return if Scalar::Util::blessed($Package);

    $Client //= Podman::Client->new();

    my $Response = $Client->Post(
        'containers/create',
        Data => {
            Image => $Image,
            Cmd   => [$Command],
        },
        Parameters => {
            name => $Name,
        },
        Headers => {
            'Content-Type' => 'application/json'
        }
    );

    return if !$Response;

    return __PACKAGE__->new(
        Client => $Client,
        Id        => $Response->{Id}
    );
}

### Delete container, optional force deleting if current in use.
sub Delete {
    my ( $Self, $Force ) = @_;

    return $Self->Client->Delete(
        ( sprintf "containers/%s", $Self->Id ),
        Parameters => {
            force => $Force,
        }
    );
}

### Display container configuration.
sub Inspect {
    my $Self = shift;

    return $Self->Client->Get( sprintf "containers/%", $Self->Id );
}

### Kill container.
sub Kill {
    my ( $Self, $Signal, $All ) = @_;

    $Signal //= 'SIGKILL';

    return $Self->Client->Post(
        ( sprintf "containers/%s/kill", $Self->Id ),
        Parameters => {
            signal => $Signal,
            all    => $All,
        },
    );
}

### Pause container.
sub Pause {
    my ( $Self, $Id ) = @_;

    return $Self->Client->Post( sprintf "containers/%s/pause", $Self->Id );
}

### Rename container.
sub Rename {
    my ( $Self, $Name ) = @_;

    return $Self->Client->Post(
        ( sprintf "containers/%s/rename", $Self->Id ),
        Parameters => {
            rename => $Name,
        }
    );
}

### Restart container.
sub Restart {
    my ( $Self, $Id ) = @_;

    return $Self->Client->Post( sprintf "containers/%s/restart", $Self->Id );
}

### Start container.
sub Start {
    my ( $Self, $Id ) = @_;

    return $Self->Client->Post( sprintf "containers/%s/start", $Self->Id );
}

### Display current statistics.
sub Stats {
    my ( $Self, $Id ) = @_;

    return $Self->Client->Get(
        ( sprintf "containers/%s/stats", $Self->Id ),
        Parameters => {
            stream     => 0,
            'one-shot' => 1
        }
    );
}

### Stop container.
sub Stop {
    my ( $Self, $Id ) = @_;

    return $Self->Client->Post( sprintf "containers/%s/stop", $Self->Id );
}

### Show running process within container.
sub Top {
    my ( $Self, $PsArgs ) = @_;

    $PsArgs //= '-ef';

    return $Self->Client->Get(
        ( sprintf "containers/%s/top", $Self->Id ),
        Parameters => {
            ps_args => $PsArgs,
        }
    );
}

### Unpause container.
sub Unpause {
    my ( $Self, $Id ) = @_;

    return $Self->Client->Post( sprintf "containers/%s/unpause", $Self->Id );
}

__PACKAGE__->meta->make_immutable;

1;
