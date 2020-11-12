use strict;
use warnings;
use 5.010;

use Email::Simple;
use File::Slurper 'read_text';
use List::Util qw(pairs);

my ($file) = @ARGV;
my $text = read_text($file);
my $email = Email::Simple->new($text);

my $header = $email->header_obj;
my @pairs = pairs $header->header_pairs;

my $return_path;
my $from;
my $received;
my @dkim_keys;

foreach my $pair (@pairs) {
	if ($pair->[0] eq "Return-path") {
		$return_path = $pair->[1];
	}
	if ($pair->[0] eq "From") {
		$from = $pair->[1];
	}
	if ($pair->[0] eq "DKIM-Signature") {
		push @dkim_keys, $pair->[1];
	}
	if ($pair->[0] eq "Received") {
		$received = $pair->[1];
	}
}

my ($return_domain) = ($return_path =~ /@(.*)>/);
my ($from_domain) = ($from =~ /@(.*)>/);
my ($received_domain) = ($received =~ /from (.*?) /);
my ($received_tld) = $received_domain =~ m/([^.]+\.[^.]+$)/;
my ($from_tld) = $from_domain =~ m/([^.]+\.[^.]+$)/;

print "Message was sent by $received_tld for $from_tld";

foreach my $dkim_sig (@dkim_keys) {
	my ($dkim) = ($dkim_sig =~ /d=(.*?);/);
	if ($dkim eq $from_domain) {
		my ($dkim_tld) = $dkim =~ m/([^.]+\.[^.]+$)/;
		print " (verified by DKIM for $dkim_tld)";
	}
}
