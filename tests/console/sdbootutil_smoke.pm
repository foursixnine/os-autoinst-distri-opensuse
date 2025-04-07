# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP
# Package: sdbootutil
# Summary: Smoke tests for sdbootutil
# Maintainer: Santiago Zarate <santiago.zarate@suse.com>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;
use power_action_utils 'power_action';

sub run {
    my $self = shift;
    my $bootloader = get_required_var('BOOTLOADER');
    select_console 'root-console';
    assert_script_run 'sdbootutil get-timeout | grep 42';
    assert_script_run 'sdbootutil set-timeout 100';
    assert_script_run 'sdbootutil get-timeout | grep 100';
    assert_script_run 'sdbootutil get-default| grep $(uname -r)';
    validate_script_output 'sdbootutil bootloader', qr/$bootloader/;
    assert_script_run 'sdbootutil -vv is-installed';
    assert_script_run 'sdbootutil list-entries';
    assert_script_run 'sdbootutil list-snapshots';
    assert_script_run 'sdbootutil list-devices';
    assert_script_run 'sdbootutil remove-all-kernels |& grep Removed';

    my $ret = script_run 'sdbootutil -vv is-bootable';
    if (!$ret) {
        die "System should not be bootable at this point";
    }

    assert_script_run 'sdbootutil add-kernel $(uname -r)';
    assert_script_run 'sdbootutil list-kernels | grep $(uname -r)';

    # after all changes, system should be in a consistent state
    power_action('reboot', textmode => 1, keepconsole => 1);
    $self->wait_boot(bootloader_time => 300);

    # System should always boot, TPM is enrolled
    my @packages = qw(git-core helix zip linux-glibc-devel libxcrypt-devel
      ncurses-devel glibc-devel make bison readline-devel
    );

    foreach my $package (@packages) {
        select_console 'root-console';
        record_info $package;
        zypper_call("in --no-recommends $package");
        power_action('reboot', textmode => 1, keepconsole => 1);
        $self->wait_boot(bootloader_time => 300);
        select_console 'root-console';
        assert_script_run 'sdbootutil list-entries';
        assert_script_run 'sdbootutil list-snapshots';
    }

    select_console 'root-console';

}

1;
