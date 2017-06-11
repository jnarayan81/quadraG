use strict;
use warnings;
use Bio::Root::Root;

# Turning off BioPerl warnings
$Bio::Root::Root::DEBUG = -1;
use re qw(eval);
use vars qw($matchStart);

sub detectHelp {
  my $ver = $_[0];
  print "\n  quadraG --detect $ver \n\n";
  print "    Usage: quadraG.pl --detect/-d --conf/-c <configuration file>\n\n";
  print "    To detect strings/quadra sequences in the genome\n\n";
  print "    The path to a valid quadraG configuration file. This file contains all parameters needed to execute  quadraG.\n\n";

exit(1);
}

sub mergeHelp {
  my $ver = $_[0];
  print "\n  quadraG --merge $ver \n\n";
  print "    Usage: quadraG.pl --merge/-m --conf/-c <configuration file>\n\n";
  print "    To merge the direct overllaping strings/quadra sequences\n\n";
  print "    The path to a valid quadraG configuration file. This file contains all parameters needed to execute  quadraG.\n\n";

exit(1);
}

sub annotHelp {
  my $ver = $_[0];
  print "\n  quadraG --annot $ver \n\n";
  print "    Usage: quadraG.pl --annot/-p --conf/-c <configuration file>\n\n";
  print "    To annotate the quadraG results \n\n";
  print "    The path to a valid quadraG configuration file. This file contains all parameters needed to execute  quadraG.\n\n";

exit(1);
}

sub plotHelp {
  my $ver = $_[0];
  print "\n  quadraG --plot $ver \n\n";
  print "    Usage: quadraG.pl --plot/-p --conf/-c <configuration file>\n\n";
  print "    To plot the quadraG results \n\n";
  print "    The path to a valid quadraG configuration file. This file contains all parameters needed to execute  quadraG.\n\n";

exit(1);
}

############################################################################################
# Read config files in the form element = value #comment --->
sub read_config_files {
  my $project_config_file = shift;
  my $quadraG_path = shift;
  my %param;
  #There is two config files, one for general settings and other for third party software
  open(my $user_config, "<", "$$project_config_file") || die ("Couldn't open the project configuration file: $!\n");
  open(my $quadraG_config, "<", "$$quadraG_path/../config_files/quadraG_config") || die ("The configuration file 'quadraG_config' couldn't be read, please check if the file exists and if its permissions are properly set.\n");

# BASIC PARAMETER FOR LOCATION AND FILE NAME --->
  $param{quadra_dir} = read_config('quadra_dir', '', $quadraG_config);

# INPUT FILES --->
  $param{data_dir} = read_config('data_dir', $param{quadra_dir}, $user_config);

# PROJECT NAME --->
  $param{out_dir} = read_config('out_dir', $param{quadra_dir}, $user_config);

# PROJECT CONFIGURATION --->
  $param{reference_genome_gff} = read_config('reference_genome_gff', '', $user_config);
  $param{verbose} = read_config('verbose', '', $user_config);
  $param{force} = read_config('force', '', $user_config);
  $param{mismatch} = read_config('mismatch', '', $user_config);
  $param{reverse} = read_config('reverse', '', $user_config);
  $param{overlaps} = read_config('overlaps', '', $user_config);
  $param{extend} = read_config('extend', '', $user_config);
  $param{palsize} = read_config('palsize', '', $user_config);
  $param{check} = read_config('check', '', $user_config);

# PROJECT PENALTY --->
  $param{mutation} = read_config('mutation', '', $user_config);
  $param{score} = read_config('score', '', $user_config);
  $param{consider} = read_config('consider', '', $user_config);
  
  
#GENERAL SETTINGS
  $param{mode} = read_config('mode', '', $user_config);

# QUALITY AND PERFORMANCE --->  
  $param{max_processors} = read_config('max_processors', '', $user_config);

  close($user_config);

# PATH TO EXTERNAL PROGRAMS --->
 
  #$param{bedtools_path} = read_config('bedtools', $param{quadra_dir}, $quadraG_config);

# OUTPUT NAMES --->
  $param{result_table} = read_config('result_table', '', $quadraG_config); 
  $param{result_uncertain} = read_config('result_uncertain', '', $quadraG_config);
  $param{result_positive} = read_config('result_positive', '', $quadraG_config);
  $param{summary} = read_config('summary', '', $quadraG_config);
  $param{intermediate} = read_config('intermediate', '', $quadraG_config);
  $param{result_recombinants} = "recombinants"; #hard coded, must go to config_file

# EXTERNAL ERROR HANDLING --->
  $param{tries} = read_config('tries', '', $quadraG_config);
  close($quadraG_config);
  return \%param;
}

############################################################################################""
sub read_config { # file format element = value
  my ($parameter, $quadra_dir, $config_file) = @_;

  seek($config_file, 0, 0);              # added to allow any order of parameters in the config files, preventing unfriendly error messages if the user changes the order
  while (my $line = <$config_file>){
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
sub parameters_validator { #check for all parameters, 
  my $param = shift;

  my $config_path = getcwd();
  $config_path =~ s/\/\w+$/\/config_files/;

# BASIC PARAMETER FOR LOCATION AND FILE NAME --->
  if (!defined $param->{quadra_dir}) { die ("No path to quadraG was specified in quadraG_config at $config_path, please open this file and fill the parameter 'quadra_dir'.\n"); }
  if (!-d $param->{quadra_dir}) { die ("The path to quadraG isn't a valid directory, please check if the path in 'quadra_dir' is correct: $param->{quadra_dir}\n"); }
  if (!-w $param->{quadra_dir}) { die ("You don't have permission to write in the quadraG directory, please redefine your permissions for this directory.\n"); }

# INPUT FILES --->
  if (!defined $param->{data_dir}) { die ("No path to the nucleotide files was specified in your project's configuration file, please fill the parameter 'data_dir'.\n"); }
  if (!-d $param->{data_dir}) { die ("The path to your project's nucleotide files isn't a valid directory, please check if the path in 'data_dir' is correct: $param->{data_dir}\n"); }
  if (!-r $param->{data_dir}) { die ("You don't have permission to read in your project's nucleotide directory, please redefine your permissions.\n"); }


# PROJECT CONFIGURATION --->

  if (!defined $param->{verbose}) { $param->{verbose} = 0; } # default value
  if (!defined $param->{force}) { $param->{force} = 0; } # default value
  if (!defined $param->{mismatch}) { $param->{mismatch} = 0; } # default value
  if (!defined $param->{reverse}) { $param->{reverse} = 0; } # default value
  if (!defined $param->{overlaps}) { $param->{overlaps} = 0; } # default value 0 to keep all
  if (!defined $param->{extend}) { $param->{extend} = 0; } # default value 0 

# EXTERNAL ERROR HANDLING --->
  if (!defined $param->{tries} || $param->{tries} !~ /^\d+$/) { $param->{tries} = 3; } # must be a number, and not a negative one; also must be an integer

  if (!defined $param->{out_dir}) {die "Project directory not configured. Please set out_dir element in configuration file\n";}

}

# now the script loads all nucleotide sequence files to a hash structure,
# checks their validity and translates them to protein sequence
sub parse_genome {
  my ($param) = shift;
  opendir (my $nt_files_dir, $param->{data_dir}) || die ("Path to asseembly fasta files not found: $!\n");
  my (%sequence_data);
  print LOG ('Parsing assembled genome/contigs/scaffolds files', "\n") if $param->{verbose};
  my $id_numeric_component = 1;  # Generate unique IDs with each sequence later on
  while (my $file = readdir ($nt_files_dir)) {
    if (($file eq '.') || ($file eq '..') || ($file =~ /^\./) || ($file =~ /~$/)) { next; }  # Prevents from reading hidden or backup files
    my $file_content = new Bio::SeqIO(-format => 'fasta',-file => "$param->{data_dir}/$file");
    print LOG ('Reading file ', $file, "\n") if $param->{verbose};
    while (my $gene_info = $file_content->next_seq()) {
      my $sequence = $gene_info->seq();
      my $accession_number = $gene_info->display_id; 
      $sequence_data{$accession_number}{status} = "OK"; #everybody starts fine
      $sequence_data{$accession_number}{problem_desc} = "-"; #everybody starts fine
      if ($sequence_data{$accession_number}{status} eq "OK") { # Add check points here <<<<<<
        $sequence_data{$accession_number}{nuc_seq} = $sequence;
      }
    }
  }
  print LOG ('Done', "\n") if $param->{verbose};
  closedir ($nt_files_dir);
  return (\%sequence_data);
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
  my ($param, $clusters_ref, $start_time) = @_;
  my ($f_tree, $model1, $model2, $model7, $model8) = (0,0,0,0,0);


  # printing time spent by the program to run
  my $total_time = time() - $$start_time;
  my ($hours, $minutes, $seconds) = divide_time(\$total_time);

  print SUMMARY ("Time spent: $hours:$minutes:$seconds ($total_time seconds)\n");
  foreach my $ortholog_group (keys %{$clusters_ref}) {
    if (-s "$param->{out_dir}/intermediate_files/$ortholog_group/time_id_rec") {
      open (my $fh_time_read, "<", "$param->{out_dir}/intermediate_files/$ortholog_group/time_id_rec");
      my $line = <$fh_time_read>;
      $f_tree += $1 if ($line =~ /:\s(\d+)/);
      close($fh_time_read);
    }
  }

  my $sequential_time = $f_tree+$model1+$model2+$model7+$model8;

  ($hours, $minutes, $seconds) = divide_time(\$sequential_time);
  print SUMMARY ("Total time (sequential run): $hours:$minutes:$seconds ($sequential_time seconds)\n");

  ($hours, $minutes, $seconds) = divide_time(\$f_tree);
  print SUMMARY (" - total time on building phylogenetic trees: $hours:$minutes:$seconds ($f_tree seconds)\n");

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

Comment here

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


sub extractSeq_new {
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

	print LOG "$accession_number\n";

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

my ($name, $sequence, $increase, $reference, $mismatch, $param) = @_;
my $defLine = $name; my $rev;
my $SeqLength=length($sequence); # Print the sequence length and a newline
#my $pattern = "G{3,5}.{1,7}G{3,5}.{1,7}G{3,5}.{1,7}G{3,5}";
my $pattern = "G{2,5}.{1,7}G{2,5}.{1,7}G{2,5}.{1,7}G{2,5}";

if ($param->{reverse}) {$rev=1;} else {$rev=0}
for (my $aa=0; $aa<=$rev; $aa++) {  ## This loop to check the G4 twice, both for negative and positive.
if ($aa == 1) { #Instead of reverse completement i reverse the pattern
	#$pattern = "T{2,5}.{1,7}T{2,5}.{1,7}T{2,5}.{1,7}T{2,5}"; 
        $sequence=rcomplement($sequence);
	}

# Find and print out all the exact matches
my $epattern = fpattern($pattern, 0);
my @ematches = mpositions($epattern, $sequence);
if (@ematches) {
   #print "Exact matches:\n";
   pmatches(\@ematches, 0, $sequence, $defLine, $SeqLength, $aa, $reference, $param);
}

# Now do the same, but allow one mismatch
#
if ($mismatch) {
my $omismatch = fpattern($pattern, $mismatch);
my @amatches = mpositions($omismatch, $sequence);
if (@amatches) {
   #print "Matches with one possible mismatch\n";
   pmatches(\@amatches, $mismatch, $sequence, $defLine, $SeqLength, $aa, $reference, $param);
   }
 }
}

########################################################################################"

sub pmatches {
   my ($mref, $diff, $sequence, $defLine, $SeqLength, $aa, $reference, $param) = @_;
   my @matches=@$mref;
   foreach my $match (@matches) {
     my @matchCor = split(/\.\./, $match);

     $matchCor[0] =~ s/[^0-9]//g; $matchCor[1] =~ s/[^0-9]//g;
     my $len=$matchCor[1]-$matchCor[0];
		
     my $mstring=substr ($sequence, $matchCor[0],$len );

	if ($aa == 0) {
	my $seqFreqG = checkFreq($mstring,"G",$diff, $param);
	my $palRes = checkPal($mstring, $param); my $palDecision;
	if ($palRes) { $palDecision=1;} else {$palDecision=0;} 
	
     #R(everse) and P(lush) 
     print INTERMEDIATE "$mstring\t$defLine\t$reference\t$matchCor[0]\t$matchCor[1]\t$diff\t$len\tP\t$seqFreqG\t$palDecision\n";
	}
	elsif ($aa ==1) {
	my $seqFreqT = checkFreq($mstring,"G", $diff, $param);
	my $palRes = checkPal($mstring, $param); my $palDecision;
	if ($palRes) { $palDecision=1;} else {$palDecision=0;}

	print INTERMEDIATE "$mstring\t$defLine\t$reference\t$matchCor[0]\t$matchCor[1]\t$diff\t$len\tR\t$seqFreqT\t$palDecision\n";
	}
   }
}


sub checkFreq {
my ($str, $letter, $mutation, $param) = @_;
my @all; my $finalScore=0; my $longString=0;
while ($str =~ /($letter+)/g) {
push @all, length($1);
	@all = grep { $_ != 1 } @all; #Keep all except 1 (i.e delete 1)
	
	if (@all) {	
	my $max = (sort { $b <=> $a } @all)[0];
	if ($max > $param->{consider}) { $longString=$max/$param->{consider}}
	}

	my $scoreGen = scalar @all/4; #4 is quadra
	if ($scoreGen == 1) { $mutation = 0;}
	my $scorePen = $scoreGen + ($mutation * $param->{mutation}) + $longString;
	my $scoreFin = $scorePen;
	$finalScore=sigmoidFun ($scoreFin);
}
$str=join ',', @all;
return "$str\t$finalScore";
}

########################################################################################"
sub get_genome_sequence {
   my ($fpath) = @_;
   open GENOME, "<$fpath" or die "Can't open $fpath: $!\n";
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
sub mpositions {
   my $pattern;
   local $_;
   ($pattern, $_) = @_;
   my @results;
   local $matchStart;
   my $iPattern = qr/(?{ $matchStart = pos() })$pattern/;

   while (/$iPattern/g) {
      my $nextStart = pos();
      push @results, "[$matchStart..$nextStart)";
      pos() = $matchStart+1;
   }
   return @results;
}


########################################################################################"
sub fpattern {
   my ($opattern, $misallowed) = @_;
   $misallowed >= 0
      or die "Number of mismatches must be greater than or equal to zero\n";
   my $npattern = mapproximate($opattern, $misallowed);
   return qr/$npattern/;
}


########################################################################################"
sub mapproximate {
   my ($pattern, $misallowed) = @_;
   if ($misallowed == 0) { return $pattern }
   elsif (length($pattern) <= $misallowed)
      { $pattern =~ tr/ACTG/./; return $pattern }
   else {
      my ($first, $rest) = $pattern =~ /^(.)(.*)/;
      my $amatch = mapproximate($rest, $misallowed);
      if ($first =~ /[ACGT]/) {
         my $amiss = mapproximate($rest, $misallowed-1);
         return "(?:$first$amatch|.$amiss)";
      }
      else { return "$first$amatch" }
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
sub rcomplement {
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
#Open and write a file
sub write_fh {
    my $filename = shift @_;
    my $filehandle;
    open $filehandle, ">$filename" or die $!;
    return $filehandle;
}


########################################################################################"
sub pLine {
my $msg = shift;
print LOG "$msg" x 80 . "\n";
#print ($msg x 20);
}


########################################################################################"

sub sorter {
	$a->[1] cmp $b->[1] ||
     $a->[3] <=> $b->[3]
  || $b->[4] <=> $a->[4]
}

########################################################################################"

sub detectStat {
my ($file, $outfile, $score)=@_;
my @terms;

my $fh = &read_fh($file);
my $out =&write_fh($outfile);
while (<$fh>) { chomp; push @terms, [split /\t/]; }
my $Ids_ref=extractIds(\@terms);
foreach my $id (@$Ids_ref) {
my ($all, %pal, %str);
my $palN=0; my $palY=0; my $strP=0; my $strR=0;

	for my $item (@terms) {
    		if ($item->[1] eq $id) {
			if ($item->[9] >= $score) { # 0 score means all the count
			$pal{$item->[10]}++;
			$str{$item->[7]}++;
			}
		$all++;
    		}  
	}
if ($pal{0}) { $palN=$pal{0};}
if ($pal{1}) { $palY=$pal{1};}
if ($str{P}) { $strP=$str{P};}
if ($str{R}) { $strR=$str{R};}
print $out "$id\t$all\t$palN\t$palY\t$strP\t$strR\n";
}

}

########################################################################################"

sub analyticStat {
my ($file, $outfile, $score)=@_;
my @terms;

my $fh = &read_fh($file);
my $out =&write_fh($outfile);
while (<$fh>) { chomp; push @terms, [split /\t/]; }
my $Ids_ref=extractIds(\@terms);
my $feature_ref=extractFeature(\@terms);

foreach my $id (@$Ids_ref) {
my %feature;
	for my $item (@terms) {
	if ($item->[11] eq $id) { if ($item->[9] >= $score) { $feature{$item->[13]}++; } } #$item->[9] >= 0 for score filter
	}
print $out "$id\t";
foreach my $f(@$feature_ref) { if ($feature{$f}) { print $out "$feature{$f}\t"; } else { print $out "0\t";} }
print $out "\n";
}
}

########################################################################################"
sub extractFeature {
my ($terms_ref)=@_;
my @allIds;
for my $item (@$terms_ref) {
     if ($item->[13]) { push @allIds , $item->[13];} 
}
my @allIds_uniq=uniq(@allIds); 
my @allIds_uniq_sorted = sort { lc($a) cmp lc($b) } @allIds_uniq; 
return \@allIds_uniq_sorted;
}

########################################################################################"
sub extractIds {
my ($terms_ref)=@_;
my @allIds;
for my $item (@$terms_ref) {
     if ($item->[1]) { push @allIds , $item->[1];} 
}
my @allIds_uniq=uniq(@allIds);
return \@allIds_uniq;
}

########################################################################################"
sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

########################################################################################"
sub blockMerger {
my ($file, $outfile)=@_;
my @terms;

my $fh = &read_fh($file);
my $out =&write_fh($outfile);
while (<$fh>) { chomp; push @terms, [split /\t/]; }

my $biggest = 0;
my $id = '';
for my $term (sort sorter @terms) {
	$biggest = 0 if $id ne $term->[1];
    if ($term->[4] > $biggest) {
        print $out join "\t", @$term; print $out "\n";
        $biggest = $term->[4];
    }
    $id = $term->[1];    
}

}

########################################################################################"

sub checkInGFF {
my ($quadraFile, $gffFile, $outFile, $exSize)=@_;
my $fh = &read_fh($quadraFile);
my $out =&write_fh($outFile);
while (my $row = <$fh>) {
  chomp $row; #print "$row\n";
  my @data = split /\t/, $row;
  my $breakST = $data[3]-$exSize; my $breakED=$data[4]+$exSize;
  my $blkSize = $data[4]-$data[3];
  my $gffIn = checkGFF ($gffFile, $data[1], $breakST, $breakED);

  #my $exSeq = extractSeq($ARGV[4],$data[1], $data[2],$data[3]);
  #my $palRes = checkPal($exSeq);

  my @gffIn=@$gffIn;
	if (@gffIn) { foreach my $line (@gffIn) { print $out "$row\t$line\n"; } }
	else { print $out "$row\tNA\n"; }

	#check the repeats in blocks then
	#my $trfInblk=checkTRF ($ARGV[1], $data[1], $data[2], $data[3]);
	#my @trfInblk=@$trfInblk; if (@trfInblk) {$trfInBlkStr = join ',', @trfInblk;} else {$trfInBlkStr='NA';}
	#my $exSeq = extractSeq($ARGV[4],$data[1], $data[2],$data[3]);
	#my $palRes = checkPal($exSeq);
	#if ($palRes) { $palDecision="Palindromic:$palRes";} else {$palDecision='NotPalindromic';}
	#$color='#181009';

	#my $coverage=checkCov ($ARGV[2], $data[1], $breakST, $breakED);
}
}

# Checks if a provided two coordinates overlaps or not it return 1 if overlaps
sub checkCorOverlaps {
my ($x1, $x2, $y1, $y2)=@_;
return $x1 <= $y2 && $y1 <= $x2;
}

sub checkGFF {
my ($file, $name, $cor1, $cor2)=@_;
my @gffData;
my $fh = &read_fh($file);
while (my $row = <$fh>) {
  	chomp $row;
	my @data = split /\t/, $row;
	next if $name ne $data[0];
	my $res=checkCorOverlaps ($data[3], $data[4], $cor1, $cor2);
	if ($res) {push @gffData, $row}

}
return \@gffData;
}

sub checkCov {
my ($file, $name, $cor1, $cor2)=@_;
my @covData; my $sum=0; my $avCov=0;
open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";
while (my $row = <$fh>) {
  	chomp $row;
	my @data = split /\t/, $row;
	next if $name ne $data[0];
	my $res=checkCorOverlaps ($data[1], $data[2], $cor1, $cor2);
	if ($res) {push @covData, $data[3]}

}
$sum += $_ for @covData;
$avCov=$sum/scalar(@covData);
return $avCov;
}

sub extractSeq {
my ($file, $chr, $st, $ed)=@_;
use Bio::DB::Fasta;
my $db = Bio::DB::Fasta->new($file);
my $seq = $db->seq($chr, $st => $ed);
return $seq;
}

sub checkPal {
my ($seq, $param)=@_;
my $pp = qr/(?: (\w) (?1) \g{-1} | \w? )/ix;
    while ($seq =~ /(?=($pp))/g) {
        return "$-[0] - $1" if length($1) > $param->{palsize};
    }
}

1;

__END__

