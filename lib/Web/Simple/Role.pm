package Web::Simple::Role;

=head1 NAME

Web::Simple::Role

=head1 SYNOPSIS

  package MyApp;
  use Web::Simple;
  with MyApp::Role;
  
  sub dispatch_request { ... }

and in the role:

  package MyApp::Role;
  use Web::Simple::Role;

  around dispatch_request => sub {
    my ($orig, $self) = @_;
    return (
      $self->$orig,
      sub (GET + /baz) { ... }
    );
  };

Now C<MyApp> can also dispatch C</baz>

=cut

use strictures 1;
use 5.008;
use warnings::illegalproto ();
use Moo::Role ();

our $VERSION = '0.020';

sub import {
  my ($class, $app_package) = @_;
  $app_package ||= caller;
  eval "package $app_package; use Web::Dispatch::Wrapper; use Moo::Role; 1"
    or die "Failed to setup app package: $@";
  strictures->import;
  warnings::illegalproto->unimport;
}

=head1 AUTHOR

osfameron@cpan.org

=cut

1;
