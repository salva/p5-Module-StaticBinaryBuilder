package Module::StaticBinaryBuilder;

our $VERSION = '0.01';

use strict;
use warnings;
use 5.012;

use File::Spec;

use Module::StaticBinaryBuilder::Driver;

our $verbose_level //= 3;

sub _notify {
    my $self = shift;
    my $level = shift;
    if ($level <= $self->{verbose_level}) {
        my $msg = join(": ", @_);
        chomp $msg;
        print STDERR "$msg\n";
    }
}

sub _debug { shift->_notify(2, @_) }
sub _info  { shift->_notify(1, @_) }
sub _error { shift->_notify(0, @_) }
sub _die   { shift->_error(@_); exit(1) };

sub new {
    my ($class, %opts) = @_;
    my $components = delete $opts{components};
    my $sbb = { opts => \%opts,
                working_directory => File::Spec->rel2abs('build'),
                components => [],
                verbose_level => $verbose_level };
    bless $sbb, $class;
    $sbb->_add_component($_) for @$components;
    $sbb;
}

sub _working_directory {
    my $sbb = shift;
    my $wd = $sbb->{working_directory};
    File::Spec->join($wd, @_);
}

sub _target_directory { shift->_working_directory("target", @_) }
sub _is_done_directory { shift->_working_directory("is_done", @_) }

sub _add_component {
    my ($sbb, $c) = @_;
    my $cs = $sbb->{components};
    push @$cs, Module::StaticBinaryBuilder::Driver->_new($sbb, %$c,
                                                         _index => scalar(@$cs));
}

sub run {
    my $sbb = shift;
    my ($cmd, @args) = (@_ ? @_ : @ARGV);
    my $method = $sbb->can("_cmd_$cmd")
        or $sbb->_die("command $cmd not supported");
    $sbb->$method(@args);
}


sub _static_binaries {
    my $sbb = shift;
    my %sbd;
    my %sb;
    for my $driver (@{$sbb->{components}}) {
        $sbd{$sbb->_target_directory($_)} = 1 for $driver->_static_binaries_dirs;
        $sb{$sbb->_target_directory($_)} = 1 for $driver->_static_binaries;
    }


    my $flm = File::LibMagic->new;
    for my $sbd (sort keys %sbd) {
        if (opendir my $dh, $sbd) {
            while (defined (my $file = readdir $dh)) {
                $file = File::Spec->join($sbd, $file);
                next unless -f $file;
                my $type = $flm->describe_filename($file);
                $sbd{$file} = 1 if $type =~ /\bexecutable\b
                $sbb->_debug("file $file is of type $type");
            }
        }
    }
    return sort keys %sb;

}

sub _cmd_build {
    my $sbb = shift;
    $sbb->_create_working_environment;
    $_->_build($sbb) for @{$sbb->{components}};
    $sbb->_build_dist;
}

sub _create_working_environment {
    my $sbb = shift;
    for my $method (qw(_working_directory _target_directory _is_done_directory)) {
        my $path = $sbb->$method;
        $sbb->_debug("creating directory $path");
        mkdir $path;
        -d $path or $sbb->_die("unable to create working directory $path");
    }
}

sub _build_dist {
    my $sbb = shift;
    my @sbfs = $sbb->_static_binaries;
}

1;
__END__

=head1 NAME

Module::StaticBinaryBuilder - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Module::StaticBinaryBuilder;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Module::StaticBinaryBuilder, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
