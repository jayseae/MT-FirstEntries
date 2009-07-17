# ===========================================================================
# A Movable Type plugin to retrieve entries from a blog or category.
# Copyright 2005 Everitz Consulting <everitz.com>.
#
# This program is free software:  You may redistribute it and/or modify it
# it under the terms of the Artistic License version 2 as published by the
# Open Source Initiative.
#
# This program is distributed in the hope that it will be useful but does
# NOT INCLUDE ANY WARRANTY; Without even the implied warranty of FITNESS
# FOR A PARTICULAR PURPOSE.
#
# You should have received a copy of the Artistic License with this program.
# If not, see <http://www.opensource.org/licenses/artistic-license-2.0.php>.
# ===========================================================================
package MT::Plugin::FirstEntries;

use base qw(MT::Plugin);
use strict;

use MT;
use MT::Entry;

# version
use vars qw($VERSION);
$VERSION = '1.0.2';

my $about = {
  name => 'MT-FirstEntries',
  description => 'Retrieve entries from the beginning of a blog or category.',
  author_name => 'Everitz Consulting',
  author_link => 'http://everitz.com/',
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
