# SUSE's openQA tests
#
# Copyright 2015-2017 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: snapper
# Summary: Check that snapper can revert file changes between snapshots
# - Disable dbus if necessary
# - Create a snapshot with description "before undochange test"
# - Create a test file on fs to simulate change
# - Create a snapshot with description "after undochange test"
# - Undo last change by running snapper undochange
# - Check for file
# - Undo last change by running snapper undochange one more time
# - Check for file
# - Cleanup
# Maintainer: mkravec <mkravec@suse.com>

use base 'btrfs_test';
use testapi;
use utils 'zypper_call';
use power_action_utils 'power_action';

sub install_updates {
    assert_script_run("sed -i 's/^# solver.allowVendorChange = false/solver.allowVendorChange = true/' /etc/zypp/zypp.conf");
    assert_script_run("zypper ar -G -p 50 -f https://download.opensuse.org/repositories/home:/fbui:/systemd:/isolate-issue/openSUSE_Factory/home:fbui:systemd:isolate-issue.repo");
    assert_script_run("zypper ref");
    zypper_call("up");
}

sub run {
    my ($self) = @_;
    select_console 'root-console';

    my $systemd = script_output("rpm -q systemd");
    record_info("Systemd", $systemd);

    install_updates;
    power_action('reboot');
    $self->wait_boot(bootloader_time => 200);
    select_console 'root-console';

    $systemd = script_output("rpm -q systemd");
    record_info("Systemd", $systemd);

    my $snapfile = '/etc/snapfile';
    my @snapper_runs = 'snapper';
    push @snapper_runs, 'snapper --no-dbus' if get_var('SNAPPER_NODBUS');

    foreach my $snapper (@snapper_runs) {
        $self->snapper_nodbus_setup if $snapper =~ /dbus/;

        assert_script_run "snapbf=`$snapper create -p -d 'before undochange test'`", 90;
        script_run "date > $snapfile";    # simulate system changing by adding new dummy file
        assert_script_run "snapaf=`$snapper create -p -d 'after undochange test'`", 90;

        # Delete snapfile
        script_run "$snapper undochange \$snapbf..\$snapaf $snapfile", 90;
        script_run("test -f $snapfile || echo \"snap-ba-ok\" > /dev/$serialdev", 0);
        wait_serial("snap-ba-ok", 30) || die "Snapper undochange failed";

        # Restore snapfile
        script_run "$snapper undochange \$snapaf..\$snapbf $snapfile", 90;
        assert_script_run("test -f $snapfile", timeout => 10, fail_message => "File $snapfile could not be found");

        assert_screen 'snapper_undochange';
        assert_script_run "rm $snapfile";
        $self->snapper_nodbus_restore if $snapper =~ /dbus/;
    }
}

1;

