package Podman::Image;

##! Provides operations to create (build, pull) a new image and to manage it.

use strict;
use warnings;
use utf8;

use Moose;

use Archive::Tar;
use Cwd ();
use File::Basename ();
use File::Temp     ();
use Path::Tiny;
use Scalar::Util;

use Podman::Client;

### [Podman::Client](Client.html) API connector.
has 'Client' => (
    is       => 'ro',
    isa      => 'Podman::Client',
    required => 1,
);

### Image identifier, short identifier or name.
has 'Id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### Build new named image by given OCI file.
###
### All files placed in the OCI file directory are packed in a tar archive and
### attached to the request body.
sub Build {
    my ( $Package, $Name, $File ) = @_;

    return if Scalar::Util::blessed($Package);

    my $Dir = File::Basename::dirname($File);

    my ( @Files, $DirHandle );
    chdir $Dir;
    opendir $DirHandle, Cwd::getcwd();
    @Files = grep { !m{^\.{1,2}$} } readdir $DirHandle;
    closedir $DirHandle;

    my $Archive = Archive::Tar->new();
    $Archive->add_files(@Files);

    my $ArchiveFile = File::Temp->new();
    $Archive->write( $ArchiveFile->filename );

    my $Client = Podman::Client->new();

    my $Response = $Client->Post(
        'build',
        Data       => $ArchiveFile,
        Parameters => {
            'file' => File::Basename::basename($File),
            't'    => $Name,
        },
        Headers => {
            'Content-Type' => 'application/x-tar'
        },
    );

    return if !$Response;

    return __PACKAGE__->new(
        Client => $Client,
        Id     => $Name,
    );
}

### Pull named image with optional tag (default **latest**) from registry.
sub Pull {
    my ( $Package, $Name, $Tag ) = @_;

    return if Scalar::Util::blessed($Package);

    $Name = sprintf "%s:%s", $Name, $Tag // 'latest';

    my $Client = Podman::Client->new();

    my $Response = $Client->Post(
        'images/pull',
        Parameters => {
            reference => $Name,
            tlsVerify => 1,
        }
    );

    return if !$Response;

    return __PACKAGE__->new(
        Client => $Client,
        Id     => $Name,
    );
}

### Export image's filesystem contents as a tar archive and write into given
### file. Optional data may be compressed.
sub Export {
    my ( $Self, $File, $Compress ) = @_;

    my $Data = $Self->Client->Get(
        (sprintf "images/%s/get", $Self->Id),
        Parameters => {
            compress => $Compress ? 1 : 0,
        }
    );

    return if !$Data;

    return path($File)->spew($Data);
}

### Show the history of the image by printing out information about each
### layer used.
sub History {
    my $Self = shift;

    return $Self->Client->Get( sprintf "images/%s/history", $Self->Id );
}

### Display image configuration.
sub Inspect {
    my $Self = shift;

    return $Self->Client->Get( sprintf "images/%s/json", $Self->Id );
}

### Push image to given destination registry.
sub Push {
    my ( $Self, $Destination ) = @_;

    return $Self->Client->Post(
        (sprintf "images/%s/push", $Destination),
        Parameters => {
            destination => $Destination,
        }
    );
}

### Remove image from local store.
sub Remove {
    my ( $Self, $Force ) = @_;

    return $Self->Client->Delete( sprintf "images/%s", $Self->Id );
}

__PACKAGE__->meta->make_immutable;

1;
