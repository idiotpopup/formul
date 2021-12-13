##################################################################################################
##                                                                                              ##
##  >> Move Topics <<                                                                           ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_movetopic.pl'} = 'Release 1.3';

LoadSupport('db_topics');
LoadSupport('db_groups');
LoadSupport('check_security');


#################################################################################################
## Check access and examine parameters


ValidateMemberCookie();

# Get the topic parameter
my $Topic     = (param('topic') || '');
my @TopicInfo = dbGetTopicInfo($Topic, 1);


#################################################################################################
## Show Add Topic

sub Show_MoveTopicDialog ()
{
  LoadSupport('html_fields');


  # Locals
  my $Title      = '';
  my $Moderators = '';
  my $Subject    = $TopicInfo[DB_TOPIC_SUBJECT];
  my $Found      = 0;
  my @Options;


  my @Subjects = dbGetSubjects();


  # Define a list of all subjects the topic can be moved to.
  foreach my $Subject (@Subjects)
  {
    if (! dbSubjectIsTitle($Subject))
    {
      my @SubjectInfo = dbGetSubjectInfo($Subject);

      if (! dbSubjectInvalid($Subject, @SubjectInfo))
      {
        if ($Subject ne $TopicInfo[DB_TOPIC_SUBJECT])
        {
          # This is not the current subject, add it,
          push @Options, ($Subject, $SubjectInfo[DB_SUBJECT_TITLE]);
          $Found = 1;
        }
        else
        {
          # We store this information, so we don't need to request it again
          $Title      = $SubjectInfo[DB_SUBJECT_TITLE];
          $Moderators = $SubjectInfo[DB_SUBJECT_MODERATORS];

          # Validate if you have access to this subject
          ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
        }
      }
    }
  }


  # No subjects?
  Action_Error($MSG[MOVETOPIC_NONE]) if(! $Found);


  # Can you actually edit something??
  ValidateSubjectEditAccess($Moderators);



  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML($MSG[SUBTITLE_MOVETOPIC], $MSG[SUBTITLE_MOVETOPIC], undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=subject&page=1&subject=$Subject"  => $Title,
                        "?show=topic&page=1&topic=$Topic"        => $TopicInfo[DB_TOPIC_TITLE],
                        "?show=movetopic&topic=$Topic"           => $MSG[SUBTITLE_MOVETOPIC]
                      );

  # Input fields
  print_inputfields_HTML(
                          $TABLE_600_HTML         => undef,1,
                          'action'                => 'movetopic',
                          'topic'                 => $Topic,
                        );
  print_memberinfo_HTML();
  print_editcells_HTML(
                        $MSG[GROUP_SUBJECTS]      => 1,
                        $MSG[GROUP_SUBJECTS]      => sprint_selectfield_HTML('subject', undef, \@Options)
                      );
  print_buttoncells_HTML(
                          $MSG[ACTION_MOVE]        => undef,
                          $MSG[ACTION_RESET]       => undef,
                        );

  # Footer
  print_footer_HTML();
}





sub Action_MoveTopic ()
{
  LoadSupport('check_fields');

  # Get Field Values
  my $NewSubject = (param('subject') || '');
  ValidateRequired($Topic);

  # Get Topic and Subject Info
  my @TopicInfo      = dbGetTopicInfo($Topic, 1);
  my $OldSubject     = $TopicInfo[DB_TOPIC_SUBJECT];
  my @OldSubjectInfo = dbGetSubjectInfo($OldSubject, 1);

  # Get the access
  ValidateSubjectAccess($OldSubjectInfo[DB_SUBJECT_GROUPS], $OldSubjectInfo[DB_SUBJECT_MODERATORS]);
  ValidateSubjectEditAccess($OldSubjectInfo[DB_SUBJECT_MODERATORS]);

  # Get Information for transfer of topic
  my @OldTopics      = dbGetTopics($OldSubject);
  my @NewSubjectInfo = dbGetSubjectInfo($NewSubject, 1);


  # Remove the old subject from the previous array...
  my $Found = 0;
  if(@OldTopics == 1)
  {
    # this was only one topic in the subject
    if($OldTopics[0] eq $Topic)
    {
      # Add the new topic to the topic index database...
      # The old index database should be empty now, so we remove the database file...
      dbTopicMoveToTop($Topic, $NewSubject);
      dbDelTopics($TopicInfo[DB_TOPIC_SUBJECT]);
      $Found = 1;
    }
  }
  else
  {
    my $I = 0;
    search:foreach my $OldTopic (@OldTopics)
    {
      if($OldTopic == $Topic)
      {
        # Add the new topic to the topic index database...
        # And Remove topic and save the old index file
        splice(@OldTopics, $I, 1) == $Topic or die "Can't remove topic from subject '$OldSubject'\n";
        dbTopicMoveToTop($Topic, $NewSubject);
        dbSaveTopics($OldSubject => @OldTopics);
        $Found = 1;
        last search;
      }
      $I++;
    }
  }


  # Not found??
  $Found or die "Can't remove topic from subject '$OldSubject'. Topic not found\n";


  # Change the stats in the topic database file
  $TopicInfo[DB_TOPIC_SUBJECT] = $NewSubject;
  dbSaveTopicInfo(@TopicInfo);


  # Update the subject's statistics...
  $OldSubjectInfo[DB_SUBJECT_TOPICNUM]--;
  $NewSubjectInfo[DB_SUBJECT_TOPICNUM]++;
  dbSaveSubjectInfo(@OldSubjectInfo);
  dbSaveSubjectInfo(@NewSubjectInfo);

  # Log print and redirect
  print_log("MOVETOPIC", $XForumUser, "TOPIC=$Topic FROM=$OldSubject TO=$NewSubject");
  print redirect("$THIS_URL?show=topic&page=1&topic=$Topic");
  exit;
}

1;
