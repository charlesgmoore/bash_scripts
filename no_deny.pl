#!/usr/bin/perl --
@FILES = ("hosts", "hosts-restricted", "hosts-root", "hosts-valid",  "users-hosts", "users-invalid", "users-valid");
$HD = "/etc/hosts.deny";
$DHP = "/var/lib/denyhosts";

if ( scalar(@ARGV) < 1 ) {
    die "Need an IP address\n";
}

$ip = shift(@ARGV);

if ($ip !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
    die "Need something that approximates a valid IP address\n";
}

open HOSTSDENY, "$HD" or die $!;
$test = 0;
while (<HOSTSDENY>) {
    $line = $_;
    chop($line);
    if ($line =~ m/^sshd: ($ip)/) {
        $test = 1;
    }
}

if ($test == 0) {
    die "Could not find the IP address in $HD\n";
}

print "Located the IP $ip in $HD. Do you want to remove these entries? [Y/N] ";
my $in = <STDIN>;
chomp ($in);
if ($in !~ /y/i) {
    exit(0);
}

print "Shutting down denyhosts service\n";
system("service denyhosts stop") == 0 or warn "Could not stop denyhosts\n";

push(@FILES, $HD);
print "Purging the following files:\n";
foreach $file (@FILES) {
    print "\t$file";
    if ($file !~ m/^\//) {
        $file = "$DHP/$file";
    }
    my @LINES = ();
    open (FILE, "$file");
    while (<FILE>) {
        $line = $_;
        if ($line !~ m/($ip)/) {
            push(@LINES, $line);
        }
    }

    close FILE;

    unshift(@LINES, $file);
    &write_file(@LINES);
    print ": purged\n";
}

print "Restarting denyhosts...\n";
system("service denyhosts start") == 0 or warn "Could not start denyhosts\n";
exit 0;

sub write_file {
    my $file = shift(@_);
    open(OUTPUT, "+>", "$file") == 0 or warn "Could not open file: $!\n";
    foreach $line (@_) {
        print OUTPUT $line;
        #print $line;
    }
    close OUTPUT;
}