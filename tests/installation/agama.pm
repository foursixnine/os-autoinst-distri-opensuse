# oSUSE's openQA tests
#
# Copyright 2024 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Summary: Installation of Leap or Tumbleweed with Agama
# https://github.com/openSUSE/agama/

# Setting agama live media root password
# https://github.com/openSUSE/agama/blob/master/doc/live_iso.md#the-access-password

# This test suite handles basic installation of Leap and Tumbleweed with Agama
# Actions past install-screen with reboot button ara handled separately in agama_reboot.pm
# Maintainer: Lubos Kocman <lubos.kocman@suse.com>,

use Mojo::Base 'Yam::Agama::agama_base';
use testapi;
use version_utils qw(is_leap is_sle is_microos);
use utils;
use Utils::Architectures;

sub scroll_down {
    # We need to click on an empty space so we can press arrow down
    mouse_set(850, 630);
    mouse_click;
    send_key "ctrl-down";
}

sub scroll_up {
    # We need to click on an empty space so we can press arrow up
    mouse_set(850, 630);
    mouse_click;
    send_key "ctrl-up";
}

sub back_to_overview {
    for (my $tries = 0; $tries <= 5; $tries++) {
        assert_and_click('agama-overview-tab');

        if (check_screen('agama-overview-screen', 5)) {
            record_info('Back to overview');
            return;
        }

        diag "Failed to get to overview screen (# $tries)";
    }

    die "Max tries to return to overview screen reached";
}

sub has_product_selection {
    return 0 if is_s390x;
    return 0 if is_ppc64le && is_leap('=16.0');
    return 0 if is_leap('>16.0');
    return 1;
}

# A More complex screen for root auth
sub agama_set_root_password_screen {
    if (is_leap('<16.1')) {
        # In leap 16 we have a simple toggle to enable root password and then we can set it in the same screen
        assert_and_click('agama-set-root-password');
        wait_still_screen 5;

        # a new toggle to enable password auth for root
        assert_and_click('agama-use-root-password');
        wait_still_screen 5;

        send_key 'tab';    # to switch from toggle to input box
        type_password();
        send_key 'tab';    # show password btn
        send_key 'tab';
        type_password();
        send_key 'tab';    # show password btn
        send_key 'tab';    # optional enable public ssh key toggle
        send_key 'tab';    # accept button
        save_screenshot;
        send_key 'ret';
    } else {
        assert_and_click('agama-root-login-method');
        assert_and_click('agama-root-login-password');
        send_key 'tab';    # to switch from combo to input box

        type_password();
        send_key 'tab';    # show password btn
        send_key 'tab';
        type_password();

        scroll_down();

        # Click the accept button to confirm changes, we use "enter" in agama_define_user_screen
        assert_and_click('agama-user-accept-button');

        scroll_up();

        assert_screen('agama-auth-changes-applied');
    }
}

sub agama_define_user_screen {
    if (is_leap('<16.1')) {
        assert_and_click('agama-define-user-button');
        wait_still_screen 5;

        # We need to click in the middle of the screen or similar
        # to make screen active so we can start typing.
        mouse_set(600, 600);
        mouse_click;

        # Fullname
        send_key 'tab';
        type_string $testapi::realname;

        # Username
        send_key 'tab';
        type_string $testapi::username;
        wait_still_screen 5;

        # Password - we have to send two tabs as there is a button to show typed password
        send_key 'tab';
        type_password();
        send_key 'tab';    # show password btn
        send_key 'tab';
        type_password();

        assert_and_click('agama-user-accept-button');
        wait_still_screen 5;
    } else {
        assert_and_click('agama-add-administrator-account');

        # Fullname
        send_key 'tab';    # to switch from checkbox to input box
        type_string $testapi::realname;

        # Username
        send_key 'tab';
        type_string $testapi::username;

        # Password
        send_key 'tab';
        type_password();
        send_key 'tab';    # show password btn
        send_key 'tab';
        type_password();

        send_key 'ret';    # accepts the changes
        assert_screen('agama-auth-changes-applied');
    }
}

sub auth_setup_root {
    assert_and_click('agama-auth-tab');
    agama_set_root_password_screen();
    back_to_overview;
}

sub auth_define_user {
    assert_and_click('agama-auth-tab');
    agama_define_user_screen();
    back_to_overview;
}

sub agama_fde_tpm_setup {
    assert_and_click('agama-encryption-change');
    assert_and_click('agama-fde-tpm-enable');
    send_key 'ret';
    assert_screen('agama-fde-tpm-enabled');
}

sub agama_fde_setup {
    assert_and_click('agma-storage-tab');
    wait_still_screen 5;
    assert_and_click('agama-encryption-tab');
    assert_and_click('agama-encryption-change');
    assert_and_click('agama-FDE-enable');
    send_key 'tab';
    type_password();
    send_key 'tab';
    send_key 'tab';
    type_password();
    save_screenshot;
    send_key 'ret';
    wait_still_screen 5;
    assert_screen('agama-fde-enabled');

    agama_fde_tpm_setup() if get_var('QEMUTPM', 0);

    back_to_overview;
}

sub agama_lvm_setup {
    assert_and_click('agma-storage-tab');
    assert_and_click('agama-use-vda-to-install');
    assert_and_click('agama-create-lvm-on-vda');
    wait_still_screen 5;
    mouse_set(630, 300);
    mouse_click;    # click on a blank portion, so we can scroll down with the keyboard
    send_key_until_needlematch('agama-lvm-proposal', 'ctrl-down');
}

sub agama_raid_setup {
    # assert_and_click('agma-storage-tab');
    # assert_and_click('agma-storage-more-devices');
    # assert_and_click('agma-storage-select-another-device');
    # assert_and_click('agma-storage-raid-tab');
    # assert_and_click('agma-storage-raid-md0');
    # wait_still_screen 5;

    # assert_and_click('agma-storage-more-devices');
    # assert_and_click('agma-storage-select-another-device');
    # assert_and_click('agma-storage-raid-tab');
    # assert_and_click('agma-storage-raid-md1');
    # wait_still_screen 5;

    # assert_and_click('agma-storage-vda-select');
    # assert_and_click('agma-storage-vda-do-not-use');
    # wait_still_screen 5;

    # assert_and_click('agma-storage-more-devices');
    # assert_and_click('agma-storage-select-another-device');
    # assert_and_click('agma-storage-vda-add');
    # wait_still_screen 5;

    # send_key 'shift-tab';
    # send_key 'shift-tab';

    # assert_and_click('agama-storage-vda-not-configured');
    # assert_and_click('agama-storage-vda-configure-partition');

    # send_key 'tab' for (0 .. 7); # get to mount point
    # type_string '/boot';
    # send_key 'tab'; # Partition combo
    # send_key 'spc'; # Show options
    # send_key 'down' for (0 .. 3);
    # assert_and_click('agama-user-accept-button');
    # wait_still_screen 5;

    # send_key 'shift-tab';
    # send_key 'shift-tab'; # content will be deleted

    # send_key 'spc'
    # send_key 'down' for (0 .. 2);
    # send_key 'ret';

    # # Keep vda1 and vda4 for /boot/efi and /boot respectively
    # # assert_and_click('agma-storage-vda-partitions-content');
    # # assert_and_click('agma-storage-vda-partitions-custom');

    # send_key 'tab' for (0 .. 7); # vda1 - 'Do not modify'
    # send_key 'spc';
    # send_key 'tab' for (0 .. 2); # vda2 - 'Do not modify'
    # send_key 'spc';
    # send_key 'tab' for (0 .. 2); # vda3 - 'Do not modify'
    # send_key 'spc';
    # send_key 'tab' for (0 .. 2); # vda4 - 'Do not modify'
    # send_key 'spc';

    # assert_screen('agama-storage-vda-do-not-modify');

    # send_key 'tab' for (0 .. 2); # vda4 - 'Do not modify'
    # send_key 'ret'; # accept changes

    # # add /boot/efi
    # send_key 'shift-tab';
    # send_key 'shift-tab';
    # send_key 'shift-tab'; # Existing partition...

    # send_key 'spc';

    # send_key 'tab';
    # send_key 'tab';
    # send_key 'ret'; # Enter configure partition

    # assert_and_click('agma-storage-configure-raid-md0');
    # assert_and_click('agma-storage-add-or-use-partition');

    # send_key 'tab' for (0 .. 7); # get to mount point
    # type_string '/';
    # assert_and_click('agama-user-accept-button');
    # wait_still_screen 5;

    # assert_and_click('agma-storage-configure-raid-md1');
    # assert_and_click('agma-storage-add-or-use-partition');

    # send_key 'tab' for (0 .. 7); # get to mount point
    # type_string '/';
    # assert_and_click('agama-user-accept-button');
    # wait_still_screen 5;

    ### maybe first flow
    assert_and_click('agma-storage-settings');
    send_key 'tab' for (0 .. 6);    # New partitions...
    send_key 'spc';    # expand menu

    send_key 'tab';    # /
    send_key 'spc';    # activate combo
    send_key 'down';
    send_key 'spc';    # select delete

    wait_still_screen 5;

    assert_and_click('agma-storage-settings');
    send_key 'tab' for (0 .. 7);    # moves to swap...

    send_key 'spc';    # activate combo
    send_key 'down';
    send_key 'spc';    # select delete

    assert_and_click('agama-storage-vda-not-configured');
    assert_and_click('agama-storage-vda-configure-partition');

    # add /boot
    send_key 'tab' for (0 .. 7);    # get to mount point
    type_string '/boot';
    send_key 'tab';    # go back to focus on the field, workaround UX bug
    type_string '/boot';
    send_key 'tab';    # Partition combo
    send_key 'spc';    # Show options
    send_key 'down' for (0 .. 3);
    send_key 'spc';    # Accept vda4
    assert_and_click('agama-user-accept-button');
    wait_still_screen 5;

    assert_and_click('agama-storage-partition-add-or-use');

    # add /boot/efi
    send_key 'tab' for (0 .. 7);    # get to mount point
    type_string '/';
    send_key 'tab';    # go back to focus on the field, workaround UX bug
    type_string '/boot/efi';
    send_key 'tab';    # Partition combo
    send_key 'spc';    # Show options
    send_key 'down';
    send_key 'spc';    # accept vda1
    send_key 'tab';    # go to filesystem
    send_key 'spc';
    send_key 'down' for (0 .. 5);    # FAT
    send_key 'spc';    # accept
    assert_and_click('agama-user-accept-button');
    wait_still_screen 5;

    # configure rest of partitions of vda
    assert_and_click('agma-storage-settings');

    send_key 'shift-tab' for (0 .. 9);    # goes to '... not configured... deleted'
    send_key 'spc';
    send_key 'down' for (0 .. 2);
    send_key 'spc';    # select what to do

    send_key 'tab' for (0 .. 7);    # vda1 - 'Do not modify'
                                    # send_key 'spc'; not needed
    send_key 'tab' for (0 .. 1);    # vda2 - 'Do not modify'
    send_key 'spc';
    send_key 'tab' for (0 .. 2);    # vda3 - 'Do not modify'
    send_key 'spc';
    send_key 'tab' for (0 .. 2);    # vda4 - 'Do not modify'
    send_key 'tab' for (0 .. 1);    # Focus the accept button

    assert_screen('agama-storage-vda-do-not-modify');

    send_key 'ret';    # accept changes

    # Add and configure md0
    assert_and_click('agma-storage-settings');

    send_key 'shift-tab' for (0 .. 8);    # goes to 'More devices'
    send_key 'spc';
    send_key 'spc';    # select existing device

    assert_and_click('agma-storage-raid-tab');
    assert_and_click('agma-storage-raid-md0');
    wait_still_screen 5;

    assert_and_click('agma-storage-settings');
    send_key 'tab' for (0 .. 6);    # md0 is not configured yet
    send_key 'spc';
    send_key 'spc';    # add or use partition

    send_key 'tab' for (0 .. 7);    # get to mount point
    type_string '/';    # the UX bug is handy here :)
    assert_and_click('agama-user-accept-button');
    wait_still_screen 5;

    # Add and configure md1
    assert_and_click('agma-storage-settings');

    # As the system's partition layout seems correct, there's now the result section
    send_key 'shift-tab' for (0 .. 12);    # goes to 'More devices'
    send_key 'spc';
    send_key 'spc';    # select existing device

    assert_and_click('agma-storage-raid-tab');
    assert_and_click('agma-storage-raid-md1');
    wait_still_screen 5;

    send_key 'tab' for (0 .. 8);    # md1 is not configured yet
    send_key 'spc';
    send_key 'spc';    # add or use partition

    send_key 'tab' for (0 .. 7);    # get to mount point
    type_string 'swap';    # the UX bug is handy here :)
    assert_and_click('agama-user-accept-button');
    wait_still_screen 5;

    back_to_overview;
}

sub select_product {
    # Product selection dialog scrolls with 4+ products at 1024x768.
    # As of now TW is the last item in the list, so we need to scroll a bit.
    mouse_set(600, 600);
    mouse_click;

    my $product_to_install = "agama-product-tumbleweed";
    $product_to_install = "agama-product-leap16" if is_leap;
    $product_to_install = "agama-product-microos" if is_microos;

    if (is_leap('=16.0')) {
        send_key_until_needlematch($product_to_install, 'down');
        assert_and_click($product_to_install);
    } else {    # Default to TW
        send_key_until_needlematch($product_to_install, 'down');
        assert_and_click($product_to_install);
        # New agama version has the Select button inside the same container
        scroll_down();

        send_key_until_needlematch('agama-product-select', 'ctrl-down');
    }
    assert_and_click('agama-product-select');
}

sub select_desktop_pattern {
    my $desktop = get_var('DESKTOP');
    send_key_until_needlematch("agama-software-selection-$desktop-desktop-wayland", 'down');
    assert_and_click("agama-software-selection-$desktop-desktop-wayland");
}

sub software_select_patterns {
    assert_and_click('agama-software-tab');
    wait_still_screen(5);
    assert_and_click('agama-change-software-selection');
    wait_still_screen(5);

    # pattern selection can be pretty long
    # I suggest to scroll down until you match the needle and then click on it
    # Go to the very top in case (ctrl+up) that you need to look for further patterns

    # Prior to Agama 20, the desktop selection used to be handled with the rest of the patterns
    if (is_leap('=16.0')) {
        select_desktop_pattern;
        # Go back to the top in case that any further patterns need to be installed
        # and we have to scroll through the list again.
        send_key "ctrl-up";
    }

    # Futher manually selected patterns should go here
    # Click somewhere in the screen to focus the view, so we can scroll down
    scroll_down();

    assert_and_click('agama-software-selection-close');

}

sub software_select_desktop {
    assert_and_click('agama-software-tab');
    wait_still_screen(5);
    assert_and_click('agama-select-desktop');
    wait_still_screen(5);

    select_desktop_pattern();

    send_key "ctrl-down";

    assert_and_click('agama-software-selection-close');

}

sub run {
    my ($self) = @_;
    my $agama_screen_timeout = 300;
    if (has_product_selection) {
        assert_screen('agama-inst-welcome-product-list', timeout => $agama_screen_timeout);
        select_product();
    }

    # can take few minutes to get here
    assert_screen('agama-overview-screen', timeout => $agama_screen_timeout);

    auth_setup_root();

    auth_define_user();

    # Agama 20+ has a new desktop selection screen
    if (!is_leap('=16.0') && !check_var('DESKTOP', "textmode")) {
        software_select_desktop;
        back_to_overview;
    }

    # Install additional patterns
    software_select_patterns();
    back_to_overview;

    if (get_var('RAIDLEVEL')) {
        agama_raid_setup();
    }

    if (check_var('LVM', 1)) {
        agama_lvm_setup();
        back_to_overview;
    }

    # We can have scenarios with TPM where ENCRYPT is set to 0
    if (defined(get_var('ENCRYPT'))) {
        agama_fde_setup();
    }

    assert_and_click('agama-install-button');

    # confirmation dialog if we keep default partitioning layout
    assert_and_click('agama-confirm-installation');

    # ensure that the installation started before matching agama-congratulations
    # https://github.com/openSUSE/agama/issues/1616
    assert_screen('agama-install-in-progress');

    my $timeout = 2400;    # 40 minutes timeout for installation process
                           # Await installation with a timeout
    while ($timeout > 0) {
        my $ret = check_screen('agama-congratulations', 30);
        $timeout -= 30;
        diag("left total await_install timeout: $timeout");
        last if $ret;
        die "timeout ($timeout) hit during await_install" if $timeout <= 0;
    }
}

1;
