#!/usr/bin/perl -w 
#use strict;

package StationaryPt;

sub new {
	my $class=shift;
	my $line=shift;
	my $self= {
		_LINE=>$line,
		_TEMPERATURE=>298.150,
		_SCF=>undef,            #basic_energy
		_SCFsol=>undef,
		_ZEROPT=>undef,
		_UCORR=>undef,
		_HCORR=>undef,
		_GCORR=>undef,
		_TOTAL_E=>undef,       #sumup energy
		_TOTAL_U=>undef,
		_TOTAL_G=>undef,
		_TOTAL_Esol=>undef,
		_TOTAL_Usol=>undef,
		_TOTAL_Gsol=>undef,
		_REL_E  =>undef,       #relative energy
		_REL_U  =>undef,
		_REL_G  =>undef,
		_REL_Esol=>undef,
		_REL_Usol=>undef,
		_REL_Gsol=>undef,
	};
	bless $self, $class;
	$self->basic_energy();
	$self->sumup();
	return $self;
}



sub basic_energy {
	my $self=shift;
	my ($SCF, $Z, $Ucorr, $Hcorr, $Gcorr);
	my $SCFsol;
	my @files=split(/\s+/, $self->{_LINE});
	for (@files) {
	$_=~s/\.(log|com|chk)//;
	$_.=".log";
		($SCF, $Z)=$self->extract_energy($_);	
		($Ucorr, $Hcorr, $Gcorr) = $self->calculate_thermal($_);
	$self->{_SCF}+=$SCF;
	$self->{_ZEROPT}+=$Z;
	$self->{_UCORR}+=$Ucorr;
	$self->{_HCORR}+=$Hcorr;
	$self->{_GCORR}+=$Gcorr;
	$self->{_SCFsol}+=$self->extract_solvent($_);
	};
}

sub extract_energy {
	my ($self,$filename)=@_;
	my ($SCF,$Z);
	open FILE, $filename or die "Couldn't open the file $filename\n";

	my @content=<FILE>;
	my $content=join('',@content);
	$Z = ($content=~/Zero-point correction=\s*(-?\d+\.\d+)/)?$1:undef;
	my $e = ($content=~/Sum of electronic and zero-point Energies=\s*(-?\d+\.\d+)/)?$1:undef;
	$SCF = $e-$Z;
	return ($SCF, $Z);
}

sub calculate_thermal {
	my ($self,$filename)=@_;
	$filename=~s/\.log/\.chk/;
	open CHK, $filename or die "Couldn't open the chk file of $filename\n";
	close(CHK);
	my $temp=$self->{_TEMPERATURE};
	my $content=`freqchk $filename N $temp 1 1 Y N`;

	my ($Ucorr, $Hcorr, $Gcorr);
	$Ucorr = ($content=~/Thermal correction to Energy\=\s+(-?\d+\.\d+)/)?$1:undef;
	$Hcorr = ($content=~/Thermal correction to Enthalpy\=\s+(-?\d+\.\d+)/)?$1:undef;
	$Gcorr = ($content=~/Thermal correction to Gibbs Free Energy\=\s+(-?\d+\.\d+)/)?$1:undef;

	return ($Ucorr, $Hcorr, $Gcorr);
}

sub extract_solvent {
	my ($self, $filename)=@_;
	$filename="sol_".$filename;
	open SOL, $filename or die "Couldn't open the sol file of $filename\n";
	my @content=<SOL>;
	my $content=join('', @content);
	my $SCFsol= ($content=~/SCF Done:\s+E\(\w+\)\s+\=\s+(-?\d+\.\d+)/)?$1:undef;
	return $SCFsol;
}

sub sumup {
	my $self = shift;
	$self->{_TOTAL_E} = $self->{_SCF} + $self->{_ZEROPT};
	$self->{_TOTAL_U} = $self->{_SCF} + $self->{_UCORR};
	$self->{_TOTAL_G} = $self->{_SCF} + $self->{_GCORR};
	$self->{_TOTAL_Esol} = $self->{_SCFsol} + $self->{_ZEROPT};
	$self->{_TOTAL_Usol} = $self->{_SCFsol} + $self->{_UCORR};
	$self->{_TOTAL_Gsol} = $self->{_SCFsol} + $self->{_GCORR};
}

sub relative_energy {
	my ($self, $rel)=@_;
	$self->{_REL_E} = ($self->{_TOTAL_E} - $rel->{_TOTAL_E})*627.509;
	$self->{_REL_U} = ($self->{_TOTAL_U} - $rel->{_TOTAL_U})*627.509;
	$self->{_REL_G} = ($self->{_TOTAL_G} - $rel->{_TOTAL_G})*627.509;
	$self->{_REL_Esol} = ($self->{_TOTAL_Esol} - $rel->{_TOTAL_Esol})*627.509;
	$self->{_REL_Usol} = ($self->{_TOTAL_Usol} - $rel->{_TOTAL_Usol})*627.509;
	$self->{_REL_Gsol} = ($self->{_TOTAL_Gsol} - $rel->{_TOTAL_Gsol})*627.509;
}

sub print_energy {
	my $self=shift;
	print "Files                     :",$self->{_LINE},"\n";
	print "SCF Done                  :",$self->{_SCF},"\n";
	print "SCF Done for solvent      :",$self->{_SCFsol},"\n";
	print "Zero-point correction     :",$self->{_ZEROPT},"\n";
	print "Total Electronic Energy   :",$self->{_TOTAL_E},"\n";
	print "Total Thermal Energy      :",$self->{_TOTAL_U},"\n";
	print "Total Thermal Free Energy :",$self->{_TOTAL_G},"\n";
	print "Relative Electronic Energy:",$self->{_REL_E},"\n" if (defined($self->{_REL_E}));
	print "Relative Thermal Energy   :",$self->{_REL_U},"\n" if (defined($self->{_REL_U}));
	print "Relative Free Energy      :",$self->{_REL_G},"\n" if (defined($self->{_REL_G}));
	print "Relative Electronic Energy(solvent):",
	                                $self->{_REL_Esol},"\n" if (defined($self->{_REL_Esol}));
	print "Relative Thermal Energy(solvent)   :",
	                                $self->{_REL_Usol},"\n" if (defined($self->{_REL_Usol}));
	print "Relative Free Energy(solvent)      :",
	                                $self->{_REL_Gsol},"\n" if (defined($self->{_REL_Gsol}));
	print "\n\n";
}

sub print_for_plot{
	my $self=shift;
	my $string=sprintf("%8.3f  %8.3f\n", $self->{_REL_E}, $self->{_REL_Gsol});
	return $string;
}

sub print_for_gnuplot_command{
	my $self=shift;
	my $string = sprintf("E0=$self->{_REL_E}\nGsolTemp=$self->{_REL_Gsol}\n");
	return $string;
}

package Path;

sub new {
	my ($class, $name,$temperature)=@_;
	my $self= {
		_FILE_NAME=> $name,
		_POINTS=>[],
	};
	bless $self, $class;
	$self->fill_points;
	$self->fill_relative_energy;
	return $self;
}

sub fill_points {
	my $self=shift;
	open PTFILE, $self->{_FILE_NAME} or die "Couldn't open the file $self->{_FILE_NAME}\n";
	my @points=<PTFILE>;
	close(PTFILE);
	for (@points) {
		chomp;
		my $statpt=StationaryPt->new($_);
		push @{$self->{_POINTS}}, $statpt;
	}
}

sub fill_relative_energy {
	my $self=shift;
	my $rel=${$self->{_POINTS}}[0];
	for (@{$self->{_POINTS}}){
		$_->relative_energy($rel);
	}
}

sub print_energy {
	my $self=shift;
	for (@{$self->{_POINTS}}) {
		$_->print_energy;
	}
}

sub print_gnuplot {
	my $self=shift;
	open DATA, ">plot.data" or die "Couldn't open the file\n";
	open GNUPLOT, ">plot.gnu" or die "Couldn't open the file\n";
	my $counter=0;
	for (@{$self->{_POINTS}}) {
		$counter+=100;
		print GNUPLOT $_->print_for_gnuplot_command;
		print GNUPLOT "set label sprintf(\"$_->{_LINE}\\n%6.2f\\n%6.2f\",GsolTemp,E0) at $counter,E0 front offset 0, -1 font \"Helvetica,12\"\n";
		print DATA $counter,  $_->print_for_plot;
		$counter+=300;
		print DATA $counter,  $_->print_for_plot;
	}

	print GNUPLOT "unset key\n";
	print GNUPLOT "set border 0\n";
	print GNUPLOT "unset xtics\n";
	print GNUPLOT "unset ytics\n";
	print GNUPLOT "set label sprintf(\"GsolTemp\\nE0\") at graph 0,0.2 font \"Helvetica,12\"\n";
	print GNUPLOT "plot \"plot.data\" with line\n";

	close(GNUPLOT);
	close(DATA);
}

package main;

use Getopt::Std;

getopts("l:r:e:");
$Usage = "   Usage: pes -l <to create solvent files>\n".
         "              -r <to run the solven files>\n".
	 "              -e <to calculate the relative energies>\n".
	 "              -i <to create supporting information\n";
die "$Usage $!\n" unless $opt_l||$opt_r||$opt_e||$opt_i;
l() if ($opt_l);
r() if ($opt_r);
e() if ($opt_e);
i() if ($opt_i);

sub uniq {
	my $filename=shift;
	open FILE, "$filename" or die "Couldn't open file: $filename\n";
	my @content=<FILE>;
	close(FILE);
	my $content=join('',@content);
	my @files=split(/\s+/,$content);
	my @selected_files;
	for (@files) {
		push(@selected_files, $_) unless ($_~~@selected_files);
	}
	return(@selected_files);
}


sub l {
	my @selected_files=uniq($opt_l);
	foreach my $filename (@selected_files) {
		open COM, $filename.".com" or die "$filename:Couldn't open the file\n";
		my @input=<COM>;
		my $input=join('',@input);
		close(COM);

		#substituting the required keyword
		$input=~s/%chk=(.+)chk/%chk=sol_$1chk/;
		$input=~s/freq /SP scrf=(solvent=2-Methyl-1-Propanol) /;

		#writing the output file for run
		open OUT, ">sol_$filename.com";
		print OUT $input;
		close(OUT);
		print "Solvent file for $filename has been written\n";
	}
}

sub r {
	my @selected_files=uniq($opt_r);
	foreach my $filename (@selected_files) {
		open FILE, "sol_".$filename.".com" or die "sol_$filename:Couldn't open the file\n";
		print "sol_$filename.com is OK\n";
		my @content=<FILE>;
		my $content=join('',@content);
		close(FILE);
		my $execute="g09 sol_".$filename;
		my $output=`$execute`;	
	}
}

sub e {
	my $path=Path->new("$opt_e");
	$path->print_energy;
	$path->print_gnuplot;
}

sub i {


}
