package Web::Simple::DispatchNode;

use Moo;

extends 'Web::Dispatch::Node';

has _app_object => (is => 'ro', init_arg => 'app_object', required => 1);

around _curry => sub {
  my ($orig, $self) = (shift, shift);
  # this ensures that the dispatchers get called as methods of the app itself
  my $code = $self->$orig($self->_app_object, @_);
  # if the first argument is a hashref, localize %_ to it to permit
  # use of $_{name} inside the dispatch sub
  ref($_[0]) eq 'HASH'
    ? do { my $v = $_[0]; sub { local *_ = $v; &$code } }
    : $code
};

1;
