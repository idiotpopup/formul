##################################################################################################
##                                                                                              ##
##  >> Display of Instant Messages <<                                                           ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'dlg_messages.pl'} = 'Release 1.6';

LoadSupport('check_security');
LoadSupport('db_messages');
LoadSupport('db_members');

ValidateMemberCookie();

my @STYLE_TITLE  = ('',   '',      $FONT_STYLE);
my @STYLE_MEMBER = ('200', '',     qq[size="1"]);
my @STYLE_DATE   = ('180', '',     qq[size="1"]);



##################################################################################################
## Display Messages

sub Show_MessagesDialog ()
{
  LoadSupport('html_tables');
  LoadSupport('html_members');
  LoadSupport('html_posts');
  LoadSupport('xbbc_convert');


  # Determine what folder should be displayed
  my $Folder = param('folder');
  my $Type;

  if(! defined $Folder)      { $Type = MSG_TYPE_INBOX  }
  elsif($Folder eq 'sent')   { $Type = MSG_TYPE_SENT   }
  elsif($Folder eq 'inbox')  { $Type = MSG_TYPE_INBOX  }
  else                       { Action_Error()          }


  # Get the messages and member info, and check them automatically.
  my @MemberInfo = dbGetMemberInfo($XForumUser, 1);
  my @Messages   = dbGetMessages($XForumUser, $Type, 1);



  # Determine what treelevel and toolbar icons should be displayed
  my $Show          = param('show');
  my @TreeLevelPath = ();
  my $OtherFolder;

  if($Type)
  {
    @TreeLevelPath = ('?show=messages&folder=sent'               => $MSG[SUBTITLE_SENTMSG]);
    $OtherFolder   = sprint_button_HTML($MSG[BUTTON_MESSAGES]    => qq[$THIS_URL?show=messages&folder=inbox],  'inbox',   $MSG[BUTTON_MESSAGES_INFO]),
  }
  else
  {
    @TreeLevelPath = ('?show=messages&folder=inbox'              => $MSG[SUBTITLE_INBOX]);
    $OtherFolder   = sprint_button_HTML($MSG[BUTTON_SENTMSG]     => qq[$THIS_URL?show=messages&folder=sent],   'sent',  $MSG[BUTTON_SENTMSG_INFO]),
  }



  # JavaScript to make the confirm() dialogs, using a hidden input-form
  # to do some actions from this document.
  my $MSG_JS = <<MESSAGE_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function DeleteMessage(Post)
      {
        if(confirm("$MSG[DELPOST_CONFIRM]"))
        {
          // We use a hidden form to make the POST request.
          document.placeholder.elements['message'].value = Post;
          document.placeholder.submit();
        }
        return false;
      }
    // --></SCRIPT>
MESSAGE_JS



  # Print the header
  print_header;
  print_header_HTML($MSG[SUBTITLE_INBOX], $MSG[SUBTITLE_INBOX], undef, $MSG_JS);
  print_toolbar_HTML( $OtherFolder,
                      sprint_button_HTML($MSG[BUTTON_COMPOSEMSG] => qq[$THIS_URL?show=compose&action=new],                'compose', $MSG[BUTTON_COMPOSEMSG_INFO]),
                    );
  print_treelevel_HTML(@TreeLevelPath);
  print_bodystart_HTML();


  # This is the hidden placeholder used by the JavaScript above.
  # It is used to submit data, without requesting the confirm page
  # from this CGI script first.
  print <<HIDDEN_DELETE_FORM;
    <!---- BEGIN placeholder for JavaScript ---->
    <FORM name="placeholder" method="POST" action="$THIS_URL">
      <INPUT type="hidden" name="action" value="delmessage">
      <INPUT type="hidden" name="folder" value="$Folder">
      <INPUT type="hidden" name="message" value="">
      <INPUT type="hidden" name="confirmback" value="$THIS_URL?show=messages&folder=$Folder">
      <INPUT type="hidden" name="submit_yes" value="Yes">
    </FORM>
    <!---- END of placeholder ---->

HIDDEN_DELETE_FORM



  # Print a list of the titles?
  if(@Messages)
  {
    my $Members = ($Type ? $MSG[MESSAGE_SENTTO] : $MSG[MESSAGE_SENDER]);
    print_tableheader_HTML(
                            $TABLE_MAX_HTML,
                            $MSG[MESSAGE_TITLE]    => $STYLE_TITLE[0],
                            $Members               => $STYLE_MEMBER[0],
                            $MSG[MESSAGE_RECEIVED] => $STYLE_DATE[0],
                          );

    for(my $I = (@Messages/2); $I >= 1; $I--)
    {
      my @MessageInfo     = dbGetMessageInfo(\@Messages,     $I);

      my $Members = '';

      foreach my $Member (split(',', $MessageInfo[DB_MSG_SENTTO]))
      {
        $Members .= ', ' if length $Members;
        $Members .= sprint_memberlink_HTML($Member);
      }

      my $Title   = qq[<IMG src="$IMAGE_URLPATH/posticons/$MessageInfo[DB_MSG_ICON].gif" width="16" height="16"> ]
                  . qq[<A href="$THIS_URL?show=messages&folder=$Folder#post$I">$MessageInfo[DB_MSG_TITLE]</A>];

      print qq[      <TR>\n];
      print_tablecell_HTML($Title,  @STYLE_TITLE);
      print_tablecell_HTML($Members, @STYLE_MEMBER);
      print_tablecell_HTML(DispTime($MessageInfo[DB_MSG_DATE]),   @STYLE_DATE);
      print qq[      </TR>\n];
    }
    print qq[    </TABLE>\n    <P><BR><BR></P>\n\n];



    # Print all the messages
    my $FirstMsg = 1;

    for(my $I = (@Messages/2); $I >= 1; $I--)
    {
      my $LastMsg = ($I == 1);

      # Get some info about the message
      my @MessageInfo     = dbGetMessageInfo(\@Messages,     $I);
      my $MessageContents = dbGetMessageContents(\@Messages, $I);

      # Determine some HTML blocks...
      my $MemberInfo      = '';
      my $Sender          = '';
      my $MessageHeader   = sprint_postinfo_HTML(-1, $MessageInfo[DB_MSG_DATE]);
         $MessageContents = FormatFieldXBBC($MessageContents);


      # What should the member display (at the left) look like:
      if($Type)
      {
        # List where you sent the message to
        foreach my $Member (split(',', $MessageInfo[DB_MSG_SENTTO]))
        {
          $MemberInfo .= ",\n        " if length $MemberInfo;
          $MemberInfo .= qq[<A href="$THIS_URL?show=member&member=$Member">] . dbGetMemberName($Member) . qq[</A>];
        }
        $MemberInfo       = "        $MSG[MESSAGE_SENTTO]:<BR>\n"
                          . "        $MemberInfo\n";
      }
      else
      {
        # From <member>.
        $MemberInfo       = sprint_memberinfo_HTML($MessageInfo[DB_MSG_SENDER]);
        $Sender           = $MessageInfo[DB_MSG_SENDER];
      }


      # Is this a new message?
      if($MessageInfo[DB_MSG_DATE] > $MemberInfo[DB_MEMBER_LASTMSG_VIEWDATE])
      {
        $MessageHeader .= qq[<IMG src="$IMAGE_URLPATH/icons/new.gif" width="22" height="9">];
      }



      # Determine footer icons
      my $FooterIcons;
      my $CanReply      = (!$Type && $XForumUser ne $MessageInfo[DB_MSG_SENDER]);
      $FooterIcons .= sprint_button_HTML($MSG[BUTTON_REPLY]    => "$THIS_URL?show=compose&action=reply&message=$I", 'msgreply', $MSG[BUTTON_REPLY_INFO]) if($CanReply);
      $FooterIcons .= qq[\n            ] . sprint_button_HTML($MSG[BUTTON_FORWARD]  => "$THIS_URL?show=compose&action=forward&folder=$Folder&message=$I", 'msgforward', $MSG[BUTTON_FORWARD_INFO]);
      $FooterIcons .= qq[\n            ] . sprint_button_HTML($MSG[BUTTON_QUOTE]    => "$THIS_URL?show=compose&action=quote&message=$I", 'quote', $MSG[BUTTON_QUOTE_INFO]) if($CanReply);
      $FooterIcons .= qq[\n            ] . sprint_button_HTML($MSG[BUTTON_DELETE]   => qq[$THIS_URL?show=delmessage&folder=$Folder&message=$I" onClick="return DeleteMessage($I)], 'delete', $MSG[BUTTON_DELETE_INFO]);


      # Print message
      print_post_HTML($MessageInfo[DB_MSG_TITLE], $Sender, $MessageInfo[DB_MSG_ICON], $I, $FirstMsg, $LastMsg, $MemberInfo, $MessageHeader, $MessageContents, $FooterIcons);

      $FirstMsg = 0;
    }


    # Save last view time.
    $MemberInfo[DB_MEMBER_LASTMSG_VIEWDATE] = SaveTime();
    dbSaveMemberInfo(@MemberInfo);
  }
  else
  {
    # Damn! No mail for me.
    print "    $MSG[MESSAGES_NONE]\n"
  }

  print_footer_HTML();
}



##################################################################################################
## Compose a new message


sub Show_ComposeDialog ()
{
  LoadSupport('html_interface');
  LoadSupport('html_xbbcedit');


  # Different types of composing
  my %Types = (
                'new'        => '',
                'forward'    => $MSG[FORWARD_PREFIX] || 'Fw: ',
                'reply'      => $MSG[ADDPOST_PREFIX] || 'Re: ',
                'quote'      => $MSG[ADDPOST_PREFIX] || 'Re: ',
              );

  my $Action    = (param('action')  || 'new');
  my $Message   = (param('message') || 0);



  # Prefix, title, contents
  my $Prefix          = ($Types{$Action});
  my $Title           = '';
  my $MessageContents = '';
  my $SendTo          = undef; # Array reference
  if(! defined $Prefix) { Action_Error() }


  # If Message suppied, make special tags first
  if ($Message)
  {
    my $Folder = param('folder');
    my $Type;

    if(! defined $Folder)      { $Type = MSG_TYPE_INBOX  }
    elsif($Folder eq 'sent')   { $Type = MSG_TYPE_SENT   }
    elsif($Folder eq 'inbox')  { $Type = MSG_TYPE_INBOX  }
    else                       { Action_Error()          }

    # Get the message info
    my @Messages    = dbGetMessages($XForumUser, $Type, 1, $Message-1, $Message);
    my @MessageInfo = dbGetMessageInfo(\@Messages, 1);
    my $MSG         = \$Messages[Index_MessageContents(1)];
    $Title          = $MessageInfo[DB_MSG_TITLE];

    if($Action eq 'forward')
    {
      # Open space, some sender info, splitter, original contents
      $MessageContents  = "\n\n\n\n[hr]";

      if($Type == MSG_TYPE_SENT)
      {
        # This message is forwarded from your sent messages folder
        $MessageContents .= "\n$MSG[MESSAGE_SENDER]: "   . dbGetMemberName($XForumUser)
                          . "\n$MSG[MESSAGE_RECEIVED]: " . DispTime($MessageInfo[DB_MSG_DATE])
                          . "\n$MSG[FORWARD_SUBJECT]: "  . $MessageInfo[DB_MSG_TITLE]
      }
      else
      {
        # This message is received by you, and now forwarded.
        $MessageContents .= "\n$MSG[FORWARD_FROM]: "     . dbGetMemberName($MessageInfo[DB_MSG_SENDER])
                          . "\n$MSG[FORWARD_TO]: "       . dbGetMemberName($XForumUser)
                          . "\n$MSG[MESSAGE_RECEIVED]: " . DispTime($MessageInfo[DB_MSG_DATE])
                          . "\n$MSG[FORWARD_SUBJECT]: "  . $MessageInfo[DB_MSG_TITLE];
      }
      $MessageContents .= "\n\n$$MSG";
    }
    else
    {
      if($MessageInfo[DB_MSG_SENDER] eq $XForumUser
      || $Type != MSG_TYPE_INBOX)
      {
        Action_Error();
        # die "This should not happen. You can't reply to yourself\n";
      }

      if($Action eq 'quote')
      {
        # Quote, like you're used to in the normal posts
        $MessageContents = "\n[quote]\n"
                         . $$MSG
                         . "\n[/ -- $MSG[ADDPOST_QUOTEEND] -- ]\n\n";
        $SendTo = [ $MessageInfo[DB_MSG_SENDER] ]
      }
      elsif($Action eq 'reply')
      {
        $SendTo = [ $MessageInfo[DB_MSG_SENDER] ]
      }
    }
  }
  else # No message specified
  {
    # We accept two formats: to=member1,member2,member3       (our short format)
    #                      : to=member1&to=member2&to=member3 (multiselect format)
    # That's why the split() and join() is used.
    my $SuggestTo = [ split(',', join(',', param('to'))) ];

    if($Action eq 'new')
    {
      $SendTo = $SuggestTo if $SuggestTo && @{$SuggestTo};
    }
  }


  # HTML Header
  print_header;
  print_header_HTML($MSG[SUBTITLE_COMPOSE], $MSG[SUBTITLE_COMPOSE], undef, $XBBC_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=messages&folder=inbox"                                           => $MSG[SUBTITLE_INBOX],
                        "?show=compose&action=$Action" . ($Message ? "&message=$Message" : '')  => $MSG[SUBTITLE_COMPOSE],
                      );
  print_bodystart_HTML();
  print_XBBCEditor_HTML('compose', $MSG[ACTION_SEND], $MSG[ADDPOST_TITLE], "$Prefix$Title", '', $MessageContents, $SendTo);
}


sub Action_Compose ()
{
  LoadSupport('check_fields');

  # Get Field Values
  my $Title      = (param('title')    || '');
  my $Msg        = (param('msg')      || '');
  my $Icon       = (param('icon')     || 'default');
  my $SaveSent   = (param('savesent') ? 1 : 0);
  my @To         = param('to');


  # Check them
  ValidateRequired($Title, $Msg, (defined @To ? 1 : undef));
  ValidateLength($Title,   $MSG[ADDPOST_TITLE], 80);
  ValidateLength($Msg,     $MSG[XBBC_MESSAGE], $IM_MAX);


  # Make Preview if value of submit button contains the word preview...
  if (param('submit_preview'))
  {
    LoadSupport('dlg_postpreview');
    Show_PostPreview($Msg => $Title, $XForumUser, $Icon, 0, -1);
  }
  elsif(param('submit_post'))
  {
    # Max receipents
    if(defined $IM_SENDTOMAX
    && $IM_SENDTOMAX
    && @To > $IM_SENDTOMAX)
    {
      Action_Error($MSG[MESSAGE_MAXTO], 1);
    }

    # The rest is handled from here.
    dbSendMessage($XForumUser, \@To, $Title, $Icon, $Msg, $SaveSent);

    # Log print and
    print_log("SENDMSG", $XForumUser, "TITLE=$Title TO=" . (@To < 10 ? join(', ', @To) : join(',', @To[0..9]) . ', ... (more then 10 members)'));

    # Print redirect
    print redirect("$THIS_URL?show=messages&folder=inbox");
    exit;
  }
  else
  {
    Action_Error();
  }
}




##################################################################################################
## Delete a Message

sub Show_DeleteMessageDialog ()
{
  # Show confirm dialog
  LoadSupport('dlg_confirm');
  Show_ConfirmDialog($MSG[SUBTITLE_DELMSG], $MSG[DELMSG_CONFIRM]);
}

sub Action_DeleteMessage ()
{
  # Check confirm dialog
  LoadSupport('dlg_confirm');
  Action_Confirm();


  # Check other parameters
  LoadSupport('check_fields');
  LoadSupport('dlg_confirm');

  my $Folder  = (param('folder'));
  my $Message = (param('message') || '');
  my $Type;

  ValidateRequired($Folder, $Message);

  if($Folder eq 'sent')      { $Type = MSG_TYPE_SENT   }
  elsif($Folder eq 'inbox')  { $Type = MSG_TYPE_INBOX  }
  else                       { Action_Error()  }

  dbDelMessage($XForumUser, $Type, $Message);

  print redirect("$THIS_URL?show=messages&folder=$Folder"); #hash not allowed in redirection header
}


1;
