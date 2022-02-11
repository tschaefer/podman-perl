use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Mock::Podman::Service;

use Podman::Image;

local $ENV{PODMAN_CONNECTION_URL} = 'http+unix://' . File::Temp::tempdir(CLEANUP => 1) . '/podman.sock';
my $s = Mock::Podman::Service->new->start;

subtest 'Create image' => sub {
  my $image = Podman::Image::pull('docker.io/library/hello-world', 'latest');
  is ref $image,   'Podman::Image',                 'Pull image ok.';
  is $image->name, 'docker.io/library/hello-world', 'Pull image Name ok.';

  $image = Podman::Image::build('localhost/goodbye', "$FindBin::Bin/data/goodbye/Dockerfile");
  is ref $image,   'Podman::Image',     'Build image ok.';
  is $image->name, 'localhost/goodbye', 'Build image name ok.';
};

subtest 'Control image' => sub {
  my $image = Podman::Image->new(name => 'localhost/goodbye');
  my $expected_data = {
    "Id"      => "a76ad2934d4d6b478541c7d7df93c64dc0dcfd780472e85f2b3133fa6ea01ab7",
    "Tag"     => "latest",
    "Created" => "2022-01-26T17:25:47.30940821Z",
    "Size"    => 786563,
  };
  my $actual_data = $image->inspect;
  is ref $actual_data, 'HASH', 'Inspect ok.';
  is_deeply $actual_data, $expected_data, 'Inspect response ok.';

  ok $image->remove, 'Remove ok.';
};

done_testing();
