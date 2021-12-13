##################################################################################################
##                                                                                              ##
##  >> Display of Forum/Subject and Topics <<                                                   ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'dlg_topic.pl'} = 'Release 1.6';

LoadSupport('check_security');
LoadSupport('check_fields');
LoadSupport('db_topics');
LoadSupport('db_posts');
LoadSupport('db_groups');
LoadSupport('html_members');
LoadSupport('html_posts');
LoadSupport('xbbc_convert');


##################################################################################################
## Display Topic

sub Show_Topic ()
{
  # Get Information
  my $Topic             = param('topic') || '';
  my $Page              = param('page')  || 1;

  my @TopicInfo         = dbGetTopicInfo($Topic, 1);
  my @SubjectInfo       = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);

  # Determine access rules for later...
  my $MemberIsModerator = dbIsSubjectModerator($SubjectInfo[DB_SUBJECT_MODERATORS], $XForumUser);
  my $ModeratorXS       = ($XForumUser eq 'admin' || $MemberIsModerator);


  # Valiate Access
  ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
  ValidateNumber($Page, $MSG[ISNUM_PAGE]);



  # Note
  #
  # The following code will attempt to restore the number of topics
  # if they appear to be incorrect. That means that we CAN'T RELY
  # on the $TopicInfo[DB_TOPIC_POSTNUM] if we want to determine
  # how many pages this topic consists of.
  # However, we use different tricks to obtain this information.
  # Hope it's not confusing.


  # Calc num pages and test
  my $Pages = dbGetTopicPages(undef, $TopicInfo[DB_TOPIC_POSTNUM]);
  if ($Page < 1)  # Don't test: $Page > $Pages
  {
    Action_Error($MSG[PAGE_OVERFLOW]);
  }


  # Calc start and end value
  my $Start = ($Page - 1) * $PAGE_POSTS;
  my $End   = $Start      + $PAGE_POSTS;  # Assume all posts, don't use DB_TOPIC_POSTNUM


  # Get the posts, and update the end value if needed
  my @Posts             = dbGetPosts($Topic, 1, $Start, $End + 1);  # +1 for extra post, to see if there is another page left...
  my $Posts             = (@Posts / 2);        # We use this a lot.
  my $RealEnd           = ($Start + $Posts);   # What's really found...
  my $RealPostNum       = undef;               # We haven't found a difference yet.

  if ($Posts == 0)
  {
    # Couldn't get any posts...
    # We requested lines that don't exist.

    # This is almost the same as $Page > $Pages
    # but $Pages is determined from a (maybe corrupted)
    # value $TopicInfo[DB_TOPIC_POSTNUM]
    Action_Error($MSG[PAGE_OVERFLOW]);
  }
  elsif($Posts > $PAGE_POSTS)
  {
    # Not the last post. We found another post
    # after this post. Maybe we can update the stats

    # If we found more posts then topic stats let us believe, we assume
    # there are that amount of posts located. If any more are there,
    # they will be updated when we open the next page...
    # The number of pages are re-calculated aswell.
    $RealPostNum = $RealEnd if($RealEnd > $TopicInfo[DB_TOPIC_POSTNUM]);
    $RealEnd--;              # We remove the extra added post.
    $End         = $RealEnd;
  }
  elsif($End >= $RealEnd)
  {
    # This is the last page...
    my $PrevPage = $Page - 1;
    $RealPostNum = ($PAGE_POSTS * $PrevPage) + $Posts;
    $End         = $RealEnd;
  }


  # Autorestore Statics if it appears to be incorrect! (and we know the number of total posts)
  if(defined $RealPostNum
  && $RealPostNum != $TopicInfo[DB_TOPIC_POSTNUM])
  {
    $TopicInfo[DB_TOPIC_POSTNUM] = $RealPostNum;

    # Re-calculate number of pages
    my $NewPages = dbGetTopicPages(undef, $TopicInfo[DB_TOPIC_POSTNUM]);
    if($NewPages != $Pages)
    {
      $Pages = $NewPages;
      $Page  = $Pages    if($Page > $Pages); # Suppose you clicked the wrong page number link, because of the bad statistics.
    }
    dbSaveTopicInfo(@TopicInfo);             # For other users...
  }



  # Make the toolbar buttons, based on the level of access
  my @ToolBarButtons = ();
  my $AllowedMember = ($XForumUser eq 'admin' || $MemberIsModerator);
  my $UserMayPost   = ! ($TopicInfo[DB_TOPIC_LOCKED] || ($GUEST_NOPOST && $XForumUser eq '' && $GUEST_NOBTN));

  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_ADDPOST] => qq[$THIS_URL?show=addpost&topic=$Topic],                                  'reply',     $MSG[BUTTON_ADDPOST_INFO])   if ($UserMayPost);
  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_MOVE]    => qq[$THIS_URL?show=movetopic&topic=$Topic],                                'movetopic', $MSG[BUTTON_MOVETOPIC_INFO]) if ($AllowedMember);
  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_LOCK]    => qq[$THIS_URL?show=locktopic&topic=$Topic" onClick="return LockTopic()],   'lock',      $MSG[BUTTON_LOCK_INFO])      if (! $TopicInfo[DB_TOPIC_LOCKED] && $AllowedMember);
  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_UNLOCK]  => qq[$THIS_URL?show=locktopic&topic=$Topic" onClick="return UnLockTopic()], 'unlock',    $MSG[BUTTON_UNLOCK_INFO])    if (  $TopicInfo[DB_TOPIC_LOCKED] && $AllowedMember);
  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_STICK]   => qq[$THIS_URL?show=sticktopic&topic=$Topic" onClick="return StickTopic()],   'stick',   $MSG[BUTTON_STICK_INFO])     if (! $TopicInfo[DB_TOPIC_STICKY] && $XForumUser eq 'admin');
  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_UNSTICK] => qq[$THIS_URL?show=sticktopic&topic=$Topic" onClick="return UnStickTopic()], 'unstick', $MSG[BUTTON_UNSTICK_INFO])   if (  $TopicInfo[DB_TOPIC_STICKY] && $XForumUser eq 'admin');
  push @ToolBarButtons, sprint_button_HTML($MSG[BUTTON_DELETE]  => qq[$THIS_URL?show=deltopic&topic=$Topic" onClick="return DeleteTopic()],  'delete',    $MSG[BUTTON_DELETE_INFO])    if ($AllowedMember);


  # JavaScript to make the confirm() dialogs, using a hidden input-form
  # to do some actions from this document.
  my $TOPIC_JS = <<TOPIC_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function ConfirmAction(Text, Action, Post)
      {
        if(confirm(Text))
        {
          // We use a hidden form to make the POST request.
          document.placeholder.elements['action'].value = Action;
          document.placeholder.elements['post'].value   = Post;
          document.placeholder.submit();
        }
        return false;
      }

      function LockTopic()    { return ConfirmAction("$MSG[LOCK_CONFIRM]",     'locktopic',  '') }
      function UnLockTopic()  { return ConfirmAction("$MSG[LOCK_CONFIRMUN]",   'locktopic',  '') }
      function StickTopic()   { return ConfirmAction("$MSG[STICK_CONFIRM]",    'sticktopic', '') }
      function UnStickTopic() { return ConfirmAction("$MSG[STICK_CONFIRMUN]",  'sticktopic', '') }
      function DeleteTopic()  { return ConfirmAction("$MSG[DELTOPIC_CONFIRM]", 'deltopic',   '') }
      function DeletePost(N)  { return ConfirmAction("$MSG[DELPOST_CONFIRM]",  'delpost',     N) }
    // --></SCRIPT>
TOPIC_JS



  # Determine moderator list
  my $ModeratorList = '';
  foreach my $Moderator (split(/,/, $SubjectInfo[DB_SUBJECT_MODERATORS]))
  {
    if (length($Moderator || ''))
    {
      my $Name = dbGetMemberName($Moderator, 0);
      $ModeratorList .= ', ' if(length($ModeratorList));
      $ModeratorList .= "<NOBR>" . sprint_memberlink_HTML($Moderator) . "</NOBR>";
    }
  }


  # HTML Header
  print_header;
  print_header_HTML("$SubjectInfo[DB_SUBJECT_TITLE] [$TopicInfo[DB_TOPIC_TITLE]]", $MSG[SUBTITLE_TOPIC], undef, $TOPIC_JS);
  print_toolbar_HTML(@ToolBarButtons);
  print_treelevel_HTML(
                        qq[?show=subject&page=1&subject=$TopicInfo[DB_TOPIC_SUBJECT]] => $SubjectInfo[DB_SUBJECT_TITLE],
                        qq[?show=topic&page=1&topic=$Topic]=>$TopicInfo[DB_TOPIC_TITLE]
                      );
  print qq[    <P>\n    <B>$MSG[SUBJECT_MODERATORS]:</B> <FONT size="1">$ModeratorList</FONT>\n];
  print_bodystart_HTML();



  # This is the hidden placeholder used by the JavaScript above.
  # It is used to submit data, without requesting the confirm page
  # from this CGI script first.
  print <<HIDDEN_DELETE_FORM;
    <!---- BEGIN placeholder for JavaScript ---->
    <FORM name="placeholder" method="POST" action="$THIS_URL">
      <INPUT type="hidden" name="action" value="">
      <INPUT type="hidden" name="topic" value="$Topic">
      <INPUT type="hidden" name="post" value="">
      <INPUT type="hidden" name="confirmback" value="$THIS_URL?show=topic&page=$Page&topic=$Topic">
      <INPUT type="hidden" name="submit_yes" value="Yes">
    </FORM>
    <!---- END of placeholder ---->

HIDDEN_DELETE_FORM



  if ($Posts)
  {
    print_topicpages_HTML($Topic, $Pages, $Page);

    my $TopicViews   = {};
    my $LastViewDate = 0;

    if($XForumUser ne '')
    {
      $TopicViews   = dbGetMemberViews($XForumUser, [$Topic]);
      $LastViewDate = ($TopicViews->{$Topic} || 0);
    }


    # Build up page, showing all posts in one list.

    post:foreach my $I ($Start..$End-1)
    {
      # Get some info about the post
      my $PostIndex    = $I + 1;
      my $ArrayIndex   = $PostIndex - $Start;
      my $FirstPost    = ($ArrayIndex == 1);
      my $LastPost     = ($I == $End - 1);
      my @PostInfo     = dbGetPostInfo(\@Posts,     $ArrayIndex);
      my $PostContents = dbGetPostContents(\@Posts, $ArrayIndex);

      next post if $PostContents eq '';

      # Determine access rule.
      my $PosterXS     = ($XForumUser eq $PostInfo[DB_POST_POSTER] && not $TopicInfo[DB_TOPIC_LOCKED]);


      # Determine some HTML blocks...
      my $MemberInfo   = sprint_memberinfo_HTML($PostInfo[DB_POST_POSTER], $SubjectInfo[DB_SUBJECT_MODERATORS]);
      my $PostHeader   = sprint_postinfo_HTML($I, $PostInfo[DB_POST_DATE], $PostInfo[DB_POST_LASTMODDATE], $PostInfo[DB_POST_LASTMODMEMBER]);
      my $IPStat       = sprint_ipstat_HTML($PostInfo[DB_POST_IP]);
         $PostContents = FormatFieldXBBC($PostContents, $Topic, \@Posts);

      # Determine what icons should be displayed.
      my $FooterIcons  = '';

      if ($UserMayPost)
      {
        $FooterIcons   = sprint_button_HTML($MSG[BUTTON_QUOTE] => "$THIS_URL?show=addpost&topic=$Topic&post=$PostIndex", 'quote', $MSG[BUTTON_QUOTE_INFO])
      }

      $FooterIcons    .= qq[\n            ] . sprint_button_HTML($MSG[BUTTON_EDITPOST] => qq[$THIS_URL?show=editpost&topic=$Topic&post=$PostIndex],                                        'modifypencil', $MSG[BUTTON_EDITPOST_INFO]) if($ModeratorXS || $PosterXS);
      $FooterIcons    .= qq[\n            ] . sprint_button_HTML($MSG[BUTTON_DELETE]   => qq[$THIS_URL?show=delpost&topic=$Topic&post=$PostIndex" onClick="return DeletePost($PostIndex)], 'delete',       $MSG[BUTTON_DELETE_INFO])   if($ModeratorXS);


      # Is this a new post?
      if($XForumUser ne ''
      && $LastViewDate < $PostInfo[DB_POST_DATE]     # Created after last visit
      && $PostInfo[DB_POST_POSTER] ne $XForumUser)   # Maybe we visited the topic laster when we posted something
      {
        $PostHeader .= qq[ <IMG src="$IMAGE_URLPATH/icons/new.gif" width="22" height="9">];
      }


      # Wee.. print the post
      print_post_HTML($PostInfo[DB_POST_TITLE], $PostInfo[DB_POST_POSTER], $PostInfo[DB_POST_ICON], $PostIndex, $FirstPost, $LastPost, $MemberInfo, "$PostHeader$IPStat", $PostContents, $FooterIcons);
    }




    print_topicpages_HTML($Topic, $Pages, $Page);   # Print the pages again
    dbMemberUpdateViews($XForumUser, $Topic);       # Update Member Views for NEW icons


    # Update topic views, unless you view this topic again.
    my $referer     = referer() || '';
    my $ViewedAgain = 0;

    if($referer)
    {
#     $ViewedAgain = $referer =~ m[^\Q$THIS_URL] && ($LastViewDate > $TopicInfo[DB_TOPIC_LASTPOSTDATE]);
      $ViewedAgain = PageHasParameters($referer, $THIS_URL, "show=topic",      "topic=$Topic", "page=$Page")
                  || PageHasParameters($referer, $THIS_URL, "show=addpost",    "topic=$Topic")
                  || PageHasParameters($referer, $THIS_URL, "show=editpost",   "topic=$Topic")
                  || PageHasParameters($referer, $THIS_URL, "show=movetopic",  "topic=$Topic")
                  || PageHasParameters($referer, $THIS_URL, "show=locktopic",  "topic=$Topic")
                  || PageHasParameters($referer, $THIS_URL, "show=sticktopic", "topic=$Topic");
    }

    if(! $ViewedAgain)
    {
      $TopicInfo[DB_TOPIC_VIEWS]++;              # Update topic views
      dbSaveTopicInfo(@TopicInfo);               # Save Topic Info
    }
  }
  else
  {
    print "    $MSG[TOPIC_EMPTY]\n"
  }
  print_footer_HTML();
}


sub print_topicpages_HTML ($$$)
{ my($Topic, $Pages, $Page) = @_;
  if ($Pages > 1)
  {
    print qq[    <B>$MSG[PAGE_COUNT]:</B>\n];
    foreach my $I (1..$Pages)
    {
      if($I == $Page) { print qq[    <A href="$THIS_URL?show=topic&page=$I&topic=$Topic"><B>$I</B></A>\n]; }
      else            { print qq[    <A href="$THIS_URL?show=topic&page=$I&topic=$Topic">$I</A>\n];        }
    }
    print qq[    <P>\n];
  }
}


# PageHasParameters("$THIS_URL?action=showitem&user=test&item=2&page=2", $THIS_URL, "action=showitem", "item=2")
sub PageHasParameters ($$@)
{ my $PageURL = shift;
  my $BaseURL = shift;
  my $ParamREString = "((" . join("|", @_) . ")&){" . @_ . "}";
  return "$PageURL&" =~ m[^\Q$BaseURL?\E$ParamREString];
}



1;