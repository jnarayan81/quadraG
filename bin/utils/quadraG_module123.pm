use strict;
use warnings;
use Bio::Root::Root;

#Turning off BioPerl warnings
$Bio::Root::Root::DEBUG = -1;

sub help {
  my $ver = $_[0];
  print "\n  quadraG $ver\n\n";

  print "Usage: quadraG.pl --conf_file_path [path to configuration file]\n\n";
  print "       To execute quadraG with the parameters defined in a configuration file\n\n";
  print "                OR\n\n";
  print "       quadraG.pl  --version\n\n       To print quadraG's version\n\n\n\n";
  print "Currently supported options when creating a new configuration file are:\n\n";
}

############################################################################################
# Read config files in the form element = value #comment --->
sub read_config_files {
  my $project_config_file = shift;
  my $quadraG_path = shift;
  my %parameters;
  open(my $fh_user_config, "<", "$$project_config_file") || die ("Couldn't open the project configuration file: $!\n");
  open(my $fh_quadraG_config, "<", "$$quadraG_path/../config_files/quadraG_config") || die ("The configuration file 'quadraG_config' couldn't be read, please check if the file exists and if its permissions are properly set.\n");

# BASIC PARAMETER FOR LOCATION AND FILE NAME --->
  $parameters{quadra_dir} = read_config_file_line('quadra_dir', '', $fh_quadraG_config);

# INPUT FILES --->
  $parameters{Out_dir_path} = read_config_file_line('Out_dir_path', $parameters{quadra_dir}, $fh_user_config);

# PROJECT NAME --->
  $parameters{project_dir_path} = read_config_file_line('project_dir_path', $parameters{quadra_dir}, $fh_user_config);

# PROJECT CONFIGURATION --->
  $parameters{reference_genome_file} = read_config_file_line('reference_genome_file', '', $fh_user_config);
  $parameters{bamfile} = read_config_file_line('bamfile', '', $fh_user_config);
  $parameters{codon_table} = read_config_file_line('codon_table', '', $fh_user_config);
  $parameters{additional_start_codons} = read_config_file_line('additional_start_codons', '', $fh_user_config);
  $parameters{additional_stop_codons} = read_config_file_line('additional_stop_codons', '', $fh_user_config);
  $parameters{verbose} = read_config_file_line('verbose', '', $fh_user_config);
  $parameters{force} = read_config_file_line('force', '', $fh_user_config);
  $parameters{remove_identical} = read_config_file_line('remove_identical', '', $fh_user_config);
  
#GENERAL SETTINGS
  $parameters{mode} = read_config_file_line('mode', '', $fh_user_config);


# QUALITY AND PERFORMANCE --->  
  $parameters{max_processors} = read_config_file_line('max_processors', '', $fh_user_config);
  $parameters{blastopt} = read_config_file_line('blastopt', '', $fh_user_config);
  $parameters{pvalue} = read_config_file_line('pvalue', '', $fh_user_config);
  $parameters{qvalue} = read_config_file_line('qvalue', '', $fh_user_config);
  $parameters{evalue} = read_config_file_line('evalue', '', $fh_user_config);
  $parameters{behavior_about_bad_clusters} = read_config_file_line('behavior_about_bad_clusters', '', $fh_user_config);   ### Need to remove it
  $parameters{validation_criteria} = read_config_file_line('validation_criteria', '', $fh_user_config);
  $parameters{fix_excess_nt} = read_config_file_line('fix_excess_nt', '', $fh_user_config);
  $parameters{absolute_min_sequence_size} = read_config_file_line('absolute_min_sequence_size', '', $fh_user_config);
  $parameters{absolute_max_sequence_size} = read_config_file_line('absolute_max_sequence_size', '', $fh_user_config);

# MODULES --->
  $parameters{multiple_alignment} = read_config_file_line('multiple_alignment', '', $fh_user_config);
  $parameters{phylogenetic_tree} = read_config_file_line('phylogenetic_tree', '', $fh_user_config);

  close($fh_user_config);

# PATH TO EXTERNAL PROGRAMS --->
 
  $parameters{bedtools_path} = read_config_file_line('bedtools', $parameters{quadra_dir}, $fh_quadraG_config);
  $parameters{bowtie2_path} = read_config_file_line('bowtie2', $parameters{quadra_dir}, $fh_quadraG_config);
  $parameters{bwakit_path} = read_config_file_line('samtools', $parameters{quadra_dir}, $fh_quadraG_config); 

# OUTPUT NAMES --->
  $parameters{result_table} = read_config_file_line('result_table', '', $fh_quadraG_config); 
  $parameters{result_uncertain} = read_config_file_line('result_uncertain', '', $fh_quadraG_config);
  $parameters{result_positive} = read_config_file_line('result_positive', '', $fh_quadraG_config);
  $parameters{result_recombinants} = read_config_file_line('result_recombinants', '', $fh_quadraG_config);
  $parameters{summary} = read_config_file_line('summary', '', $fh_quadraG_config);
  $parameters{intermediate} = read_config_file_line('intermediate', '', $fh_quadraG_config);
  $parameters{result_recombinants} = "recombinants"; #hard coded, must go to config_file

# EXTERNAL ERROR HANDLING --->
  $parameters{tries} = read_config_file_line('tries', '', $fh_quadraG_config);
  close($fh_quadraG_config);
  return \%parameters;
}

############################################################################################""
sub read_config_file_line { # file format element = value
  my ($parameter, $quadra_dir, $fh_config_file) = @_;

  seek($fh_config_file, 0, 0);              # added to allow any order of parameters in the config files, preventing unfriendly error messages if the user changes the order
  while (my $line = <$fh_config_file>){
    if ($line =~ /^\s*$parameter\s*=/) {    # the string to be searched in the file
      chomp ($line);
      $line =~ s/^\s*$parameter\s*=\s*//;   # removing what comes before the user input
      $line =~ s/#.*$//;                    # removing what comes after the user input (commentaries)
      $line =~ s/\s*$//;                    # removing what comes after the user input (space caracteres)
      $line =~ s/\$quadra_dir/$quadra_dir/;     # allows the use of "$quadra_dir" in the config file as a reference to the said parameter
      if ($line eq 'undef' || $line eq '') { return; }
      else { return $line; }
    }
  }
  return;
}

############################################################################################""
# function to identify errors in the configuration files and direct the user to the needed adjustments
sub check_parameters { #check for all parameters, 
  my $parameters = shift;

  my $config_path = getcwd();
  $config_path =~ s/\/\w+$/\/config_files/;

# BASIC PARAMETER FOR LOCATION AND FILE NAME --->
  if (!defined $parameters->{quadra_dir}) { die ("No path to quadraG was specified in quadraG_config at $config_path, please open this file and fill the parameter 'quadra_dir'.\n"); }
  if (!-d $parameters->{quadra_dir}) { die ("The path to quadraG isn't a valid directory, please check if the path in 'quadra_dir' is correct: $parameters->{quadra_dir}\n"); }
  if (!-w $parameters->{quadra_dir}) { die ("You don't have permission to write in the quadraG directory, please redefine your permissions for this directory.\n"); }

# INPUT FILES --->
  if (!defined $parameters->{Out_dir_path}) { die ("No path to the nucleotide files was specified in your project's configuration file, please fill the parameter 'Out_dir_path'.\n"); }
  if (!-d $parameters->{Out_dir_path}) { die ("The path to your project's nucleotide files isn't a valid directory, please check if the path in 'Out_dir_path' is correct: $parameters->{Out_dir_path}\n"); }
  if (!-r $parameters->{Out_dir_path}) { die ("You don't have permission to read in your project's nucleotide directory, please redefine your permissions.\n"); }


# MODULES --->
  
  my @phylogenetic_tree_programs = ("bwa", "bowtie", "segemehl");
  
  my $flag = 0;
  foreach my $program (@phylogenetic_tree_programs) {
    if ($program =~ /$parameters->{phylogenetic_tree}/) {$flag = 1;}
  }
  if ($flag == 0) {
    die("Currently supported programs for alignment are @phylogenetic_tree_programs. You chose $parameters->{phylogenetic_tree}.\n");
  }

  if (!defined $parameters->{phylogenetic_tree}) { die ("No program specified for alignment, please set the parameter 'phylogenetic_tree' in your project configuration file.\n"); }
  
  my @sequence_alignment_programs = ("bwa", "bowtie", "segemehl");

  $flag = 0;
  foreach my $program (@sequence_alignment_programs) {
    if ($program =~ /$parameters->{multiple_alignment}/) {$flag = 1;}
  }
  if ($flag == 0) {
    die("Currently supported programs for alignment are @sequence_alignment_programs. You chose $parameters->{multiple_alignment}.\n");
  }
  
  if (!defined $parameters->{multiple_alignment}) { die ("No program specified for multiple alignment, please set the parameter 'multiple_alignment' in your project configuration file.\n"); }

# PROJECT CONFIGURATION --->
  if (!defined $parameters->{codon_table}) { die ("Codon table not specified, please set the parameter 'codon_table' in your project configuration file.\n"); }
  if (!defined $parameters->{verbose}) { $parameters->{verbose} = 0; } # default value
  if (!defined $parameters->{force}) { $parameters->{force} = 0; } # default value


# EXTERNAL ERROR HANDLING --->
  if (!defined $parameters->{tries} || $parameters->{tries} !~ /^\d+$/) { $parameters->{tries} = 3; } # must be a number, and not a negative one; also must be an integer

  if (!defined $parameters->{project_dir_path}) {die "Project directory not configured. Please set project_dir_path element in configuration file\n";}

}


############################################################################################""
# This function checks whether the nucleotide sequence:
# 1- has any of the specified start codons
# 2- has either of the specified stop codons
# 3- has a sequence that is multiple of 3
# 4- has non-standard nucleotides
# If the method find any inconsistency, it is added in $validation variable according to the pattern above and reported in the LOG
sub validate_sequence {
  my ($parameters, $accession_number, $file_name, $nt_sequence) = @_;
  my $codon_table = Bio::Tools::CodonTable -> new (-id => $parameters->{codon_table});
  my $validation;  # output with the errors found
  if ($$nt_sequence =~ /[^TACG]/) {
    if (defined $parameters->{validation_criteria} && $parameters->{validation_criteria} =~ /(4|all)/ && $$nt_sequence =~ /T/ && $$nt_sequence =~ /U/) {
      $validation .= '4 ';
      print LOG ('Invalid sequence (', $$accession_number, '): presence of both T and U nucleotides', "\n");
    }
    # Presence of non-canonical nucleotides
    if (defined $parameters->{validation_criteria} && $parameters->{validation_criteria} =~ /(4|all)/ && $$nt_sequence =~ /[^TUACG]/) {
      $validation .= '4 ';
      my $non_canonical_nt = $$nt_sequence;
      $non_canonical_nt =~ s/[TUACG]//g;  # preparing to print non-canonical nucleotides found in LOG
      print LOG ("REMOVE_SEQUENCE_FLAG\tQUALITY\t$$accession_number\t$$file_name:non standard nucleotides\t$non_canonical_nt\n");
      print LOG ('Invalid sequence (', $$accession_number, '): presence of non-canonical nucleotides: ', $non_canonical_nt, "\n");
    }  
  }
  return $validation;
}

# Function to ensure control of the absolute size of the sequences
# Simple at the moment, kept as a function in case users request more types of filters
sub validate_absolute_size {
  my ($parameters, $accession_number, $tmp_file, $sequence) = @_;
#  print "\t=>\t$$sequence\n";
#  my $a = <STDIN>;
  my $flag = "";
  if (defined $parameters->{absolute_min_sequence_size} && length($$sequence) < $parameters->{absolute_min_sequence_size})  {
    my $tmp_length = length($$sequence);
    print LOG ("REMOVE_SEQUENCE_FLAG\tQUALITY\t$$accession_number\t$$tmp_file : smaller than absolute length cutoff\t$tmp_length\n");
#    $flag = "smaller_than_ab_len_cutoff:$tmp_length";
    return "smaller_than_ab_len_cutoff:$tmp_length";
  } elsif (defined $parameters->{absolute_max_sequence_size} && length($$sequence) > $parameters->{absolute_max_sequence_size}) {
      my $tmp_length = length($$sequence);
      print LOG ("REMOVE_SEQUENCE_FLAG\tQUALITY\t$$accession_number\t$$tmp_file : greater than absolute length cutoff\t$tmp_length\n");
      return "greater_than_ab_len_cutoff:$tmp_length";
  }  else {
    return 0;
  }
}

# now the script loads all nucleotide sequence files to a hash structure,
# checks their validity and translates them to protein sequence
sub parse_genome_files {
  my ($parameters) = shift;

  opendir (my $nt_files_dir, $parameters->{Out_dir_path}) || die ("Path to genome fasta files not found: $!\n");
  my (%sequence_data, %id2tmp_id, %tmp_id2id);

  print LOG ('Parsing assembled genome/contigs/scaffolds files', "\n") if $parameters->{verbose};

  my $id_numeric_component = 1;  # Generate unique IDs with each sequence later on
  while (my $file = readdir ($nt_files_dir)) {
    if (($file eq '.') || ($file eq '..') || ($file =~ /^\./) || ($file =~ /~$/)) { next; }  # Prevents from reading hidden or backup files

    my $file_content = new Bio::SeqIO(-format => 'fasta',-file => "$parameters->{Out_dir_path}/$file");
    print LOG ('Reading file ', $file, "\n") if $parameters->{verbose};
    print LOG ('Reading file ', $file, "\n");
    while (my $gene_info = $file_content->next_seq()) {
      my $sequence = $gene_info->seq();
      my $accession_number = $gene_info->display_id; 


      $sequence_data{$accession_number}{status} = "OK"; #everybody starts fine
      $sequence_data{$accession_number}{problem_desc} = "-"; #everybody starts fine

      # validate the assembled contig sequences before adding to %sequences hash
      if ($parameters->{behavior_about_bad_clusters}) {
         my $validation = validate_sequence ($parameters, \$accession_number, \$file, \$sequence);
         if ($validation) {    # This part prevents entry of invalid sequences in the hash          
           $sequence_data{$accession_number}{status} = "NOTOK";
           if (defined ($sequence_data{$accession_number}{problem_desc})&&($sequence_data{$accession_number}{problem_desc} ne "-")) {
             $sequence_data{$accession_number}{problem_desc} = join ("**", $sequence_data{$accession_number}{problem_desc}, "validate_seq:$validation");
           } else {
             $sequence_data{$accession_number}{problem_desc} = "validate_seq:$validation";
           }
          print LOG ('Warning: sequence ', $accession_number, ' does not have a valid sequence, check the log file for more information', "\n") if $parameters->{verbose};          
#          next;
        }
        $validation = "";
        $validation = validate_absolute_size ($parameters, \$accession_number, \$file, \$sequence);
        if ($validation) {
          $sequence_data{$accession_number}{status} = "NOTOK";
          if (defined ($sequence_data{$accession_number}{problem_desc})&&($sequence_data{$accession_number}{problem_desc} ne "-")) {
            $sequence_data{$accession_number}{problem_desc} = join ("**", $sequence_data{$accession_number}{problem_desc}, "ab_len_cutoff:$validation");
          } else {
            $sequence_data{$accession_number}{problem_desc} = "ab_len_cutoff:$validation";
          }
          print LOG ('Warning: sequence ', $accession_number, ' does not have a valid sequence, check the log file for more information', "\n") if $parameters->{verbose};
        }
      }
      
      if ($sequence_data{$accession_number}{status} eq "NOTOK") { # I did it forcefully .... but need to update it HERE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        $sequence_data{$accession_number}{nuc_seq} = $sequence;
      } else {
#        print "$accession_number\t$sequence_data{$accession_number}{problem_desc}\t$sequence_data{$accession_number}{status}\n";
#        my $a = <STDIN>;
        next;
      }

      my $sequence_id = 'A'.$id_numeric_component;

      $id2tmp_id{$accession_number} = $sequence_id;
      $tmp_id2id{$sequence_id} = $accession_number;
#      $id2tmp_id{$accession_number} = $accession_number;
#      $tmp_id2id{$accession_number} = $accession_number;
      $id_numeric_component++;
      print LOG "ID2TMPID\t$accession_number\t$sequence_id\n" if $parameters->{verbose};
      my $prot_obj = $gene_info->translate(-codontable_id => ($parameters->{codon_table}));
      $sequence_data{$accession_number}{prot_seq} = $prot_obj->seq();
    }
  }
  print LOG ('Done', "\n") if $parameters->{verbose};
  closedir ($nt_files_dir);
  return (\%sequence_data, \%id2tmp_id, \%tmp_id2id);
}

sub parse_cluster_id {
  my $line = shift;
  $line =~ s/:$//;
  $line =~ s/\(\s*\d*\s*gene[s]?\s*,\d*\s*tax(a|on)\s*\)$//;
  return $line;
}

sub parse_gene_id {
  my @aux = split (/\(/, $_[0]);
  my $specie = $aux[1];
  $specie =~ s/\)//g;
  return ($aux[0], $specie);  # aux[0] has the if o the gene
}

sub mean {
  my @tmp = @{$_[0]};
  my $soma = 0;
  foreach my $value(@tmp) {
    $soma = $soma + $value;
  }
  my $mean = ($soma/($#tmp+1));
  return $mean;
}

############################################################################################""
# Fills the result files (except the table file), used by parse_dn_ds_results()
# printing ortholog group, ID, aminoacid sequence of gene and evidences of non-synonimous selection in the positive result file
sub print_results {
  my ($fh_result_file, $fh_result_interleaved, $ortholog_group, $parameters, $gene_id, $selected_aminoacids, $model) = @_;
#  print "\t=>\t$$fh_result_file, $$fh_result_interleaved, $$ortholog_group, $parameters, $$gene_id, $selected_aminoacids, $model\n";
  my $ortholog_dir = "$parameters->{project_dir_path}/intermediate_files/" . $$ortholog_group . '/';
  open (my $fh_trim_file, "<", "$ortholog_dir$$ortholog_group.cluster.aa.fa.aln.aa.phy.trim");

  my $line = <$fh_trim_file>;
  my $n_sequences = $1 if ($line =~ /^\s(\d+)/);
  my $alignment_size = $1 if ($line =~ /(\d+)$/);
  $line = <$fh_trim_file>;
  chomp $line;
  my @aux;
  @aux = split (/\s+/, $line);
  my $aa_sequence = $aux[1];
  foreach (1..POSIX::floor($alignment_size / 60)) {
    foreach (1..($n_sequences)) { <$fh_trim_file>; }
    $line = <$fh_trim_file>;
    chomp $line;
    $aa_sequence .= $line;
  }
#  print ""
  $$selected_aminoacids .= '-' x ($alignment_size - length($$selected_aminoacids));

  # removing gaps by checking each charactere and removing if '-' in both the alignment and the sequence of selected aminoacids by BEB
  foreach (my $i = 0; $i < $alignment_size; $i++) {
    if (substr($aa_sequence, $i, 1) eq '-') {
      substr($aa_sequence, $i, 1, '');
      substr($$selected_aminoacids, $i, 1, '');
      $alignment_size--;                         # preventing substr from trying to read beyond the shortened string
      $i--;                                      # the next caractere now is where we just checked, we need to adjust the loop for that
    }
  }

  # printing in sequential format
  find_ortholog_group(\$ortholog_dir, $ortholog_group, $fh_result_file); 
  if (defined $$gene_id) { 
    print $fh_result_file (">$$gene_id ($model)\n");
    print $fh_result_file ("$aa_sequence", "\n");
    print $fh_result_file ("$$selected_aminoacids", "\n\n");
  }
  else { print LOG ("Warning: gene id not defined for model $model in group $$ortholog_group\n"); }


  # printing in interleaved format
  find_ortholog_group(\$ortholog_dir, $ortholog_group, $fh_result_interleaved); 
  if (defined $$gene_id) {
    print $fh_result_interleaved (">$$gene_id ($model)\n");
    for (my $i = 0; $i < length($aa_sequence); $i += 60) {
      print $fh_result_interleaved (substr("$aa_sequence", $i, 60), "\n");
      print $fh_result_interleaved (substr("$$selected_aminoacids", $i, 60), "\n");
    }
  }
  print $fh_result_interleaved ("\n");

  close ($fh_trim_file);
  return;
}


############################################################################################""
# Prints the time taken by the tasks of the group before the codeml runs in a file. Used for summary
sub print_task_time {
  my ($ortholog_dir, $task_time, $name) = @_;
  my $f_tree_time = time() - $$task_time;
  open(my $fh_time_write, ">", "$$ortholog_dir/$name");
  print $fh_time_write ('Time taken by task: ', $f_tree_time, "\n");
#  print "$$fh_time_write\n";
  close ($fh_time_write);
  return;
}

############################################################################################""
sub write_summary {
  my ($parameters, $clusters_ref, $start_time) = @_;
  my ($f_tree, $model1, $model2, $model7, $model8) = (0,0,0,0,0);


  # printing time spent by the program to run
  my $total_time = time() - $$start_time;
  my ($hours, $minutes, $seconds) = divide_time(\$total_time);

  print SUMMARY ("Time spent: $hours:$minutes:$seconds ($total_time seconds)\n");
  foreach my $ortholog_group (keys %{$clusters_ref}) {
    if (-s "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_id_rec") {
      open (my $fh_time_read, "<", "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_id_rec");
      my $line = <$fh_time_read>;
      $f_tree += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }

    if (-s "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_f_tree") {
      open (my $fh_time_read, "<", "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_f_tree");
      my $line = <$fh_time_read>;
      $f_tree += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }

    if (-s "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_1") {
      open (my $fh_time_read, "<", "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_1");
      my $line = <$fh_time_read>;
      $model1 += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }

    if (-s "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_2") {
      open (my $fh_time_read, "<", "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_2");
      my $line = <$fh_time_read>;
      $model2 += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }

    if (-s "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_7") {
      open (my $fh_time_read, "<", "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_7");
      my $line = <$fh_time_read>;
      $model7 += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }

    if (-s "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_8") {
      open (my $fh_time_read, "<", "$parameters->{project_dir_path}/intermediate_files/$ortholog_group/time_model_8");
      my $line = <$fh_time_read>;
      $model8 += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }
  }

  my $sequential_time = $f_tree+$model1+$model2+$model7+$model8;

  ($hours, $minutes, $seconds) = divide_time(\$sequential_time);
  print SUMMARY ("Total time (sequential run): $hours:$minutes:$seconds ($sequential_time seconds)\n");

  ($hours, $minutes, $seconds) = divide_time(\$f_tree);
  print SUMMARY (" - total time on building phylogenetic trees: $hours:$minutes:$seconds ($f_tree seconds)\n");

  ($hours, $minutes, $seconds) = divide_time(\$model1);
  print SUMMARY (" - total time on model 1: $hours:$minutes:$seconds ($model1 seconds)\n");

  ($hours, $minutes, $seconds) = divide_time(\$model2);
  print SUMMARY (" - total time on model 2: $hours:$minutes:$seconds ($model2 seconds)\n");

  ($hours, $minutes, $seconds) = divide_time(\$model7);
  print SUMMARY (" - total time on model 7: $hours:$minutes:$seconds ($model7 seconds)\n");

  ($hours, $minutes, $seconds) = divide_time(\$model8);
  print SUMMARY (" - total time on model 8: $hours:$minutes:$seconds ($model8 seconds)\n");

  return;
}

############################################################################################""
#Time check
sub divide_time {
  my $total_time = shift;

  my $hours = POSIX::floor( $$total_time / 3600 );
  my $minutes = POSIX::floor(($$total_time % 3600) / 60);
  if ($minutes < 10) { $minutes = '0' . $minutes; }
  my $seconds = $$total_time % 60;
  if ($seconds < 10) { $seconds = '0' . $seconds; }

  return ($hours, $minutes, $seconds);
}

############################################################################################""!!
#Function to move the files with wild
sub moveFiles {
    my ( $source_ref, $arc_dir ) = @_;
    my @old_files = @$source_ref;
    foreach my $old_file (@old_files)
         {
    #my ($short_file_name) = $old_file =~ m~/(.*?\.dat)$~;
    #my $new_file = $arc_dir . $short_file_name;
    move($old_file, $arc_dir) or die "Could not move $old_file to $arc_dir: $!\n";
   }
}

=pod
############################################################################################""!!
sub process_string {
  my($contig, $sequence) = @_;
  my($len, $ACGTbases, $ATbases, $GCbases, $nonACGTbases);

  # Remove name prefix?
  $contig =~ s/^.*([Cc]ontig)/$1/ if $SHORTEN_CONTIG_NAMES;
  $len = length($sequence);
  push @CONTIG_LENGTHS, $len;
  $Total_Bases += $len;
  $Max_Bases = $len if $Max_Bases < $len;
  $Min_Bases = $len if $Min_Bases > $len || $Min_Bases < 0;

  $ATbases = ($sequence =~ tr/aAtT/aAtT/);
  $GCbases = ($sequence =~ tr/cCgG/cCgG/);
  $ACGTbases = $ATbases + $GCbases;
  $nonACGTbases = $len - $ACGTbases;
  if ($ACGTbases) {
    $GC_per_cent = sprintf "%.1f", 100 * $GCbases / $ACGTbases;
    }
  else {
    $GC_per_cent = '-';
    }
  $Total_GC += $GCbases;
  $Total_ACGT += $ACGTbases;
  if ($nonACGTbases) {
    my $more_Max_Nons = ($Max_Nons < $MAX_PATTERN_MIN_RPT) ?
      $Max_Nons + 1 : $MAX_PATTERN_MIN_RPT;
    my @Nons = ($sequence =~ /[^acgtACGT]{$more_Max_Nons,}/g);
    foreach (@Nons) {
      my $l = length $_;
      $Max_Nons = $l if ($Max_Nons < $l);
      }
    $Total_Non_ACGT_Ends += length $1 if ($sequence =~ /^([^acgtACGT]+)/);
    if (substr($sequence, -1) =~ /[^acgtACGT]+$/) {
      my $rs = reverse $sequence;
      $Total_Non_ACGT_Ends += length $1 if ($rs =~ /^([^acgtACGT]+)[acgtACGT]/);
      }
    my $more_Max_Ns = ($Max_Ns < $MAX_PATTERN_MIN_RPT) ?
      $Max_Ns + 1 : $MAX_PATTERN_MIN_RPT;
    my @Ns = ($sequence =~ /[nN]{$more_Max_Ns,}/g);
    foreach (@Ns) {
      my $l = length $_;
      $Max_Ns = $l if ($Max_Ns < $l);
      }
    $Total_N_Ends += length $1 if ($sequence =~ /^([nN]+)/);
    if (uc substr($sequence, -1) eq 'N' && uc substr($sequence, 0, 1) ne 'N') {
      my $rs = uc reverse $sequence;
      $Total_N_Ends += length $1 if ($rs =~ /^(N+)/);
      }
    }

my $StringRes= "$contig\t$len\t$GC_per_cent\t$nonACGTbases";
return ($StringRes);

} # end process_string

=cut



########################################################################################"
#Store fasta file to hash
sub fastafile2hash {
    my $fastafile = shift @_;
    my %sequences;
    my $fh = &read_fh($fastafile);
    my $seqid;
    while (my $line = <$fh>) {
        if ($line =~ /^>(\S+)(.*)/) {
            $seqid = $1;
            $sequences{$seqid}{desc} = $2;
        }
        else {
            chomp $line;
            $sequences{$seqid}{seq}     .= $line;
            $sequences{$seqid}{len}     += length $line;
            $sequences{$seqid}{gc}      += ($line =~ tr/gcGC/gcGC/);
            $line =~ s/[^atgc]/N/ig;
            $sequences{$seqid}{nonatgc} += ($line =~ tr/N/N/);
        }
    }
    close $fh;
    return \%sequences;
}


########################################################################################"
#Open and Read a file
sub read_fh {
    my $filename = shift @_;
    my $filehandle;
    if ($filename =~ /gz$/) {
        open $filehandle, "gunzip -dc $filename |" or die $!;
    }
    else {
        open $filehandle, "<$filename" or die $!;
    }
    return $filehandle;
}


sub extractSeq {
my ($name, $st, $end, $db)=@_;
my $seq = $db->seq($name, $st => $end);
return $seq;
}


########################################################################################"
#Process the GCAT sequence
sub processGCAT {
    my $sequence = shift;
    my @letters = split(//, $sequence);
    my $gccount = 0; my $totalcount = 0; my $gccontent = 0;
    my $acount = 0; my $tcount = 0; my $gcount = 0; my $ccount = 0; my $atcontent =0; 
    foreach my $i (@letters) {
	if (lc($i) =~ /[a-z]/) { $totalcount++;}
	if (lc($i) eq "g" || lc($i) eq "c") { $gccount++; }
	if (lc($i) eq "a") { $acount++;}
	if (lc($i) eq "t") { $tcount++;}
	if (lc($i) eq "g") { $gcount++;}
	if (lc($i) eq "c") { $ccount++;}
    }
    if ($totalcount > 0) {
	$gccontent = (100 * $gccount) / $totalcount;
    }
    else {
	$gccontent = 0;
    }
    my $others=($totalcount-($acount+$tcount+$gcount+$ccount));
    return ($gccontent,$others,$totalcount,$gcount,$ccount,$acount,$tcount);

}


########################################################################################"
#Print the hash values 
sub print_hash_final {
    my ($href,$fhandler)  = @_;
    while( my( $key, $val ) = each %{$href} ) {
        print $fhandler "$key\n";
	#print $fhandler "$key\t=>$val\n";
    }
}


########################################################################################"
# Returns 1 if present else 0
sub isInList {
   my $needle = shift;
   my @haystack = @_;
   foreach my $hay (@haystack) {
	if ( $needle eq $hay ) {
	return 1;
	}
   }
   return 0;
}


########################################################################################"
#Mean of GCAT
use List::Util qw(sum);
sub meanGCAT { return @_ ? sum(@_) / @_ : 0 }
#sub meanGCAT { return sum(@_)/@_; }


########################################################################################"
#  Sigmoid function
sub sigmoidFun {
my $val = shift;
   my ($h) = @_;
   return 1.0 / ( 1.0 + exp(-$val) );
}


########################################################################################"

sub sumArray {
    return( defined $_[0] ? $_[0] + sumArray(@_[1..$#_]) : 0 );
}

########################################################################################"

sub spacer { return (" " x 20000);}


########################################################################################"


sub geneBased {
my ($accession_number, $sequence)=@_;

# next if length($sequence) <= 10000; # Limit the minimum length

	print "$accession_number\n";
	

	my $tmpf = new File::Temp( UNLINK => 1 );
	print $tmpf ">$accession_number\n$sequence\n";
	
	my $SStat = &processGCAT($sequence);
	my $seqLen = length($sequence);
	my $gcSStat = (split /\t/, "$SStat")[0];


}

########################################################################################"

=pod
sub round {

    my ($nr,$decimals) = @_;
    return (-1)*(int(abs($nr)*(10**$decimals) +.5 ) / (10**$decimals)) if $nr<0;
    return int( $nr*(10**$decimals) +.5 ) / (10**$decimals);

}
=cut


########################################################################################

sub findQuadra {

my ($name, $sequence, $increase, $reference, $rev) = @_;

my $defLine = $name;
my $SeqLength=length($sequence); # Print the sequence length and a newline

#my $ntca_pattern = "GTA.{8}TAC.{20,24}TA.{3}T";    # Pattern to search for
my $ntca_pattern = "G{3,5}.{1,7}G{3,5}.{1,7}G{3,5}.{1,7}G{3,5}";

# G{m}.{1,7}G{m}.{1,7}G{m}.{1,7}G{m}
# m=3:5
print "$sequence <-->\n";
for (my $aa=0; $aa<=$rev; $aa++) {  ## This loop to check the G4 twice, both for negative and positive.
if ($aa == 1) {$sequence=reverse_complement($sequence);}

# Find and print out all the exact matches
my $exact_pattern = fuzzy_pattern($ntca_pattern, 0);
print "$exact_pattern, $sequence ---->\n";
my @exact_matches = match_positions($exact_pattern, $sequence);
if (@exact_matches) {
   #print "Exact matches:\n";
   print_matches(\@exact_matches, 0, $sequence, $defLine, $SeqLength, $aa, $reference);
}

# Now do the same, but allow one mismatch
#
my $one_mismatch = fuzzy_pattern($ntca_pattern, 1);
my @approximate_matches = match_positions($one_mismatch, $sequence);
if (@approximate_matches) {
   #print "Matches with one possible mismatch\n";
   print_matches(\@approximate_matches, 1, $sequence, $defLine, $SeqLength, $aa, $reference);
}
}

########################################################################################"

sub print_matches {
   my ($matches_ref, $diff, $sequence, $defLine, $SeqLength, $aa, $reference) = @_;
   my @matches=@$matches_ref;
   foreach my $match (@matches) {
     my @matchCor = split(/\.\./, $match);

     $matchCor[0] =~ s/[^0-9]//g; $matchCor[1] =~ s/[^0-9]//g;
     my $len=$matchCor[1]-$matchCor[0];
		
     my $matching_string=substr ($sequence, $matchCor[0],$len );

	if ($aa == 0) {
     print INTERMEDIATE "$matching_string\t$defLine\t$reference\t$matchCor[0]\t$matchCor[1]\t$diff\t$len\t+\n";
	}
	elsif ($aa ==1) {
	print INTERMEDIATE "$matching_string\t$defLine\t$reference\t$matchCor[0]\t$matchCor[1]\t$diff\t$len\t-\n";
	}
   }
}


########################################################################################"
sub get_genome_sequence {
   my ($file_path) = @_;
   open GENOME, "<$file_path" or die "Can't open $file_path: $!\n";
   $_ = <GENOME>; # discard first line
   my $sequence = ""; 
   while (<GENOME>) {
      chomp($_);                  # Remove line break
      s/\r//;                     # And carriage return
      $_ = uc $_;                 # Make the line upper-case;
      $sequence = $sequence . $_; # Append the line to the sequence
   }
   return $sequence;
}



########################################################################################"
##### Black magic past this point
#
use re qw(eval);
use vars qw($matchStart);

# match_positions($pattern, $sequence) returns the start and end points of all
# places in $sequence matching $pattern.
sub match_positions {
   my $pattern;
   local $_;
   ($pattern, $_) = @_;
   my @results;
   local $matchStart;
   my $instrumentedPattern = qr/(?{ $matchStart = pos() })$pattern/;

   while (/$instrumentedPattern/g) {
      my $nextStart = pos();
      push @results, "[$matchStart..$nextStart)";
      pos() = $matchStart+1;
   }
   return @results;
}


########################################################################################"
# fuzzy_pattern($pattern, $mismatches) returns a pattern that matches whatever
# $pattern matches, except that bases may differ in at most $mismatches positions.
sub fuzzy_pattern {
   my ($original_pattern, $mismatches_allowed) = @_;
   $mismatches_allowed >= 0
      or die "Number of mismatches must be greater than or equal to zero\n";
   my $new_pattern = make_approximate($original_pattern, $mismatches_allowed);
   return qr/$new_pattern/;
}


########################################################################################"
# make_approximate("ACT", 1) returns "(?:A(?:C.|.T)|.CT)"
# make_approximate("ACT", 2) returns "(?:A..|.(?:C.|.T))"
# make_approximate("ACGT", 2) returns
#        "(?:A(?:C..|.(?:G.|.T))|.(?:C(?:G.|.T)|.GT))"
#

sub make_approximate {
   my ($pattern, $mismatches_allowed) = @_;
   if ($mismatches_allowed == 0) { return $pattern }
   elsif (length($pattern) <= $mismatches_allowed)
      { $pattern =~ tr/ACTG/./; return $pattern }
   else {
      my ($first, $rest) = $pattern =~ /^(.)(.*)/;
      my $after_match = make_approximate($rest, $mismatches_allowed);
      if ($first =~ /[ACGT]/) {
         my $after_miss = make_approximate($rest, $mismatches_allowed-1);
         return "(?:$first$after_match|.$after_miss)";
      }
      else { return "$first$after_match" }
   }
}
}


########################################################################################"
# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^[\t\s]+//;
	$string =~ s/[\t\s]+$//;
	$string =~ s/[\r\n]+$//; ## remove odd or bad newline ...
	return $string;
}


########################################################################################"
#Get reverse complement
sub reverse_complement {
        my $dna = shift;

	# reverse the DNA sequence
		my $revcomp = reverse($dna);

	# complement the reversed DNA sequence
        $revcomp =~ tr/ACGTacgt/TGCAtgca/;
        return $revcomp;
}
#print the lines

########################################################################################"
use Carp qw/croak/;
sub file_write {
        my $file = shift;
        open IO, ">$file" or croak "Cannot open $file for output: $!\n";
        print IO @_;
        close IO;
}

########################################################################################"
sub pLine {
my $msg = shift;
print "$msg" x 80 . "\n";
#print ($msg x 20);
}


########################################################################################"


1;

__END__

