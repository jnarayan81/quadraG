#!/usr/bin/env perl

=head1 NAME

quadraG.pl - quadraG script by Jitendra Narayan

=head1 SYNOPSIS

quadraG.pl --detect/-d

	quadraG.pl --detect/-d --conf/-c <configuration file>

quadraG.pl --merge/-m

	quadraG.pl --merge/-m --conf/-c <configuration file>

quadraG.pl --plot/-p

	quadraG.pl --plot/-p --conf/-c <configuration file>

quadraG.pl --annot/-a

	quadraG.pl --annot/-a --conf/-c <configuration file>
=cut

use strict;
use warnings;

use Bio::SeqIO;
use Cwd;
use File::chdir;
use File::Copy;
use POSIX;
use File::Temp qw(tempfile);
use File::Spec::Functions qw(rel2abs);
use File::Basename;
use FindBin;
use File::Remove;
use File::Path qw(make_path remove_tree);
use Capture::Tiny ':all';
use Getopt::Long;
use Tie::File;
use Try::Tiny;
use Data::Dumper;
#use Statistics::R;
use Math::Round;
use File::Find;
use Pod::Usage;
use Parallel::ForkManager;
use String::ProgressBar;
use lib "$FindBin::Bin/.";
require 'quadraG_module.pm';

#Basics mandatory quadraG variables
my (
$outfile, 	# Name for quadraG's main configuration file
$conf,
$detect,
$merge,
$plot,
$annot,
$help,		# If you are asking for help
);

# Default settings here for quadraG
my $current_version = "0.1";	#quadraG version
my %opts; my $nam;

print <<'WELCOME';

    ---. .-. .---
      --\'G'/--
         \ /
         " "
 >---quadraG v0.1---<

Citation - quadraG: an open and parallel tool for automated G-quadruplexes analysis 
License: Creative Commons Licence
Bug-reports and requests to: jnarayan81ATgmail.com

WELCOME

$|++;
#Get options for quadraG
GetOptions(
	\%opts,
	"conf|c=s" 	=> \$conf,
	"detect|d" 	=> \$detect,
	"merge|m" 	=> \$merge,
	"plot|p" 	=> \$plot,
	"annot|a" 	=> \$annot,
	"help|h" 	=> \$help,
); 
pod2usage(-verbose => 1) if ($help);
pod2usage(-msg => 'Please check manual.') unless ($detect or $merge or $plot or $annot);
detectHelp($current_version) if (($detect) and (!$conf));
mergeHelp($current_version) if (($merge) and (!$conf));
annotHelp($current_version) if (($annot) and (!$conf));
plotHelp($current_version) if (($plot) and (!$conf));

pod2usage(-msg => 'Please supply a valid filename.') unless ($conf && -s $conf);

# used to measure total execution time
my $start_time = time(); 

#Store thr opted name
if ($detect) {$nam = 'detect';} elsif ($merge) {$nam = 'merge';} elsif ($plot) {$nam = 'plot';} elsif ($annot) {$nam = 'annot';} else { print "Missing parameters\n"; exit(1);}
 
my $project_config_file = $conf;

# Absolute path of the current working directory
my $quadraG_path = dirname(rel2abs($0)); #print " Path of the dir\n$quadraG_path --------\n";

# Parameters_ref - stores all user-defined parameters, such as file locations and program parameters
my $param_ref = read_config_files(\$project_config_file, \$quadraG_path);  # stores the configuration in a hash reference

# Check all the parameters for their correctness
parameters_validator($param_ref); #checkin if user set the parameters right


#---------------------------------------
if ($detect) {
# Delete the directory if already exisit
if ((-e $param_ref->{out_dir}) and ($param_ref->{force} == 1)){ remove_tree( $param_ref->{out_dir});}

# Creating the needed directories if they don't exist
if (!-e $param_ref->{out_dir}) { mkdir ($param_ref->{out_dir}) || die ("Couldn't create the directory specified as '$param_ref->{out_dir}', check if you are trying to create a subdirectory in a non-existent directory or if you don't have permission to create a directory there.\n"); }
else { die("Directory $param_ref->{out_dir} already exists.\n"); }

if (!-e "$param_ref->{out_dir}/results") { mkdir ("$param_ref->{out_dir}/results") || die ("Couldn't create the directory with the results of quadraG's analysis.\nDetails: $!\n"); }
if (!-e "$param_ref->{out_dir}/intermediate_files") { mkdir ("$param_ref->{out_dir}/intermediate_files/") || die ("Couldn't create the directory with the steps of quadraG's analysis.\nDetails: $!\n"); }
if (!-e "$param_ref->{out_dir}/intermediate_files/quadra") { mkdir ("$param_ref->{out_dir}/intermediate_files/quadra") || die ("Couldn't create the directory with the steps of quadraG's analysis.\nDetails: $!\n"); }
if (!-e "$param_ref->{out_dir}/intermediate_files/stat") { mkdir ("$param_ref->{out_dir}/intermediate_files/stat") || die ("Couldn't create the directory with the steps of quadraG's analysis.\nDetails: $!\n"); }

#Copy file to the locations
copy($project_config_file, "$param_ref->{out_dir}/project_config");
#Create an intermediate folder 
#Write the log files for all steps
open (LOG, ">", "$param_ref->{out_dir}/log.$nam") || die ('Could not create log file in ', $param_ref->{out_dir}, '. Please check writing permission in your current directory', "\n");
open (LOG_ERR, ">", "$param_ref->{out_dir}/log.err.$nam") || die ('Could not create log.err file in ', $param_ref->{out_dir}, '. Please check writing permission in your current directory', "\n");
open (SUMMARY, ">", "$param_ref->{out_dir}/results/$param_ref->{summary}.$nam") || die ('Could not create summary file. Please check writing permission in your current directory', "\n");

open (INTERMEDIATE, ">", "$param_ref->{out_dir}/intermediate_files/quadra/$param_ref->{intermediate}") || die ('Could not create all_quadra file. Please check writing permission in your current directory', "\n");

#Parse the genome file and store in Hash
my ($sequence_data_ref, $id2tmp_id_ref, $tmp_id2id_ref) = parse_genome($param_ref);
my %abc=%{$sequence_data_ref}; 
my $max_procs = $param_ref->{max_processors};
my @names = keys %abc;
my $pr = String::ProgressBar->new(max => $#names);

  # hash to resolve PID's back to child specific information
  my $pm =  new Parallel::ForkManager($max_procs);

 # Setup a callback for when a child finishes up so we can
  # get it's exit code
  $pm->run_on_finish (
    sub { my ($pid, $exit_code, $ident) = @_;
      #print "** $ident just got out of the pool ". "with PID $pid and exit code: $exit_code\n";
    }
  );

  $pm->run_on_start(
    sub { my ($pid,$ident)=@_;
     #print "** $ident started, pid: $pid\n";
    }
  );

  $pm->run_on_wait(
    sub {
      #print "** Have to wait for one children ...\n"
    },
    0.5
  );

  NAMES:
  foreach my $child ( 0 .. $#names ) {
    $pr->update($child); if ($child % 1000 == 0) { $pr->write; }
    my $pid = $pm->start($names[$child]) and next NAMES;
    #checkATCG($names[$child]);
    my $sequence=$abc{$names[$child]}{nuc_seq};
    #print INTERMEDIATE"$names[$child]\n";
    findQuadra($names[$child], $abc{$names[$child]}{nuc_seq}, 10, 'testref', $param_ref->{mismatch}, $param_ref);
    $pm->finish($child); # pass an exit code to finish
  }

$pr->write; #Write at the terminal

print LOG "Waiting for jobs to complete...\n" if $param_ref->{verbose};
$pm->wait_all_children;

print LOG "Printing the STAT!\n" if $param_ref->{verbose};
detectStat("$param_ref->{out_dir}/intermediate_files/quadra/$param_ref->{intermediate}", "$param_ref->{out_dir}/intermediate_files/stat/quadra.q4.stat", $param_ref->{score});
print LOG "Everything is sucessfully completed!\n" if $param_ref->{verbose};

}

if ($merge) {
#---------------------------------------
# Merge all "direct" overlaps

#Write the log files for all steps
openLog($nam);
openLogErr($nam);

if ($param_ref->{overlaps} == 1) {
	print LOG "Merging all DIRECT overlaps\n";
 	blockMerger("$param_ref->{out_dir}/intermediate_files/quadra/$param_ref->{intermediate}", "$param_ref->{out_dir}/intermediate_files/quadra/final.q4");
	}
elsif ($param_ref->{overlaps} == 0) { #Keep all the info
	print LOG "You decided not to merge direct overlaps, keeping all\n";
	copy("$param_ref->{out_dir}/intermediate_files/quadra/$param_ref->{intermediate}", "$param_ref->{out_dir}/intermediate_files/quadra/final.q4");
	}
else { print LOG "No parameters provided in config file\n"; exit; }

print LOG "Printing the STAT!\n" if $param_ref->{verbose};
if ($param_ref->{overlaps} == 0) {print LOG "Since you set overlaps = 0 in config file, the stats will be the same as initial\n";}
detectStat("$param_ref->{out_dir}/intermediate_files/quadra/final.q4", "$param_ref->{out_dir}/intermediate_files/stat/final.q4.stat", $param_ref->{score});
}

if ($annot) {
#---------------------------------------
# Annotate the results
#Write the log files for all steps
openLog($nam);
openLogErr($nam);

if (!$param_ref->{check}) { print LOG_ERR "You set NOT to check option in config line\n Change in config file if needed\n"; exit(0);}

if ($param_ref->{check}==1) { # Set zero in conf, if not interested
	print LOG "Checking in user provided GFF file for G4 associated features\n";
	if (!"$param_ref->{out_dir}/intermediate_files/quadra/final.q4") { print LOG_ERR "Missing final.q4 file; You might need to run --detect first\n";}
 	checkInGFF("$param_ref->{out_dir}/intermediate_files/quadra/final.q4", "$param_ref->{reference_genome_gff}", "$param_ref->{out_dir}/intermediate_files/quadra/final_annotated.q4", $param_ref->{extend} );

}

analyticStat("$param_ref->{out_dir}/intermediate_files/quadra/final_annotated.q4", "$param_ref->{out_dir}/intermediate_files/stat/final_annotated.q4.stat", $param_ref->{score});
}

#---------------------------------------
if ($plot) {
# Plot the results
#Write the log files for all steps
openLog($nam);
openLogErr($nam);

print "Thanks for your interest, still working on it :)\n\n"; exit;
}

#-------------------------------------------------------------------------------
print LOG "Analysis finished, closing quadraG.  \nGood bye :) \n" if $param_ref->{verbose};

close(SUMMARY);
close(INTERMEDIATE);
close(LOG_ERR);
close(LOG);


############## Subs ###################
sub openLog {
my $nam =shift;
open (LOG, ">", "$param_ref->{out_dir}/log.$nam") || die ('Could not create log file in ', $param_ref->{out_dir}, '. Please check writing permission in your current directory', "\n");
}

sub openLogErr {
my $nam =shift;
open (LOG_ERR, ">", "$param_ref->{out_dir}/log.err.$nam") || die ('Could not create log.err file in ', $param_ref->{out_dir}, '. Please check writing permission in your current directory', "\n");
}

sub openSummary {
my $nam =shift;
open (SUMMARY, ">", "$param_ref->{out_dir}/results/$param_ref->{summary}.$nam") || die ('Could not create summary file. Please check writing permission in your current directory', "\n");
}
__DATA__

