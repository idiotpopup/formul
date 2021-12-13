##################################################################################################
##                                                                                              ##
##  >> Administrator Log Files <<                                                               ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'admin_logfiles.pl'} = 'Release 1.4';

LoadSupport('check_security');

my @LogErrorCodes = qw( ERROR PASSXS BANXS MAILERR REPAIRERR );
my $LOG_ITEMCLR = '#666666';
my $LOG_DATECLR = '#666666';
my $LOG_ERRCLR  = '#FF0000';


# Check for admin member access.
ValidateAdminAccess();

# Sorting of the dates...
my %MonthCode = (
                  jan => 1,
                  feb => 2,
                  mar => 3,
                  apr => 4,
                  may => 5,
                  jun => 6,
                  jul => 7,
                  aug => 8,
                  sep => 9,
                  oct => 10,
                  nov => 11,
                  dec => 12,
                );


##################################################################################################
## View Log Files

sub Show_AdminLogFilesDialog
{
  LoadSupport('html_interface');

  # Get param
  my ($LogFile) = (param('logfile') || '');


  my (@Files, $LogYear, $LogMonth, $LogDay, $LogDisp);
  my @Path = ('?show=admin_center'=>'Admin Center', '?show=admin_logfiles'=>'Logging Files');
  my $FolderType;


  if ($LogFile eq '')
  {
    $FolderType = 'closed';

    # Show all log files
    opendir(PATH, "$DATA_FOLDER${S}logs") or die "Can't read log folder dir: $!";
      @Files = grep { /\.log$/ } readdir PATH;
    closedir(PATH);
  }
  else
  {
    $FolderType = 'open';

    Action_Error("Illegal directory path included", 1) if (index($LogFile, "${S}..") != -1 || index($LogFile, '/..') != -1 || index($LogFile, "${S}${S}") != -1 || index($LogFile, '//') != -1);
    Action_Error("Illegal directory path included", 1) if (length($LogFile) >= 3 && substr($LogFile, 3) eq '../');



    # Split logfile
    (undef, $LogYear, $LogMonth, $LogDay) = split(/^(\d+)([a-zA-Z]+)(\d+)$/, $LogFile, 3);

    if(defined $LogYear && defined $LogMonth)
    {
      # Show log files of current month
      opendir(PATH, "$DATA_FOLDER${S}logs") or die "Can't read log folder dir: $!";
        @Files = grep { /^$LogYear$LogMonth(\d+)\.log$/ } readdir PATH;
      closedir(PATH);

      $LogMonth   = ucfirst($LogMonth);
      $LogDisp = "$LogYear, $LogMonth $LogDay";
    }
    else
    {
      # Show log files of all members
      opendir(PATH, "$DATA_FOLDER${S}logs") or die "Can't read log folder dir: $!";
        @Files = grep { /^[a-zA-Z]([a-zA-Z0-9]+)\.log$/ } readdir PATH;
      closedir(PATH);

      LoadSupport('db_members');
      $LogDisp = dbGetMemberName($LogFile);
    }
    push @Path, (qq[?show=admin_logfiles&logfile=$LogFile#FileView" name="FileView]=>$LogDisp);
  }


  # Print HTML
  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Log Files]', 'Admin Center <FONT size="-1">[Log Files]</FONT>');
  print_toolbar_HTML();
  print_treelevel_HTML(@Path);
  print_bodystart_HTML();
  print qq[    <A href="$THIS_URL?show=admin_browser&root=data&dir=logs">Edit logging Files</A><BR><BR>\n];

  if (@Files)
  {
    # Convert and split the file names
    @Files        = ParseLogFiles(@Files);
    my $PrevYear  = 0;
    my $PrevMonth = '';


    foreach my $LogData (@Files)
    {
      my ($Member, $Year, $Month, $Day) = @{$LogData};

      if(defined $Year && defined $Month)
      {
        my $LogDate  = "$Year$Month$Day";
        if ($PrevYear != $Year || $PrevMonth ne $Month)
        {
          print qq[    <P>\n] if ($PrevYear != 0);
          $PrevYear  = $Year;
          $PrevMonth = $Month;
          $Month     = ucfirst_lcrest($Month);
          print qq[    <IMG src="$IMAGE_URLPATH/folders/logfolder_$FolderType.gif" width="16" height="16"> <B>$Year, $Month:</B>\n];
        }
        else
        {
          $Month     = ucfirst_lcrest($Month);
        }

        if($LogDate eq $LogFile) { print qq[    <A href="$THIS_URLSEC?show=admin_logfiles&logfile=$LogDate#FileView"><B>$Day</B></A>\n] }
        else                     { print qq[    <A href="$THIS_URLSEC?show=admin_logfiles&logfile=$LogDate#FileView">$Day</A>\n] }
      }
      else
      {
        if(not defined $Member)
        {
          print qq[    $LogFile\n];
        }
        else
        {
          if ($PrevYear != -1)
          {
            # Just a hack with some variabale that will not be -1, if the first file get's printed.
            print qq[    <P>\n];
            print qq[    <IMG src="$IMAGE_URLPATH/folders/logfolder_$FolderType.gif" width="16" height="16"> <B>Users:</B>\n];
            $PrevYear = -1;
          }

          if($Member eq $LogFile) { print qq[    <A href="$THIS_URLSEC?show=admin_logfiles&logfile=$Member#FileView"><B>$Member</B></A>\n] }
          else                    { print qq[    <A href="$THIS_URLSEC?show=admin_logfiles&logfile=$Member#FileView">$Member</A>\n] }
        }
      }
    }
  }
  else
  {
    print qq[    No log files found!\n] unless($LogFile);
  }


  if ($LogFile ne '')
  {
    LoadSupport('html_tables');

    # Get contents
    if (! -e "$DATA_FOLDER${S}logs${S}$LogFile.log")
    {
      Action_Error("That logfile does not exist!");
    }


    # Print a header.
    print_tableheader_HTML($TABLE_MAX_HTML, $LogDisp=>'');
    print qq[      <TR><TD>\n];

    my $LOG = new File::PlainIO("$DATA_FOLDER${S}logs${S}$LogFile.log", MODE_READ, "Can't open log file $LogFile");
    while(defined $LOG->readline())
    {
      # Color the text.
      s{(\s)(\w+)=}                                   {$1<FONT color="$LOG_ITEMCLR">$2</FONT>=}g;              # ' Item='
      s{<BR>}                                         { | }g;                                                  # Line break escape codes
      s{ *$}                                          {</NOBR><BR>\n}g;                                        # Line breaks at the end
      foreach my $Error (@LogErrorCodes) {
        s{\[([A-Za-z0-9: ]+?)\] $Error:\t(.*)\n}      {\[$1\] <FONT color="$LOG_ERRCLR">$Error:</FONT>\t$2\n}g # Errors after the [dates]
      }
      s{\[([A-Za-z0-9: ]+?)\](.*\t)(.*)\n}            {<CODE><FONT color="$LOG_DATECLR">\[$1\]</FONT>$2</CODE>$3\n}g;        # [Dates] at the begin  (should be done the last)

      print "        <NOBR>$_";
    }
    $LOG->close();

    # Print a footer
    print qq[      </TD></TR>\n];
    print qq[    </TABLE>\n];
  }

  print_footer_HTML();
}



sub ParseLogFiles (@)
{
  return sort
         {
           return @$a[0] cmp @$b[0]                      # Compare file names
           unless defined @$a[1]                         # unless: we have a year
               && defined @$b[1];                        # and:    another year

                          @$b[1] <=> @$a[1]              # Compare years
           || $MonthCode{@$b[2]} <=> $MonthCode{@$a[2]}  # Compare month names
           ||             @$a[3] <=> @$b[3]              # Compare days
           ||             @$a[0] cmp @$b[0]              # Compare file names
         }
         map
         {
           [ /^((\d+)([a-zA-Z]+)(\d+)|.+)\.log$/ ]
         }     # Split the filename in an anonymous array
         @_;                                             # ...foreach filename (arglist)
}

sub ucfirst_lcrest ($) { return uc(substr($_[0], 0,1)).lc(substr($_[0], 1)) }

1;
