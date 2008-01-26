# ===========================================================================
# Copyright 2005, Everitz Consulting (mt@everitz.com)
#
# Licensed under the Open Software License version 2.1
# ===========================================================================
package MT::Plugin::FirstEntries;

use base qw(MT::Plugin);
use strict;

use MT;
use MT::Entry;

# version
use vars qw($VERSION);
$VERSION = '1.0.1';

my $about = {
  name => 'MT-FirstEntries',
  description => 'Retrieves entries from the beginning of a blog or category.',
  author_name => 'Everitz Consulting',
  author_link => 'http://www.everitz.com/',
  version => $VERSION,
}; 
MT->add_plugin(new MT::Plugin($about));

use MT::Template::Context;
MT::Template::Context->add_container_tag(FirstEntries => \&FirstEntries);

sub FirstEntries {
  my($ctx, $args, $cond) = @_;

  my %args;
  $args{'sort'} = 'created_on';
  $args{'direction'} = 'ascend';

  # limit entries?
  $args{'limit'} = $args->{firstn} if ($args->{firstn});

  my ($blog_id, $category);
  if ($args->{blog}) {
    $blog_id = $args->{blog};
  } elsif ($args->{category}) {
    use MT::Category;
    $category = MT::Category->load({ label => $args->{category} });
  } else {
    $category = $ctx->stash('category') || $ctx->stash('archive_category');
    $blog_id = $ctx->stash('blog_id') unless ($category);
  }

  my %terms;
  $terms{'status'} = MT::Entry::RELEASE();
  if ($blog_id) {
    $terms{'blog_id'} = $blog_id;
  } elsif ($category) {
    use MT::Placement;
    $args{'join'} = [ 'MT::Placement', 'entry_id', { category_id => $category->id } ];
  } else {
    return $_[0]->error(MT->translate(
      "You used an [_1] tag outside of the proper context.", $ctx->stash('tag')));
  }

  my @entries = MT::Entry->load(\%terms, \%args);

  my $builder = $ctx->stash('builder');
  my $tokens = $ctx->stash('tokens');
  my $res = '';

  foreach (@entries) {
    eval ("use MT::Promise qw(delay);");
    $ctx->{__stash}{entry} = $_ if $@;
    $ctx->{__stash}{entry} = delay (sub { $_; }) unless $@;
    my $out = $builder->build($ctx, $tokens);
    return $ctx->error($builder->errstr) unless defined $out;
    $res .= $out;
  }
  $res;
}

1;
