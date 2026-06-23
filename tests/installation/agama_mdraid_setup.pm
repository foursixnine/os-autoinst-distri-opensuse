use Mojo::Base 'Yam::Agama::agama_base';
use testapi;

sub run {

    my ($self) = @_;
    my $agama_screen_timeout = 300;
    my @tags = qw(agama-inst-welcome-product-list agama-overview-screen);
    assert_screen(\@tags, timeout => $agama_screen_timeout);
    select_console('install-shell');

    my $raid_level = get_var('RAIDLEVEL');
    my $num_disks = get_var('NUMDISKS');
    my @letters = ("a" .. "z")[0 .. $num_disks - 1];

    my $disks = join(" ", map { "/dev/vd$_" } @letters);
    my $md1_parts = join(" ", map { "/dev/vd${_}2" } @letters);
    my $md0_parts = join(" ", map { "/dev/vd${_}3" } @letters);

    assert_script_run(q{for disk in } . $disks . q{; do
            parted -s $disk -- mklabel gpt \
            mkpart primary fat32 1MiB 1024MiB \
            mkpart primary 1024MiB 1536MiB \
            mkpart primary 1536MiB -1GiB \
            mkpart primary xfs -1GiB 100% \
            set 2 raid on \
            set 3 raid on
    done});

    # 4. Create md1 using the 2GB partitions (Partition 2)
    # Note: Setting this to RAID 1 as it is the standard practice for boot/system arrays
    assert_script_run("mdadm --create --verbose /dev/md1 --level=0 --raid-devices=$num_disks $md1_parts");
    assert_script_run("mdadm --detail /dev/md1");

    # 5. Create md0 using the remaining capacity partitions (Partition 3)
    assert_script_run("mdadm --create --verbose /dev/md0 --level=$raid_level --raid-devices=$num_disks $md0_parts");
    assert_script_run("mdadm --detail /dev/md0");

    select_console('x11', tags => \@tags);

}

1;
