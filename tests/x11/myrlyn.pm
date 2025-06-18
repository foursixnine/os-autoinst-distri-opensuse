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
    x11_start_program('xdg-su -c myrlyn');
    send_key 'alt-f4';
}

1;
