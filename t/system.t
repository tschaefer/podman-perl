use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::System;

local $ENV{PODMAN_CONNECTION_URL} = 'http+unix://' . File::Temp::tempdir(CLEANUP => 1) . '/podman.sock';
my $s = Mock::Podman::Service->new->start;

subtest 'System' => sub {
  my $expected = {
    "APIVersion" => "3.0.0",
    "Version"    => "3.0.1",
    "GoVersion"  => "go1.15.9",
    "BuiltTime"  => "Thu Jan  1 01:00:00 1970",
    "OsArch"     => "linux/amd64"
  };
  my $actual = Podman::System->version;
  is ref $actual, 'HASH', 'Version ok.';
  is_deeply $actual, $expected, 'Version response ok.';

  $expected = {
    "Containers" => {"Active" => "0", "Size" => "13256",     "Total" => "1"},
    "Images"     => {"Active" => "2", "Size" => "129100529", "Total" => "2"},
    "Volumes"    => {"Active" => "0", "Size" => "0",         "Total" => "1"}
  };
  $actual = Podman::System->disk_usage;
  is ref $actual, 'HASH', 'Disk usage ok.';
  is_deeply $actual, $expected, 'Disk usage response ok.';

  $actual = Podman::System->info;
  is ref $actual, 'HASH', 'Info ok.';
  my @expected_keys = qw(host registries store version);
  my @actual_keys   = sort keys %{$actual};
  is_deeply \@actual_keys, \@expected_keys, 'Info response ok.';
};

done_testing();
