use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::Images;

local $ENV{PODMAN_CONNECTION_URL} = 'http+unix://' . File::Temp::tempdir(CLEANUP => 1) . '/podman.sock';
my $s = Mock::Podman::Service->new->start;

subtest 'Images list' => sub {
  my $list = Podman::Images->list;
  is ref $list,        'Mojo::Collection', 'List ok.';
  is $list->size,      2,                  'List length ok.';
  is ref $list->first, 'Podman::Image',    'List item[0] ok.';
  is ref $list->[1],   'Podman::Image',    'List item[1] ok.';
};

done_testing();
