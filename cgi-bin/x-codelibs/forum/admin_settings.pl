##################################################################################################
##                                                                                              ##
##  >> Administrator Settings <<                                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'admin_settings.pl'} = 'Release 1.6';

LoadSupport('check_security');


# Check for admin member access.
ValidateAdminAccess();

if (IsSettingsVersionConflict('admin_settings.pl'))
{
  Error("Module Version Error", "Invalid Version of admin_settings.pl used. Version $VERSIONS{'xf-settings.pl'} is required.");
}

my @REQ_FIELDS_SETTINGS   = qw(forumtitle language postmax immax hotpostnum hothotpostnum pagetopics pageposts memberttl floodtimeout templatefile datafolder imagefolder langfolder libaryfolder imageurlpath libaryurlpath);
my @REQ_FIELDS_TEMPLATE   = qw(cellcolor fontcolor btntcolor postheadcolor postcaptcolor postbodycolor postfontcolor postfootcolor headbackcolor headfontcolor databackcolor datafontcolor tablheadcolor tablfontcolor tablestyle reqhtml tabletbrstyle);
my @INT_FIELDS_SETTINGS   = qw(postmax immax imsendtomax memberttl floodtimeout hotpostnum hothotpostnum pagetopics pageposts);
my @EMAIL_FIELDS_SETTINGS = qw(webmastermail);


my @Files = qw(template style inputstyle);
my %Files = (
               template   => "$DATA_FOLDER${S}settings${S}$TEMPLATE_FILE",
               style      => "$LIBARY_FOLDER${S}style.css",
               inputstyle => "$LIBARY_FOLDER${S}input.css",
            );
my %Errors = (
               template   => "Can't read template file",
               style      => "Can't read style.css",
               inputstyle => "Can't read input.css",
             );
my %Titles = (
               template   => "Template HTML",
               style      => "Style Code",
               inputstyle => "Input Style Code",
             );


##################################################################################################
## Admin: Settings

sub Show_AdminEditSettingsDialog ()
{
  # RULE: We assume that every field has a value, otherwise this forum
  # wouldn't run propertly anyway.

  LoadSupport('html_fields');
  LoadModule('HTML::EscapeASCII;');

  my $ALLOWICONURL_CHECKED  = ($ALLOW_ICONURL   ? ' CHECKED' : '');
  my $ALLOWXBBC_CHECKED     = ($ALLOW_XBBC      ? ' CHECKED' : '');
  my $LOCBARHIDE_CHECKED    = ($LOCBAR_HIDE     ? ' CHECKED' : '');
  my $LOCBARLASTURL_CHECKED = ($LOCBAR_LASTURL  ? ' CHECKED' : '');
  my $CANKEEPLOGIN_CHECKED  = ($CAN_KEEPLOGIN   ? ' CHECKED' : '');
  my $GUESTNOBTN_CHECKED    = ($GUEST_NOBTN     ? ' CHECKED' : '');
  my $GUESTNOPOST_CHECKED   = ($GUEST_NOPOST    ? ' CHECKED' : '');
  my $GUESTNOMAIL_CHECKED   = ($GUEST_NOMAIL    ? ' CHECKED' : '');
  my $LIMIT_CHECKED         = ($LIMIT_VIEW      ? ' CHECKED' : '');
  my $SEC_CHECKED           = ($SEC_CONNECT     ? ' CHECKED' : '');
  my $ISOLATED_CHECKED      = ($FORUM_ISOLATED  ? ' CHECKED' : '');
  my $BUMPTO_CHECKED        = ($TOPIC_BUMPTOTOP ? ' CHECKED' : '');
  my $POST_MAX              = $POST_MAX;
  my $IM_MAX                = $IM_MAX;
  my $IM_SENDTOMAX          = $IM_SENDTOMAX;
  my $MEMBER_TTL            = $MEMBER_TTL / 60;
  my $WEBMASTER_MAIL        = $WEBMASTER_MAIL || '';
  my $IMAGE_URLPATH         = $IMAGE_URLPATH;
  my $IMAGE_FOLDER          = $IMAGE_FOLDER;
  my $LIBARY_URLPATH        = $LIBARY_URLPATH;
  my $DATA_FOLDER           = $DATA_FOLDER;
  my $LIBARY_FOLDER         = $LIBARY_FOLDER;
  my $LANG_FOLDER           = $LANG_FOLDER;
  my $FORUM_TITLE           = $FORUM_TITLE;
  my $TEMPLATE_FILE         = $TEMPLATE_FILE;
  my $MAIL_HOST             = $MAIL_HOST || '';
  my $MAIL_PROG             = $MAIL_PROG || '';


  # Can be undef.
  for($WEBMASTER_MAIL, $MAIL_PROG, $MAIL_HOST, $IM_SENDTOMAX)
  {
    $_ = '' if not defined;
  }

  FormatFieldHTML($WEBMASTER_MAIL, $IMAGE_URLPATH, $IMAGE_FOLDER, $LIBARY_URLPATH, $DATA_FOLDER, $LIBARY_FOLDER, $LANG_FOLDER, $FORUM_TITLE, $TEMPLATE_FILE, $MAIL_HOST, $MAIL_PROG);

  my @MailOptions = (
                      0 => 'No e-mail used',
                      1 => 'UNIX sendmail program',
#                      3 => 'Windows blat program',
                      2 => 'Perl Net::SMTP module'
                    );
  push @MailOptions, (3 => 'Windows blat program') if $MAIL_TYPE == 3;


  my @Languages;

  # Print header
  CGI::cache(1);
  print_header;


  # Find out what languages are available.
  opendir(LANGS, $LANG_FOLDER) or die "Can't read languages: $!";
    while(my $File = readdir(LANGS))
    {
      if (substr($File, -5) eq '.lang')
      {
        $File = substr($File, 0, length($File) - 5);
        push @Languages, ($File => ucfirst($File));
      }
    }
  closedir(LANGS);


  # Print HTML header
  print_header_HTML('Admin Center [Edit Settings]', 'Admin Center <FONT size=\"-1\">[Edit Settings]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'            => 'Admin Center',
                        '?show=admin_editsettings'      => 'Edit Forum Settings'
                      );
  print_bodystart_HTML();


  # Print input fields
  print_inputfields_HTML(
                          $TABLE_600_HTML               => undef,1,
                          'action'                      => 'admin_editsettings',
                        );
  print_required_TEST(@REQ_FIELDS_SETTINGS);
  print_int_TEST(@INT_FIELDS_SETTINGS);
  print_email_TEST(@EMAIL_FIELDS_SETTINGS);
  print_editcells_HTML(
                        'Forum Settings'               => 1,
                        $REQ_HTML.'Titlebar Text'       => qq[<INPUT type="text" class="CoolText" name="forumtitle" size="60" value="$FORUM_TITLE">],
                        $REQ_HTML.'Language'            => sprint_selectfield_HTML('language' => $LANGUAGE, \@Languages),
                        $REQ_HTML.'Hot Topic Replies'   => qq[<INPUT type="text" class="CoolText" name="hotpostnum" size="60" value="$HOT_POSTNUM">],
                        $REQ_HTML.'Very-Hot Replies'    => qq[<INPUT type="text" class="CoolText" name="hothotpostnum" size="60" value="$HOTHOT_POSTNUM">],
                        $REQ_HTML.'Topics per Page'     => qq[<INPUT type="text" class="CoolText" name="pagetopics" size="60" value="$PAGE_TOPICS">],
                        $REQ_HTML.'Posts per Page'      => qq[<INPUT type="text" class="CoolText" name="pageposts" size="60" value="$PAGE_POSTS">],
                        $REQ_HTML.'Visitor TTL (Min)'   => qq[<INPUT type="text" class="CoolText" name="memberttl" size="60" value="$MEMBER_TTL">],
                      );
  print_editcells_HTML(
                        'Forum Appearance'              => 1,
                        'Data Field Limitations'        => qq[<INPUT type="checkbox" class="CoolBox" name="limitview"$LIMIT_CHECKED><FONT size="1"> Doesn't show any information (eg. in profile) that isn't specified.</FONT>],
                        'Hide Location Bar'             => qq[<INPUT type="checkbox" class="CoolBox" name="locbarhide"$LOCBARHIDE_CHECKED><FONT size="1"> Uncheck to hide the "Location Bar" in the forum pages.</FONT>],
                        'Last URL at Location Bar'      => qq[<INPUT type="checkbox" class="CoolBox" name="locbarlasturl"$LOCBARLASTURL_CHECKED><FONT size="1"> When checked, the last item at the location bar is also clickable.</FONT>],
                        'Topic Bump To Top'             => qq[<INPUT type="checkbox" class="CoolBox" name="topicbumptotop"$BUMPTO_CHECKED><FONT size="1"> Topics should bump to top when replies are posted.</FONT>],
                      );
  print_editcells_HTML(
                        'Forum Limitations'             => 1,
                        'Allow Remember Me'             => qq[<INPUT type="checkbox" class="CoolBox" name="cankeeplogin"$CANKEEPLOGIN_CHECKED><FONT size="1"> Uncheck to disable the "Remember Me" for the login window.</FONT>],
                        'Guest Button Limitations'      => qq[<INPUT type="checkbox" class="CoolBox" name="guestnobutton"$GUESTNOBTN_CHECKED><FONT size="1"> Doens't show any buttons that require being logged in.</FONT>],
                        'Guest Posting Limitations'     => qq[<INPUT type="checkbox" class="CoolBox" name="guestnopost"$GUESTNOPOST_CHECKED><FONT size="1"> Doesn't allow guests to post something.</FONT>],
                        'Guest E-mail Limitations'      => qq[<INPUT type="checkbox" class="CoolBox" name="guestnomail"$GUESTNOMAIL_CHECKED><FONT size="1"> Doesn't show any e-mail addresses to guests..</FONT>],
                        'Custom Avatar URL\'s'          => qq[<INPUT type="checkbox" class="CoolBox" name="allowiconurl"$ALLOWICONURL_CHECKED><FONT size="1"> Allows members to specify their own avatar by entering an URL.</FONT>],
                        'Markup in Posts'               => qq[<INPUT type="checkbox" class="CoolBox" name="allowxbbc"$ALLOWXBBC_CHECKED><FONT size="1"> Uncheck to disable XBBC formatting of posted messages.</FONT>],
                      );
  print_editcells_HTML(
                        'Data Limitations'              => 1,
                        $REQ_HTML.'Max Chars per Post'  => qq[<INPUT type="text" class="CoolText" name="postmax" size="60" value="$POST_MAX">],
                        $REQ_HTML.'Max Chars per IM'    => qq[<INPUT type="text" class="CoolText" name="immax" size="60" value="$IM_MAX">],
                        'Max Receipents per IM'         => qq[<INPUT type="text" class="CoolText" name="imsendtomax" size="60" value="$IM_SENDTOMAX">],
                        $REQ_HTML.'Flood Protection (Sec)' => qq[<INPUT type="text" class="CoolText" name="floodtimeout" size="60" value="$FLOOD_TIMEOUT">]
                      );
  print_editcells_HTML(
                        'SMTP Settings'                 => 1,
                        'Mail Type'                     => sprint_selectfield_HTML('mailtype' => $MAIL_TYPE, \@MailOptions),
                        'E-mail Program Location'       => qq[<INPUT type="text" class="CoolText" name="mailprog" size="60" value="$MAIL_PROG">],
                        'SMTP Replay host'              => qq[<INPUT type="text" class="CoolText" name="mailhost" size="60" value="$MAIL_HOST">],
                        'Webmaster e-mail'              => qq[<INPUT type="text" class="CoolText" name="webmastermail" size="60" value="$WEBMASTER_MAIL">]);
  print_editcells_HTML(
                        'HTTP Settings'                 => 1,
                        $REQ_HTML.'Maximum Security'    => qq[<INPUT type="checkbox" class="CoolBox" name="secconnect"$SEC_CHECKED><FONT size="1"> Forces HTTPS (SSL) transfers in some cases. Your server has to support this!</FONT>],
                        $REQ_HTML.'Isolated Cookies'    => qq[<INPUT type="checkbox" class="CoolBox" name="forumisolated"$ISOLATED_CHECKED><FONT size="1"> Forces cookies to current path only. Uncheck if then browsers don't store them.</FONT>]
                      );
  print_editcells_HTML(
                         'Folder Locations'              => 1,
                        $REQ_HTML.'Data Folder'         => qq[<INPUT type="text" class="CoolText" name="datafolder" size="60" value="$DATA_FOLDER">],
                        $REQ_HTML.'Image Folder'        => qq[<INPUT type="text" class="CoolText" name="imagefolder" size="60" value="$IMAGE_FOLDER">],
                        $REQ_HTML.'Language Folder'     => qq[<INPUT type="text" class="CoolText" name="langfolder" size="60" value="$LANG_FOLDER">],
                        $REQ_HTML.'Libary Folder'       => qq[<INPUT type="text" class="CoolText" name="libaryfolder" size="60" value="$LIBARY_FOLDER">],
                        $REQ_HTML.'Template File'       => qq[<INPUT type="text" class="CoolText" name="templatefile" size="60" value="$TEMPLATE_FILE">],
                      );
  print_editcells_HTML(
                        'Folder URL Locations'          => 1,
                        $REQ_HTML.'Image URL'           => qq[<INPUT type="text" class="CoolText" name="imageurlpath" size="60" value="$IMAGE_URLPATH">],
                        $REQ_HTML.'Libary URL'          => qq[<INPUT type="text" class="CoolText" name="libaryurlpath" size="60" value="$LIBARY_URLPATH">]
                      );
  print_buttoncells_HTML('Change');
  print_footer_HTML();
}






sub Show_AdminEditTemplateDialog ()
{
  # RULE: We assume that every field has a value, otherwise this forum
  # wouldn't run propertly anyway.

  LoadSupport('html_fields');
  LoadModule('HTML::EscapeASCII;');

  my $CELL_COLOR           = $CELL_COLOR;
  my $FONT_COLOR           = $FONT_COLOR;
  my $BTNT_COLOR           = $BTNT_COLOR;
  my $POSTHEAD_COLOR       = $POSTHEAD_COLOR;
  my $POSTCAPT_COLOR       = $POSTCAPT_COLOR;
  my $POSTBODY_COLOR       = $POSTBODY_COLOR;
  my $POSTFONT_COLOR       = $POSTFONT_COLOR;
  my $POSTFOOT_COLOR       = $POSTFOOT_COLOR;
  my $HEADBACK_COLOR       = $HEADBACK_COLOR;
  my $HEADFONT_COLOR       = $HEADFONT_COLOR;
  my $DATABACK_COLOR       = $DATABACK_COLOR;
  my $DATAFONT_COLOR       = $DATAFONT_COLOR;
  my $TABLHEAD_COLOR       = $TABLHEAD_COLOR;
  my $TABLFONT_COLOR       = $TABLFONT_COLOR;
  my $TABLE_STYLE          = $TABLE_STYLE;
  my $TABLE_TBRSTYLE       = $TABLE_TBRSTYLE;
  my $REQ2_HTML            = $REQ_HTML;

  my $TEMPLATE;
  my @OtherFields;

  FormatFieldHTML($CELL_COLOR, $FONT_COLOR, $BTNT_COLOR, $POSTHEAD_COLOR, $POSTCAPT_COLOR, $POSTBODY_COLOR, $POSTFONT_COLOR, $POSTFOOT_COLOR, $HEADBACK_COLOR, $HEADFONT_COLOR, $DATABACK_COLOR, $DATAFONT_COLOR, $TABLHEAD_COLOR, $TABLFONT_COLOR, $TABLE_STYLE, $TABLE_TBRSTYLE, $REQ2_HTML);


  foreach my $File (@Files)
  {
    # Read more files
    my $FileObj = new File::PlainIO($Files{$File}, MODE_READ);

    if(defined $FileObj)
    {
      my $data  = $FileObj->readall();
                  $FileObj->close();
      FormatFieldHTML($data);
      push @OtherFields, $REQ_HTML.$Titles{$File} => qq[<TEXTAREA name="$File" class="editbox" ROWS="24" COLS="100">$data</TEXTAREA>];
    }
    else
    {
      push @OtherFields, $REQ_HTML.$Titles{$File} => qq[<IMG src="/x-images/icons/error.gif" width="15" height="15" alt="Error"> $Errors{$File}];
    }
  }




  # Print header
  CGI::cache(1);
  print_header;


  # Print HTML header
  print_header_HTML('Admin Center [Edit Template]', 'Admin Center <FONT size=\"-1\">[Edit Template]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'            => 'Admin Center',
                        '?show=admin_edittemplate'      => 'Edit Forum Template'
                      );
  print_bodystart_HTML();


  # Print input fields
  print_inputfields_HTML(
                          $TABLE_600_HTML                => undef,1,
                          'action'                       => 'admin_edittemplate',
                        );
  print_required_TEST(@REQ_FIELDS_TEMPLATE);
  print_editcells_HTML(
                        'HTML Snippets'                  => 1,
                        $REQ_HTML.'Dialog Table Style'   => qq[<INPUT type="text" class="CoolText" name="tablestyle" size="60" value="$TABLE_STYLE">],
                        $REQ_HTML.'Required Icon Style'  => qq[<INPUT type="text" class="CoolText" name="reqhtml" size="60" value="$REQ2_HTML">],
                        $REQ_HTML.'Toolbar Style'        => qq[<INPUT type="text" class="CoolText" name="tabletbrstyle" size="60" value="$TABLE_TBRSTYLE">]
                      );
  print_editcells_HTML(
                        'Forum Colors'                    => 1,
                        $REQ_HTML.'Alt. Text Color'       => qq[<INPUT type="text" class="CoolTextClr" name="fontcolor" size="12" value="$FONT_COLOR"><FONT size="1"> Used to display the default color in some hyperlinks.</FONT>],
                        $REQ_HTML.'Tool Button Text Color'    => qq[<INPUT type="text" class="CoolTextClr" name="btntcolor" size="12" value="$BTNT_COLOR"><FONT size="1"> Text color of the toolbar buttons</FONT>],
                        $REQ_HTML.'Table Header Color'    => qq[<INPUT type="text" class="CoolTextClr" name="tablheadcolor" size="12" value="$TABLHEAD_COLOR"><FONT size="1"> Background color of the table header.</FONT>],
                        $REQ_HTML.'Table Header Text Color'   => qq[<INPUT type="text" class="CoolTextClr" name="tablfontcolor" size="12" value="$TABLFONT_COLOR"><FONT size="1"> Text color of the table header labels.</FONT>],
                      );
  print_editcells_HTML(
                        'Post Colors'                     => 1,
                        $REQ_HTML.'Post Bar Back Color'   => qq[<INPUT type="text" class="CoolTextClr" name="postheadcolor" size="12" value="$POSTHEAD_COLOR"><FONT size="1"> Background color of post header bar</FONT>],
                        $REQ_HTML.'Post Bar Text Color'   => qq[<INPUT type="text" class="CoolTextClr" name="postcaptcolor" size="12" value="$POSTCAPT_COLOR"><FONT size="1"> Caption color of post header bar</FONT>],
                        $REQ_HTML.'Post Bar Footer Color' => qq[<INPUT type="text" class="CoolTextClr" name="postfootcolor" size="12" value="$POSTFOOT_COLOR"><FONT size="1"> Background color of the post footer/tool bar</FONT>],
                        $REQ_HTML.'Post Back Color'       => qq[<INPUT type="text" class="CoolTextClr" name="postbodycolor" size="12" value="$POSTBODY_COLOR"><FONT size="1"> Background of the post contents</FONT>],
                        $REQ_HTML.'Post Text Color'       => qq[<INPUT type="text" class="CoolTextClr" name="postfontcolor" size="12" value="$POSTFONT_COLOR"><FONT size="1"> Text color of the post contents</FONT>],
                      );
  print_editcells_HTML(
                        'Data Dialog Colors'              => 1,
                        $REQ_HTML.'Group Back Color'      => qq[<INPUT type="text" class="CoolTextClr" name="headbackcolor" size="12" value="$HEADBACK_COLOR"><FONT size="1"> Background color of the group title. (above fields)</FONT>],
                        $REQ_HTML.'Group Text Color'      => qq[<INPUT type="text" class="CoolTextClr" name="headfontcolor" size="12" value="$HEADFONT_COLOR"><FONT size="1"> Text color of the group title.</FONT>],
                        $REQ_HTML.'Data Cell Back Color'  => qq[<INPUT type="text" class="CoolTextClr" name="cellcolor" size="12" value="$CELL_COLOR"><FONT size="1"> Cell color for information in dialogs (eg. profile)</FONT>],
                      );
  print_editcells_HTML(
                        'Input Dialog Colors'             => 0,
                        $REQ_HTML.'Field Back Color'      => qq[<INPUT type="text" class="CoolTextClr" name="databackcolor" size="12" value="$DATABACK_COLOR"><FONT size="1"> Background color behind the input fields.</FONT>],
                        $REQ_HTML.'Field Info Text Color' => qq[<INPUT type="text" class="CoolTextClr" name="datafontcolor" size="12" value="$DATAFONT_COLOR"><FONT size="1"> Text color of the text next to the input fields</FONT>],
                      );
  print qq[      </TABLE>\n]
      . qq[      <P>\n]
      . qq[\n]
      . qq[      $TABLE_MAX_HTML\n];
  print_editcells_HTML(
                        'Other Files'                   => 1,
                        @OtherFields
                      );
  print_buttoncells_HTML('Change');
  print_footer_HTML();
}
























sub Action_AdminEditTemplate ()
{
  LoadSupport('check_fields');

  foreach my $File (@Files)
  {
    my $Contents = param($File);
    if(defined $Contents)
    {
      my $FileObj = new File::PlainIO($Files{$File}, MODE_WRITE_NEW, "Can't open file for $Titles{$File}");
         $FileObj->write($Contents);
         $FileObj->close();
    }
  }

  Action_AdminEditSettings();
}


sub Action_AdminEditSettings ()
{
  LoadSupport('check_fields');

  my $IsTemplateEdit = param('action') eq 'admin_edittemplate';

  sub choose { return ($IsTemplateEdit ? $_[1] : (param($_[0]) ? 1 : 0)) };
  sub switch { return ($IsTemplateEdit ? $_[1] : (param($_[0]) ? param($_[0]) : undef)) };

  # Get Input Fields
  my $SecConnect      = choose('secconnect'       ,  $SEC_CONNECT);
  my $ForumIsolated   = choose('forumisolated'    ,  $FORUM_ISOLATED);
  my $GuestNoButton   = choose('guestnobutton'    ,  $GUEST_NOBTN);
  my $GuestNoPost     = choose('guestnopost'      ,  $GUEST_NOPOST);
  my $GuestNoMail     = choose('guestnomail'      ,  $GUEST_NOMAIL);
  my $LimitView       = choose('limitview'        ,  $LIMIT_VIEW);
  my $TopicBumpToTop  = choose('topicbumptotop'   ,  $TOPIC_BUMPTOTOP);
  my $AllowXBBC       = choose('allowxbbc'        ,  $ALLOW_XBBC);
  my $AllowIconURL    = choose('allowiconurl'     ,  $ALLOW_ICONURL);
  my $LocBarHide      = choose('locbarhide'       ,  $LOCBAR_HIDE);
  my $LocBarLastURL   = choose('locbarlasturl'    ,  $LOCBAR_LASTURL);
  my $CanKeepLogin    = choose('cankeeplogin'     ,  $CAN_KEEPLOGIN);
  my $PostMax         = (param('postmax')         || $POST_MAX);
  my $IMMax           = (param('immax')           || $IM_MAX);
  my $IMSendToMax     = switch('imsendtomax'      ,  $IM_SENDTOMAX);
  my $WebmasterMail   = switch('webmastermail'    ,  $WEBMASTER_MAIL);
  my $MemberTTL       = (param('memberttl')       || $MEMBER_TTL / 60);
  my $FloodTimeOut    = (param('floodtimeout')    || $FLOOD_TIMEOUT);
  my $Language        = (param('language')        || $LANGUAGE);
  my $HotPostNum      = (param('hotpostnum')      || $HOT_POSTNUM);
  my $HotHotPostNum   = (param('hothotpostnum')   || $HOTHOT_POSTNUM);
  my $PageTopics      = (param('pagetopics')      || $PAGE_TOPICS);
  my $PagePosts       = (param('pageposts')       || $PAGE_POSTS);
  my $ForumTitle      = (param('forumtitle')      || $FORUM_TITLE);
  my $TemplateFile    = (param('templatefile')    || $TEMPLATE_FILE);
  my $CellColor       = (param('cellcolor')       || $CELL_COLOR);
  my $FontColor       = (param('fontcolor')       || $FONT_COLOR);
  my $BtntColor       = (param('btntcolor')       || $BTNT_COLOR);
  my $PostHeadColor   = (param('postheadcolor')   || $POSTHEAD_COLOR);
  my $PostCaptColor   = (param('postcaptcolor')   || $POSTCAPT_COLOR);
  my $PostBodyColor   = (param('postbodycolor')   || $POSTBODY_COLOR);
  my $PostFontColor   = (param('postfontcolor')   || $POSTFONT_COLOR);
  my $PostFootColor   = (param('postfootcolor')   || $POSTFOOT_COLOR);
  my $HeadBackColor   = (param('headbackcolor')   || $HEADBACK_COLOR);
  my $HeadFontColor   = (param('headfontcolor')   || $HEADFONT_COLOR);
  my $DataBackColor   = (param('databackcolor')   || $DATABACK_COLOR);
  my $DataFontColor   = (param('datafontcolor')   || $DATAFONT_COLOR);
  my $TablHeadColor   = (param('tablheadcolor')   || $TABLHEAD_COLOR);
  my $TablFontColor   = (param('tablfontcolor')   || $TABLFONT_COLOR);
  my $TableStyle      = (param('tablestyle')      || $TABLE_STYLE);
  my $MailType        = (param('mailtype')        || $MAIL_TYPE);
  my $MailProg        = switch('mailprog'         ,  $MAIL_PROG);
  my $MailHost        = switch('mailhost'         ,  $MAIL_HOST);
  my $ReqHTML         = (param('reqhtml')         || $REQ_HTML);
  my $TableTbrStyle   = (param('tabletbrstyle')   || $TABLE_TBRSTYLE);
  my $DataFolder      = (param('datafolder')      || $DATA_FOLDER);
  my $ImageURLPath    = (param('imageurlpath')    || $IMAGE_URLPATH);
  my $LangFolder      = (param('langfolder')      || $LANG_FOLDER);
  my $ImageFolder     = (param('imagefolder')     || $IMAGE_FOLDER);
  my $LibaryURLPath   = (param('libaryurlpath')   || $LIBARY_URLPATH);
  my $LibaryFolder    = (param('libaryfolder')    || $LIBARY_FOLDER);


  # Can be undef.
  my $MailProgOriginal = $MailProg;
  for($WebmasterMail, $MailProg, $MailHost, $IMSendToMax)
  {
    if(! defined || $_ eq '') { $_ = 'undef';  }
    else                      { $_ = qq['$_']; }
  }


  ValidateRequired($WebmasterMail)             unless ($MailType == 0);

  if(param('action') eq 'admin_edittemplate')
  {
    ValidateRequiredFields(@REQ_FIELDS_TEMPLATE);
  }
  else
  {
    ValidateRequiredFields(@REQ_FIELDS_SETTINGS);
    ValidateNumberFields(@INT_FIELDS_SETTINGS);
    ValidateEmail($WebmasterMail)     unless ($WebmasterMail eq 'undef');


    ValidatePath($_) foreach("$DATA_FOLDER${S}settings${S}$TemplateFile", $DataFolder, $ImageFolder, $LangFolder, $LibaryFolder);
    ValidatePath($MailProgOriginal) unless($MailProg eq 'undef' || $MailType == 0 || $MailType == 2);

    # And URL Path Check?
  }



  # Find x-settings.pl
  my $SettingsLoc = $SETTINGS_FILE;
  if (! -e $SettingsLoc)
  {
    if (-e "$THIS_PATH${S}x-settings.pl") { $SettingsLoc = "$THIS_PATH${S}x-settings.pl"; }
    elsif (-e "x-settings.pl")            { $SettingsLoc = "x-settings.pl"; }
    else                                  { Action_Error("'x-settings.pl' could not be found! You should change x-settings.pl manually,or set the \$SETTINGS_FILE variable to the correct location!"); }
  }


  # Modify special Character: $
  # replace $ with \$
  s/\$/\\\$/g foreach ($ForumTitle, $TemplateFile, $CellColor, $FontColor, $BtntColor, $PostHeadColor, $PostCaptColor, $PostBodyColor, $PostFontColor, $PostFootColor, $HeadBackColor, $HeadFontColor, $DataBackColor, $DataFontColor, $TablHeadColor, $TablFontColor, $TableStyle, $ReqHTML, $TableTbrStyle, $DataFolder, $ImageURLPath, $LangFolder, $ImageFolder, $LibaryURLPath, $LibaryFolder);

  foreach ($SETTINGS_FILE, $TemplateFile, $DataFolder, $ImageFolder, $LangFolder, $LibaryFolder)
  {
    s{^\Q$THIS_PATH${S}}    {\$THIS_PATH\${S}};
    s{^\Q$THIS_DOCROOT${S}} {\$THIS_DOCROOT\${S}};
    s{^\Q$THIS_UPPATH${S}}  {\$THIS_UPPATH\${S}};
    s{\Q${S}}               {\${S}}g;
  }

  foreach ($ImageURLPath, $LibaryURLPath)
  {
    s{^\Q$THIS_SITE$THIS_URLPATH/}   {\$THIS_SITE\$THIS_URLPATH/}   unless $THIS_URLPATH   eq '';
    s{^\Q$THIS_SITE$THIS_URLUPPATH/} {\$THIS_SITE\$THIS_URLUPPATH/} unless $THIS_URLUPPATH eq '';
    s{^\Q$THIS_SITE}                 {\$THIS_SITE};
  }


  # Modify other special Characters
  # replace ] \ with \] \\
  foreach ($ForumTitle, $TemplateFile, $CellColor, $FontColor, $BtntColor, $PostHeadColor, $PostCaptColor, $PostBodyColor, $PostBodyColor, $PostFootColor, $HeadBackColor, $HeadFontColor, $DataBackColor, $DataFontColor, $TablHeadColor, $TablFontColor, $TableStyle, $ReqHTML, $TableTbrStyle, $DataFolder, $ImageURLPath, $LangFolder, $ImageFolder, $LibaryURLPath, $LibaryFolder)
  {
    s/\\/\\\\/g;
    s/\]/\\\]/g;
  }


  my $ModTime = scalar(gmtime) . " GMT";
  my $NEW_SETTINGS = <<NEW_SETTINGS;
##################################################################################################
##                                                                                              ##
##  This file contains additional data for x-forum.cgi                                          ##
##  >> X-Forum settings <<                                                                      ##
##                                                                                              ##
##  Note that this file can be overwritten by the                                               ##
##  "Admin Edit Settings" and "Admin Edit Template" features!                                   ##
##                                                                                              ##
##  Please open x-forum.cgi for copyright and other information                                 ##
##                                                                                              ##
##################################################################################################
##  Last time overwritten: $ModTime



use strict;
\$VERSIONS{'xf-settings.pl'} = '$VERSIONS{'admin_settings.pl'}';





##################################################################################################
## Define the settings:


# Folder Locations. Some Folders (with local paths) should actually be placed outsize the www root (if possible).
\$IMAGE_URLPATH\t= qq[$ImageURLPath];\t\t\t# URL path to images folder
\$LIBARY_URLPATH\t= qq[$LibaryURLPath];\t\t\t# Extra data files

\$DATA_FOLDER\t= qq[$DataFolder];\t\t# Full path to data folder
\$LANG_FOLDER\t= qq[$LangFolder];\t# Full Path to language folder
\$IMAGE_FOLDER\t= qq[$ImageFolder];\t\t# Full Path to images folder
\$LIBARY_FOLDER\t= qq[$LibaryFolder];\t\t# Full path to libary folder


# File Locations
\$SETTINGS_FILE\t= qq[$SETTINGS_FILE];\t\t# Used by admin center and file browser.
\$TEMPLATE_FILE\t= qq[$TemplateFile];\t\t\t\t# Cool Template


# Encryped passwords with compare key (READ 'Password Note' to create you own admin password).
\$ADMIN_PASS\t= qq[$ADMIN_PASS];\t\t\t\t# Use the X-Forum password generator online for this.




# Forum Settings
\$FORUM_TITLE\t= qq[$ForumTitle];\t\t\t# HTML Title
\$LANGUAGE\t= '$Language';\t\t\t\t\t# Language file

\$HOT_POSTNUM\t= $HotPostNum;\t\t\t\t\t\t# Topic is hot topic when more then x replies
\$HOTHOT_POSTNUM\t= $HotHotPostNum;\t\t\t\t\t\t# Topic is very hot topic  when more then x replies

\$PAGE_TOPICS\t= $PageTopics;\t\t\t\t\t\t# Number of Topics per page
\$PAGE_POSTS\t= $PagePosts;\t\t\t\t\t\t# Number of Posts per page

\$MEMBER_TTL\t= 60 * $MemberTTL;\t\t\t\t\t# Seconds before member is considered being logged out.




# Forum Appearance (some things are defined in the Forum Script)
\$LIMIT_VIEW\t= $LimitView;\t\t\t\t\t\t# Hide fields (eg. in profile) when not specified
\$LOCBAR_HIDE    = $LocBarHide;\t\t\t\t\t\t# Use this to hide the location bar
\$LOCBAR_LASTURL = $LocBarLastURL;\t\t\t\t\t\t# Doesn't make the last topic clickable when false,
\$TOPIC_BUMPTOTOP= $TopicBumpToTop;\t\t\t\t\t\t# Topics bump to top when reply added




# Forum Limitations
\$CAN_KEEPLOGIN\t= $CanKeepLogin;\t\t\t\t\t\t# Allows that users check the "Remember Me" option.

\$GUEST_NOBTN\t= $GuestNoButton;\t\t\t\t\t\t# Don't show buttons that require login when user is guest
\$GUEST_NOPOST\t= $GuestNoPost;\t\t\t\t\t\t# Don't let guests post
\$GUEST_NOMAIL\t= $GuestNoMail;\t\t\t\t\t\t# Don't show e-mail adresses when user is guest

\$ALLOW_ICONURL\t= $AllowIconURL;\t\t\t\t\t\t# When disabled, members can't specify their own icon by URL anymore.
\$ALLOW_XBBC\t= $AllowXBBC;\t\t\t\t\t\t# To disable XBBC codes, set this to 0




# Data Limitations
\$POST_MAX\t= $PostMax;\t\t\t\t\t\t# max bytes for posts (1kB = 1024 bytes; 1MB = 1024 kB)
\$IM_MAX\t\t= $IMMax;\t\t\t\t\t\t# max characters in an instant message
\$IM_SENDTOMAX\t= $IMSendToMax;\t\t\t\t\t\t# max members you can send a message to
\$FLOOD_TIMEOUT\t= $FloodTimeOut;\t\t\t\t\t\t# Seconds before new post is allowed by the save user.




# Forum General Colors
\$FONT_COLOR\t= qq[$FontColor];\t\t\t\t\t# Used to display the default color in some hyperlinks.
\$BTNT_COLOR\t= qq[$BtntColor];\t\t\t\t\t# Text color of the toolbar buttons
\$TABLHEAD_COLOR\t= qq[$TablHeadColor];\t\t\t\t\t# Background color of the table header.
\$TABLFONT_COLOR\t= qq[$TablFontColor];\t\t\t\t\t# Text color of the table header labels.

# Post Fields Colors
\$POSTHEAD_COLOR\t= qq[$PostHeadColor];\t\t\t\t\t# Background color of post header bar
\$POSTCAPT_COLOR\t= qq[$PostCaptColor];\t\t\t\t\t# Caption color of post header bar
\$POSTFOOT_COLOR\t= qq[$PostFootColor];\t\t\t\t\t# Background color of the post footer/tool bar
\$POSTBODY_COLOR\t= qq[$PostBodyColor];\t\t\t\t\t# Background of the post contents
\$POSTFONT_COLOR\t= qq[$PostFontColor];\t\t\t\t\t# Text color of the post contents

# Data Dialog Colors
\$HEADBACK_COLOR\t= qq[$HeadBackColor];\t\t\t\t\t# Background color of the group title. (above fields)
\$HEADFONT_COLOR\t= qq[$HeadFontColor];\t\t\t\t\t# Text color of the group title.
\$CELL_COLOR\t= qq[$CellColor];\t\t\t\t\t# Cell color for information in dialogs (eg. profile)

# Input Dialog Colors
\$DATABACK_COLOR\t= qq[$DataBackColor];\t\t\t\t\t# Background color behind the input fields.
\$DATAFONT_COLOR\t= qq[$DataFontColor];\t\t\t\t\t# Text color of the text next to the input fields

# HTML codes used to format tables.
\$TABLE_STYLE\t= qq[$TableStyle];
\$TABLE_TBRSTYLE\t= qq[$TableTbrStyle];
\$REQ_HTML\t= qq[$ReqHTML];




# E-mail settings
\$MAIL_TYPE\t= $MailType;\t\t\t\t\t\t# 0=none, 1=sendmail, 2=Net::SMTP
\$MAIL_PROG\t= $MailProg;\t\t\t\t# Location of sendmail                  (undef for default)
\$MAIL_HOST\t= $MailHost;\t\t\t# Mail server (ie. mail.yourdomain.com) (undef for default)
\$WEBMASTER_MAIL\t= $WebmasterMail;\t\t\t# Webmaster e-mail                      (can be undef for mailtype 0)




# HTTP Settings
\$SEC_CONNECT\t= $SecConnect;\t\t\t\t\t\t# It's recommended setting this to 1 if your server can handle https connections
\$FORUM_ISOLATED\t= $ForumIsolated;\t\t\t\t\t\t# Sets cookie path value (current path if 1, www root if 0). Recommended setting to 0 if login failes with a 'login error page', which could be caused by strange paths like 'My Cool Forum'.



1;
NEW_SETTINGS

  # Reset some variables now.
  $SEC_CONNECT = $SecConnect;
  ReInitSec();

  # Set them
  dbSetFileContents($SettingsLoc, 'Failed to save forum settings!' => $NEW_SETTINGS);

  # Log print and redirect
  print_log("EDITVARS", '');
  print redirect("$THIS_URLSEC?show=admin_center");
  exit;
}





1;
