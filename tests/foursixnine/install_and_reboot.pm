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

use Utils::Backends 'is_remote_backend';
use power_action_utils 'power_action';

sub run {
    my ($self) = @_;

    $self->select_serial_terminal;
    my $is_textmode = check_var('DESKTOP', 'textmode');
    # Install required software
    if (get_var("EXTRA_REPO")){
        my $EXTRA_REPO = get_var("EXTRA_REPO");
        zypper_call("ar -r $EXTRA_REPO -p 90 -G -n bug");
        record_info("Repositories", script_output("zypper lr"));
        zypper_call('in --allow-vendor-change '.get_required_var("PACKAGES_TO_INSTALL"));
        power_action('reboot', textmode=> 1, keepconsole => 1, observe => 1);
        $self->wait_boot(textmode => 1, in_grub => 1, bootloader_time => 250);
    }
    select_console('root-console');
    select_console('user-console');
    select_console('x11');
    select_console('root-console');
    select_console('user-console');


}

1;
