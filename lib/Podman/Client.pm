package Podman::Client;

use Mojo::Base 'Mojo::UserAgent';

use English qw( -no_match_vars );
use Mojo::Asset::File;
use Mojo::Asset::Memory;
use Mojo::JSON qw(encode_json);
use Mojo::URL;
use Mojo::Util qw(monkey_patch url_escape);

use Podman::Exception;

our $VERSION     = '20220211.0';
our $API_VERSION = '3.0.0';

use constant ROOTLESS_BASE_URL => "http+unix:///run/user/$UID/podman/podman.sock";
use constant ROOT_BASE_URL     => "http+unix:///run/podman/podman.sock";

has 'base_url'  => sub { $UID ? ROOTLESS_BASE_URL : ROOT_BASE_URL unless $ENV{PODMAN_BASE_URL} };

sub build_tx {
  my ($self, $method, $path, %options) = @_;

  my $c = Mojo::URL->new($self->base_url);
  $self->proxy->http($c->scheme . '://' . url_escape($c->path)) if $c->scheme eq 'http+unix';

  my $url = $c->scheme eq 'http+unix' ? Mojo::URL->new('http://d') : $c;
  $url->path('v' . $API_VERSION . '/libpod/')->path($path);
  $url->query($options{parameters}) if $options{parameters};

  my $tx = $self->SUPER::build_tx($method => $url, $options{headers});
  if ($options{data}) {
    my $asset
      = ref $options{data} eq 'Mojo::File'
      ? Mojo::Asset::File->new(path => $options{data})
      : Mojo::Asset::Memory->new->add_chunk(encode_json($options{data}));
    $tx->req->content->asset($asset);
  }

  return $tx;
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->transactor->name("Podman/$VERSION");
  return $self;
}

# "Rename" method start to run. The method name start is needed in Podman::Container.
sub run {
  my $tx = shift->SUPER::start(@_);
  return $tx unless ref $tx eq 'Mojo::Transaction::HTTP';
  return Podman::Exception->throw($tx->res->code // 900) unless $tx->res->is_success;
  return $tx;
}

# "Rename" method start to run. The method name start is needed in Podman::Container.
sub run_p {
  my ($self, $tx) = @_;
  my $promise = Mojo::Promise->new;
  $self->run($tx => sub { shift->transactor->promisify($promise, shift) });
  return $promise
    ->then(sub {
      my $tx = shift;
      return Podman::Exception->throw($tx->res->code) unless $tx->res->is_success;
      return $tx;
    },
    sub {
      return Podman::Exception->throw(900);
    });
}

for my $name (qw(DELETE GET HEAD OPTIONS PATCH POST PUT)) {
  monkey_patch __PACKAGE__, lc $name, sub {
    my ($self, $cb) = (shift, ref $_[-1] eq 'CODE' ? pop : undef);
    return $self->run($self->build_tx($name, @_), $cb);
  };
  monkey_patch __PACKAGE__, lc($name) . '_p', sub {
    my $self = shift;
    return $self->run_p($self->build_tx($name, @_));
  };
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
        base Mojo::UserAgent

L<Podman::Client> is a HTTP client (user agent) with support to connect to and query the Podman service.

=head1 ATTRIBUTES

L<Podman::Client> implements the following attributes.

=head2 base_url

    $client->base_url('https://127.0.0.1:1234');

URL to connect to Podman service, defaults to user UNIX domain socket in rootless mode
C<http+unix://run/user/$UID/podman/podman.sock> otherwise C<http+unix:///run/podman/podman.sock>. Customizable via the
value of C<PODMAN_BASE_URL> environment variable.

=head1 METHODS

L<Podman::Client> provides the valid HTTP requests - blocking and non-blocking - to query the Podman service. All
methods take a relative endpoint path, optional header parameters and path parameters. If the resulting transaction has
a HTTP response code unequal C<2xx> a L<Podman::Exception> is raised.

=head2 delete

    my $tx = $client->delete('images/docker.io/library/hello-world');

Perform C<DELETE> request and return L<Mojo::Transactor::HTTP>.

=head2 delete_p

    my $promise = $client->delete_p('images/docker.io/library/hello-world');

Same as C<delete> but performs request non-blocking and returns L<Mojo::Promise>.

=head2 get

    my $tx = $client->get('version');

Perform C<GET> request and return L<Mojo::Transactor::HTTP>.

=head2 get_p

    my $promise = $client->get_p('version');

Same as C<get> but performs request non-blocking and returns L<Mojo::Promise>.

=head2 post

    my $res = $client->post(
        'build',
        data       => $archive_file, # Mojo::File object or perl data structure
        parameters => {
            'file' => 'Dockerfile',
            't'    => 'localhost/goodbye',
        },
        headers => {
            'Content-Type' => 'application/x-tar'
        },
    );

Perform C<POST> request and return L<Mojo::Transactor::HTTP>, takes additional optional request data.

=head2 post_p

    my $promise = $client->post('build', ...);

Same as C<post> but performs request non-blocking and returns L<Mojo::Promise>.

=head1 AUTHORS

=over 2

Tobias Sch??fer, <tschaefer@blackox.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-2022, Tobias Sch??fer.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version
2.0.

=cut
