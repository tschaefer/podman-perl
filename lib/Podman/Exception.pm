package Podman::Exception;

##! Simple generic exception class.
##!
##!     Podman::Exception->new(
##!         Message => 'Human error description',
##!         Cause   => 'API root cause',
##!     );
##!
##! Exception is thrown on API request failure.

use strict;
use warnings;
use utf8;

use Moose;
with qw(Throwable);

use overload '""' => 'AsString';

### Human error description.
has 'Message' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

### API root cause.
has 'Cause' => (
    is => 'ro',
    isa => 'Maybe[Str]',
);

### #[ignore(item)]
sub AsString {
    my $Self = shift;

    return $Self->Message;
}

__PACKAGE__->meta->make_immutable;

1;
