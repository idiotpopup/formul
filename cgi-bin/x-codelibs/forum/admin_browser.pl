##################################################################################################
##                                                                                              ##
##  >> Administrator Browser <<                                                                 ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;
use CGI::Location qw(ParseFilePath);

$VERSIONS{'admin_browser.pl'} = 'Release 1.5 Revision 3';

LoadSupport('check_security');


##################################################################################################
## Settings

my %BaseLocations = (
                      'data'            => $DATA_FOLDER,
                      'languages'       => $LANG_FOLDER,
                      'libaries'        => $LIBARY_FOLDER,
                    );

my $IsImageRegExp = qr/(.gif|.jpe|.jpg|.jpeg)$/i;




##################################################################################################
# Check access and examine parameters.

ValidateAdminAccess();




##################################################################################################
# Get directory name.

my $Root = param('root') || '';
my $Dir  = param('dir')  || '';
my $File = param('file') || '';

if(DirContainsJumps($Dir)) { Action_Error("Invalid directory path", 1); }



my $HAS_ROOT = ($Root ne '');
my $HAS_DIR  = ($Dir  ne '');
my $HAS_FILE = ($File ne '');
my $IN_ROOT  = ! ($HAS_ROOT || $HAS_DIR);



# Prepare
my $BaseDir = '';                   # Base location, depends on virual directory start point

if ($HAS_ROOT)
{
  $BaseDir = ($BaseLocations{$Root} || '');
  if ($BaseDir eq '')
  {
    Action_Error("Invalid Root parameter", 1);
  }
  $IN_ROOT = 0;
}
elsif ($BaseDir eq '')
{
  $BaseDir = $THIS_PATH;
}


# Edit the dir a bit (removing an extra / at the end)
my $MS = "[/$S]";
   $MS =~ s/\\/\\\\/g;
$Dir   = $1   if ($Dir =~ m[(.+)$MS$]);

# Dir without trailing slash
my $DirStrip = $Dir;
my $HAS_DIR2 = ($DirStrip ne '');

# Add that trailing slash
$Dir  .= ${S} unless ($Dir eq '');


##################################################################################################
## These can only be used later

my @STYLE_FILE;
my @STYLE_SIZE;
my @STYLE_MODE;
my @STYLE_TIME;




##################################################################################################
## Admin: Browse For Files

sub Show_AdminBrowserDialog ()
{
  LoadSupport('html_tables');

  # These styles are used 3 times in this sub.
  # When html_tables is loaded, the $FONT variables
  # also have their value.
  @STYLE_FILE = ('',    'left',  $FONTEX_STYLE);
  @STYLE_SIZE = ('100', 'right', $FONT_STYLE);
  @STYLE_MODE = ('30',  'right', qq[size="1"]);
  @STYLE_TIME = ('175', 'left',  qq[size="1"]);



  # Variables
  my @Files;
  my $DirIcon;
  my $TotalPath = '';
  my $I = 0;
  my @Path = (
                '?show=admin_center'   =>   'Admin Center',
                '?show=admin_browser'  =>   'Admin File Browser'
             );


  # Get contents of directory/location
  if (! $IN_ROOT)
  {
    # Get Files
    if (-e "$BaseDir${S}$DirStrip")
    {
      @Files = GetFileBrowserFiles("$BaseDir${S}$DirStrip", $Dir);
    }
    else
    {
      # No notification whether is exists, or not
      Action_Error("Invalid directory path", 1);
    }


    # Add the directory to the treelevel html path
    my $RootParam = ($HAS_ROOT ? "&root=$Root" : '');
    push @Path, ("?show=admin_browser&root=$Root" => ucfirst($Root)) if($HAS_ROOT);
    foreach my $Path (split(/\Q${S}\E/, $Dir))
    {
      $TotalPath .= $Path;
      push @Path, ("?show=admin_browser$RootParam&dir=" . escape($TotalPath) => $Path);
      $TotalPath .= ${S};
    }

    $DirIcon = 'folder_closed.gif';
  }
  else
  {
    # No dir? build up virtual directory
    @Files   = ((sort keys %BaseLocations), $SETTINGS_FILE); # , $0);
    $DirIcon = 'folder_special.gif';
  }



  # Determine boolean values only, it's also more readable
  my $PRINT_PARENTDIR = ! $IN_ROOT;
  my $PRINT_FILES     = @Files;
  my $PRINT_TABLE     = ($PRINT_PARENTDIR || $PRINT_FILES);



  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Browser' .($HAS_ROOT? "${S}$Root" :'').($HAS_DIR? "${S}$DirStrip" :'').($HAS_FILE? "${S}$File" :'').']', 'Admin Center <FONT size="-1">[Browser]</FONT>');
  print_toolbar_HTML();
  print_treelevel_HTML(@Path);
  print_bodystart_HTML();


  if($PRINT_TABLE)
  {
    print_tableheader_HTML($TABLE_MAX_HTML,
                           'File'     =>  $STYLE_FILE[0],
                           'Size'     =>  $STYLE_SIZE[0],
                           'Mode'     =>  $STYLE_MODE[0],
                           'Created'  =>  $STYLE_TIME[0],
                           'Modified' =>  $STYLE_TIME[0],
                          );

    print qq[      <TR>\n];

    # We print To Parent Directory
    if ($PRINT_PARENTDIR)
    {
      print_ToParentDir($DirStrip);
      $I++;
    }
  }



  # Print out a list of all files
  if ($PRINT_FILES && $PRINT_TABLE)
  {
    foreach my $File (@Files)
    {
      next if ((substr($File, 0, 1)) eq '.'); # no hidden files like .htaccess

      # Define the displayed text and the real location (for stat calls)
      my $RealFile = "$BaseDir${S}$Dir$File";
      my $DispFile = $File;

      if($IN_ROOT)
      {
        if ($File eq $0 || $File eq $SETTINGS_FILE)
        {
          # This is a script file in the cgi-bin root (full path)
          $DispFile = ParseFileName($File, $S);
          $File     = $DispFile;
          $Root     = '';
          $RealFile = $File;
        }
        elsif ($BaseDir eq $THIS_PATH && ! $HAS_DIR)
        {
          # This is a filename found in the root by this script
          # This is the root-directory
          $DispFile = ucfirst($File);
          $Root     = $File;
          $RealFile = ($BaseLocations{$Root} || $RealFile);
        }
      }



      # Print the filename
      my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($RealFile);

      print qq[      </TR><TR>\n] if ($I > 0);
      if (-d $RealFile)
      {
        $size = -1; # Change so ConvertFileSize() returns ''
        my $ICON = qq[<IMG src="$IMAGE_URLPATH/folders/$DirIcon" width="18" height="18">];
        if ($IN_ROOT)
        {
          print_FileName(  qq[$ICON <A href="$THIS_URLSEC?show=admin_browser&root=$Root">$DispFile</A>]  );
        }
        else
        {
          my $File      = "$Dir$File";
          my $HAS_FILE  = ($File ne '');
          my $RootParam = ($HAS_ROOT ? "&root=$Root"           : '');
          my $DirParam  = ($HAS_FILE ? "&dir=".escape($File)   : '');
          print_FileName(  qq[$ICON <A href="$THIS_URLSEC?show=admin_browser$RootParam$DirParam">$DispFile</A>]  );
        }
      }
      else
      {
        my $ICON = qq[<IMG src="$IMAGE_URLPATH/folders/file.gif" width="18" height="18">];
        if ($File =~ m/$IsImageRegExp/)
        {
          print_FileName(  qq[$ICON $DispFile]  );
        }
        else
        {
          my $RootParam = ($HAS_ROOT ? "&root=$Root"                 : '');
          my $DirParam  = ($HAS_DIR2 ? "&dir=".escape($DirStrip)     : '');
          my $FileParam = ("&file=".escape($File));
          print_FileName(qq[$ICON <A href="$THIS_URLSEC?show=admin_browser$RootParam$DirParam$FileParam#FileView">$DispFile</A>]  );
        }
      }



      # Print the extra info of the file.
      if (defined $dev)
      {
        print_FileInfo(
                        ConvertFileSize($size, '&nbsp;'),
                        ConvertFileMode($mode),
                        DispTime($ctime),
                        DispTime($mtime),
                      );
      }
      else
      {
        print_FileInfo(
                        '&nbsp;',
                        '&nbsp;',
                        '&nbsp;',
                        '&nbsp;',
                      );
      }
      $I++;
    }

    print qq[      </TR>\n];
    print qq[    </TABLE>\n];
  }
  else
  {
    if($PRINT_TABLE)
    {
      print qq[      </TR>\n];
      print qq[    </TABLE>\n];
    }


    # Directory is empty! Should it be deleted?
    $File     = ParseFileName($DirStrip, ${S});
    $DirStrip = ParseFilePath($DirStrip, ${S});
    $DirStrip = "" if $DirStrip eq ".";

    print <<DELETE_EMPTYDIR_HTML;
    <P>
    This directory is empty!
DELETE_EMPTYDIR_HTML

    if(! ($DirStrip eq "" && $File eq ""))
    {
      print <<DELETE_EMPTYDIR_HTML;
    <FORM method="POST" action="$THIS_URLSEC">
      <INPUT type="hidden" name="action" value="admin_browseredit">
      <INPUT type="hidden" name="root" value="$Root">
      <INPUT type="hidden" name="dir" value="$DirStrip">
      <INPUT type="hidden" name="file" value="$File">
      <INPUT type="submit" name="submit_delete" class="CoolButton" value="  Delete It  ">
    </FORM>
DELETE_EMPTYDIR_HTML
  }
    print_footer_HTML();
  }



  # Then, if a file is specified, show it.
  if ($HAS_FILE)
  {
    if ( $File =~ m/$IsImageRegExp/)
    {
      print qq[    \n    <BR>\n    <A name="FileView"><FONT color="#FF0000">Error: Images can't be edited here!</FONT></A>\n];
    }
    else
    {
      # Print FORM HTML codes
      print <<FILE_EDIT_FORM;
      <A name="FileView">
        <FORM method="POST" action="$THIS_URLSEC">
          <INPUT type="hidden" name="action" value="admin_browseredit">
          <INPUT type="hidden" name="root" value="$Root">
          <INPUT type="hidden" name="dir" value="$DirStrip">
          <INPUT type="hidden" name="file" value="$File">
          $TABLE_MAX_HTML
FILE_EDIT_FORM
      print qq[            <TR><TD>$Root] . ($HAS_ROOT ? ${S} : '') . qq[$Dir$File</TD></TR>\n];


      # Print the file...
      if (substr($File, 0, 1) ne '.')
      {
        LoadModule('HTML::EscapeASCII;');
        my $DATA = new File::PlainIO("$BaseDir${S}$Dir$File", MODE_READ);
        if(defined $DATA)
        {
          local($|) = 1; # We don't want to overload the webserver with tons of string space! So buffer flushing on!
          print qq[            <TR><TD><TEXTAREA name="msg" class="editbox" ROWS="24" COLS="100">]; # no \n

          while(defined $DATA->readline())
          {
            FormatFieldHTML($_);
            print "$_\n";
          }
          close(FILE);

          print <<FILE_EDIT_FORM;
</TEXTAREA></TD></TR>
            <TR><TD></TD></TR>
            <TR><TD></TD></TR>
            <TR><TD></TD></TR>
            <TR><TD><INPUT type="submit" name="submit_save" class="CoolButton" value="    Save    "> &nbsp; <INPUT type="submit" name="submit_delete" class="CoolButton" value="    Delete    " onClick="this.form.msg.value = ''; return true"> &nbsp; <INPUT type="reset" class="CoolButton" value="    Reset    "></TD></TR>
FILE_EDIT_FORM
        }
        else
        {
          print qq[            <TR><TD><FONT color="#FF0000">$!</FONT></TD></TR>\n];
        }
      }
      else
      {
        print qq[            <TR><TD><FONT color="#FF0000">No such file or directory</FONT></TD></TR>\n];
      }

      print qq[          </TABLE>\n];
      print qq[        </FORM>\n];
      print qq[      </A>\n];
    }
  }

  print_footer_HTML();
}



##################################################################################################
## Edit a file.


sub Action_AdminBrowserEdit ()
{
  # Make checks for .htaccess files and images.
  Action_Error("Error: Images can't be edited here!") if ( $File =~ m/$IsImageRegExp/);
  Action_Error("You're not allowed to change or delete this file!", 1) if ( substr($File, 0, 1) eq '.' ); # files like .htaccess

  if (param('submit_delete'))
  {
    my $FileToDelete = "$BaseDir${S}$Dir$File";
    if((stat($FileToDelete))[4] != $<
    || ($Dir eq "" && $File eq ""))
    {
      Action_Error("You're not allowed to delete this file!", 1);
    }

    # Delete the file, or empty the directory if it's a directory.
    if   (-f $FileToDelete)
    {
      unlink($FileToDelete) or die "Can't delete file: $!";
    }
    elsif(-d $FileToDelete)
    {
      my $HasFiles = '';
      opendir(DIR, $FileToDelete) or die "Can't open directory: $!";
        while($HasFiles = readdir(DIR))
        {
          if ($HasFiles eq '.' || $HasFiles eq '..') { $HasFiles = undef; }
          else { last if(length($HasFiles)); }
        }
      closedir(DIR);

      if ($HasFiles) { Action_Error("This directory cann't be deleted; it's not empty!"); }
      rmdir($FileToDelete) or die "Can't delete directory: $!";

      # Return to the browser
      print redirect("$THIS_URLSEC?show=admin_browser" . ($HAS_ROOT ? "&root=$Root" : '') . ($HAS_DIR2 ? "&dir=".escape($DirStrip) : ''));
      exit;
    }
    else
    {
      Action_Error("You're not allowed to delete this kind of file!", 1);
    }
  }
  else
  {
    # Set the new filecontents
    my $Contents = (param('msg') || '');
    dbSetFileContents("$BaseDir${S}$Dir$File", "Can't save $Dir$File" => $Contents);
  }

  # Return to the browser
  print redirect("$THIS_URLSEC?show=admin_browser" . ($HAS_ROOT ? "&root=$Root" : '') . ($HAS_DIR2 ? "&dir=".escape($DirStrip) : ''));
  exit;
}



##################################################################################################
## Get the filename of a path/path/path/filename string

sub GetFileBrowserFiles ($$)
{ my($Dir, $DirError) = @_;
  my @Files;
  opendir(PATH, $Dir) or die "Can't browse to directory $DirError: $!";
  {
    @Files = grep( !/^\.\.?$/, readdir PATH);
  }
  closedir(PATH);

  my $RE_NUMSORT = qr/\d+(\.\w+)?/;

  my %IsDir;
  my %Special;
  foreach(@Files)
  {
    $IsDir{$_}   = -d "$Dir${S}$_"  ? 1 : 0;
    $Special{$_} = m[^$RE_NUMSORT$] ? length($_) : 0;
  }

  @Files = sort
           {
                  $IsDir{$b} <=> $IsDir{$a}
             || $Special{$a} <=> $Special{$b}
             ||       uc($a) cmp uc($b)
           } @Files;
  return @Files;
}

sub ParseFileName ($;$) #(STRING FileName[, STRING PathSep]) >> STRING FileName
{ my $pos = rindex($_[0], ($_[1] || '/'));
  return substr($_[0], $pos + 1) if $pos != -1;
  return $_[0];
}

sub DirContainsJumps ($)
{ my($Dir) = @_;
  $Dir =~ s~\Q$S~/~g;

  return 1 if $Dir eq '.';
  return 1 if $Dir eq '..';
  return 1 if index($Dir, '/..')      != -1;
  return 1 if index($Dir, '//')       != -1;

  if(length($Dir) >= 3)
  {
    return 1 if substr($Dir, 0,3) eq '../';
  }

  return 0;
}


##################################################################################################
## Convert File Information


sub ConvertFileSize ($;$)
{ my($size, $unknown) = @_;
  if ($size >= 1024)
  {
   $size = int($size / 1024 + 0.5);
   if ($size >= 1024) { $size = int($size / 1024 + 0.5) . " MB"; }
   else               { $size .= " kB"; }
  }
  elsif ($size >= 0)  { $size .= " bytes"; }
  else                { $size = $unknown; }
  return $size;
}

sub ConvertFileMode ($)
{ my($mode) = @_;
  return sprintf("%03o", $mode & 0777)
}


##################################################################################################
## Rows of the files table

sub print_ToParentDir ($)
{ my($Dir) = @_;
  my $DirBack = ParseFilePath($Dir, $S);

  $DirBack = ($HAS_DIR ? "&root=$Root" : '') . ($DirBack ne '.' && $DirBack ne '' ? "&dir=" . escape($DirBack) : '');

  print_FileName(  qq[<IMG src="$IMAGE_URLPATH/folders/folder_special.gif" width="16" height="16"> <A href="$THIS_URLSEC?show=admin_browser$DirBack">To Parent Directory</A>]  );
  print_FileInfo(
                  '&nbsp;',
                  '&nbsp;',
                  '&nbsp;',
                  '&nbsp;',
                 );
}

sub print_FileName ($)
{ my($file) = @_;
  print_tablecell_HTML( $file     =>  @STYLE_FILE );
}

sub print_FileInfo ($$$$)
{ my($size, $mode, $ctime, $mtime) = @_;
  print_tablecell_HTML( $size     =>  @STYLE_SIZE );
  print_tablecell_HTML( $mode     =>  @STYLE_MODE );
  print_tablecell_HTML( $ctime    =>  @STYLE_TIME );
  print_tablecell_HTML( $mtime    =>  @STYLE_TIME );
}

1;
