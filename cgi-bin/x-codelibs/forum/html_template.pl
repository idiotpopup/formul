##################################################################################################
##                                                                                              ##
##  >> Interface HTML Parts: Template <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'html_template.pl'} = 'Release 1.6';


use CGI::Template;



##################################################################################################
## Template

my $InBody   = 0;
my $InHeader = 0;
$CGI::Template::LABEL = 'XFORUM';



##################################################################################################
## Check Online


my $Visitors = '';
my $Guests   = 0;


{
  LoadSupport('db_members') if($XForumUser ne '');

  my %MemberLinks;
  my $Found     = 0;
  my $EpochSecs = time();
  my $Name      = ($XForumUser ne '' ? dbGetMemberName($XForumUser) : '');
  my $SeenUser  = 0;


  ## OK, we define an inner-subroutine here,
  ## that will be used to update the vistors.rct

  ## BEGIN INNER SUBROUTINE ##
  my $UPDATE_MEMBERS =
  sub {
    my ($TTL, $IP, $Member, $Name) = split(/\|/);

    my $GotXForumUser = ($Member ne '' && $Member eq $XForumUser);
    $SeenUser = 1 if $GotXForumUser;  # Persistant value

    if ($TTL && ($EpochSecs - $TTL) <= $MEMBER_TTL     # Time not past?
    && ($XForumUserIP ne $IP)                          # Not the current user?? (IP)
    && (! $GotXForumUser))                             # Not the current user?? (login)
    {
      # If we don't need to change $_, analyse it.
      if ($Member eq '' || $Name eq '')
      {
        $Guests++;
      }
      else
      {
        $MemberNames{$Member}  = $Name;     # Update the buffer so all visitor-names are known already.
        $MemberLinks{$Member}  = sprint_memberlink_HTML($Member);
        $MemberOnline{$Member} = 1;         # He is online off course
      }
    }
    else
    {
      # Remove the line
      $_ = undef;
    }
  };
  ## END INNER SUBROUTINE ##


  my $TTLDB = new File::PlainIO("$DATA_FOLDER${S}visitors.rct", MODE_RDWR);
  if(defined $TTLDB)
  {
    # Update the file.
    $TTLDB->update($UPDATE_MEMBERS);
    $TTLDB->writeline("$EpochSecs|$XForumUserIP|$XForumUser|$Name\n");
    $TTLDB->close();
  }

  if ($XForumUser eq '' || $Name eq '')
  {
    $Guests++;
  }
  else
  {
    $MemberNames{$XForumUser}  = $Name;       # Update the buffer so all visitor-names are known already.
    $MemberLinks{$XForumUser}  = sprint_memberlink_HTML($XForumUser);
    $MemberOnline{$XForumUser} = 1;           # He is online off course
  }

  if($CAN_KEEPLOGIN && ! $SeenUser && $XForumUser ne '')
  {
    # Time to recheck your password ;-)
    LoadSupport('check_security');
    ValidateMemberCookie();
  }


  # Make the string to display
  my @MemberNames = sort { $MemberNames{$a} cmp $MemberNames{$b} }
                    keys %MemberLinks;

  foreach my $Member (@MemberNames)
  {
    $Visitors .= "$MemberLinks{$Member}, ";
  }

  # Also for the guests
  if    ($Guests == 0) { $Guests  =     $MSG[GUEST_NONE]   }
  elsif ($Guests == 1) { $Guests .= ' '.$MSG[GUEST_SINGLE] }
  elsif ($Guests >= 2) { $Guests .= ' '.$MSG[GUEST_MORE]   }
}




##################################################################################################
## HTML Parts

$TABLE_600_HTML = qq[<TABLE width="600" $TABLE_STYLE>];
$TABLE_MAX_HTML = qq[<TABLE width="100%" $TABLE_STYLE>];




##################################################################################################
## Template default replacements


my $Copyright1 = qq{$MSG[HTML_FOOTER1]}
               . qq{ <A href="mailto:webmaster\@codingdomain.com?subject=Reply\%20about\%20x-forum\%20script\%21">Diederik v/d Boor</A>}
               . qq{ [<A href="$THIS_URL?show=help&help=about">$MSG[HTML_FOOTER2]</A>]};
my $Copyright2 = qq{$MSG[HTML_FOOTER2B] <A href="$THIS_URL?show=help&help=about">X-Forum</A>};


TemplateSetReplace( SITE         => $THIS_SITE                 );
TemplateSetReplace( URL          => $THIS_URL                  );
TemplateSetReplace( IMAGEURL     => $IMAGE_URLPATH             );
TemplateSetReplace( MEMBERLIST   => $MSG[SUBTITLE_MEMBERLIST]  );
TemplateSetReplace( USERSONLINE  => "$MSG[VISITOR_LIST]:"      );
TemplateSetReplace( VISITORS     => "$Visitors$Guests"         );
TemplateSetReplace( COPYRIGHT    => $Copyright1                );
TemplateSetReplace( SUPERVISION  => "$MSG[HTML_SUPERVISION]: " . sprint_webmaster_HTML(1) );
TemplateSetReplace( WEBMASTER    => (sprint_webmaster_HTML(1, 1) || '') );





##################################################################################################
## Get Template File with the line breaks


TemplateLoad("$DATA_FOLDER${S}settings${S}$TEMPLATE_FILE");
$TemplateLoaded = 1;



##################################################################################################
## Print the HTTP header. (litte adjustment from CGI.pm)

sub print_header
{
  return if($HEADER_PRINTED);
  $HEADER_PRINTED = 1;

  if(CGI::cache())
  {
    push @_, -expires => 'Thu, 01-Jan-1970 00:00:01 GMT';
  }

  print header(@_) || '';
}


##################################################################################################
## Headers and Footers. You can change it, but please keep the credits to me.
## (Although you may change the formatting to your site's style).

sub print_header_HTML (;$$$$) #([STRING Title][, STRING SubTitle][, STRING Redirect][, STRING MoreCode])
{ my ($Title, $SubTitle, $Redirect, $More) = @_;
  return if $InHeader;


  # Build up header
  $More     ||= '';
  $SubTitle ||= '';
  $Title    ||= '';
  $Title      = "$FORUM_TITLE" . ($Title ne '' ? ": $Title" : '');

  if (defined $Redirect) { $Redirect = qq[<META http-equiv="refresh" content="$Redirect">]; }
  else                   { $Redirect = ""; }

  TemplateSetReplace( 'SUBTITLE' => $SubTitle );

  my $HeaderHTML = <<HEADER_HTML;
    <TITLE> $Title </TITLE>
    <META name="author" content="Diederik van der Boor">
    <META name="generator" content="X-Forum CGI Script">
    $Redirect
$More    <LINK rel="StyleSheet" href="$LIBARY_URLPATH/style.css">
HEADER_HTML
  chomp $HeaderHTML;


  print_TemplateUntil('HEADER' => $HeaderHTML);
  $CGI::ErrorTrap::DIALOG_FULL = 0;
  $InHeader = 1;
}



##################################################################################################
## HTML Parts

sub print_smalldlg_HTML ()
{
  TemplateSetReplace( USERSONLINE  => "");
  TemplateSetReplace( VISITORS     => "");
  TemplateSetReplace( SUPERVISION  => "");
  TemplateSetReplace( COPYRIGHT    => $Copyright2);
}

sub print_bodystart_HTML ()
{
  return if $InBody;
  print_TemplateUntilLabel('BODY'); # Prints all template codes until <!--XFORUM::BODY-->
  $InBody = 1;
}


sub print_footer_HTML ()
{
  print_TemplateUntilEOF();
  exit;
}


sub sprint_webmaster_HTML #([BOOLEAN CanBeUndef], [BOOLEAN NoPreText]) >> STRING HTML
{
  my $Mail = ($WEBMASTER_MAIL || $ENV{SERVER_ADMIN});
  if($Mail)
  {
    return qq[<a href="mailto:$Mail">$Mail</a>] if ($_[1]);
    return qq[(<a href="mailto:$Mail">$Mail</a>)];
  }
  else
  {
    return undef if ($_[0]);
    return $MSG[HTML_WEBMASTER_X];
  }
}



sub sprint_memberlink_HTML # Will be called too early to check prototype
{
  LoadSupport('db_members');
  if(dbMemberIsGuest($_[0]))
  {
    my($G, $Name, $Email) = split(/:/, $_[0]);
    return $Name || $MSG[HTML_NA];
  }
  elsif(! dbMemberExist($_[0]))
  {
    return "&lt;$MSG[MEMBER_UNKNOWN] - $_[0]&gt;";
  }
  else
  {
    return qq[<A href="$THIS_URL?show=member&member=$_[0]">] . dbGetMemberName($_[0]) . "</A>";
  }
}

1;
