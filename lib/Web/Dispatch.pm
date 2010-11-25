package Web::Dispatch;

use Sub::Quote;
use Scalar::Util qw(blessed);
use Moo;
use Web::Dispatch::Parser;
use Web::Dispatch::Node;

with 'Web::Dispatch::ToApp';

has app => (is => 'ro', required => 1);
has parser_class => (
  is => 'ro', default => quote_sub q{ 'Web::Dispatch::Parser' }
);
has node_class => (
  is => 'ro', default => quote_sub q{ 'Web::Dispatch::Node' }
);
has node_args => (is => 'ro', default => quote_sub q{ {} });
has _parser => (is => 'lazy');

sub _build__parser {
  my ($self) = @_;
  $self->parser_class->new;
}

sub call {
  my ($self, $env) = @_;
  $self->_dispatch($env, $self->app);
}

sub _dispatch {
  my ($self, $env, @match) = @_;
  while (my $try = shift @match) {
    if (ref($try) eq 'HASH') {
      $env = { %$env, %$try };
      next;
    } elsif (ref($try) eq 'ARRAY') {
      return $try;
    }
    my @result = $self->_to_try($try)->($env, @match);
    next unless @result and defined($result[0]);
    if (ref($result[0]) eq 'ARRAY') {
      return $result[0];
    } elsif (blessed($result[0]) && $result[0]->can('wrap')) {
      return $result[0]->wrap(sub {
        $self->_dispatch($_[0], @match)
      })->($env);
    } elsif (blessed($result[0]) && !$result[0]->can('to_app')) {
      return $result[0];
    } else {
      # make a copy so we don't screw with it assigning further up
      my $env = $env;
      # try not to end up quite so bloody deep in the call stack
      if (@match) {
        unshift @match, sub { $self->_dispatch($env, @result) };
      } else {
        @match = @result;
      }
    }
  }
  return;
}

sub _to_try {
  my ($self, $try) = @_;
  if (ref($try) eq 'CODE') {
    if (defined(my $proto = prototype($try))) {
      $self->_construct_node(
        match => $self->_parser->parse($proto), run => $try
      )->to_app;
    } else {
      $try
    }
  } elsif (blessed($try) && $try->can('to_app')) {
    $try->to_app;
  } else {
    die "No idea how we got here with $try";
  }
}

sub _construct_node {
  my ($self, %args) = @_;
  @args{keys %$_} = values %$_ for $self->node_args;
  $self->node_class->new(\%args);
}

1;