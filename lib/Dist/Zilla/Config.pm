use strict;
use warnings;
package Dist::Zilla::Config;
# ABSTRACT: read in a dist.ini file
use Config::INI::MVP::Reader;
BEGIN { our @ISA = 'Config::INI::MVP::Reader' }

use Dist::Zilla::Util;

=head1 DESCRIPTION

Dist::Zilla::Config reads in the F<dist.ini> file for a distribution.  It uses
L<Config::INI::MVP::Reader> to do most of the heavy lifting.  You may write
your own class to read your own config file format.  It is expected to return 
a hash reference to be used in constructing a new Dist::Zilla object.  The
"plugins" entry int he hashref should be an arrayref of plugin configuration
like this:

  $config->{plugins} = [
    [ $class_name => { ...config...} ],
    ...
  ];

=cut

sub multivalue_args { qw(author) }

sub default_filename { 'dist.ini' }

sub _expand_package {
  my $str = Dist::Zilla::Util::Config->_expand_config_package_name($_[1]);
  return $str;
}

sub finalize {
  my ($self) = @_;
  $self->SUPER::finalize;

  ## no critic
  my $data = $self->{data};

  my $root_config = $data->[0]{'=name'} eq '_' ? shift @$data : {};

  $root_config->{authors} = delete $root_config->{author};

  my @plugins;
  for my $plugin (@$data) {
    my $class = delete $plugin->{'=package'};
    
    if ($class->does('Dist::Zilla::Role::PluginBundle')) {
      push @plugins, $class->bundle_config($plugin);
    } else {
      push @plugins, [ $class => $plugin ];
    }
  }

  $root_config->{plugins} = \@plugins;
  $self->{data} = $root_config;
}

1;
