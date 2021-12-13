##################################################################################################
##                                                                                              ##
##  >> Modifications to Posts <<                                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_addpost.pl'} = 'Release 1.6';

LoadSupport('db_topics');
LoadSupport('db_posts');
LoadSupport('db_groups');
LoadSupport('check_security');


#################################################################################################
# # Check for member access. and exemine parameters


ValidateMemberCookie() if $GUEST_NOPOST;


# Get topic info
my $Topic       = (param('topic') || '');
my @TopicInfo   = dbGetTopicInfo($Topic, 1);
my @SubjectInfo = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);


# Have we got access?
if ($TopicInfo[DB_TOPIC_LOCKED]) { Action_Error($MSG[TOPIC_ISLOCKED], 1) }
ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);




#################################################################################################
## Show Add Post

sub Show_AddPostDialog
{
  LoadSupport('html_interface');
  LoadSupport('html_xbbcedit');


  # If post suppied, make quote tags first
  my $Post         = (param('post') || '');
  my $PostContents = '';
  my $PostTitle = '';

  if ($Post)
  {
    my ($contents, @PostInfo) = dbGetPostTest($Topic, $Post);
    $PostContents = "\n[quotepost=$Post]\n"
                  . $contents
                  . "\n[/ -- $MSG[ADDPOST_QUOTEEND] -- ]\n\n";
    $PostTitle = $PostInfo[DB_POST_TITLE];
  }
  else
  {
    $PostTitle = $TopicInfo[DB_TOPIC_TITLE];
  }


  # HTML Header
  print_header;
  my $TopicPage = dbGetTopicPages($Topic);
  print_header_HTML($MSG[SUBTITLE_ADDPOST], $MSG[SUBTITLE_ADDPOST], undef, $XBBC_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=subject&page=1&subject=$TopicInfo[DB_TOPIC_SUBJECT]"  => $SubjectInfo[DB_SUBJECT_TITLE],
                        "?show=topic&page=$TopicPage&topic=$Topic"                   => $TopicInfo[DB_TOPIC_TITLE],
                        "?show=addpost&topic=$Topic"                                 => $MSG[SUBTITLE_ADDPOST]
                      );
  print_bodystart_HTML();
  print_XBBCEditor_HTML('addpost', $MSG[ACTION_POST], $MSG[ADDPOST_TITLE], "$MSG[ADDPOST_PREFIX]$PostTitle", '', $PostContents);
}




sub Action_AddPost
{
  LoadSupport('check_fields');
  LoadSupport('db_notify');
  LoadSupport('db_members');

  # Get Field Values
  my $Title  = (param('title')  || '');
  my $Msg    = (param('msg')    || '');
  my $Icon   = (param('icon')   || 'default');
  my $Notify = (param('notify') ? 1 : 0);
  my $Poster = DeterminePoster();


  # Make Checks
  ValidateRequired($Title, $Msg, $Poster);
  ValidateLength($Title, $MSG[ADDPOST_TITLE], 80);
  ValidateLength($Msg, $MSG[XBBC_MESSAGE], $POST_MAX);

  if($XForumUser eq '')
  {
    # Guest posting...
    ValidateRequiredFields('email');
    ValidateEmailFields('email');
  }



  # Make Preview if value of submit button contains the word preview...
  if (param('submit_preview'))
  {
    LoadSupport('dlg_postpreview');
    Show_PostPreview($Msg => $Title, $Poster, $Icon, $Topic, $TopicInfo[DB_TOPIC_POSTNUM]);
  }
  elsif(param('submit_post'))
  {
    # Flood test.
    dbMemberFloodTest($Poster, undef, time());

    # Make the post and log.
    dbMakePost($Topic => $Title, $Poster, $Icon, $Msg);

    # Determine topic link
    my $TopicPage = dbGetTopicPages($Topic);
    my $TopicLink = "$THIS_URL?show=topic&page=$TopicPage&topic=$Topic";


    # Give the browser it's redirect now.
    print redirect($TopicLink); # hash location not allowed in redirect header?!


    # Notifiy
    if($XForumUser)
    {
      # Print log.
      print_log("ADDPOST", $XForumUser, "TOPIC=$Topic");

      # Notification
      if($Notify) { dbAddNotify($Topic, $XForumUser)       }
      else        { dbDelNotifyMember($Topic, $XForumUser) }
    }
    dbDoNotify($Topic, $TopicLink, $XForumUser);

    exit;
  }
  else
  {
    Action_Error();
  }
}


1;

