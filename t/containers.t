use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::Containers;

local $ENV{PODMAN_CONNECTION_URL} = 'http+unix://' . File::Temp::tempdir(CLEANUP => 1) . '/podman.sock';
my $s = Mock::Podman::Service->new->start;

subtest 'Containers list' => sub {
  my $list = Podman::Containers->list;
  is ref $list,        'Mojo::Collection',  'List ok.';
  is $list->size,      1,                   'List length ok.';
  is ref $list->first, 'Podman::Container', 'List item[0] ok.';
};

done_testing();
