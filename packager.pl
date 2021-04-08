#!/usr/bin/perl
#use strict;
#use warnings;
use File::Copy;
# use Getopt::Long qw(GetOptions);
use Getopt::Std;
# Commented out MIME::Lite until we can re-install on this new Mac (carlj, 151209)
# use MIME::Lite;

#---------------------------------------------------------------------------
# DSpace packager program written by Carl Jones and Melanie Howell
#
# Usage: packager+tiff.pl
# Default is to assume source filename (from IRIS) is called export.xml, which is the equivalent of running:
# packager+tiff.pl --filename=export.xml
#
# Script always assumes source XML file (e.g. export.xml) is in /Users/rvcdigital/IRIS_raw_XML
# If you want to use a different file name it still needs to be in the IRIS_raw_XML directory
# For example: packager.pl --filename=foo.xml
#
# Last Modified on September 14, 2006
# Last Modified on February 1, 2007 
# Include TIFF master file in SIP package (carlj, 080110)
#
# Last Modified Sept. 20, 2010:
# Update to /Users/rvcdigital home directory (carlj, 100920)
#
# Last modified on May 16, 2012 (carlj)
# Call revised xslt crosswalk with updated Dome fields (e.g. cleaned up dc:creator, dc:date, new
# dc:contributor.display, etc.) 
# Added 3 new VRA core fields: worktype, technique, culturalContext
#
# Last modified on June 7, 2012 (carlj)
# allow for no TIFF files present, copy existing jpg's to submission package
#
# Last modified: November 14, 2013 (carlj)
# add PDF to list of filetypes for SIPs; rework check for image files and writing to CONTENTS file
#
# Add option to set location for incoming bitstreams, for example CSM storage, our networked managed storage area  - July 21, 2014 (carlj)
# NOTE: currently we're running this from the image workstation, lib-s098.mit.edu. 

# Special Edition: May 7, 2019
# read existing Felice Frankel sips directories, copy _cp.jpg into place and create contents file
# 

# 2021
#

#---------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Prints a welcome message
# ----------------------------------------------------------------------------

     # print "*--------------------------------------------*\n";
   #   print "*                                            *\n";
   #   print "*      Welcome to the RVC XSpace Packager    *\n";
   #   print "*                                            *\n";
   #   print "*      Version 1.6                           *\n";
   #   print "*                                            *\n";
   #   print "*      Written by Melanie Howell and         *\n";
   #   print "*              Carl Jones                    *\n";
   #   print "*                                            *\n";
   #   print "*--------------------------------------------*\n";

    
# variable name for directory that contains the dspace package directories
$dspacedir = "/Users/rvcdigital/forDspaceUpload/FeliceFrankel";

# should this be settable from command line
# we can make it optional to give ourselves some flexibility
# $dspacedir = command line option string but defaults to forDSpaceUpload

# tools home directory on image workstation, lib-s098.mit.edu
$dspace_home = "/Users/rvcdigital";

# item counter
$count = 0;

#----------------------------------------------------------------------------
# Allows user to declare the name of the xml file to be transformed.  This is 
# currently set so that the user does not have to declare the filename since
# it was agreed that only one file name would be used.  This file name is
# currently "export.xml"
#---------------------------------------------------------------------------- 

	# default values for command line options
     my $filename = ' ';
     # my $xml_file = "export.xml";
	 
	 # add command line option for bitstream directory and optional output directory if different than default
	 my $bitstream_dir = ' ';
	 my $output_dir = '/Users/rvcdigital/forDspaceUpload/FeliceFrankel';	 
	 my $xml_file = 'export.xml'; 
	 my %options=();
	 
	 # declare options
	 getopts("hf:b:o:", \%options);

	 
	 # print "-f $options{f}\n" if defined $options{f};
 #     print "-h $options{h}\n" if defined $options{h};
 # 	 print "-b $options{b}\n" if defined $options{b};
 # 	 print "-o $options{o}\n" if defined $options{o};
 #
	 # todo: print usage message 
	 # other things found on the command line..
	 print "Unprocessed by Getopt::Long\n" if $ARGV[0];
	 foreach ($ARGV) {
	 	print "$_\n";
	 }
	 
   
   #cleanup subroutine
     &cleanup;
	
	# TODO: process command line option for output directory...
	
	if ($options{h})
	{
		print "Usage: packager4bags.pl -b [bitstream directory] -f [xml metadata file] -o [output directory] -h [help/usage] \n\n";
		exit;
	}

	
	if ($options{o}) 
	{
		$dspacedir = $options{o};
		print "Submission packages will be written to: $dspacedir\n";
	} 
	else 
	{ 
		print "Using default output directory for submission packages: $dspacedir";
	}
	
	
	# check for bitstream_dir
	if ($options{b})
	{
		$bitstream_dir = $options{b};
		print "Will set bitstream directory to: $bitstream_dir\n";
	}
	else 
	{
		print "Error, no bitstream directory specified. Exiting.";
		exit 2;
	}
	
	# check for xmlfile
	if ($options{f})
	{
		$iris_xml = $options{f};
		print "Did set xmlfile to: $iris_xml\n";
		$xmlfile = $iris_xml;
	}
	else 
	{
		print "Otherwise, will use default IRIS_raw_XML/export.xml\n";
                $xmlfile = 'export.xml';
	}


	#system call to perform the xsl transform which also creates the contents directories

	print "Will call java saxon9.jar ?.xml iris2dc_frankel_add_cp_bitstreams.xsl....\n";

    system ("java -jar /Library/Java/Extensions/saxon9.jar $dspace_home/IRIS_raw_XML/$xmlfile $dspace_home/tools/xslt/iris2dc_frankel_add_cp_bitstreams.xsl");
	
#-----------------------------------------------------------------------------  
# pulls the corresponding .jpg and .tiff files from the SV, CP, TM, and TIFF
# folders, adds them to the folder. Also writes the contents file
#-----------------------------------------------------------------------------
    
# we may not use these pre-defined paths, but for now here they are...
     # $image_source_dir="/RVC_Digital_Archive/DSpace_images";
     $csm_storage="/Volumes/csm_storage";
     # base image file submission directory
     $image_submission_directory="$csm_storage/Submission/Visual_Collections";

      opendir(DIRHANDLE, $dspacedir) or die $!;
      $unique_filename = "log_".get_timestamp();
     open (LOGFILE, "+>/Users/rvcdigital/logs/$unique_filename");
     open (ERRORLOGFILE, "+>/Users/rvcdigital/logs/error$unique_filename");

print "Will get image files...\n";

foreach $name (sort readdir(DIRHANDLE)) {

 print "Name variable = $name\n";

 print "At top of foreach loop...\n";
          if ($name eq "." || $name eq ".." || $name eq ".DS_Store"){
              next;
          }

          print "processing $name directory\n"; 

#-----------------------------------------------------------------------------
# checks to see if the CP files exist. If not, 
# writes to the errorlog file. 
# If file is found, log in the regular log file.
# cp file and finally write filename string to open CONTENTS file
#-----------------------------------------------------------------------------

print "Will open CONTENTS file....";

open(CONTENTSFILE, "+>$dspacedir/$name/contents") || die("Could not open file!");

 print "Will check to see if cp, sv, and tiff files are present\n";
		  
	  $filecheck1 = "$bitstream_dir/cp/${name}_cp.jpg";	  

	  print "In filecheck1: $filecheck1, cp_jpg's...\n";

          if(-e $filecheck1)
	  {
              print LOGFILE "file $name\_cp.jpg sucessfully located\n";
	      system ("cp $bitstream_dir/cp/$name\_cp.jpg $dspacedir/$name");
		  
	      print CONTENTSFILE "$name\_cp.jpg\n" ;		  
          }
          else{
              print "file $name\_cp.jpg not found\n";	
              print ERRORLOGFILE "file $name\_cp.jpg not found\n";
          }
		  
	 print "Closing contents file";
         close(CONTENTSFILE);

    $count++; 
    print "Reached end of readdir\n";
    print "Did copy images for $count items\n";

         } #end of readir
     
     closedir(DIRHANDLE);

#-------------------------------------------------------------------------------
# creates a compressed file  of the now ready content containing 
# both images and metadata.
#-------------------------------------------------------------------------------

print "Will copy to dome.mit.edu using separate bin/scp2dome.sh\n";

      opendir(UPLOADDIR, "/Users/rvcdigital/forDspaceUpload") || die("Cannot open directory");
	  

# Move to libaxis4.mit.edu  - 070212 
     
# Using non-tar version (carlj, 070212), use "scp -C -r" instead
# -C option will cause scp to use compression; -r for copy directory and subtree
print "\nWill secure copy SIPs to dome.mit.edu\n";

# copy to server using bash script
# disabled for testing on lib-sts-16 (carlj)
system("/Users/rvcdigital/bin/scp2dome.sh");

#-----------------------------------------------------------------------------
# Prints the total number of files processed and finishes
#-----------------------------------------------------------------------------
     print LOGFILE "The number of SIPs processed = $count\n";
     print "The number of IRIS SIPs processed = $count\n";
     print "\npackager+tiff.pl Upload complete\n";
     closedir(UPLOADDIR);
     close(LOGFILE);
     close(ERRORLOGFILE);

#-----------------------------------------------------------------------------
# Sends email out if there are any errors in this process
#-----------------------------------------------------------------------------
# commenting this out, at least temporarily, need to reinstall MIME:LITE module (carlj, 151209)
# which requires XCode command line tools...

#     if (-s "/Users/rvcdigital/logs/error$unique_filename"){
#          print "An email was sent containing the error log file\n";
#          &send_email; #sends the errorlog file if it is not an empty file
#     }

#------------------------------------------------------------------------------
# Cleanup subroutine to remove old files from the forDspaceImport and tarFiles 
# directory
#------------------------------------------------------------------------------
     sub cleanup{
     print "cleaning up directories...\n";
     print "removing forDspaceUpload/FeliceFrankel/....\n";
     # 
     system ("rm -rf $dspace_home/forDspaceUpload/FeliceFrankel/*");
     print "removing old files from forDSpaceUpload/FeliceFrankel directory...\n";
     #
     print "finished cleaning...\n";
     }

#------------------------------------------------------------------------------
# Subroutine to produce a timestamp (used for log file naming)
#------------------------------------------------------------------------------
     sub get_timestamp {
     ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);

            $Month = ($Month + 1);
            if ($Month < 10) { $Month = "0$Month"; }
            if ($Hour < 10) { $Hour = "0$Hour"; }
            if ($Minute < 10) { $Minute = "0$Minute"; }
            if ($Day < 10) { $Day = "0$Day"; }
            $Year = ($Year - 100);
            $Year = ("0$Year");
            return($Year."_".$Month.$Day."_".$Hour.$Minute);
      }

}



