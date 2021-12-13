##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'db_subjects.pl'} = 'Release 1.6';


##################################################################################################
## Subjects Index Database


# File names for the data files
sub FileName_Subject  ($) { return "$DATA_FOLDER${S}subjects${S}".NameGen($_[ID]).".sub"; }
sub FileName_Subjects ()  { return "$DATA_FOLDER${S}index.lst"; }
sub FileName_OldIndex ()  { return "$DATA_FOLDER${S}subjects.lst"; }


# Conversion... X-Forum 1.3
my $OldFile = FileName_OldIndex();
if(-e $OldFile)
{
  my @Subjects = dbGetFileContents($OldFile, FILE_NOERROR);
  @Subjects = map { "--$_" } @Subjects;
  unshift @Subjects, 'Subjects';
  dbSaveSubjects(@Subjects);
  unlink $OldFile or die "Can't delete/convert old subject index file: $!";
}


# Make the subject
# RULE: Subject shouldn't exist already.
sub dbMakeSubject ($)
{
  my $Index = FileName_Subjects();
  if(! -e $Index)
  {
    dbSetFileContents($Index, "Can't modify subjects index database" => "Subjects", "--$_[ID]");
  }
  else
  {
    dbAppendFileContents($Index, "Can't modify subjects index database" => "--$_[ID]");
  }
}

sub dbDelSubject ($$)
{ my($SubjectDel, $SubjectTo) = @_;

  LoadSupport('db_topics');

  my @Subjects  = dbGetSubjects();

  my @SubjectDel = dbGetSubjectInfo($SubjectDel, 1);
  my @SubjectTo  = dbGetSubjectInfo($SubjectTo,  1);

  # Delete the subject from the index
  {
    my $EmptyCat = 1;

    for(my $I = @Subjects-1; $I >= 0; $I--)
    {
      my $Subject = $Subjects[$I];  # Copy element
      if(! dbSubjectIsTitle($Subject))
      {
        if($Subject eq $SubjectDel)
        {
          splice(@Subjects, $I, 1);
          if($EmptyCat && $I > 0)
          {
            my $PrevItem = $Subjects[$I - 1]; # Copy element
            if(dbSubjectIsTitle($PrevItem))
            {
              # Remove the category too!
              $I--;
              splice(@Subjects, $I, 1);
            }
          }
        }
        else
        {
          $EmptyCat = 0;
        }
      }
      else
      {
        $EmptyCat = 1;
      }
    }
  }

  # Move all old topics
  {
    dbMoveTopics($SubjectDel => $SubjectTo);

    # Update the subject's statistics...
    $SubjectTo[DB_SUBJECT_TOPICNUM] += $SubjectDel[DB_SUBJECT_TOPICNUM];
    $SubjectDel[DB_SUBJECT_TOPICNUM] = 0;
    dbSaveSubjectInfo(@SubjectDel);
    dbSaveSubjectInfo(@SubjectTo);
  }


  # Save index
  dbSaveSubjects(@Subjects);

  # Delete the subject files...
  unlink(FileName_Subject($SubjectDel)) or die "Can't remove subject '$SubjectDel' file: $!";
  unlink FileName_Topics($SubjectDel);  # might be removed already
}


# Get / Set the subject's database
sub dbGetSubjects  ()     { return dbGetFileContents(FileName_Subjects(), FILE_NOERROR); }

# RULE: Subject should exist.
sub dbSaveSubjects (@)    { dbSetFileContents(FileName_Subjects(), 'subjects database' => @_); }



##################################################################################################
## Subject Information



# Save the subject information
sub dbSaveSubjectInfo (@) { dbSetFileContents(FileName_Subject($_[ID]), "Can't create subject '$_[ID]' database" => @_); }

sub dbSubjectIsTitle
{ my($Subject) = @_;

  return 1 if($Subject !~ m[^--]);

  $Subject =~ s/^--(.+)/$1/;
  if($Subject eq $_[0])
  {
    my @C=caller();
    die "Invalid subject passed through dbSubjectIsTitle: $Subject! at $C[1] line $C[2]\n";
  }
  else
  {
    $_[0] = $Subject; # Update automatically.
    return 0;
  }
}

sub dbGetSubjectInfo
{ my ($Subject, $Error) = @_;

  # Get the file name
  Action_Error($MSG[SUBJECT_NOTEXIST]) if ($Error && not dbSubjectExist($Subject));

  # Get the data structure
  my @SubjectInfo = dbGetFileContents(FileName_Subject($Subject), FILE_NOERROR, DB_SUBJECT_FIELDS);
  if ($Error && dbSubjectInvalid($Subject, @SubjectInfo))
  {
    die "The database of the member '$Subject' is corrupted!\nPlease contact the webmaster to fix the problem.\n";
  }


  # Update default values
  $SubjectInfo[DB_SUBJECT_TOPICNUM]      ||= 0;
  $SubjectInfo[DB_SUBJECT_LASTPOSTDATE]  ||= 0;
  $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC] ||= 0;
  $SubjectInfo[DB_SUBJECT_MODERATORS]    ||= 'admin';
  $SubjectInfo[DB_SUBJECT_GROUPS]        ||= 'everyone';

  return @SubjectInfo;
}


sub dbGetSubjectPages
{ my ($SubjectID, $TopicNum) = @_;
  if (not defined $TopicNum) { $TopicNum = (dbGetSubjectInfo($SubjectID))[DB_SUBJECT_TOPICNUM]; }
  return int(($TopicNum - 1) / $PAGE_TOPICS) + 1
}


sub dbIsSubjectModerator
{ my($ModeratorList, $Member) = @_;
  return 0 if($Member eq '');
  foreach my $Moderator (split(/,/, $ModeratorList))
  {
    if(length($Moderator)) { return 1 if ($Moderator eq $Member); }
  }
  return 0;
}

sub dbSubjectCount ()
{
  my $Count = 0;
  foreach my $Subject (dbGetSubjects())
  {
    if(! dbSubjectIsTitle($Subject))
    {
      $Count++ unless dbSubjectInvalid($Subject, dbGetSubjectInfo($Subject))
    }
  }
  return $Count;
}


sub dbSubjectExist   ($)   { return -e FileName_Subject($_[ID]); }
sub dbSubjectInvalid ($@)  { return ($_[ID] || '') eq '' || $_[ID] ne ($_[ID + 1] || '');        }
sub dbSubjectIndexExist () { return -e FileName_Subjects;       }

sub dbSubjectFileInvalid ($)
{
  return dbSubjectExist($_[ID])
      && dbSubjectInvalid($_[ID], dbGetFileContents(FileName_Subject($_[ID]), FILE_NOERROR, 0,ID,1));
}

1;
