##################################################################################################
##                                                                                              ##
##  >> Log File Dumper <<                                                                       ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'logprint.pl'} = 'Release 1.4';

sub LOG(){1}
sub NO_LOG(){0}

use vars qw( %LogActions );
require "$DATA_FOLDER${S}settings${S}logactions.cfg";


##################################################################################################
## LOG File Support

sub WriteLog ($$@) #(STRING id, STRING Member, ARRAY text)
{
  if (($DATA_FOLDER || '') ne '')
  {
    # Get parameters
    my $id = uc shift; $id = ($id || "UNDEF");
    my $Member = shift;
    my @Log = @_;
    chomp @Log;


    # Don't log if we blocked it.
    return if exists $LogActions{$id}
           && (! defined $LogActions{$id} || $LogActions{$id} == NO_LOG);



    # Make log folder if not created yet!
    if (! -e "$DATA_FOLDER${S}logs")
    {
      return;
      #mkdir("$DATA_FOLDER${S}logs", 0777) or die "Can't create log storage folder: $!";
    }

    # Determine date/time
    my (@MONTH_NAMES) = qw(jan feb mar apr may jun jul aug sep oct nov dec);
    my ($LogTime)     = scalar(gmtime());
    my ($Sec, $Min, $Hour, $MonthDay, $Month, $Year, $WeekDay, $YearDay, $IsDST) = gmtime();
    $Year += 1900;

    # Determine Filename and contents
    my $Log;
    if ($Member)
    {
      $Log = $Member;
    }
    else
    {
      $MonthDay = "0$MonthDay" unless ($MonthDay > 9);
      $Log = "$Year$MONTH_NAMES[$Month]$MonthDay";
    }
    $Log = "$DATA_FOLDER${S}logs${S}$Log.log";

    my $AddText = '';
    $AddText .= " IP=$ENV{'REMOTE_ADDR'}"                if($ENV{'REMOTE_ADDR'});
    $AddText .= " Host=" . ($ENV{'REMOTE_HOST'} || '?')  if (($ENV{'REMOTE_HOST'} || '') ne ($ENV{'REMOTE_ADDR'} || '') || !defined $ENV{'REMOTE_ADDR'});
    $AddText .= " BROWSER=" . user_agent                 if($id eq 'ERROR');

    $AddText = "[$LogTime GMT] $id:\t" . join('', @Log) . "$AddText\n";


    # Fixed race condition: after we opened and locked this file,
    # we check if this is the first time!
    my $LOG   = new File::PlainIO($Log, MODE_WRITE, "Can't write to log $Log file");
    my $First = ($LOG->stat)[7] == 0;  # 0 bytes in file

    if($First) { $LOG->writeline("[$LogTime GMT] LOGINIT:\tURL=$THIS_URL SERVER=" . (server_software || '???') . "\n") }
    else       { $LOG->seekeof() }

    $LOG->writeline($AddText);
    $LOG->close();
  }
}

1;
