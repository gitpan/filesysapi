# A simple api to deal with directory operations that i have been coding
# over and over for years. i decided to put in module so i could reuse
# 

###############################################################################
##### WHO, WHAT, WHERE, etc...
###############################################################################
#AUTHOR   Eric Matthews
#VERSION  09.0

#DESCRIPTION
## Simple API for various filesystem operations 
## (see pod for details)

#HISTORY
#Initial writing began  - 2/10/2004  - Eric Matthews
#Beta version completed - 10/16/

package filsysapi;
use strict;
use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;
$VERSION		= .090;
@ISA = qw(Exporter);

#only exposing the subs currently available
@EXPORT	= qw(&get_dirsfiles_startingfrom 
             &get_dirs_startingfrom     
             &get_files_startingfrom    
             &subdirfilList_singledir   
             &subdirList_singledir      
             &filList_singledir         
             &filsHash_startingfrom     
             &dirsHash_startingfrom     
             &filsdirsHash_startingfrom 
            );

# given the relationship of our subs and how we are using conventional
# loops instead of recursion for performance and memory reasons these
# are best as package scope
my @dirProcessList;
my @FileList;
my $strTemp;


#get OS
#not using this at the moment, but may come in handy later
my $os = $^O;


#-------------------------------------------------------------------------#
sub get_dirsfiles_startingfrom
#-------------------------------------------------------------------------#
{
 my $cwd = $_[0];
 # un-wintel-ify \ to make compatible with posix since wintel allows both
 # \ or / and posix does not
 $cwd = changeSlashToPosixStyle($cwd);

#add path seperator so consumer can identify a directory from a file
 $cwd .= "\/" if $cwd !~ /\/$/;
 my @dirsfils=();
 if ($cwd) #...as we do not want to get a directory if no arg is given to us
 {
  push(@dirProcessList, $cwd);
  #here is where we deal with getting our subdirs sarting from the 
  #supplied root
  while (@dirProcessList > 0)
  {
   $strTemp = shift(@dirProcessList);
   push(@dirsfils, $strTemp);
   #print "Directory: $strTemp\n";
   scan_dirs($strTemp);
   #here is where we get the files for each subdir and for our root 
   while (@FileList)
   {
    $strTemp = shift(@FileList);
    push(@dirsfils, $strTemp);
    #print "$strTemp\n";  #left for test
   } #end inner loop
  
  } #end outer loop
 }
 else
 {
   $dirsfils[0] = "You did not send me a path\n!"; #some error handling
 }	
 return @dirsfils; 
}#end sub
1;

#-------------------------------------------------------------------------#
sub get_dirs_startingfrom
#-------------------------------------------------------------------------#
{
 my $cwd = $_[0];
 # un-wintelify \ to make compatible with posix since wintel allows both
 # \ or / and posix does not
 $cwd = changeSlashToPosixStyle($cwd); 
 
 $cwd .= "\/" if $cwd !~ /\/$/;
 my @dirs=();
 if ($cwd)
 {
  push(@dirProcessList, $cwd);
  while (@dirProcessList > 0)
  {
   $strTemp = shift(@dirProcessList);
   push(@dirs, $strTemp);
   #print "$strTemp\n";
   scan_dirs($strTemp);
  }
 }
  else
 {
   $dirs[0] = "You did not send me a path!\nExample: c:\\temp\n";	
 }
 return @dirs;
}
1;

#-------------------------------------------------------------------------#
sub get_files_startingfrom
#-------------------------------------------------------------------------#
{
 my $cwd = $_[0];
 # un-wintelify \ to make compatible with posix since wintel allows both
 # \ or / and posix does not
 $cwd = changeSlashToPosixStyle($cwd); 
 
 $cwd .= "\/" if $cwd !~ /\/$/;
 my @fils=();
 $cwd = $cwd . "\/" if ($cwd !~ /\/$/);
 push(@dirProcessList, $cwd);
 while (@dirProcessList > 0)
 {
  $strTemp = shift(@dirProcessList);
  scan_dirs($strTemp);
 
   while (@FileList)
   {
    $strTemp = shift(@FileList);
    push(@fils, $strTemp);
    #print "$strTemp\n";
   }
 }

 return @fils;
}
1;

#-------------------------------------------------------------------------#
sub subdirfilList_singledir
#-------------------------------------------------------------------------#
{
  my $cwd = $_[0];
 # un-wintelify \ to make compatible with posix since wintel allows both
 # \ or / and posix does not
 $cwd = changeSlashToPosixStyle($cwd);

  my @dirfil=();
  #use what we already gots
  my @dir = subdirList_singledir($cwd);
  my @fil = filList_singledir($cwd);
  @dirfil = (@dir, @fil);
  
  return @dirfil;	
}	
1;

#-------------------------------------------------------------------------#                     
sub subdirList_singledir
#-------------------------------------------------------------------------#
{
#	
# Returns a list of subdirectories for a given directory
#		
 my $cwd = $_[0];

 # un-wintelify \ to make compatible with posix since wintel allows both
 # \ or / and posix does not
 $cwd = changeSlashToPosixStyle($cwd);

 $cwd .= "\/" if $cwd !~ /\/$/;
 my @dirs=();
 if ($cwd)
 {
   scan_dirs($cwd);
 }
  else
 {
   $dirProcessList[0] = "You did not send me a path!\nExample: c:\\temp\n";	
 }
 @dirs = @dirProcessList;
 my $i=0;
 foreach (@dirProcessList)
 {
   $dirs[$i] = $1 if $_ =~ /.+\/(.+)\/?$/;
   $i++;	
 }	
 
 return @dirs;
}
1;

#-------------------------------------------------------------------------#
sub filList_singledir
#-------------------------------------------------------------------------#
{
#	
# Returns a list of files for a given directory
#	
 my $cwd = $_[0];
 # un-wintelify \ to make compatible with posix since wintel allows both
 # \ or / and posix does not
 $cwd = changeSlashToPosixStyle($cwd);

 $cwd .= "\/" if $cwd !~ /\/$/;
 my $filefilter;
 my @assets;
 my @ProcessList;

 chdir $cwd;
 @assets = <*>;

 foreach (@assets)
 {
  push(@ProcessList, $_) if (-f $_);
 }

 return @ProcessList;
}
1;

#
# NOTE: i am not preserving order with hashes. If preservation is important
#       to you use the subs that return arrays
#

#
# The hash subroutines are built to use the subroutines that return the
# results in an array format.
#
# The convention is to return the full path (file/subdir included) as the
# key, and the subdir or filename as the value.
#
#-------------------------------------------------------------------------#
sub dirsHash_startingfrom
#-------------------------------------------------------------------------# 
#	
# key is path, value is subdirectory
#
{
 my $cwd = $_[0];
 my %hshdirProcessList;
 my $key;
 my $val;
 
 my @dirs = get_dirs_startingfrom($cwd);

 foreach (@dirs)
 { 
  $key = $_;
  #strip off all the path crap so we are left with subdir name
  $val = $1 if $_ =~ /.+\/(.+)\/?$/;
  $hshdirProcessList{$key} = $val;
 }
 return %hshdirProcessList;
}
1;

#-------------------------------------------------------------------------#
sub filsHash_startingfrom
#-------------------------------------------------------------------------# 
#	
# key is path, value is file
#
{

 my $cwd = $_[0];
 my %hshdirProcessList;
 my $key;
 my $val;
 
 my @dirs = get_files_startingfrom($cwd);

 foreach (@dirs)
 { 
  $key = $_;
  #strip off all the path crap so we are left with file name
  $val = $1 if $_ =~ /.+\/(.+)$/;
  $hshdirProcessList{$key} = $val;
 }
 return %hshdirProcessList;
}
1;

#-------------------------------------------------------------------------#
sub filsdirsHash_startingfrom
#-------------------------------------------------------------------------# 
#	
# key is path, value is subdirectory or file
#
{
  my $cwd = $_[0];
  my %hshdirProcessList; 
  #use what already exists
  my %dirs = dirsHash_startingfrom($cwd);
  my %fils = filsHash_startingfrom($cwd);
  #concat our efforts
  %hshdirProcessList = (%dirs, %fils);
  
  return %hshdirProcessList;     	
}
1;



#### MEANT FOR PSUEDO ENCAPSULATION (after all this is Perl)###############
#### MAIN WORKHORSE for _startingfrom SUBROUTINES 
#-------------------------------------------------------------------------#
sub scan_dirs 
#-------------------------------------------------------------------------#
{
    my @arr;
    my $i=0;
    my $k=0;

    my $dir = $_[0];
    $dir .= "\/" if $dir !~ /(\\|\/)$/;
    
# read the specified directory and load into @arr
    chdir $dir or die "directory does not exist\n";
    opendir (cDir, '.') or die "directory does not exist\n";
    @arr = (readdir(cDir));
    closedir cDir;

# loop through the list of files and push directories and files onto arrays
  if (@arr)
  {
   $i = @arr;
   $k = 0;
   while ($k < $i)
   {
   if ($arr[$k] !~ /^\.\.?$/)
   {
     if (-d ($arr[$k]) )  		# is it a directory?
     {
      push(@dirProcessList, $dir . $arr[$k] . "\/")
     }
     elsif (-f ($arr[$k]) )		# is it a regular file?
     {
      push(@FileList,$dir . $arr[$k])
     }
       
   }
  $k++;
   }
 }
   
} # end sub


#-------------------------------------------------------------------------#
sub changeSlashToPosixStyle
#-------------------------------------------------------------------------#
{
#	
# i wanted this to be compatible on both posix and wintel platforms. Since
# Perl wintel allows using either \ or / and Perl posix does not i decided 
# to convert any wintel entries to /. This of course will cause problems if 
# you plan to you the results by other wintel programs. They will barf as 
# they will see the / as an invalid path seperator.
#
# i will add a method changeSlashToWintelStyle() to convert back to wintel
# style for use outside of a Perl program. i just have not yet done so.
#		
 my $res = $_[0];
 $res =~ s/\\/\//g;
 return $res;	
}

#### WORK IN PROGESS AREA - HARDHATS ONLY

#-------------------------------------------------------------------------#
sub changeSlashToWintelStyle
#-------------------------------------------------------------------------#
{
	
}	


#-------------------------------------------------------------------------#
sub filPathStripper
#-------------------------------------------------------------------------# 
#	
# strip path, all i want is filename
#
{
	
}
1;
	
#-------------------------------------------------------------------------#
sub dirPathStripper
#-------------------------------------------------------------------------# 
#	
# strip path, all i want is directory name
#
{
	
}
1;

#-------------------------------------------------------------------------#
sub listXmlFormat
#-------------------------------------------------------------------------# 
#	
# since the planet has gone xml bonkers, out in xml format
#
{
	
}
1;

#-------------------------------------------------------------------------#
sub returnListDuplicateFiles
#-------------------------------------------------------------------------# 
#	
# zzz
#
{
	
}
1;


__END__;
####POD below...

###############################################################################
##### GENERAL COMMENTS and DOCUMENTATION (POD)
###############################################################################

=head1 NAME

FILSYSAPI - File system API

=head1 GENERAL DESCRIPTION

This module provides a simple api for various file system operations, like
reading directories and subdirectories and returning a list of files and
or subdirectories in either array or hash format. Below are some high
level bullets describing functionality.

=over 2

=item *

Get list of files and/or directories for a single directory

=item *

Get list of files and/or directories for a directory tree starting with
a starting location of your choosing. Will return results in either hash
or array format.

i decided to put this together as i typically end up writing this code in
my various scripts and realized this would be a nice candidate for reuse.

=back
                                                            
                                             

=head1 BUGS

None i have found yet, though they certainly exist ;-)

=head1 SUBROUTINES

The following is a list of subroutines presently supported. This module comes
with a simple test harness program named C<use_filsysapi.pl> .

=head1 Get list of files as directories starting from...

=item input args: path
         returns: an array containing full path

=item subroutine: C<get_dirsfiles_startingfrom(path)>
      
      example: > my @arr = get_dirsfiles_startingfrom("c:/foobar")

This method returns an array element containing the full path of the 
file/directory.

B<Subroutine:> Get list of files as directories starting from (return hash)...

 C<filsdirsHash_startingfrom(path)>

B<Example:>

C<my %hsh = filsdirsHash_startingfrom("c:/foobar")>

This method returns the full path as the key (including file/subdir) and the  
file/sub directory name as the value

B<Subroutine:> Get list of directories starting from (return array)...

C<get_dirs_startingfrom(path)>

B<Example:>

C<my @arr = get_dirs_startingfrom("c:/foobar")>

This method returns an array element containing the full path of the 
sub directory

B<Subroutine:> Get list of directories starting from (return hash)...

C<dirsHash_startingfrom(path)>

B<Example:>

C<\>my %hsh = dirsHash_startingfrom("c:/foobar")>

This method returns the full path as the key (subdir name) and the  
sub directory name as the value

B<Subroutine:> Get list of files starting from (return array)...

C<get_files_startingfrom(path)>

B<Example:>

C<my @arr = get_files_startingfrom("c:/foobar")>

This method returns an array element containing the full path of the 
file

B<Subroutine:> Get list of files starting from (return hash)...

C<filsHash_startingfrom(path)>

B<Example:>

C<my %hsh = filsHash_startingfrom("c:/foobar")>

This method returns the full path as the key (filename) and the  
file name as the value

B<Subroutine:> Get list of files and dirs for single dir (return array)...

C<subdirfilList_singledir(path)>

B<Example:>

C<>my @arr = subdirfilList_singledir("c:/foobar")>

Returns the file/subdirectory name only.
     
B<Subroutine:> Get list of subdirs for single dir (return array)...

C<subdirList_singledir(path)>

B<Example:>

C<my @arr = subdirList_singledir("c:/foobar")>

Returns the sub directory name only.

B<Subroutine:> Get list of files for single dir (return array)...

C<filList_singledir(path)>

B<Example:>

C<my @arr = filList_singledir("c:/foobar")>

Returns the filename only.   

=head1 TODO

zzz

=head1 AUTHOR

Eric Matthews        webmaster@anglesanddangles.com  http://www.anglesanddangles.com

=head1 VERSION

Version 0.90    15 feb 2004

=cut
	