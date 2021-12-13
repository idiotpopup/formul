##################################################################################################
##                                                                                              ##
##  >> Move Topics <<                                                                           ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_movetopic.pl'} = 'Release 1.6';

LoadSupport('db_topics');
LoadSupport('db_groups');
LoadSupport('check_security');


#################################################################################################
## Check access and examine parameters


ValidateAdminAccess();

# Get the topic parameter
my $Subject     = (param('subject') || '');
my @SubjectInfo = dbGetSubjectInfo($Subject, 1);


#################################################################################################
## Show Add Topic

sub Show_MoveTopicsDialog ()
{
  LoadSupport('html_fields');

  if($SubjectInfo[DB_SUBJECT_TOPICNUM] == 0)
  {
    Action_Error($MSG[SUBJECT_EMPTY]);
  }


  # Locals
  my $Title      = '';
  my $Found      = 0;
  my @Options;


  my @Subjects = dbGetSubjects();


  # Define a list of all subjects the topic can be moved to.
  foreach my $SubjectTo (@Subjects)
  {
    if (! dbSubjectIsTitle($SubjectTo))
    {
      my @SubjectInfo = dbGetSubjectInfo($SubjectTo);

      if (! dbSubjectInvalid($SubjectTo, @SubjectInfo))
      {
        if ($SubjectTo ne $Subject)
        {
          # This is not the current subject, add it,
          push @Options, ($SubjectTo, $SubjectInfo[DB_SUBJECT_TITLE]);
          $Found = 1;
        }
        else
        {
          # We store this information, so we don't need to request it again
          $Title      = $SubjectInfo[DB_SUBJECT_TITLE];
        }
      }
    }
  }


  # No subjects?
  Action_Error($MSG[MOVETOPICS_NONE]) if(! $Found);


  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML($MSG[SUBTITLE_MOVETOPICS], $MSG[SUBTITLE_MOVETOPICS], undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=subject&page=1&subject=$Subject"  => $Title,
                        "?show=movetopics&subject=$Subject"      => $MSG[SUBTITLE_MOVETOPICS]
                      );

  # Input fields
  print_inputfields_HTML(
                          $TABLE_600_HTML         => undef,1,
                          'action'                => 'movetopics',
                          'subject'               => $Subject,
                        );
  print_memberinfo_HTML();
  print_editcells_HTML(
                        $MSG[GROUP_SUBJECTS]      => 1,
                        $MSG[GROUP_SUBJECTS]      => sprint_selectfield_HTML('subjectto', undef, \@Options)
                      );
  print_buttoncells_HTML(
                          $MSG[ACTION_MOVE]        => undef,
                          $MSG[ACTION_RESET]       => undef,
                        );

  # Footer
  print_footer_HTML();
}





sub Action_MoveTopics ()
{
  LoadSupport('check_fields');

  # Get Field Values
  my $NewSubject     = (param('subjectto') || '');
  my @NewSubjectInfo = dbGetSubjectInfo($NewSubject, 1);


  # Remove the old subject from the previous array...
  dbMoveTopics($Subject => $NewSubject);


  # Update the subject's statistics...
  $NewSubjectInfo[DB_SUBJECT_TOPICNUM] += $SubjectInfo[DB_SUBJECT_TOPICNUM];
  $SubjectInfo[DB_SUBJECT_TOPICNUM]     = 0;
  dbSaveSubjectInfo(@SubjectInfo);
  dbSaveSubjectInfo(@NewSubjectInfo);

  # Log print and redirect
  print_log("MOVETOPICS", $XForumUser, "FROM=$Subject TO=$NewSubject");
  print redirect("$THIS_URL?show=subject&page=1&subject=$NewSubject");
  exit;
}

1;
