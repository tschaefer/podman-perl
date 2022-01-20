package Podman::System;

##! Provide system level information for the Podman service.

use strict;
use warnings;
use utf8;

use Moose;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is       => 'ro',
    isa      => 'Podman::Client',
    required => 1,
);

###  Return information about disk usage for containers, images and volumes.
###
### ```
###     use Podman::Client;
###
###     my $System = Podman::System->new(Client => Podman::Client->new());
###
###     my $DiskUsage = $System->DiskUsage();
###     is(ref $DiskUsage, 'HASH', 'DiskUsage object ok.');
###
###     my @Keys = sort keys %{ $DiskUsage };
###     my @Expected = (
###         'Containers',
###         'Images',
###         'Volumes',
###     );
###     is_deeply(\@Keys, \@Expected, 'DiskUsage object complete.');
### ```
sub DiskUsage {
    my $Self = shift;

    return $Self->Client->Get('system/df');
}

### Returns information on the system and libpod configuration
### ```
###     use Podman::Client;
###
###     my $System = Podman::System->new(Client => Podman::Client->new());
###
###     my $Info = $System->Info();
###     is(ref $Info, 'HASH', 'Info object ok.');
###
###     my @Keys = sort keys %{ $Info };
###     my @Expected = (
###         'host',
###         'registries',
###         'store',
###         'version',
###     );
###     is_deeply(\@Keys, \@Expected, 'Info object complete.');
### ```
sub Info {
    my $Self = shift;

    return $Self->Client->Get('info');
}

### Obtain a dictionary of versions for the Podman components.
### ```
###     use Podman::Client;
###
###     my $System = Podman::System->new(Client => Podman::Client->new());
###
###     my $Version = $System->Version();
###     is(ref $Version, 'HASH', 'Version object ok.');
###     is($Version->{Version}, '3.0.1', 'Version number ok.');
### ```
sub Version {
    my $Self = shift;

    return $Self->Client->Get('version');
}

__PACKAGE__->meta->make_immutable;

1;
