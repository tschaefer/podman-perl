package Podman::Containers;

##! Provides the operations against containers for a Podman service.
##!
##!     my $Containers = Podman::Containers->new(Client => Podman::Client->new());
##!
##!     # Display names and Ids of available containers.
##!     for my $Container (@{ $Containers->list() }) {
##!         my $Info = $Container->Inspect();
##!         printf "%s: %s\n", $Container->Id, $Info->{RepoTags}->[0];
##!     }

use strict;
use warnings;
use utf8;

use Moose;

use Podman::Client;
use Podman::Container;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is       => 'ro',
    isa      => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### List all local stored containers.
### ```
###     use Podman::Client;
###
###     my $Containers = Podman::Containers->new(Client => Podman::Client->new());
###
###     my $List = $Containers->List();
###     is(ref $List, 'ARRAY', 'Containers list ok.');
###
###     if ($List) {
###         is(ref $List->[0], 'Podman::Container', 'Containers list items ok.');
###     }
###
### ```
sub List {
    my $Self = shift;

    my $List = $Self->Client->Get(
        'containers/json',
        Parameters => {
            all => 1
        },
    );

    my @List = map {
        Podman::Container->new(
            Client => $Self->Client,
            Id        => $_->{Id},
        )
    } @{$List};

    return \@List;
}

### List all mounted local stored containers.
### ```
###     use Podman::Client;
###
###     my $Containers = Podman::Containers->new(Client => Podman::Client->new());
###
###     my $List = $Containers->Mounted();
###     is(ref $List, 'HASH', 'Containers list ok.');
###
### ```
sub Mounted {
    my $Self = shift;

    return $Self->Client->Get('containers/showmounted');
}

### Delete all unused containers.
sub Prune {
    my $Self = shift;

    return $Self->Client->Post('containers/prune');
}

### Create new container, see [`Podman::Container`](Container.html)
sub Create {
    my ( $Self, $Name, $Id, $Command ) = @_;

    return Podman::Container->Create( $Name, $Id, $Command );
}

__PACKAGE__->meta->make_immutable;

1;
