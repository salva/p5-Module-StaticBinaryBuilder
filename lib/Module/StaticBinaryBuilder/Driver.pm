package Module::StaticBinaryBuilder::Driver;

use strict;
use warnings;
use 5.012;

use File::Spec;
use LWP::Simple qw(mirror RC_OK RC_NOT_MODIFIED);
use File::LibMagic qw(MagicFile);
use File::chdir;

sub _new {
    my ($class, $sbb, %opts) = @_;
    my $index       = delete($opts{_index}) // $sbb->_error("internal error", "_index missing");
    my $name        = delete($opts{name})   // "component-$index";
    my $driver_name = delete($opts{driver}) // 'autoconf';
    $driver_name =~ /^\w+$/ or $sbb->_die("invalid driver name $driver_name");
    my $source      = delete($opts{source});
    my $md5         = delete($opts{md5});
    my $wd = $sbb->_working_directory("component-$name");

    my $driver = { name              => $name,
                   driver_name       => $driver_name,
                   index             => $index,
                   source            => $source,
                   md5               => $md5,
                   working_directory => $wd };

    $class .= "::$driver_name";
    eval "require $class; 1" or $sbb->_die("unable to load driver class $class:\n$@");
    bless $driver, $class;

    $driver->{unpack_directory} = $driver->_working_directory('unpack');
    $driver->_init($sbb, %opts);
    $driver;
}

sub _working_directory {
    my $sbb = shift;
    my $wd = $sbb->{working_directory};
    File::Spec->join($wd, @_);
}

sub _build {
    my ($driver, $sbb) = @_;
    $sbb->_info("building $driver->{name}");
    $driver->_create_working_environment($sbb);
    $driver->_download($sbb);
    $driver->_unpack($sbb);
    $driver->_find_src_directory($sbb);
    $driver->_configure($sbb);
    $driver->_compile($sbb);
    $driver->_install($sbb);
}

sub _create_working_environment {
    my ($driver, $sbb) = @_;
    for my $slot (qw(working_directory unpack_directory)) {
        my $path = $driver->{$slot};
        $sbb->_debug("creating directory $path");
        mkdir $path;
        -d $path or $sbb->_die("unable to create directory $path");
    }
}

sub _download {
    my ($driver, $sbb) = @_;
    my $source = $driver->{source} // $sbb->_die("unable to download archive for component $driver->{name}",
                                               "source not defined");
    $sbb->_info("downloading $source");
    my $archive = $driver->{archive} = $driver->_working_directory('archive-0');
    my $ok = mirror($driver->{source}, $archive);
    grep { $ok = $_ } RC_OK, RC_NOT_MODIFIED or
        $sbb->_die("unable to retrieve $driver->{source}", $ok);
}

sub _unpack {
    my ($driver, $sbb) = @_;
    my $archive = $driver->{archive} // $sbb->_die("internal error",
                                                   "archive slot is undefined");

    $sbb->_info("unpacking archive $archive");

    -f $archive or $sbb->_die("internal error",
                              "$archive does not exists or is not a file");
    my $flm = File::LibMagic->new;
    my $tm = $flm->checktype_filename($archive);
    $sbb->_debug("archive is of type $tm");
    if ($tm =~ m|^application/x-gzip\b|) {
        local $CWD = $driver->{unpack_directory};
        system 'tar', 'xzf', $archive
            and $sbb->_die("unable to untar file $archive, rc", ($? >> 8));
    }
    else {
        $sbb->_die("unsupported file format", $tm);
    }
}

sub _check_src_directory { 1 }

sub _find_src_directory {
    my ($driver, $sbb) = @_;

    opendir my $dh, $driver->{unpack_directory}
        or $sbb->_die("unable to list contents of directory $driver->{unpack_directory}");
    my @dirs = grep !/^\./, readdir $dh;
    for my $short (@dirs) {
        my $dir = File::Spec->join($driver->{unpack_directory}, $short);
        if (-d $dir and $driver->_check_src_directory($sbb, $dir)) {
            my $sd = $driver->{src_directory} = $dir;
            $sbb->_info("package source found at $sd");
            return;
        }
    }

    $sbb->_die("unable to find source directory inside $driver->{unpack_directory}");
}

sub _configure {
    my ($driver, $sbb) = @_;
    $sbb->_die("internal error", "_configure method is not implemented");
}

sub _compile {
    my ($driver, $sbb) = @_;
    $sbb->_die("internal error", "_compile method is not implemented");
}

1;
