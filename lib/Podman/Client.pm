package Podman::Client;

use Mojo::Base -base;

our $VERSION     = '20220211.0';
our $API_VERSION = '3.0.0';

use English qw( -no_match_vars );
use Mojo::Asset::File;
use Mojo::Asset::Memory;
use Mojo::JSON qw(encode_json);
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(monkey_patch url_escape);

use Podman::Exception;

use constant ROOTLESS => "http+unix:///run/user/$UID/podman/podman.sock";
use constant ROOT     => "http+unix:///run/podman/podman.sock";

has 'connection' => sub { $UID ? ROOTLESS : ROOT unless $ENV{PODMAN_CONNECTION} };

sub api_version {
  my $self = shift;

  my $tx      = $self->_user_agent->get($self->_base_url->path('version'));
  my $version = $tx->res->json->{Components}->[0]->{Details}->{APIVersion};

  say {*STDERR} "Potential insufficient supported Podman service API version." unless $version eq $API_VERSION;

  return $version;
}

for my $name (qw(delete get post)) {
  monkey_patch(__PACKAGE__, $name, sub { shift->_request(uc $name, @_); });
}

sub new { shift->SUPER::new(@_)->_ping; }

sub _base_url { $_[0]->_connection_url->scheme eq 'http+unix' ? Mojo::URL->new('http://d/') : $_[0]->_connection_url; }
sub _connection_url { Mojo::URL->new(shift->connection); }

sub _request {
  my ($self, $method, $path, %opts) = @_;

  $self->_ping;

  my $url = $self->_base_url->path('v' . $self->api_version . '/libpod/')->path($path);
  $url->query($opts{parameters}) if $opts{parameters};

  my $tx = $self->_user_agent->build_tx($method => $url, $opts{headers});
  if ($opts{data}) {
    my $asset
      = ref $opts{data} eq 'Mojo::File'
      ? Mojo::Asset::File->new(path => $opts{data})
      : Mojo::Asset::Memory->new->add_chunk(encode_json($opts{data}));
    $tx->req->content->asset($asset);
  }
  $tx = $self->_user_agent->start($tx);

  Podman::Exception->throw($tx->res->code) unless $tx->res->is_success;

  return $tx->res;
}

sub _user_agent {
  my $self = shift;

  my $user_agent = Mojo::UserAgent->new(insecure => 1);
  $user_agent->transactor->name("Podman/$VERSION");
  $user_agent->proxy->http($self->_connection_url->scheme . '://' . url_escape($self->_connection_url->path))
    if $self->_connection_url->scheme eq 'http+unix';

  return $user_agent;
}

sub _ping {
  my $self = shift;

  my $tx;
  my $url = $self->_base_url->path('_ping');
  for (0 .. 3) {
    $tx = $self->_user_agent->get($url);
    last if $tx->res->is_success;
    sleep 1;
  }
  Podman::Exception->throw(900) unless $tx->res->is_success;

  return $self;
}

1;

__END__

=encoding utf8

=head1 NAME

Podman::Client - Podman service client.

=head1 SYNOPSIS

    # Send service requests
    my $client = Podman::Client->new;
    my $res = $client->delete('images/docker.io/library/hello-world');
    my $res = $client->get('version');
    my $res = $client->post('containers/prune');

=head1 DESCRIPTION

=head2 Inheritance

    Podman::Client
        wrap Mojo::UserAgent

L<Podman::Client> is a HTTP client (user agent) with the needed support to connect to and query the Podman service.

=head1 ATTRIBUTES

=head2 connection_url

    $client->connection_url('https://127.0.0.1:1234');

URL to connect to Podman service, defaults to user UNIX domain socket in rootless mode e.g.
C<http+unix://run/user/1000/podman/podman.sock> otherwise C<http+unix:///run/podman/podman.sock>. Customize via the
value of C<PODMAN_CONNECTION_URL> environment variable.

=head1 METHODS

L<Podman::Client> provides the valid HTTP requests to query the Podman service. All methods take a relative
endpoint path, optional header parameters and path parameters. if the response has a HTTP code unequal C<2xx> a
L<Podman::Exception> is raised.

=head2 api_version

    say $client->api_version;

Return Podman service API version. Emits warning if API version differs from implemented
C<$Podman::Client::API_VERSION>.

=head2 delete

    my $res = $client->delete('images/docker.io/library/hello-world');

Perform C<DELETE> request and return resulting content.

=head2 get

    my $res = $client->get('version');

Perform C<GET> request and return resulting content.

=head2 post

    my $res = $client->post(
        'build',
        data       => $archive_file, # Mojo::File object
        parameters => {
            'file' => 'Dockerfile',
            't'    => 'localhost/goodbye',
        },
        headers => {
            'Content-Type' => 'application/x-tar'
        },
    );

Perform C<POST> request and return resulting content, takes additional optional request data.

=head1 AUTHORS

=over 2

Tobias Schäfer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Schäfer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
