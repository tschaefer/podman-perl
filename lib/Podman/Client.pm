package Podman::Client;

##! API connection client.
##!
##!     my $Client = Podman::Client->new(
##!         ConnectionUrl => 'http+unix:///run/user/1000/podman/podman.sock',
##!         Timeout       => 1800,
##!     );
##!
##!     my $Response = $Client->Get(
##!         'version',
##!         Parameters => {},
##!         Headers    => {},
##!     );

use strict;
use warnings;
use utf8;

use Moose;

use Try::Tiny;
use Readonly;

use Mojo::Asset::File;
use Mojo::Asset::Memory;
use Mojo::JSON ();
use Mojo::UserAgent;
use Mojo::Util ();
use Mojo::URL;

Readonly::Scalar my $VERSION => '20220124.0';

use Podman::Exception;

### API connection Url. Possible connections are via UNIX socket (default) or
### tcp connection.
###
###     * http+unix
###     * https+unix
###     * http
###     * https
has 'ConnectionUrl' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_BuildConnectionUrl',
);

### API connection timeout, default `3600 seconds`.
has 'Timeout' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    default => sub { return 3600 },
);

### API connection object.
has 'UserAgent' => (
    is       => 'ro',
    isa      => 'Mojo::UserAgent',
    lazy     => 1,
    builder  => '_BuildUserAgent',
    init_arg => undef,
);

### API request Url depends on connection Url and Podman service version.
has 'RequestUrl' => (
    is       => 'ro',
    isa      => 'Mojo::URL',
    lazy     => 1,
    builder  => '_BuildRequestUrl',
    init_arg => undef,
);

### API client identification.
has 'UserAgentName' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_BuildUserAgentName',
    init_arg => undef,
);

sub _BuildUserAgentName {
    my $Self = shift;

    return sprintf "Podman::Perl/%s", $VERSION;
}

sub _BuildConnectionUrl {
    my $Self = shift;

    return sprintf "http+unix://%s/podman/podman.sock",
      $ENV{XDG_RUNTIME_DIR} ? $ENV{XDG_RUNTIME_DIR} : '/tmp';
}

sub _BuildRequestUrl {
    my $Self = shift;

    my $Scheme = Mojo::URL->new( $Self->ConnectionUrl )->scheme();

    my $RequestBaseUrl =
      $Scheme =~ m{unix$} ? 'http://d/' : $Self->ConnectionUrl;

    my $Transaction =
      $Self->UserAgent->get( Mojo::URL->new($RequestBaseUrl)->path('version') );

    my $JSON = $Transaction->res->json;
    my $Path = sprintf "v%s/libpod", $JSON->{Version};

    return Mojo::URL->new($RequestBaseUrl)->path($Path);
}

sub _BuildUserAgent {
    my $Self = shift;

    my $UserAgent = Mojo::UserAgent->new(
        connect_timeout    => 10,
        inactivity_timeout => $Self->Timeout,
    );
    $UserAgent->transactor->name( $Self->UserAgentName );

    my $ConnectionUrl = Mojo::URL->new( $Self->ConnectionUrl );
    my $Scheme        = $ConnectionUrl->scheme();

    if ( $Scheme =~ m{unix$} ) {
        my $Path = Mojo::Util::url_escape( $ConnectionUrl->path() );

        if ( $Scheme =~ m{^https} ) {
            $UserAgent->proxy->https( sprintf "https+unix://%s", $Path );
        }
        else {
            $UserAgent->proxy->http( sprintf "http+unix://%s", $Path );
        }
    }

    return $UserAgent;
}

sub _MakeUrl {
    my ( $Self, $Path, $Parameters ) = @_;

    my $Url = Mojo::URL->new( $Self->RequestUrl )->path($Path);

    if ($Parameters) {
        $Url = Mojo::URL->new($Url)->query($Parameters);
    }

    return $Url;
}

sub _HandleTransaction {
    my ( $Self, $Transaction ) = @_;

    my $Content = try { $Transaction->res->json; };
    $Content //= $Transaction->res->body;

    if ( !$Transaction->res->is_success ) {
        if ( ref $Content ne 'HASH' ) {
            return Podman::Exception->new(
                Message => $Content,
                Cause   => $Content,
            )->throw();
        }

        return Podman::Exception->new(
            Message => $Content->{message},
            Cause   => $Content->{cause},
        )->throw();
    }

    return $Content;
}

### Send API get request to path with optional parameters and headers.
sub Get {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        GET => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );
    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

### Send API post request to path with optional parameters, headers and
### data.
sub Post {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        POST => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );

    my $Data = $Options{Data};
    if ( $Data && ref $Data eq 'File::Temp' ) {
        $Transaction->req->content->asset(
            Mojo::Asset::File->new( path => $Data->filename ) );
    }
    else {
        $Transaction->req->content->asset(
            Mojo::Asset::Memory->new->add_chunk(
                Mojo::JSON::encode_json($Data)
            )
        );
    }

    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

### Send API delete request to path with optional parameters and headers.
sub Delete {
    my ( $Self, $Path, %Options ) = @_;

    my $Transaction = $Self->UserAgent->build_tx(
        Delete => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        $Options{Headers},
    );
    $Transaction = $Self->UserAgent->start($Transaction);

    return $Self->_HandleTransaction($Transaction);
}

__PACKAGE__->meta->make_immutable;

1;
