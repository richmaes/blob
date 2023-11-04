#!/usr/bin/perl

use Getopt::Long;
use Cwd;
use File::Basename;
Getopt::Long::Configure("pass_through");

my $cmd_options = "@ARGV";
my $xilinx_lib_path = "xilinx_lib";
my $precompile_list = "../common/xilinx_precompile.tcl";
my $opt_snapshot = NULL;
my $opt_snapshot_switch = "";
my $opt_snapshot_functional_sim = "";
my $opt_snapshot_behave = "";
my $testfile_without_extension = "";
my $fh;
$test_size = 0;

$opt_testfile = NULL; 

# System check  observed the return code of a system command and makes an appropriate
# printf to flag the issue
sub system_check  {
    my ($system_cmd) = @_;
    print("$system_cmd\n");
    system($system_cmd);
    
    if ($? == -1) {
        print "failed to execute: $!\n";
        exit($?);
    }
    elsif ($? & 127) {
        printf "child died with signal %d, %s coredump\n",
        ($? & 127),  ($? & 128) ? 'with' : 'without';
        exit($?);
    }
    elsif ($? >= 128) {
         printf "  irun_script.pl exits with code %d.\n", $?;
        exit($?);
    }
    else {
        printf "  Done with code %d.\n", $?;
    }
}


# specify the log file location
# specify wheter we are performing a precompile operation
&GetOptions ("testfile=s", "logfile=s", "precompile!", "range=s", "help!", "verbose=s", "stoperror!", "gui", "snapshot=s");

if ($opt_help) {
    print("----------------------------------------------------------\n");
    print("xsim_script.pl - Kristen simulation script for Vivado XSim\n");
    print("Copyright 2018-2020 Xmissile, LLC.\n");
    print("----------------------------------------------------------\n\n");
    print("Runs a demo simulation of the my_host host design.\n");
    print(" -probe     Log all signals.  Increases simulation time.\n");
    print(" -gui       Launch graphical simulation.\n");
    print(" -logfile   Define a log file for output storage.\n");
    print(" -range     Range of tests to run. ex -r 0-2,3,7-9\n");
    print(" -stoperror Stop on detection of a simulation error.\n");
    print(" -testfile  Test file to execute.\n");
    print(" -stop      Stop on Error.\n");
    print(" -clean     Clean simulation files.  Does not clean xilinx_lib.\n");
    print(" -help      Display help screen.\n");
    print("\n");
    exit(0);
}
$tests = "";

if ($opt_testfile eq NULL) {
    print("testfile name must be specified.\n");
    exit;
}
#($testfile_without_extension = $opt_testfile) =~ s/\.[^.]+$//;
($testfile_without_extension,$bdir,$bext) = fileparse($opt_testfile, qr/\.[^.]*/);

if ($opt_snapshot eq NULL) {
    $opt_snapshot = $testfile_without_extension;
    $opt_snapshot_behave = "$opt_snapshot" . "_behave";
    $opt_snapshot_switch = " --snapshot $opt_snapshot_behave";
    $opt_snapshot_functional_sim = " -key {Behavioral:sim_1:Functional:" . $testfile_without_extension . "}";   
}

if ($opt_range eq "") {
       $opt_range = "everything";   
}

if ($opt_range =~ /everything/) {
       $test_size = 32;
       for ($i = 0;$i < $test_size; $i = $i + 1) {
          $tests = "1" . $tests;
    }
} else {
    @range_substrs = split(",",$opt_range);
    foreach $range_substr (@range_substrs) {
        ($range_start, $range_end) = split ("-", $range_substr);

        # check if the end is NULL as that means there was no - or end for that matter
        if ($range_end == NULL) {
               if ($range_start >= $test_size) {
                   $test_size = $range_start + 1;
               }
               if (length($tests) < $test_size) {
                   my $bits_to_add = $test_size - length($tests);
                   for ($str_index = 0; $str_index < $bits_to_add; $str_index = $str_index + 1) {
                       $tests = "0" . $tests;
                   }
               }
               substr($tests,$test_size-($range_start+1),1) = "1";
        } else {
            #order the range make sure that $start is less than $end
            if ($range_start > $range_end) {
                $tmp = $range_start;
                $range_start = $range_end;
                $range_end = $tmp;
            }
               if ($range_end >= $test_size) {
                   $test_size = $range_end + 1;
               }
   
               if (length($tests) < $test_size) {
                   my $bits_to_add = $test_size - length($tests);
                   for ($str_index = 0; $str_index < $bits_to_add; $str_index = $str_index + 1) {
                       $tests = "0" . $tests;
                   }
               }
               for ($str_index = $range_start; $str_index <= $range_end; $str_index = $str_index + 1) {
                  substr($tests,$test_size-($str_index+1),1) = "1";
            }
        }
    }
}



my $uc_define_filename;
$uc_define_filename = $testfile_without_extension . ".vh";
open($fh, ">", $uc_define_filename)
  or die "Can't open > " . $uc_define_filename;

print $fh "// -----------------------------------------------------------\n";
print $fh "// $testfile_without_extension" . ".vh\n";
print $fh "// Generated file specifies which numerical test cases to run.\n";
   print $fh "// Kristen Software License - Version 1.0 - January 1st, 2019                  \n";
   print $fh "//                                                                             \n";
   print $fh "// Permission is hereby granted, free of charge, to any person or organization \n";
   print $fh "// obtaining a copy of the software and accompanying documentation covered by  \n";
   print $fh "// this license (the \"Software\") to use, reproduce, display, distribute,     \n";
   print $fh "// execute, and transmit the Software, and to prepare derivative works of the  \n";
   print $fh "// Software, and to permit third-parties to whom the Software is furnished to  \n";
   print $fh "// do so, all subject to the following:                                        \n";
   print $fh "//                                                                             \n";
   print $fh "// The copyright notices in the Software and this entire statement, including  \n";
   print $fh "// the above license grant, this restriction and the following disclaimer,     \n";
   print $fh "// must be included in all copies of the Software, in whole or in part, and    \n";
   print $fh "// all derivative works of the Software, unless such copies or derivative      \n";
   print $fh "// works are solely in the form of machine-executable object code generated by \n";
   print $fh "// a source language processor.                                                \n";
   print $fh "//                                                                             \n";
   print $fh "// THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n";
   print $fh "// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    \n";
   print $fh "// FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT   \n";
print $fh "// SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE   \n";
   print $fh "// FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE, \n";
   print $fh "// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER \n";
   print $fh "// DEALINGS IN THE SOFTWARE.                                                   \n";
   print $fh "                                                                               \n";
   print $fh "// GENERATED FILE - DO NOT MODIFY THIS FILE MANUALLY.                          \n";
print $fh "// -----------------------------------------------------------\n";
print $fh "\n";
print $fh "`ifndef " . uc $testfile_without_extension . "_RUN_TESTS_TEST_CASES\n";
print $fh "`define " . uc $testfile_without_extension . "_RUN_TESTS_TEST_CASES  1\n";
print $fh "`define TEST_CASE_RANGE $test_size\n";
print $fh "`define TEST_CASES $test_size\'b$tests\n";
print $fh "`define TEST_NAME " . uc $testfile_without_extension . "\n";
print $fh "`define TEST_NAME_STR \"" . uc $testfile_without_extension . "\"\n";
print $fh "`define VERBOSE 0\n";
print $fh "`endif // " . uc $testfile_without_extension . "_RUN_TESTS_TEST_CASES\n";
close $fh;


# ----------------------------------------------
# Formulate standard options for compilation
# ----------------------------------------------

my $std_compile_opt  = "";
   $std_compile_opt .= " +licq";
   $std_compile_opt .= " -64bit";
   $std_compile_opt .= " -compile -v93";
   $std_compile_opt .= " -l $opt_logfile";
   $std_compile_opt .= " +define+SIM_SPEED_UP";

# ----------------------------------------------
# Formulate simulation options
# ----------------------------------------------
my $xsim_options = "";
if ($opt_gui) {
   $xsim_options = " -gui";
}


# ----------------------------------------------
# Build Vivado Libs for usage by all simulations
# ----------------------------------------------

if (!(-d "../$xilinx_lib_path")) {
    print ("Xilinx libraries must be created.\n");
    # -------------------------------------------------------
    # The Xilinx library was not found so we need to build it
    # -------------------------------------------------------

    my $current_working_directory = cwd();
    # -------------------------------------------------------
    # Move to our build directory and start the build process
    # -------------------------------------------------------
    chdir("../") or die "Stragely enough, we cannot cd to ../ \nCowardly refusing to continue this endevor.  $!\n";

    # -------------------------------------------------------
    # Make our new build directory for the Xilinx library
    # -------------------------------------------------------
    mkdir("$xilinx_lib_path") or die "ERROR: Unable to create directory $xilinx_lib_paths: $!\n";
    chdir("$xilinx_lib_path") or die "ERROR: Unable to change directory to $xilinx_lib_path: $!\n";

    
    system("vivado -mode batch -source $precompile_list");

    print ("Xilinx libraries are complete.\n");
}


$sim_path = $ENV{'SIMULATOR_DIR'};
$xsim_path = "$ENV{'XILINX_VIVADO'}/data/xsim/xsim.ini";
if (-e "$xsim_path") {
   system_check ("cp $xsim_path .");
}

my $ip_path = "../../design/ip";

# if (-d "$ip_path/lib") {
#     print ("Removing $ip_path/lib\n");
#     system("rm -rf $ip_path/lib");
# }

# ----------------------------------------------
# Compile 
# ----------------------------------------------
# 
system_check ("xvlog --incr --relax -prj ../../design/generated/xsim_kristen_generated.prj");
system_check ("xvlog --incr --relax -L xil_defaultlib -work xil_defaultlib --include \"../common\" --include \"../sim\" --include \"../../design/generated\" -sv \"$opt_testfile\"");

# ----------------------------------------------
# Elaborate 
# ----------------------------------------------
system_check("xelab --incr --debug typical --relax --mt 8 --include \"../sim\" -L xil_defaultlib -L unisims_ver -L unimacro_ver -L xpm $opt_snapshot_switch  xil_defaultlib.$testfile_without_extension -log elaborate.log");

# ----------------------------------------------
# Simulate 
# ----------------------------------------------
$bd_tcl_switch = "";
# Test specific tcl file
$proj_bd_tcl = "../sim/$testfile_without_extension" . ".tcl";
# generic tcl file
$bd_tcl = "../sim/bd.tcl";
if (-e "$proj_bd_tcl") {
  $bd_tcl_switch = "-tclbatch " . $proj_bd_tcl;
} elsif (-e "$bd_tcl") {
   print("found bd.tcl\n");
   $bd_tcl_switch = "-tclbatch $bd_tcl";
} else {
    print("Found no bd.tcl\n");
}
system_check("xsim $opt_snapshot_behave $opt_snapshot_functional_sim $bd_tcl_switch -log simulate.log $xsim_options");

