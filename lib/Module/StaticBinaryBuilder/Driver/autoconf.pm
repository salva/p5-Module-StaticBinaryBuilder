package Module::StaticBinaryBuilder::Driver::autoconf;

use strict;
use warnings;
use 5.012;

use File::Spec;
use File::chdir;

use parent 'Module::StaticBinaryBuilder::Driver';

sub _init {
    my ($driver, $sbb, %opts) = @_;
    $driver->{configure_script} = delete $opts{configure_script} // 'configure';
    $driver->{configure_extra}  = [ @{delete $opts{configure_extra} // [] } ];
    $driver->{compile_command}  = delete $opts{compile_command}  // 'make';
    $driver->{install_command}  = delete $opts{install_command}  // 'make install';
}

sub _check_src_directory {
    my ($driver, $sbb, $dir) = @_;
    -x File::Spec->join($dir, $driver->{configure_script});
}

sub _configure {
    my ($driver, $sbb) = @_;
    $sbb->_info("running $driver->{configure_script} inside $driver->{src_directory}");
    my $configure = File::Spec->join('.', $driver->{configure_script});
    my $extra = $driver->{configure_extra};
    my $target = $sbb->_target_directory;
    my $include = $sbb->_target_directory('include');
    my $lib = $sbb->_target_directory('lib');
    local $ENV{CPPFLAGS} = "-I$include";
    local $ENV{LDFLAGS}  = "-L$lib -static";
    local $CWD = $driver->{src_directory};
    system $configure, "--prefix=$target", @$extra
        and $sbb->_die("configure failed, rc", ($? >> 8));
}

sub _compile {
    my ($driver, $sbb) = @_;
    $sbb->_info("compiling with command $driver->{compile_command}");
    local $CWD = $driver->{src_directory};
    system $driver->{compile_command}
        and $sbb->_die("compilation failed, rc", ($? >> 8));
}

sub _install {
    my ($driver, $sbb) = @_;
    $sbb->_info("installing with command $driver->{install_command}");
    local $CWD = $driver->{src_directory};
    system $driver->{install_command}
        and $sbb->_die("installation failed, rc", ($? >> 8));
}

1;
