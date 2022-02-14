package Mock::Podman::Service;

use Mojo::Base 'Mojolicious';

use English qw( -no_match_vars );

use Mojo::Server::Daemon;
use Mojo::IOLoop;
use Mojo::Util qw(url_escape);
use Mojo::URL;

use constant ROOTLESS_BASE_URL => "http+unix:///run/user/$UID/podman/podman.sock";
use constant ROOT_BASE_URL     => "http+unix:///run/podman/podman.sock";

has pid    => sub { return; };
has listen => sub { $UID ? ROOTLESS_BASE_URL : ROOT_BASE_URL unless $ENV{PODMAN_BASE_URL} };

$ENV{MOJO_LOG_LEVEL} ||= $ENV{HARNESS_IS_VERBOSE} ? 'trace' : 'fatal';

sub startup {
  my $self = shift;

  $self->hook(
    after_build_tx => sub {
      my $Transaction = shift;

      return $Transaction->res->headers->header('Content-Type' => 'Application/JSON');
    }
  );

  $self->secrets('dedf9c3d-93ca-42ca-9ee7-82bc1d625c61');
  $self->routes->any('/*route')->to('Routes#any');
  $self->renderer->classes(['Mock::Podman::Service::Routes']);

  return;
}

sub start {
  my $self = shift;

  my $listen = Mojo::URL->new($self->listen);
  if ($listen->scheme eq 'http+unix') {
    $listen = Mojo::URL->new($listen->scheme . '://' . url_escape($listen->path));
  }

  my $daemon = Mojo::Server::Daemon->new(
    app    => $self,
    listen => [$listen->to_string],
    silent => $ENV{MOJO_LOG_LEVEL} ne 'fatal' ? 1 : 0,
  );

  my $pid = fork;
  if (!$pid) {
    $daemon->start;
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

    exit 0;
  }

  $self->pid($pid);

  return $self;
}

sub stop {
  my $self = shift;

  if ($self->pid) {
    kill 'KILL', $self->pid;
    waitpid $self->pid, 0;
  }

  return;
}

sub DESTROY {
  my $self = shift;

  $self->stop();

  return;
}

1;
