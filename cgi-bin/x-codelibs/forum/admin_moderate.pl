##################################################################################################
##                                                                                              ##
##  >> Administrator Moderate <<                                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'admin_moderate.pl'} = 'Release 1.4';

LoadSupport('check_security');


# Check for admin member access.
ValidateAdminAccess();


##################################################################################################
## Admin: Ban Users

sub Show_AdminBanUsersDialog ()
{
  LoadSupport('html_fields');

  my @MemberBan;
  my $IPBan     = '';


  @MemberBan = dbGetFileContents("$DATA_FOLDER${S}settings${S}members.ban", FILE_NOERROR);

  # Get the raw data
  my $BANIP = new File::PlainIO("$DATA_FOLDER${S}settings${S}ips.ban", MODE_READ);
  if(defined $BANIP)
  {
    $IPBan = $BANIP->readall();
    $BANIP->close();
  }


  # Header
  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Ban Users]', 'Admin Center <FONT size="-1">[Ban Users]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'           => 'Admin Center',
                        '?show=admin_banusers'         => 'Ban Users'
                      );
  print_bodystart_HTML();


  # Information about banning
  print <<ADMIN_BANUSERS;
    There are two methods to ban users: either by the IP of their computers, and
    by their account name. Note that you have to be sure about the IP before you ban it,
    especially if it's a Proxy of Dynamic IP address. The IP can be written like 192.168.12.213 or even 128.0.*.*!
ADMIN_BANUSERS


  # Input
  print_inputfields_HTML(
                          $TABLE_600_HTML              => undef,1,
                          'action'                     => 'admin_banusers',
                        );
  print_editcells_HTML(
                        'Ban Users'                    => 1,
                        'IP Banning'                   => qq[<TEXTAREA name="ipban" class="small" ROWS="4" COLS="45">$IPBan</TEXTAREA>],
                        'Member Account Banning'       => sprint_memberfield_HTML('memberban', 4, \@MemberBan),
                      );
  print_buttoncells_HTML('Ban');
  print_footer_HTML();
}




sub Action_AdminBanUsers ()
{
  LoadSupport('db_members');

  # Get Field values
  my $IPBan     = (param('ipban')      || '');
  my @MemberBan = param('memberban');

  $IPBan =~ s/$LINEBREAK_PATTERN/\n/g;

  # Well, this is strange, but I don't need more.
  while(chomp $IPBan)     {}


  # Preform Field Checks
  foreach my $Member (@MemberBan)
  {
    chomp $Member;
    if($Member eq 'admin')
    {
      Action_Error(q[The administrator can't be banned!]);
    }
    if(dbMemberFileInvalid($Member))
    {
      Action_Error("Invalid Banned Member '$Member' in memberlist!");
    }
  }


  my @BanIP = split(/\n/, $IPBan);
  chomp @BanIP;

  foreach my $IP (@BanIP)
  {
    if(! IsIPBlock($IP))                   { Action_Error("The list element '$IP' is not an IP block!"); }
  }

  if(    IsIPInBlock('127.0.0.1', @BanIP)) { Action_Error("The 'localhost' computer (127.0.0.1) can't be banned!"); }
  elsif( IsClientIP(@BanIP))               { Action_Error("You can't ban yourself! ($XForumUserIP)"); }


  # Save Files
  dbSetFileContents("$DATA_FOLDER${S}settings${S}ips.ban", 'IP banning file' => $IPBan);
  dbSetFileContents("$DATA_FOLDER${S}settings${S}members.ban", 'Members banning file' => @MemberBan);


  # Log print and redirect
  print_log("CHBAN");
  print redirect("$THIS_URLSEC?show=admin_center");
  exit;
}

##################################################################################################
## Admin: Censor Words

sub Show_AdminCensorDialog ()
{
  LoadSupport('html_fields');

  # Check for admin member access.
  ValidateAdminAccess();

  my $Censor = '';
  my $Language = $LANGUAGE;
  my %Censor = dbGetFileContents("$DATA_FOLDER${S}settings${S}$Language.cen", FILE_NOERROR);
  foreach my $Word (sort keys %Censor) { $Censor .= "$Word=$Censor{$Word}\n"; }

  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Censor Words]', 'Admin Center <FONT size="-1">[Censor Words]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'                   => 'Admin Center',
                        '?show=admin_censor'                   => 'Censor Words'
                      );
  print_bodystart_HTML();
  print_inputfields_HTML(
                          $TABLE_600_HTML                      => undef,1,
                          'action'                             => 'admin_censor',
                          'language'                           => $Language, # Language may have changed when changed submitted
                        );
  print_editcells_HTML(
                        'Censor Words'                         => 1,
                        'Word=Replacement (one line each)'     => qq[<TEXTAREA name="censor" class="large" ROWS="8" COLS="45">$Censor</TEXTAREA>]
                      );
  print_buttoncells_HTML('Save');
  print_footer_HTML();
}


sub Action_AdminCensor ()
{
  LoadSupport('check_fields');

  # Check for admin member access.
  ValidateAdminAccess();

  # Get Field values
  my $Censor   = (param('censor')     || '');
  my $Language = (param('language')   || $LANGUAGE);
  ValidateRequired($Censor, $Language);

  $Censor =~ s/$LINEBREAK_PATTERN/\n/g;
  $Censor =~ s/=/\n/g;
  while(chomp $Censor) {}

  # Save Files
  dbSetFileContents("$DATA_FOLDER${S}settings${S}$Language.cen", 'Censor words', $Censor);

  # Log print and redirect
  print_log("CHCENSOR");
  print redirect("$THIS_URLSEC?show=admin_center");
  exit;
}

1;
