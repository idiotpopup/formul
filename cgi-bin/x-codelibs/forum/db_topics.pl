##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'db_topics.pl'} = 'Release 1.4';

LoadSupport('db_subjects');
use HTML::EscapeASCII;


##################################################################################################
## Topics Index Database


# Filenames for the topic data files
sub FileName_Topic  ($) { return "$DATA_FOLDER${S}topics${S}".NameGen($_[ID]).".top";  }
sub FileName_Topics ($) { return "$DATA_FOLDER${S}subjects${S}".NameGen($_[ID]).".in"; }


# Make a new topic
sub dbMakeTopic ($$)
{ # RULE: Topic should not exist
  my ($Topic, $Subject) = @_;

  my @SubjectInfo = dbGetSubjectInfo($Subject, 1);
  {
    dbAppendFileContents(FileName_Topics($Subject), "Can't modify topics index database" => $Topic);
    $SubjectInfo[DB_SUBJECT_TOPICNUM]++;
  }
  dbSaveSubjectInfo(@SubjectInfo);

  UpdateTopicStat();
}


# Get/Set all the topics in a subject
sub dbGetTopics ($)
{
  return dbGetFileContents(FileName_Topics($_[ID]), FILE_NOERROR);
}

sub dbDelTopic ($$)
{ # RULE: SubjectInfo is updated, topic id is validated
  LoadSupport('db_stats');
  unlink FileName_Topic($_[ID]) or die "Can't delete topic '$_[ID]': $!";
  unlink FileName_Posts($_[ID]) or die "Can't delete posts for topic '$_[ID]': $!";
  UpdateTopicStat(-1);
  UpdatePostStat(-$_[1]);
}

sub dbDelTopics ($$$)
{ # RULE: Subject Index file is updated
  # topic files will be deleted aswell.
  LoadSupport('db_stats');
  unlink FileName_Topics($_[ID]) or die "Can't delete subject index database: $!";
  UpdateTopicStat(-$_[1]);
  UpdatePostStat(-$_[2]);
}


sub dbSaveTopics ($@)
{ # RULE: Subject should exist.
  # RULE: The sticky topics are unharmed
  my $Subject = shift;
  dbSetFileContents(FileName_Topics($Subject), "Topics index database of subject '$Subject'", @_);
}



##################################################################################################
## Topic Information


sub dbSaveTopicInfo (@)
{ my $TopicData = '';
  dbSetFileContents(FileName_Topic($_[ID]), "Can't create topic '$_[ID]' database" => @_);
}


sub dbGetTopicInfo ($;$)
{ my ($Topic, $Error) = @_;


  # Read the data file
  if ($Error && ! dbTopicExist($Topic)) { Action_Error($MSG[TOPIC_NOTEXIST]) }

  my @TopicInfo = dbGetFileContents(FileName_Topic($Topic), FILE_NOERROR, DB_TOPIC_FIELDS);
  if ($Error && dbTopicInvalid($Topic, @TopicInfo))
  {
    die "The database of the topic '$Topic' is corrupted!\n"
      . "Please contact the webmaster to fix the problem.\n";
  }

  # Change some values that should have an other default value
  $TopicInfo[DB_TOPIC_DATE]         ||= 0;
  $TopicInfo[DB_TOPIC_LASTPOSTDATE] ||= 0;
  $TopicInfo[DB_TOPIC_POSTNUM]      ||= 0;
  $TopicInfo[DB_TOPIC_VIEWS]        ||= 0;
  $TopicInfo[DB_TOPIC_LOCKED]       ||= 0;
  $TopicInfo[DB_TOPIC_STICKY]       ||= 0;
  $TopicInfo[DB_TOPIC_ICON]         ||= 'default';
  return @TopicInfo;
}

sub dbGetTopicPages (;$$)
{ my ($Topic, $PostNum) = @_;
  if (not defined $PostNum) { $PostNum = (dbGetTopicInfo($Topic))[DB_TOPIC_POSTNUM]; }
  return int(($PostNum - 1) / $PAGE_POSTS) + 1;
}



##################################################################################################

sub dbTopicMoveToTop ($$;$)
{ # RULE: The sticky topics are on top.
  # RULE: The statistics are handled by other subroutines
  # RULE: Removing the old topic is done by an other subroutine

  # We search the array in reverse, since the
  # topic will mostly be found faster that way.

  my($TopicID, $Subject, $InternalMove) = @_;
  my @Topics = dbGetTopics($Subject);

  # Bump to top effect
  if($InternalMove)
  {
    my $Found = 0;
    topic:for(my $I = @Topics-1; $I >= 0; $I--)
    {
      if($Topics[$I] eq $TopicID)
      {
        splice(@Topics, $I, 1);
        $Found = 1;
        last topic;
      }
    }
    $Found or die "Topic $TopicID can't be moved to the top in subject $Subject\n";
  }

  # Is this a sticky topic?
  my @TopicInfo = dbGetTopicInfo($TopicID, 1);
  if($TopicInfo[DB_TOPIC_STICKY])
  {
    push @Topics, $TopicID;
  }
  else
  {
    # Remove the sticky topics
    my @Sticky;
    sticky:for(my $I = @Topics-1; $I >= 0; $I--)
    {
      my @TopicInfo = dbGetTopicInfo($Topics[$I]);
      if(dbTopicInvalid($Topics[$I], @TopicInfo))
      {
        splice(@Topics, $I, 1); # Get out!
      }
      elsif($TopicInfo[DB_TOPIC_STICKY])
      {
        # Remove the topic, and add it to the @Sticky list
        unshift @Sticky, splice(@Topics, $I, 1);
      }
      else
      {
        last sticky;
      }
    }

    push @Topics, $TopicID;
    push @Topics, @Sticky;
  }

  dbSaveTopics($Subject, @Topics);
}


sub dbMoveTopics
{ my($SubjectFrom, $SubjectTo) = @_;

  return if $SubjectFrom eq $SubjectTo;

  my %LastPost; # Keep track of post dates if we want to re-sort the topics
  my @OldTopics = dbGetTopics($SubjectFrom);
  my @NewTopics = dbGetTopics($SubjectTo);
  my @OldSticky;
  my @NewSticky;
  my $InSticky = 1;

  return if @OldTopics == 0;

  # Splice the new topics into a list of normal and sticky topics
  topic:for(my $I = @NewTopics-1; $I >= 0; $I--)
  {
    my $ID = $NewTopics[$I];
    my @TopicInfo = dbGetTopicInfo($ID, 0);

    if(dbTopicInvalid($ID, @TopicInfo))
    {
      splice(@NewTopics, $I, 1); # Get out!
    }
    else
    {
      if($TopicInfo[DB_TOPIC_STICKY])
      {
        unshift @NewSticky, splice(@NewTopics, $I, 1);
      }
      $LastPost{$ID} = $TopicInfo[DB_TOPIC_LASTPOSTDATE] if $TOPIC_BUMPTOTOP;
    }
  }


  topic:for(my $I = @OldTopics-1; $I >= 0; $I--)
  {
    my $ID = $OldTopics[$I];
    my @TopicInfo = dbGetTopicInfo($ID, 0);

    if(dbTopicInvalid($ID, @TopicInfo))
    {
      splice(@OldTopics, $I, 1); # Get out!
    }
    else
    {
      if($TopicInfo[DB_TOPIC_STICKY])
      {
        unshift @OldSticky, splice(@OldTopics, $I, 1);
      }

      $LastPost{$ID} = $TopicInfo[DB_TOPIC_LASTPOSTDATE] if $TOPIC_BUMPTOTOP;

      $TopicInfo[DB_TOPIC_SUBJECT] = $SubjectTo;
      dbSaveTopicInfo(@TopicInfo);
    }
  }

  if($TOPIC_BUMPTOTOP)
  {
    my @Topics = sort { $LastPost{$a} <=> $LastPost{$b} } @OldTopics, @NewTopics;
    my @Sticky = sort { $LastPost{$a} <=> $LastPost{$b} } @OldSticky, @NewSticky;

    # Clearup
    @NewTopics = ();
    @NewSticky = ();
    @OldTopics = ();
    @OldSticky = ();

    # Write new sorted list into the database
    dbSaveTopics($SubjectTo => @Topics, @Sticky);
  }
  else
  {
    # Just append the topics to the list, when you don't expect any sorting.
    dbSaveTopics($SubjectTo => @OldTopics, @NewTopics, @OldSticky, @NewSticky);
  }
  unlink FileName_Topics($SubjectFrom) or die "Can't delete subject index database: $!\n";
}


##################################################################################################
## Portability

sub dbTopicExist ($)    { return -e FileName_Topic($_[ID]);                             }
sub dbTopicInvalid ($@) { return ($_[ID] || '') eq '' || $_[ID] ne ($_[ID + 1] || '');  }

sub dbTopicFileInvalid ($)
{
  return dbTopicExist($_[ID])
      && dbTopicInvalid($_[ID], dbGetFileContents(FileName_Topic($_[ID]), FILE_NOERROR, 0,ID,1));
}

1;
