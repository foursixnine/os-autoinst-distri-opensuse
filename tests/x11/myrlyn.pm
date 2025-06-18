use base "x11test";
use strict;
use warnings;
use testapi;

sub run {
    ensure_installed('myrlyn');

    #start myrlyn in read-only mode
    x11_start_program('myrlyn');
    send_key 'alt-f4';

    # now start myrlyn in rw
    x11_start_program('myrlyn-sudo', target_match => 'myrlyn-askpass');
    type_password;
    send_key 'ret';

    # verify that myrlyn has started
    assert_screen('myrlyn');
    send_key 'alt-f4';

}

1;
