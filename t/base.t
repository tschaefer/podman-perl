use Test::More;

subtest "Podman::Container interface" => sub {
  require_ok Podman::Container;
  can_ok Podman::Container, $_ for (qw(create delete inspect kill pause restart start stop unpause name));
};

subtest "Podman::Containers interface" => sub {
  require_ok Podman::Containers;
  can_ok Podman::Containers, $_ for (qw(list prune));
};

subtest "Podman::Images interface" => sub {
  require_ok Podman::Images;
  can_ok Podman::Images, $_ for (qw(list prune));
};

subtest "Podman::Image interface" => sub {
  require_ok Podman::Image;
  can_ok Podman::Image, $_ for (qw(build inspect pull remove name));
};

subtest "Podman::System interface" => sub {
  require_ok Podman::System;
  can_ok Podman::System, $_ for (qw(disk_usage info prune version));
};

done_testing();
