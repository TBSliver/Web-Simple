#!/usr/bin/perl

use FindBin;
use lib $FindBin::Bin.'/code';
use Web::Simple 'Bloggery';

package Bloggery::PostList;

use File::stat;

sub from_dir {
  my ($class, $dir) = @_;
  bless ({ dir => $dir }, $class);
}

sub all {
  my ($self) = @_;
  map { Bloggery::Post->from_file($_) }
    sort { stat($a)->mtime <=> stat($b)->mtime }
    grep { !/\.summary\.html$/ }
      glob($self->{dir}.'/*.html');
}

sub post {
  my ($self, $name) = @_;
  my $file = $self->{dir}."/${name}.html";
  return unless $file && -f $file;
  return Bloggery::Post->from_file($file);
}

package Bloggery::Post;

sub from_file {
  my ($class, $file) = @_;
  bless({ file => $file }, $class);
}

sub name {
  my $name = shift->{file};
  $name =~ s/.*\///;
  $name =~ s/\.html$//;
  $name;
}

sub title {
  my $title = shift->name;
  $title =~ s/-/ /g;
  $title;
}

sub html {
  \do { local (@ARGV, $/) = shift->{file}; <> };
}

sub summary_html {
  my $file = shift->{file};
  $file =~ s/\.html$/.summary.html/;
  return \'<p>No summary</p>' unless -f $file;
  \do { local (@ARGV, $/) = $file; <> };
}

package Bloggery;

default_config(
  title => 'Bloggery',
  posts_dir => $FindBin::Bin.'/posts',
);

sub post_list {
  my ($self) = @_;
  $self->{post_list}
    ||= Bloggery::PostList->from_dir(
          $self->config->{posts_dir}
        );
}

sub post {
  my ($self, $post) = @_;
  $self->post_list->post($post);
}

dispatch [
  sub (.html) {
    filter_response { $self->render_html($_[1]) },
  },
  sub (GET + /) {
    $self->redispatch('index.html')
  },
  sub (GET + /index) {
    $self->post_list
  },
  sub (GET + /*) {
    $self->post($_[1]);
  },
  sub (GET) {
    [ 404, [ 'Content-type', 'text/plain' ], [ 'Not found' ] ]
  },
  sub {
    [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
  },
];

sub render_html {
  my ($self, $data) = @_;
  use HTML::Tags;
  return $data if ref($data) eq 'ARRAY';
  return [
    200,
    [ 'Content-type', 'text/html' ],
    [
      HTML::Tags::to_html_string(
        <html>,
          <head>,
            <title>, $self->title_for($data), </title>,
          </head>,
          <body>,
            <h1>, $self->title_for($data), </h1>,
            <div id="main">,
              $self->main_html_for($data),
            </div>,
          </body>,
        </html>
      )
    ]
  ];
}

sub title_for {
  my ($self, $data) = @_;
  if ($data->isa('Bloggery::Post')) {
    return $data->title;
  }
  return $self->config->{title};
}

sub main_html_for {
  my ($self, $data) = @_;
  use HTML::Tags;
  if ($data->isa('Bloggery::Post')) {
    $data->html
  } elsif ($data->isa('Bloggery::PostList')) {
    <ul>,
      (map {
        my $path = '/'.$_->name.'.html';
        <li>,
          <h4>, <a href="$path">, $_->title, </a>, </h4>,
          <span class="summary">, $_->summary_html, </span>,
        </li>;
      } $data->all),
    </ul>;
  } else {
    <h2>, "Don't know how to render $data", </h2>;
  }
}

Bloggery->run_if_script;