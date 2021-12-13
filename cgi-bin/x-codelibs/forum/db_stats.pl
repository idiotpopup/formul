##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'db_stats.pl'} = 'Release 1.6';



##################################################################################################
## Members Database Index



sub FileName_Stats ()  { return "$DATA_FOLDER${S}contents.stat"; }


##################################################################################################
## I don't know where to put it else.
## This is used for some database functions.


sub GenerateID ($;$$)
{ my($Index, $RelativeChange, $MemberAdded) = @_;
  my @ID;
  my $ID;

  $RelativeChange ||= 1;

  my $IDFILE = new File::PlainIO(FileName_Stats(), MODE_RDWR, "Can't generate ID");
  {
    @ID = $IDFILE->readlines();

    # Append the rest of the remaining fields, if they don't exist
    push @ID, ("0") x (DB_STAT_FIELDS - @ID) if (@ID < DB_STAT_FIELDS);

    $ID[$Index] += $RelativeChange;
    $ID = $ID[$Index];

    if($MemberAdded)
    {
      $ID[DB_STAT_NEWMEMBER]     = $MemberAdded;
      $ID[DB_STAT_NEWMEMBERDATE] = SaveTime();
    }

    $IDFILE->clear();

    $IDFILE->writelines(@ID);
    $IDFILE->close();
  }

  return $ID;
}

sub TopicIDGen          { return GenerateID(DB_STAT_TOPICID) }
sub MessageIDGen        { return GenerateID(DB_STAT_MSGID)   }

sub UpdateTopicStat     { GenerateID(DB_STAT_TOPICNUM, $_[0])        } # No return
sub UpdateMemberStat    { GenerateID(DB_STAT_MEMBERNUM, $_[0],$_[1]) } # just update one
sub UpdatePostStat      { GenerateID(DB_STAT_POSTNUM, $_[0])         } # of the fields
sub UpdateGuestPostStat { GenerateID(DB_STAT_GUESTPOSTNUM, $_[0])    }

sub dbGetStats
{
  my @Stat = dbGetFileContents(FileName_Stats(), FILE_NOERROR, DB_STAT_FIELDS);
  $_ ||= 0 foreach @Stat;
  $Stat[DB_STAT_NEWMEMBER] ||= '';
  return @Stat;
}

sub dbSaveStats
{
  dbSetFileContents(FileName_Stats(), "Can't save stats", @_);
}

1;
