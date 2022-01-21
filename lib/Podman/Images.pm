package Podman::Images;

##! Provides the operations against images for a Podman service.
##!
##!     my $Images = Podman::Images->new(Client => Podman::Client->new());
##!
##!     # Display names and Ids of available images.
##!     for my $Image (@{ $Images->list() }) {
##!         my $Info = $Image->Inspect();
##!         printf "%s: %s\n", $Image->Id, $Info->{RepoTags}->[0];
##!     }

use strict;
use warnings;
use utf8;

use Moose;

use Podman::Client;
use Podman::Image;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is      => 'ro',
    isa     => 'Podman::Client',
    lazy    => 1,
    default => sub { return Podman::Client->new() },
);

### List all local stored images.
### ```
###     use Podman::Client;
###
###     my $Images = Podman::Images->new(Client => Podman::Client->new());
###
###     my $List = $Images->List();
###     is(ref $List, 'ARRAY', 'Images list ok.');
###
###     if ($List) {
###         is(ref $List->[0], 'Podman::Image', 'Images list items ok.');
###     }
###
### ```
sub List {
    my $Self = shift;

    my $List = $Self->Client->Get(
        'images/json',
        Parameters => {
            all => 1
        },
    );

    my @List = ();
    @List =
      map { Podman::Image->new( Client => $Self->Client, Id => $_->{Id}, ) }
      @{$List};

    return \@List;
}

### Remove all unused images.
sub Prune {
    my $Self = shift;

    return $Self->Client->Post('images/prune');
}

### Build new image, see [`Podman::Image`](Podman/Image.html).
sub Build {
    my ( $Self, $Name, $File ) = @_;

    return Podman::Image->Build( $Name, $File );
}

### Pull an image from a registry, see [`Podman::Image`](Podman/Image.html).
sub Pull {
    my ( $Self, $Name ) = @_;

    return Podman::Image->Pull($Name);
}

__PACKAGE__->meta->make_immutable;

1;
