#!/usr/bin/perl

$Temperature=298.15;  # In kelvin
$pressure=1;       # In bar
$toKcal=627.509;


%Atomic_Number= (	1 => "H",
			2 => "He",
			3 => "Li",
			4 => "Be",
			5 => "B",
			6 => "C",
			7 => "N",
			8 => "O",
			9 => "F",
			10 => "Ne",
			11 => "Na",
			12 => "Mg",
			13 => "Al",
			14 => "Si",
			15 => "P",
			16 => "S",
			17 => "Cl",
			18 => "Ar",
			19 => "K",
			20 => "Ca",
			21 => "Sc",
			22 => "Ti",
			23 => "V",
			24 => "Cr",
			25 => "Mn",
			26 => "Fe",
			27 => "Co",
			28 => "Ni",
			29 => "Cu",
			30 => "Zn",
			31 => "Ga",
			78 => "Pt",
			79 => "Au"

);

open STN_PT, "stationary.list";

@stn_files=<STN_PT>;
close(STN_PT);

#open REF_PT, "reference.list";
#@ref_files=<REF_PT>;
#close(REF_PT);


push(@total_files, @ref_files);
push(@total_files, @stn_files);

# File for writing  data in rtf format
open OUT, ">data.rtf";

	print OUT "\{\\rtf1\\ansi\\deff0\{\\fonttbl\n";
	print OUT "\{\\f0 \'Times New Roman\'\}\}\n";
	print OUT "\\paperw11908\\paperh16833\\margl720\\margt720\\margr720\\margb720\n";

$E0ref=0;
$ETempref=0;
$HTempref=0;
$GTempref=0;

$Esol0ref=0;
$EsolTempref=0;
$HsolTempref=0;
$GsolTempref=0;

$E0=0;
$ETemp=0;
$HTemp=0;
$GTemp=0;

$Esol0=0;
$EsolTemp=0;
$HsolTemp=0;
$GsolTemp=0;

foreach $filename (@total_files) {

	chop($filename);
	open FILE, "$filename.log" or die "$filename.log:Couldn't open the file:$!\n";
	undef $/;
	$content=<FILE>;
	close(FILE);
	print "\n$filename.log\n\n";

	@sentences=split(/\n/, $content);

	print "Cartesian coordinate of the structure ----\n";
#	Extraction of essential data for input geometry
	$start=0;
	$capture_coord="";
	foreach $line (@sentences) {
		if ($line=~/Standard orientation:/) {$start=1;}
		if ($start>0 && $start<7) {$start++;}
		if ($start>=7) {
			if ($line!~/------------------------/)
				{$line=~s/         0      //g;
				 $line=~s/^     [ 0-9][0-9]       //g;
				 $capture_coord.=$line;
				 $capture_coord.="\n";
				}
			else {$start=0}
			}
		}
#	Splitting the data in line of each atom
	@atom_coord=split(/\n/,$capture_coord);

#	Splitting each line for atom to atno, x, y and z arrays
	$i=0;
	foreach $line (@atom_coord) {
		$_=$line;
		@atnoxyz=split;
		$atno[$i]=$atnoxyz[0];
		$x[$i]=$atnoxyz[1];
		$y[$i]=$atnoxyz[2];
		$z[$i]=$atnoxyz[3];
		$i++;
		}
	print "At. No.          X             Y             Z\n" if ($opt_v);
	for ($i=0; $i<=$#atno; $i++){
		printf "%5s%15.5f%15.5f%15.5f\n",$Atomic_Number{$atno[$i]},$x[$i],$y[$i],$z[$i];
	}

	#Calculation of reference thermodynamic parameter
	if ($content=~/SCF Done:\s+E\(\w+\)\s\=\s*(-?\w+\.\w+)\s+A.U./) {
		$Escf=$1;
		print " Escf:$Escf\n";
	}


	open FILE, "sol_$filename.log" or die "sol_$filename.log:Couldn't open the file:$!\n";
	undef $/;
	$content=<FILE>;
	close(FILE);
	if ($content=~/SCF Done:\s+E\(\w+\)\s\=\s*(-?\w+\.\w+)\s+A.U./) {
		$Escfsol=$1;
		print " Escfsol:$Escfsol\n";
	}

	open FILE, "$filename.chk" or die "$filename.chk:Couldn't open the file;$!\n";
	close(FILE);
	$content=`freqchk $filename.chk N $Temperature $pressure 1 Y N`;
	if ($content=~/Zero-point correction\=\s+(-?\w+\.\w+).+/) {
		$ZPcorr=$1;
		print " ZPcorr:$ZPcorr\n";
	}


	if ($content=~/Thermal correction to Energy\=\s+(-?\w+\.\w+)/) {
		$ThermalEcorr=$1;
		print " ThermalEcorr:$ThermalEcorr\n";
	}


	if ($content=~/Thermal correction to Enthalpy\=\s+(-?\w+\.\w+)/) {
		$ThermalHcorr=$1;
		print " ThermalHcorr:$ThermalHcorr\n";
	}


	if ($content=~/Thermal correction to Gibbs Free Energy\=\s+(-?\w+\.\w+)/) {
		$ThermalGcorr=$1;
		print " ThermalGcorr:$ThermalGcorr\n";
	}

	@sentences=split(/\n/, $content);

	# Frequencies;
	$freq_string="";
	foreach $line(@sentences) {
		if ($line=~/^ Frequencies --/) {$freq_string.=$line;}
	}
	$freq_string=~s/ Frequencies --//g; # Substitute the 'Frequencies --' by nothing
	$_=$freq_string;
	@freq=split;
	$tot_freq=scalar(@freq);
	print "$tot_freq number of Frequencies found\n"; 
	print "@freq\n";

	#RTF file

	print OUT "\\par\n{";
#############printing the first row#####
	print OUT "\\trowd\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx1440\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx6000\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx10450\n";
	######Data in the row1 ########
	print OUT "\\qc St.Pt.\\intbl\\cell\n";
	print OUT "\\qc General Structure\\intbl\\cell\n";
	print OUT "\\qc Ball & Stick model\\intbl\\cell\n";
	print OUT "\\row\n";
#############printing the second row####
	print OUT "\\trowd\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx1440\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx6000\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx10450\n";
	print OUT "$filename\\intbl\\cell\n";
	print OUT "\\qc\n";
	d() if ($opt_d);
	print OUT "\\intbl\\cell\n";
	print OUT "\\qc\n";
	b() if ($opt_b);
	print OUT "\\intbl\\cell\n";
	print OUT "\\row\n";
#############printing the third row####
	print OUT "\\trowd\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx6000\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx10450\n";
	#######Data in the col-1 row-3 (Coordinate data)####
	print OUT "\\qc\\fs24\{\\b\\ul Cartesian co-ordinate\}\\par\\pard\n";
	print OUT "\\ql\{\\tx350\\tab -----------------------------------------------------------\}\\par\\pard\n";
	print OUT "\\ql\\fs20\{\\tx500\\tx2000\\tx3500\\tx4900\n";
	print OUT "\\tab Atoms\\tab X\\tab Y\\tab Z\}\\par\\pard\n";
	print OUT "\\ql\\fs24\{\\tx350\\tab -----------------------------------------------------------\}\\par\\pard\n";
	print OUT "\\ql\\fs20\{\\tx750\\tqdec\\tx1800\\tqdec\\tx3250\\tqdec\\tx4700\n";
		###    Coordinate Data #####
#	c();
	for ($i=0; $i<=$#atno; $i++){
		printf OUT "\\tab %2s\\tab %-15.5f\\tab %-15.5f\\tab %-15.5f\\line\n",$Atomic_Number{$atno[$i]},$x[$i],$y[$i],$z[$i];
	}
		###    End of Data ########
	print OUT "\}\\par\\pard\n";
#	print OUT "\\ql\\fs24\{\\tx350\\tab -----------------------------------------------------------\}\\par\\pard\n";
	print OUT "\\intbl\\cell\n";
	#######End of coordinates######
	########Data in the col-2 row-3 (Frequencies)######
	print OUT "\\qc\{\\b\\ul Frequencies\\line\}\\par\\pard\n";
	print OUT "\\ql\\fs20\{\\tqdec\\tx750\\tqdec\\tx2220\\tqdec\\tx3700\n";
		###   Frequencies  #####
#	f();
	$counter=0;
	foreach $individual_freq (@freq) {
		$counter++;
		printf OUT "\\tab $individual_freq";
		if ($counter>2) { $counter=0; print OUT "\\line\n";}
	}
		###   End of Frequencies
	print OUT "\}\\par\\pard\n";
	print OUT "\\intbl\\cell\n";
	print OUT "\\row\n";
#############printing the fourth row####
#	z();
#	e();
#	h();
#	g();
#	t();
#	p();
	print OUT "\\trowd\n";
	print OUT "\\clbrdrt\\brdrdb\\clbrdrl\\brdrdb\\clbrdrr\\brdrdb\\clbrdrb\\brdrdb\n";
	print OUT "\\cellx10450\n";
	print OUT "\\qc\{\\b\\ul Statistical Thermodynamic Analysis\}\\par\\pard\n";
	print OUT "\\ql\\fs20\{\n";
	print OUT "\\tab Temperature=$Temperature K\\tab \\tab \\tab \\tab Pressure=$pressure  atm\\line\n";
	print OUT "\\tab Zero-point correction= $ZPcorr\n";
	print OUT "\\tab \\tab Electronic Energy = $Escf\\line\n";
	$E=$ThermalEcorr+$Escf;
	print OUT "\\tab Internal Energy (E)= $E\n";
	$H=$ThermalHcorr+$Escf;
	print OUT "\\tab Enthalpy (H)= $H\\line\n";
	$G=$Escf + $ThermalGcorr;
	print OUT "\\tab Gibbs Free Energy (G)=$G\n";
	$Gsol=$Escfsol + $ThermalGcorr;
	print OUT "\\tab Gibbs Free Energy of Solvation=$Gsol\\line\n";
	print OUT "\}\n";
	print OUT "\\intbl\\cell\n";
	print OUT "\\row\n";
	print OUT "}\\pard\n\\page";
#############end of printing the table###

}

print OUT "\}\n";
close(OUT);


sub b()
{
	print "You have given the picture file of the model\n";
	print "$opt_b\n";
	$_=`identify $opt_b`;
	@image_character=split;
	print "The model file supplied is in $image_character[1] format\n";
	if ($image_character[1]!~/JPEG/) {die "Couldn't handle file other than JPEG format\n"};
	@image_size=split(/x/,$image_character[2]);
	print "Resolution: $image_size[0] x $image_size[1]\n";
	open(IMG, $opt_b) or print "Couldn't open image file; $!\n";
	binmode(IMG);
	undef $/;
	$image=<IMG>;
	$hex=unpack("H*", $image);
	close IMG;
	if ($image_size[0] > $image_size[1]) {
		$transformed_width=3000;
		$transformed_height=int(3000*$image_size[1]/$image_size[0])
	}
	else {
		$transformed_height=3000;
		$transformed_width=int(3000*$image_size[0]/$image_size[1])
	}
	print OUT "\{\\pict\\jpegblip\\picw$image_size[0]\\pich$image_size[1]\n";
	print OUT "\\picwgoal$transformed_width\\pichgoal$transformed_height\n";
	print OUT "$hex\n";
	print OUT "\}\n";
}

sub d()
{
	print "You have given the diagram file of structure\n";
	print "$opt_d\n";
	$_=`identify $opt_d`;
	@image_character=split;
	print "The diagram file supplied is in $image_character[1] format\n";
	if ($image_character[1]!~/WMF/) {die "Couldn't handle file other than WMF format\n"};
	@image_size=split(/x/,$image_character[2]);
	print "Resolution: $image_size[0] x $image_size[1]\n";
	open(IMG, $opt_d) or print "Couldn't open image file; $!\n";
	binmode(IMG);
	undef $/;
	$image=<IMG>;
	$hex=unpack("H*", $image);
	close IMG;
	if ($image_size[0] > $image_size[1]) {
		$transformed_width=3000;
		$transformed_height=int(3000*$image_size[1]/$image_size[0])
	}
	else {
		$transformed_height=3000;
		$transformed_width=int(3000*$image_size[0]/$image_size[1])
	}
	print OUT "\{\\pict\\wmetafile8\\picw$image_size[0]\\pich$image_size[1]\n";
	print OUT "\\picwgoal$transformed_width\\pichgoal$transformed_height\n";
	print OUT "$hex\n";
	print OUT "\}\n";
}
