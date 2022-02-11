use Test::More;

use English qw( -no_match_vars );

use Podman::Exception;

subtest 'Exception 304' => sub {
  eval { Podman::Exception->throw(304); };
  is $EVAL_ERROR->message, 'Action already processing.', 'Exception message ok.';
  is $EVAL_ERROR->code,    304,                          'Exception code ok.';
};

subtest 'Exception 400' => sub {
  eval { Podman::Exception->throw(400); };
  is $EVAL_ERROR->message, 'Bad parameter in request.', 'Exception message ok.';
  is $EVAL_ERROR->code,    400,                         'Exception code ok.';
};

subtest 'Exception 404' => sub {
  eval { Podman::Exception->throw(404); };
  is $EVAL_ERROR->message, 'No such item.', 'Exception message ok.';
  is $EVAL_ERROR->code,    404,             'Exception code ok.';
};

subtest 'Exception 409' => sub {
  eval { Podman::Exception->throw(409); };
  is $EVAL_ERROR->message, 'Conflict error in operation.', 'Exception message ok.';
  is $EVAL_ERROR->code,    409,                            'Exception code ok.';
};

subtest 'Exception 500' => sub {
  eval { Podman::Exception->throw(500); };
  is $EVAL_ERROR->message, 'Internal server error.', 'Exception message ok.';
  is $EVAL_ERROR->code,    500,                      'Exception code ok.';
};

subtest 'Exception 666' => sub {
  eval { Podman::Exception->throw(666); };
  is $EVAL_ERROR->message, 'Unknown error.', 'Exception message ok.';
  is $EVAL_ERROR->code,    666,              'Exception code ok.';
};

subtest 'Exception 900' => sub {
  eval { Podman::Exception->throw(900); };
  is $EVAL_ERROR->message, 'Connection failed.', 'Exception message ok.';
  is $EVAL_ERROR->code,    900,                  'Exception code ok.';
};


done_testing();
