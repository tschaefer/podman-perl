package Podman::Client;

##! API connection client.
##!
##!     my $Client = Podman::Client->new(
##!         ConnectionUrl => 'unix:///run/user/1000/podman/podman.sock',
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

use File::Basename ();
use JSON::XS ();
use URI;
use Try::Tiny;
use Readonly;

Readonly::Scalar my $VERSION => '20220120.0';

use Podman::Exception;
use Podman::Client::Furl;

### API connection Url. Possible connections are via UNIX socket path
### (default) or tcp (http/https) connection.
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
has 'Connection' => (
    is       => 'ro',
    isa      => 'Furl',
    lazy     => 1,
    builder  => '_BuildConnection',
    init_arg => undef,
);

### API request Url depends on connection Url and Podman service version.
has 'RequestUrl' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_BuildRequestUrl',
    init_arg => undef,
);

### API client identification.
has 'UserAgent' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_BuildUserAgent',
    init_arg => undef,
);

sub _BuildUserAgent {
    my $Self = shift;

    return sprintf "Podman::Perl/%s", $VERSION;
}

sub _BuildConnectionUrl {
    my $Self = shift;

    return sprintf "unix://%s/podman/podman.sock",
      $ENV{XDG_RUNTIME_DIR} ? $ENV{XDG_RUNTIME_DIR} : '/tmp';
}

sub _BuildRequestUrl {
    my $Self = shift;

    my ($Scheme) = $Self->ConnectionUrl =~ m{([a-z]+)://};

    my $RequestBaseUrl = $Scheme eq 'unix' ? 'http://d/' : $Self->ConnectionUrl;

    my $Response = $Self->Connection->request(
        url    => URI->new_abs( 'version', $RequestBaseUrl )->as_string(),
        method => 'GET',
    );

    my $JSON = $Self->_HandleResponse($Response);
    my $Path = sprintf "v%s/libpod", $JSON->{Version};

    my $RequestUrl = URI->new_abs( $Path, $RequestBaseUrl )->as_string();

    return $RequestUrl;
}

sub _BuildConnection {
    my $Self = shift;

    my ( $Scheme, $Path ) = $Self->ConnectionUrl =~ m{([a-z]+)://(.+)};

    return Podman::Client::Furl->http(
        agent   => $Self->UserAgent,
        timeout => $Self->Timeout,
    ) if $Scheme =~ m{http(?:s)?};

    return Podman::Client::Furl->unix(
        agent   => $Self->UserAgent,
        timeout => $Self->Timeout,
        socket  => $Path,
    ) if $Scheme eq 'unix';

    return;
}

sub _MakeUrl {
    my ( $Self, $Path, $Parameters ) = @_;

    my $Url = URI->new_abs( $Path, $Self->RequestUrl );

    if ($Parameters) {
        my $Parameters = $Self->_StringifyParameters($Parameters);
        $Url = URI->new_abs( $Parameters, $Url );
    }

    return $Url->as_string;
}

sub _StringifyParameters {
    my ( $Self, $Parameters ) = @_;

    my $String = '';
    while ( my ( $Key, $Value ) = each %{$Parameters} ) {
        $String = sprintf "%s%s=%s&", $String, $Key, $Value;
    }

    if ($String) {
        chop $String;
        $String = sprintf "?%s", $String;
    }

    return $String;
}

sub _FlattenHeaders {
    my ( $Self, $Headers ) = @_;

    my @Flatten;
    while ( my ( $Key, $Value ) = each %{$Headers} ) {
        push @Flatten, $Key, $Value;
    }

    return \@Flatten;
}

sub _HandleResponse {
    my ( $Self, $Response ) = @_;

    my $Content = try { JSON::XS::decode_json( $Response->content ) };
    $Content //= $Response->content;

    if ( !$Response->is_success ) {
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

    my $Response = $Self->Connection->request(
        url     => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        method  => 'GET',
        headers => $Self->_FlattenHeaders( $Options{Headers} )
    );

    return $Self->_HandleResponse($Response);
}

### Send API post request to path with optional parameters, headers and
### data.
sub Post {
    my ( $Self, $Path, %Options ) = @_;

    my $Data = $Options{Data};
    if ( $Data && ref $Data ne 'File::Temp' ) {
        $Data = JSON::XS::encode_json($Data);
    }

    my $Response = $Self->Connection->request(
        url     => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        content => $Data,
        method  => 'POST',
        headers => $Self->_FlattenHeaders( $Options{Headers} )
    );

    return $Self->_HandleResponse($Response);
}

### Send API delete request to path with optional parameters and headers.
sub Delete {
    my ( $Self, $Path, %Options ) = @_;

    my $Response = $Self->Connection->request(
        url     => $Self->_MakeUrl( $Path, $Options{Parameters} ),
        method  => 'DELETE',
        headers => $Self->_FlattenHeaders( $Options{Headers} )
    );

    return $Self->_HandleResponse($Response);
}

__PACKAGE__->meta->make_immutable;

1;
