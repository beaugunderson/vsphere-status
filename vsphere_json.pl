#!/usr/bin/perl -w

use strict;
use warnings;

use CGI qw(:standard);

use JSON;

use Term::ANSIColor;

use VMware::VILib;
use VMware::VIRuntime;

$SIG{__DIE__} = sub{Util::disconnect()};

# Disable parsing for testing
#Opts::parse();
#Opts::validate();

Util::connect("https://vsphere/sdk", "USERNAME", "PASSWORD");

my $sc = Vim::get_service_content();

print header('application/json');

main();

Util::disconnect();

sub listVMs {
	my ($entity_moref, $folder_name) = @_;

	my ($num_entities, $entity_view, $child_view, $i, $mo);

	$entity_view = Vim::get_view(
		mo_ref => $entity_moref, properties => ['name', 'childEntity']
	);

	$num_entities = defined($entity_view->childEntity) ? @{$entity_view->childEntity} : 0;

	my @entries = ();
	my %folders = ();

	my %tree = (
		entries => \@entries,
		folders => \%folders
	);

	if ($num_entities > 0) {
		foreach $mo (@{$entity_view->childEntity}) {
			$child_view = Vim::get_view(
				mo_ref => $mo
			);

			if ($child_view->isa("VirtualMachine")) {
				my $host = Vim::get_view(
					mo_ref => $child_view->runtime->host,
					properties => ['name']);

				my %vm = (
					name => $child_view->name,
					host => $host->name,
					guestName => $child_view->summary->guest->guestFullName,
					hostName => $child_view->summary->guest->hostName,
					ipAddress => $child_view->summary->guest->ipAddress,
					guestMemoryUsage => $child_view->summary->quickStats->guestMemoryUsage,
					hostMemoryUsage => $child_view->summary->quickStats->hostMemoryUsage,
					swappedMemory => $child_view->summary->quickStats->swappedMemory,
					cpuDemand => $child_view->summary->quickStats->overallCpuDemand,
					cpuUsage => $child_view->summary->quickStats->overallCpuUsage,
					bootTime => $child_view->summary->runtime->bootTime,
					powerState => $child_view->summary->runtime->powerState->val
				);

				push(@entries, \%vm);
			}

			if ($child_view->isa("Folder")) {
				$child_view = Vim::get_view(
					mo_ref => $mo,
					properties => ['name', 'childEntity']
				);

				my %result = listVMs($mo);

				$tree{'folders'}{$child_view->name} = \%result;
			}
		}
	}

	return %tree;
}

sub main {
	my $datacenter_views = Vim::find_entity_views(
		view_type => 'Datacenter',
		properties => ["name", "vmFolder"],
	);

	foreach (@{$datacenter_views}) {
		my %tree = ();

		my %result = listVMs($_->vmFolder);
		
		$tree{$_->name} = \%result;

		my $json = new JSON;

		print $json->pretty->encode(\%tree);
	}
}
