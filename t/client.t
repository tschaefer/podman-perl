use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use English qw( -no_match_vars );
use File::Temp ();
use Mojo::URL;
use Mock::Podman::Service;

use Podman::Client;

subtest 'Client connection failure' => sub {
  eval {
    local $ENV{PODMAN_CONNECTION} = 'http+unix:///no/such/path/sock';
    Podman::Client->new;
  };
  is ref $EVAL_ERROR, 'Podman::Exception', 'Connection failure unix domain socket ok.';
  eval {
    local $ENV{PODMAN_CONNECTION} = 'http://127.0.0.1:1';
    Podman::Client->new;
  };
  is ref $EVAL_ERROR, 'Podman::Exception', 'Connection failure tcp port ok.';
  eval {
    local $ENV{PODMAN_CONNECTION} = 'https://127.0.0.1:1';
    Podman::Client->new;
  };
  is ref $EVAL_ERROR, 'Podman::Exception', 'Connection failure secure tcp port ok.';
};

subtest 'Client connection via http+unix socket.' => sub {
  local $ENV{PODMAN_CONNECTION} = 'http+unix://' . File::Temp::tempdir(CLEANUP => 1) . '/podman.sock';
  my $s   = Mock::Podman::Service->new->start;
  my $obj = Podman::Client->new;
  ok $obj, 'Connection unix socket ok.';
  $s->stop;
};

subtest 'Client connection via http.' => sub {
  local $ENV{PODMAN_CONNECTION} = 'http://127.0.0.1:1234';
  my $s   = Mock::Podman::Service->new->start;
  my $obj = Podman::Client->new;
  ok $obj, 'Connection tcp port ok.';
  $s->stop;
};

subtest 'Client connection via https.' => sub {
  local $ENV{PODMAN_CONNECTION} = 'https://127.0.0.1:1234';
  my $s   = Mock::Podman::Service->new->start;
  my $obj = Podman::Client->new;
  ok $obj, 'Connection secure tcp port ok.';
  $s->stop;
};

done_testing();
