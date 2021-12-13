##################################################################################################
##                                                                                              ##
##  >> HTML Generators for XBBC Editor Input Fields <<                                          ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;


# You can make an alternative hover effect in the style.css file...
sub DO_IMAGEHOVER_JS_EFFECT (){ 1 }
sub DO_DHTML_JS_EFFECT      (){ 1 }


$VERSIONS{'html_xbbcedit.pl'} = 'Release 1.6';

LoadSupport('html_interface');
LoadSupport('html_fields');
LoadSupport('db_notify');


my @REQ_FIELDS_XBBC   = qw(title msg);
my @EMAIL_FIELDS_XBBC = qw();

my $RE_ICON = qr/^(.+)\.gif$/;



##################################################################################################
## Find the XBBC Icons

my @IconFiles;
if( opendir(ICONS, "$IMAGE_FOLDER${S}posticons") )
{
  @IconFiles = sort map {/$RE_ICON/} readdir ICONS;
  closedir ICONS;
}


##################################################################################################
## XBBC Window Toolbar Field

{
  my $IconJSList = "'" . join("','", @IconFiles) . "'";
  my $IMAGE_URLPATHJS = $IMAGE_URLPATH;
     $IMAGE_URLPATHJS =~ s/"/\\"/g;
  my $TABLE_STYLE     = $TABLE_STYLE;
     $TABLE_STYLE     =~ s/'/\\'/g;
  my $REQ_HTML        = $REQ_HTML;
     $REQ_HTML        =~ s/'/\\'/g;
  my $DO_DHTML        = DO_DHTML_JS_EFFECT || 0;

  $XBBC_JS = <<XBBC_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      // Variables and text from X-Forum variables, used by xbbc.js
      XBBC_DO_DHTML    = $DO_DHTML;
      XBBC_ImagePath   = "$IMAGE_URLPATHJS";
      XBBC_MSG_SELECT  = "$MSG[XBBC_SELECT]";
      XBBC_MSG_INSERT  = "$MSG[XBBC_INSERT]";
      XBBC_MSG_ADD     = '$MSG[ACTION_ADD]';
      XBBC_MSG_CLOSE   = "$MSG[ACTION_CLOSE]";
      XBBC_MSG_FONT    = '$MSG[XBBC_INPUT_FONT]';
      XBBC_MSG_SIZE    = '$MSG[XBBC_INPUT_SIZE]';
      XBBC_MSG_COLOR   = '$MSG[XBBC_INPUT_COLOR]';
      XBBC_MSG_URL     = '$MSG[XBBC_INPUT_URL]';
      XBBC_MSG_EMAIL   = '$MSG[XBBC_INPUT_EMAIL]';
      XBBC_MSG_WIDTH   = '$MSG[XBBC_INPUT_WIDTH]';
      XBBC_MSG_HEIGHT  = '$MSG[XBBC_INPUT_HEIGHT]';
      XBBC_MSG_CAPTION = '$MSG[XBBC_INPUT_CAPTION]';
      XBBC_MSG_TITLE   = '$MSG[XBBC_INPUT_TITLE]';
      XBBC_MSG_FILLIN  = '$MSG[XBBC_INPUT_FILLIN]';
      XBBC_MSG_NUMBER  = '$MSG[XBBC_INPUT_NUMBER]';
      XBBC_MSG_BADCLR  = '$MSG[XBBC_INPUT_BADCLR]';
      XBBC_TableStyle  = '$TABLE_STYLE';
      XBBC_DlgHeadClr  = '$POSTHEAD_COLOR';
      XBBC_DlgCaptClr  = '$POSTCAPT_COLOR';
      XBBC_DlgLabel0   = '$REQ_HTML';
      XBBC_DlgLabel1   = '<FONT size="2">';
      XBBC_DlgLabel2   = '</FONT>'
    // --></SCRIPT>
    <SCRIPT language="JavaScript" type="text/javascript" src="$LIBARY_URLPATH/xbbc.js"></SCRIPT>
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function ShowSmileys() { window.open('$THIS_URL?show=smileylist&javascript=1', 'XForumSmileyWindow', 'scrollbars,resizable,status,left=5,top=30,width=350,height=400'); return false; }

      // Functions called after the previous stuff is loaded
      setTimeout("LoadXBBCImages('bold','center','char','code','color','email','enum','face','flash','font','ftp','glow','help','hr','img','indent','italicize','justify','left','list','move','pre','quotetext','right','shadow','size','strike','sub','sup','table','td','tr','tt','underline','url')", 200);
      setTimeout("LoadIconImages($IconJSList)", 300);
    // --></SCRIPT>
    <STYLE type="text/css"><!--
      #XBBCDialog
      {
        position:         absolute;
        top:              450px;
        left:             150px;
        visibility:       hidden;
        width:            400px;
        height:           200px;
        z-index:          10;
        background-color: transparent;
      }
    --></STYLE>
$FORM_JS
XBBC_JS
}







##################################################################################################
## XBBC Editor HTML

sub print_XBBCEditor_HTML ($$$;$$$$) #(STRING FormAction, STRING SubmitButtonText, STRING TitleText, STRING TitleValue, STRING DefaultIconField, STRING DefaultMessage, STRING SendToMember, BOOLEAN HideNotify)
{ my ($FormAction, $HTMLSubmit, $HTMLTitle, $HTMLTitleValue, $IconName, $HTMLMessage, $SendTo, $HideNotify) = @_;

  $HTMLTitleValue ||= '';
  $HTMLMessage    ||= '';
  $IconName       ||= 'default';


  # Get Information
  my $Subject = param('subject') || '';
  my $Topic   = param('topic')   || '';
  my $Post    = param('post')    || '';



  # Make the toolbar
  my $SWITCH = qq[onMouseOver="return XBBC_SelImg(this);" onMouseOut="return XBBC_UnSelImg(this);"];

  if(! DO_IMAGEHOVER_JS_EFFECT) { $SWITCH = ''; }

  my $GRIP         = qq[<IMG src="$IMAGE_URLPATH/xbbc/bar_grip.gif" width="8" height="21">];
  my $SPLIT        = qq[<IMG src="$IMAGE_URLPATH/xbbc/bar_vsplit.gif" width="6" height="21">];
  my $NEWLINE      = qq[<BR><IMG src="$IMAGE_URLPATH/xbbc/bar_hsplit.gif" width="400" height="2"><BR>$GRIP];
  my $BUTTON_STYLE = qq[border="0" width="23" height="21"];
  my $XBBCToolbar;

  if($ALLOW_XBBC)
  {
    my $Dialog = '';
    $Dialog = '_Dialog' if DO_DHTML_JS_EFFECT;

  $XBBCToolbar  = qq[\n          <TABLE width="100%" cellspacing="0" cellpadding="0" bgcolor="#CCCCCC"><TR><TD>];

  $XBBCToolbar .= qq[\n          <IMG src="$IMAGE_URLPATH/xbbc/bar_top.gif" width="399" height="1"><BR><NOBR>];
  $XBBCToolbar .= $GRIP;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Bold();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/bold_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_BOLD]" title="$MSG[XBBC_BOLD]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Italicize();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/italicize_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_ITALICS]" title="$MSG[XBBC_ITALICS]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Underline();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/underline_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_UNDERLINE]" title="$MSG[XBBC_UNDERLINE]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_StrikeThrough();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/strike_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_STRIKE]" title="$MSG[XBBC_STRIKE]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_AlignLeft();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/left_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_ALIGNLEFT]" title="$MSG[XBBC_ALIGNLEFT]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_AlignCenter();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/center_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_ALIGNCENTER]" title="$MSG[XBBC_ALIGNCENTER]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_AlignRight();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/right_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_ALIGNRIGHT]" title="$MSG[XBBC_ALIGNRIGHT]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_AlignJustify();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/justify_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_ALIGNJUSTIFY]" title="$MSG[XBBC_ALIGNJUSTIFY]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Font$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/font_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_FONTFULL]" title="$MSG[XBBC_FONTFULL]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_FontFace$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/face_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_FONTFACE]" title="$MSG[XBBC_FONTFACE]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_FontColor$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/color_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_FONTCOLOR]" title="$MSG[XBBC_FONTCOLOR]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_FontSize$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/size_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_FONTSIZE]" title="$MSG[XBBC_FONTSIZE]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_BulletList();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/list_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_BULLETLIST]" title="$MSG[XBBC_BULLETLIST]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_EnumList();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/enum_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_ENUMLIST]" title="$MSG[XBBC_ENUMLIST]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="$THIS_URL?show=help&help=markup" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/help_1.gif" $BUTTON_STYLE alt="$MSG[SUBTITLE_HELP]" title="$MSG[SUBTITLE_HELP]" $SWITCH></A>];
  $XBBCToolbar .= $NEWLINE;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_SubScript();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/sub_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_SUBSCRIPT]" title="$MSG[XBBC_SUBSCRIPT]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_SuperScript();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/sup_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_SUPERSCRIPT]" title="$MSG[XBBC_SUPERSCRIPT]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_QuoteText$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/quotetext_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_QUOTETEXT]" title="$MSG[XBBC_QUOTETEXT]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_CodeLines();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/code_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_CODELINES]" title="$MSG[XBBC_CODELINES]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_NoMarkup();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/nomarkup_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_NOMARKUP]" title="$MSG[XBBC_NOMARKUP]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_TypeWriter();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/tt_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_TYPEWRITER]" title="$MSG[XBBC_TYPEWRITER]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Indent();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/indent_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_INDENT]" title="$MSG[XBBC_INDENT]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_HorizontalRule();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/hr_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_HORLINE]" title="$MSG[XBBC_HORLINE]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Marquee();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/move_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_MOVETEXT]" title="$MSG[XBBC_MOVETEXT]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Table();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/table_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_TABLE]" title="$MSG[XBBC_TABLE]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_TableRow();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/tr_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_TABLEROW]" title="$MSG[XBBC_TABLEROW]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_TableCol();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/td_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_TABLECELL]" title="$MSG[XBBC_TABLECELL]" $SWITCH></A>];
  $XBBCToolbar .= $NEWLINE;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Shadow$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/shadow_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_SHADOW]" title="$MSG[XBBC_SHADOW]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Glow$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/glow_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_GLOWTEXT]" title="$MSG[XBBC_GLOWTEXT]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Image$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/img_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_IMAGE]" title="$MSG[XBBC_IMAGE]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Flash$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/flash_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_FLASH]" title="$MSG[XBBC_FLASH]" $SWITCH></A>];
  $XBBCToolbar .= $SPLIT;;
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_URL$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/url_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_URLHTTP]" title="$MSG[XBBC_URLHTTP]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_FTP$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/ftp_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_URLFTP]" title="$MSG[XBBC_URLFTP]" $SWITCH></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="XBBC_Email$Dialog();return false" class="XBBCButton"><IMG src="$IMAGE_URLPATH/xbbc/email_1.gif" $BUTTON_STYLE alt="$MSG[XBBC_URLMAILTO]" title="$MSG[XBBC_URLMAILTO]" $SWITCH></A>];

  $XBBCToolbar .= qq[<BR><IMG src="$IMAGE_URLPATH/xbbc/bar_bottom.gif" width="400" height="1"></NOBR><BR>\n];
  $XBBCToolbar .= qq[          </TD></TR></TABLE>\n];

  } # End allow.



  # Make the smileybar
  $BUTTON_STYLE = qq[border="0" width="16" height="16"];

  $XBBCToolbar .= qq[          <NOBR>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Happy();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/happy.gif" $BUTTON_STYLE alt="$MSG[XBBC_HAPPY] :)" title="$MSG[XBBC_HAPPY] :)"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Wink();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/wink.gif" $BUTTON_STYLE alt="$MSG[XBBC_WINK] ;)" title="$MSG[XBBC_WINK] ;)"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Cheesy();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/cheesy.gif" $BUTTON_STYLE alt="$MSG[XBBC_CHEESY] :D" title="$MSG[XBBC_CHEESY] :D"></A>];
  $XBBCToolbar .= qq[</NOBR>\n          <NOBR>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Sad();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/sad.gif" $BUTTON_STYLE alt="$MSG[XBBC_SAD] :)" title="$MSG[XBBC_SAD] :)"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Angry();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/angry.gif" $BUTTON_STYLE alt="$MSG[XBBC_ANGRY] &gt;:-(" title="$MSG[XBBC_ANGRY] &gt;:-("></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Devious();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/devious.gif" $BUTTON_STYLE alt="$MSG[XBBC_DEVIOUS] &gt;:-)" title="$MSG[XBBC_DEVIOUS] &gt;:-)"></A>];
  $XBBCToolbar .= qq[</NOBR>\n          <NOBR>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Grin();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/grin.gif" $BUTTON_STYLE alt="$MSG[XBBC_GRIN] ;D" title="$MSG[XBBC_GRIN] ;D"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Kiss();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/kiss.gif" $BUTTON_STYLE alt="$MSG[XBBC_KISS] :-*" title="$MSG[XBBC_KISS] :-*"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Cool();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/cool.gif" $BUTTON_STYLE alt="$MSG[XBBC_COOL] 8)" title="$MSG[XBBC_COOL] 8)"></A>];
  $XBBCToolbar .= qq[</NOBR>\n          <NOBR>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Cry();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/cry.gif" $BUTTON_STYLE alt="$MSG[XBBC_CRY] :'(" title="$MSG[XBBC_CRY] :'("></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Tongue();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/tongue.gif" $BUTTON_STYLE alt="$MSG[XBBC_TONGUE] :P" title="$MSG[XBBC_TONGUE] :P"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Embarassed();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/embarassed.gif" $BUTTON_STYLE alt="$MSG[XBBC_EMBARASSED] {:-(" title="$MSG[XBBC_EMBARASSED] {:-("></A>];
  $XBBCToolbar .= qq[</NOBR>\n          <NOBR>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Shocked();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/shocked.gif" $BUTTON_STYLE alt="$MSG[XBBC_SHOCKED] :o" title="$MSG[XBBC_SHOCKED] :o"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Confused();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/confused.gif" border="0" width="16" height="22" alt="$MSG[XBBC_CONFUSED] ???" title="$MSG[XBBC_CONFUSED] ???"></A>];
  $XBBCToolbar .= qq[</NOBR>\n          <NOBR>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_RollEyes();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/rolleyes.gif" $BUTTON_STYLE alt="$MSG[XBBC_ROLLEYES] 69)" title="$MSG[XBBC_ROLLEYES] 69)"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Undecided();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/undecided.gif" $BUTTON_STYLE alt="$MSG[XBBC_UNDECIDED] :-/" title="$MSG[XBBC_UNDECIDED] :-/"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_MouthShut();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/mouthshut.gif" $BUTTON_STYLE alt="$MSG[XBBC_MOUTHSHUT] :-x" title="$MSG[XBBC_MOUTHSHUT] :-x"></A>];
  $XBBCToolbar .= qq[<A href="#" onClick="Smiley_Sleeping();return false" class="SmileyButton"><IMG src="$IMAGE_URLPATH/smileys/sleeping.gif" $BUTTON_STYLE alt="$MSG[XBBC_SLEEPING] N:)" title="$MSG[XBBC_SLEEPING] N:)"></A>];
  $XBBCToolbar .= qq[</NOBR>\n          <NOBR>];
  $XBBCToolbar .= qq[<A href="$THIS_URL?show=smileylist&javascript=0" onClick="return ShowSmileys()">$MSG[ACTION_MORE]</A>];
  $XBBCToolbar .= qq[</NOBR>\n          ];



  # Icon select box
  my $IconSelected = $IconName || 'default';
  my @IconOptions = ('default' => 'Default');  # At the top


  # Get the icons
  if(@IconFiles)
  {
    foreach my $Icon (@IconFiles)
    {
      push @IconOptions, $Icon, ucfirst($Icon) unless($Icon eq 'default');
    }
  }




  # The header of the form are determined by our caller
  my @Actions =    ('action'   => $FormAction);
  if ($FormAction eq 'addpost' || $FormAction eq 'editpost')
  {
    push @Actions, ('topic'    => $Topic);
    push @Actions, ('post'     => $Post) if ($FormAction eq 'editpost');
  }
  elsif ($FormAction eq 'addtopic')
  {
    push @Actions, ('subject'  => $Subject);
  }



  # Add a test for another field, if we this is a compose dialog.
  my @REQ_FIELDS_XBBC = @REQ_FIELDS_XBBC;
  push @REQ_FIELDS_XBBC, 'to'              if($FormAction eq 'compose');


  if($XForumUser eq '')
  {
    print qq[    $MSG[LOGIN_REGTIP]<BR>\n];
    print qq[    $MSG[LOGIN_REENTER1] <A href="$THIS_URL?show=login">$MSG[LOGIN_REENTER2]</A> $MSG[LOGIN_REENTER3]<BR>\n];

    push @REQ_FIELDS_XBBC, 'poster', 'email';
    push @EMAIL_FIELDS_XBBC, 'email';
  }


  # Print table
  print_inputfields_HTML(
                          $TABLE_600_HTML => qq[name="xbbceditor"],1,
                          @Actions,
                        );
  print_required_TEST(@REQ_FIELDS_XBBC);
  print_email_TEST(@EMAIL_FIELDS_XBBC) if(@EMAIL_FIELDS_XBBC);



  # Print account info, or guest input fields
  if($XForumUser)
  {
    print_memberinfo_HTML();
  }
  else
  {
    print_editcells_HTML(
                          $MSG[GROUP_GUESTINFO]           => 1,
                          $REQ_HTML.$MSG[MEMBER_DISPNAME] => qq[<INPUT type="text" class="CoolText" name="poster" size="60">],
                          $REQ_HTML.$MSG[MEMBER_EMAIL]    => qq[<INPUT type="text" class="CoolText" name="email" size="60">],
                        );
  }



  # Determine variable fields when composing, or guest is posting
  my @SendMessageTo;
  my @CheckBoxes;
  if($FormAction eq 'compose')
  {
    # Add the checkboxes
    push @SendMessageTo, $REQ_HTML.$MSG[MESSAGE_SENDTO]   => sprint_memberfield_HTML('to', 4, $SendTo);
    push @CheckBoxes,    $MSG[MESSAGE_SAVESENT]           => qq[<INPUT type="checkbox" class="CoolBox" name="savesent"><FONT size="1"> $MSG[MESSAGE_SAVEINFO]</FONT>];
  }
  elsif($XForumUser ne '')
  {
    if(! $HideNotify)
    {
      # Check whether we have notification turned on.
      my $Checked = '';
      if(dbHasNotify($Topic, $XForumUser)) { $Checked = ' CHECKED' }
      push @CheckBoxes,    $MSG[NOTIFY_ADDCHECK]          => qq[<INPUT type="checkbox" class="CoolBox" name="notify"$Checked><FONT size="1"> $MSG[NOTIFY_ADD_INFO]</FONT>];
    }
  }
  else
  {
    push @CheckBoxes,    $MSG[NOTIFY_ADDCHECK]            => qq[<IMG src="$IMAGE_URLPATH/icons/error.gif" width="16" height="16" border="0" alt="!" title=""> <FONT size="1">$MSG[GUEST_NONOTIFY]</FONT>];
  }



  # Print the XBBC text editor
  print_editcells_HTML(
                       $MSG[GROUP_MESSAGE]                => 1,
                       @SendMessageTo,
                       $REQ_HTML.$HTMLTitle               => qq[<INPUT type="text" class="CoolText" name="title" size="60" maxlength="80" value="$HTMLTitleValue">],
                       $REQ_HTML.$MSG[XBBC_ICON]          => sprint_selectfield_HTML('icon" class="autosize" onChange="DisplayIcon(this)', $IconSelected, \@IconOptions)
                                                           . qq[<IMG src="$IMAGE_URLPATH/posticons/$IconSelected.gif" name="viewicon" width="16" height="16">],
                       $MSG[XBBC_TOOLBAR]                 => $XBBCToolbar,
                       $REQ_HTML.$MSG[XBBC_MESSAGE]       => qq[<TEXTAREA name="msg" class="large" ROWS="12" COLS="45" onBlur="XBBC_StoreCaret()" onClick="XBBC_StoreCaret()" onKeyUp="XBBC_StoreCaret()" onSelect="XBBC_StoreCaret()" onChange="XBBC_StoreCaret()">$HTMLMessage</TEXTAREA>],
                       @CheckBoxes,
                      );
  print_buttoncells_HTML(
                          $HTMLSubmit                     => q[name="submit_post" onClick="this.form.target='';"],
                          $MSG[ACTION_PREVIEW]            => q[name="submit_preview" type="submit" onClick="return OpenPreview(this.form)"],
                          $MSG[ACTION_RESET]              => undef,
                        );
  print <<DHTML_DIALOG;
    <DIV id="XBBCDialog"></DIV>
DHTML_DIALOG
  print_footer_HTML();
}

1;
