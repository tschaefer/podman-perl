package Podman;

##! This Perl package is a library of bindings to use the RESTful API of
##! [Podman](https://podman.io). For further information please have a look in
##! the [API reference](https://docs.podman.io/en/latest/_static/api.html).
##!
##!     my $Podman = Podman->new();
##!
##!     # List of available images in local store.
##!     my $Images = $Podman->Images->List();
##!
##!     # Display names and Ids of available images.
##!     for my $Image (@{ $Images }) {
##!         my $Info = $Image->Inspect();
##!         printf "%s: %s\n", $Image->Id, $Info->{RepoTags}->[0];
##!     }

use strict;
use warnings;
use utf8;

our $VERSION = '20220122.0';

use Moose;

use Podman::Client;
use Podman::Containers;
use Podman::Images;
use Podman::System;

### Binding to [Podman::Containers](Podman/Containers.html).
has 'Containers' => (
    is       => 'ro',
    isa      => 'Podman::Containers',
    lazy     => 1,
    builder  => '_BuildContainers',
    init_arg => undef,
);

### Binding to [Podman::Images](Podman/Images.html).
has 'Images' => (
    is       => 'ro',
    isa      => 'Podman::Images',
    lazy     => 1,
    builder  => '_BuildImages',
    init_arg => undef,
);

### Binding to [Podman::System](Podman/System.html).
has 'System' => (
    is       => 'ro',
    isa      => 'Podman::System',
    lazy     => 1,
    builder  => '_BuildSystem',
    init_arg => undef,
);

### [Podman::Client](Podman/Client.html) API connector.
has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

sub _BuildContainers {
    my $Self = shift;

    return Podman::Containers->new( Client => $Self->Client );
}

sub _BuildImages {
    my $Self = shift;

    return Podman::Images->new( Client => $Self->Client );
}

sub _BuildSystem {
    my $Self = shift;

    return Podman::System->new( Client => $Self->Client );
}

__PACKAGE__->meta->make_immutable;

1;
