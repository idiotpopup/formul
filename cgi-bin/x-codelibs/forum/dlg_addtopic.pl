##################################################################################################
##                                                                                              ##
##  >> Modifications to Topics <<                                                               ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_addtopic.pl'} = 'Release 1.3';

LoadSupport('db_topics');
LoadSupport('db_groups');
LoadSupport('check_security');


#################################################################################################
## check for member access and examine parameters

ValidateMemberCookie() if($GUEST_NOPOST);


# Get subject info
my ($Subject)   = (param('subject') || '');
my @SubjectInfo = dbGetSubjectInfo($Subject, 1);

# Access??
ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);



#################################################################################################
## Show Add Topic

sub Show_AddTopicDialog ()
{
  LoadSupport('html_fields');
  LoadSupport('html_xbbcedit');


  # HTML Header
  print_header;
  print_header_HTML($MSG[SUBTITLE_ADDTOPIC], $MSG[SUBTITLE_ADDTOPIC], undef, $XBBC_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=subject&page=1&subject=$Subject"  => $SubjectInfo[DB_SUBJECT_TITLE],
                        "?show=addtopic&subject=$Subject"        => $MSG[SUBTITLE_ADDTOPIC]
                      );
  print_bodystart_HTML();
  print_XBBCEditor_HTML('addtopic', $MSG[ACTION_CREATE], $MSG[ADDTOPIC_TITLE], '', '', '');
}




sub Action_AddTopic
{
  LoadSupport('db_stats');
  LoadSupport('db_posts');
  LoadSupport('db_notify');
  LoadSupport('db_members');
  LoadSupport('check_fields');
  LoadModule('HTML::EscapeASCII;');

  # Get Field Values
  my $Title  = (param('title') || '');
  my $Msg    = (param('msg')   || '');
  my $Icon   = (param('icon')  || 'default');
  my $Notify = (param('notify') ? 1 : 0);
  my $Poster = DeterminePoster();

  # Make Preview if value of submit button contains the word preview...
  if (param('submit_preview'))
  {
    LoadSupport('dlg_postpreview');
    Show_PostPreview($Msg => $Title, $Poster, $Icon, undef, 0);
  }
  elsif(param('submit_post'))
  {
    my $Time = SaveTime();

    # Make Checks
    ValidateRequired($Title, $Msg, $Poster);
    ValidateLength($Title, $MSG[ADDTOPIC_TITLE], 80);
    ValidateLength($Msg, $MSG[XBBC_MESSAGE], $POST_MAX);

    if($XForumUser eq '')
    {
      # Guest posting...
      ValidateRequiredFields('email');
      ValidateEmailFields('email');
    }


    # Also tested in dbMakePost, but we need to know it earlier.
    dbMemberFloodTest($Poster, undef, $Time);




    # Define the information structure
    my @TopicInfo;
    $TopicInfo[DB_TOPIC_SUBJECT]      = $Subject;
    $TopicInfo[DB_TOPIC_TITLE]        = $Title;
    $TopicInfo[DB_TOPIC_CREATOR]      = $Poster;
    $TopicInfo[DB_TOPIC_DATE]         = $Time;
    $TopicInfo[DB_TOPIC_LOCKED]       = 0;
    $TopicInfo[DB_TOPIC_POSTNUM]      = 1;
    $TopicInfo[DB_TOPIC_VIEWS]        = 0;
    $TopicInfo[DB_TOPIC_ICON]         = $Icon;
    $TopicInfo[DB_TOPIC_LASTPOSTER]   = $TopicInfo[DB_TOPIC_CREATOR];
    $TopicInfo[DB_TOPIC_LASTPOSTDATE] = $TopicInfo[DB_TOPIC_DATE];

    FormatFieldHTML($TopicInfo[DB_TOPIC_TITLE]);


    # Although this edits the stat file,
    # We need to do this first. This reserves our place
    # in the forum, and no-one can take it away.
    # Otherwise two users could the same topic ID
    # if they post between each other's read/save time-slice

    # Make the topic
    my $TopicID    = TopicIDGen();
    $TopicInfo[ID] = $TopicID;



    # Save the topic info
    dbMakeTopic($TopicID => $Subject);
    dbSaveTopicInfo(@TopicInfo);
    dbMakePost($TopicID => $Title, $Poster, $Icon, $Msg);

    if($XForumUser)
    {
      # Print the log
      print_log("ADDTOPIC", $XForumUser, "TOPIC=$TopicID");

      # Notification
      dbAddNotify($TopicID, $XForumUser) if $Notify;
    }

    # Redirect
    print redirect("$THIS_URL?show=topic&page=1&topic=$TopicID");
    exit;
  }
  else
  {
    Action_Error();
  }
}





1;
