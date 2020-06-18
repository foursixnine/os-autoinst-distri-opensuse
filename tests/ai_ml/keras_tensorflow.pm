# SUSE's openQA tests
#
# Copyright © 2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: This module install tensorflow2-lite and downloads
#   a test program in python, a model, labels and an image.
#   Then, it runs the model with the image as input.
# Maintainer: Guillaume GARDET <guillaume@opensuse.org>

use strict;
use warnings;
use base "opensusebasetest";
use testapi;
use utils;
use version_utils qw(is_sle);
use registration qw(add_suseconnect_product register_product);

sub run {
    my ($self) = @_;

    $self->select_serial_terminal;
    select_console('root-console');

    if (is_sle '>=15') {
        assert_script_run 'source /etc/os-release';
        add_suseconnect_product('PackageHub', undef, undef, undef, 300, 1);
        add_suseconnect_product('sle-module-development-tools');
        #add_suseconnect_product('sle-module-desktop-applications');
    }

    assert_script_run('tar -xvjf ~/data/ai_ml/keras-excersice-files.tar.bz2');
    assert_script_run('python3 test');
}

sub post_fail_hook {
    wait_serial 'work is done', 3600;
}

1;
