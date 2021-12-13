##################################################################################################
##                                                                                              ##
##  >> Administrator Center <<                                                                  ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'admin_center.pl'} = 'Release 1.6';

LoadSupport('check_security');
LoadSupport('html_interface');
LoadSupport('html_tables');


##################################################################################################
## Check for admin member access.

sub CAN_REPAIR(){ 1 }   # Expects that the database consists of flat files.

ValidateAdminAccess();
my $Maintaince = ( -e "$DATA_FOLDER${S}x-forum.lock" ? 1 : 0);


##################################################################################################
## Admin: Index Page

sub Show_AdminCenterDialog
{
  CGI::cache(1);


  my $MaintainceAction  = ($Maintaince ? 'Deactivate' : 'Activate' ) . ' Maintaince Mode';
  my $MaintainceConfirm = ($Maintaince ? 'Are you sure you want to re-open the forum?' : 'Are you sure you want to close the forum?');
  my $MaintainceHref    = qq[admin_maintaince" onClick="return Maintaince()];
  my $RepairHref        = qq[admin_repair" onClick="return Repair()];

  my $MAINTAINCE_JS = <<JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function ConfirmAction(Text, Action)
      {
        if(confirm(Text))
        {
          // We use a hidden form to make the POST request.
          document.placeholder.elements['action'].value = Action;
          document.placeholder.submit();
        }
        return false;
      }

      function Maintaince() { return ConfirmAction("$MaintainceConfirm", 'admin_maintaince') }
      function Repair()     { return ConfirmAction("Are you sure you want to validate and repair everything in the database?", 'admin_repair') }
    // --></SCRIPT>
JS


  print_header;
  print_header_HTML('Admin Center', 'Admin Center', undef,$MAINTAINCE_JS);
  print_toolbar_HTML();
  print_treelevel_HTML('?show=admin_center'=>'Admin Center');
  print_bodystart_HTML();

  print <<PLACEHOLDER_HTML;
    <FORM name="placeholder" method="POST" action="$THIS_URLSEC">
      <INPUT type="hidden" name="action" value="admin_maintaince">
      <INPUT type="hidden" name="confirmback" value="$THIS_URLSEC?show=admin_center">
      <INPUT type="hidden" name="submit_yes" value="Yes">
    </FORM>
PLACEHOLDER_HTML


  my $SPLIT = qq[      </TR><TR>\n];

  print qq[    $TABLE_MAX_HTML\n];

  print_admintitle_HTML('Subjects');
    print_adminaction_HTML('admin_addsubject'    => 'Add a Forum Subject',   'Add subjects to the forum');
    print_adminaction_HTML('admin_editsubject'   => 'Edit a Forum Subject',  'Edit subjects of the forum');
    print_adminaction_HTML('admin_sortsubjects'  => 'Restucture Subjects',   'Reorder the forum subjects, and change categories');
    print_adminaction_HTML('admin_delsubject'    => 'Delete a Forum Subject','Delete a subject from the forum');
  print_admintitle_HTML('Member Groups');
    print_adminaction_HTML('admin_addgroup'      => 'Add a Member Group',    'Add membergroups to the forum');
    print_adminaction_HTML('admin_editgroup'     => 'Edit a Member Group',   'Edit membergroups of the forum');
  print_admintitle_HTML('Moderating');
    print_adminaction_HTML('admin_logfiles'      => 'View Loggging Files',   'View any changes recorded by the script');
    print_adminaction_HTML('admin_banusers'      => 'Ban Users',             'Ban Users from the forum');
    print_adminaction_HTML('admin_censor'        => 'Set Censored Words',    'Censored words can limit the use of violent or hateful language by users');
    print_adminaction_HTML($MaintainceHref       => $MaintainceAction,       'Once in maintaince mode, only an administrator can access the forum to do maintaince work!');
  print_admintitle_HTML('Forum Management');
    print_adminaction_HTML('admin_edittemplate'  => 'Edit Template',         'Edits the forum template, colors and style');
    print_adminaction_HTML('admin_editsettings'  => 'Edit Settings',         'Edits the forum settings, defined through the xf-settings.pl file');
    print_adminaction_HTML($RepairHref           => 'Repair database',       'The entire database will be tested and validated!') if CAN_REPAIR;
  print_admintitle_HTML('Miscellaneous');
    print_adminaction_HTML('admin_browser'       => 'Edit Forum Files',      'Manually edit forum data files');
  print qq[    </TABLE>\n];
  print_footer_HTML();
}


sub print_admintitle_HTML ($)
{ my($Title) = @_;
  print qq[      <TR bgcolor="$TABLHEAD_COLOR">\n];
  print qq[        <TD align="left" colspan="2"><FONT size="4" color="$TABLFONT_COLOR">$Title</FONT></TD>\n];
  print qq[      </TR><TR>\n];
}

sub print_adminaction_HTML ($$$)
{ my($URL, $Title, $Info) = @_;
  print qq[      <TR>]
      . qq[<TD><IMG src="$IMAGE_URLPATH/subjecticons/private.gif" width="16" height="16"> ]
      . qq[<A href="$THIS_URL?show=$URL"><FONT size="2"><B>$Title</B></FONT></A></TD>]
      . qq[<TD bgcolor="$DATABACK_COLOR"><FONT size="1" color="$DATAFONT_COLOR">$Info</FONT></TD>]
      . qq[</TR>\n];
}


##################################################################################################
## Admin: Maintaince On/Off

sub Show_AdminMaintainceDialog
{
  LoadSupport('dlg_confirm');
  Show_ConfirmDialog('Maintance Mode', ($Maintaince ? 'Are you sure you want to re-open the forum?' : 'Are you sure you want to close the forum?'));
}

sub Action_AdminMaintaince
{
  LoadSupport('dlg_confirm');
  Action_Confirm();

  if ($Maintaince) { Action_AdminMaintainceOff();print_log('MAINTAINCE','','STATUS=OFF') }
  else             { Action_AdminMaintainceOn() ;print_log('MAINTAINCE','','STATUS=ON') }

  print redirect("$THIS_URL?show=admin_center");
}

sub Action_AdminMaintainceOn   { dbSetFileContents("$DATA_FOLDER${S}x-forum.lock", q[Can't activate maintaince mode], q[If this file exists, the forum is locked for maintaince mode!]) };
sub Action_AdminMaintainceOff  { unlink("$DATA_FOLDER${S}x-forum.lock") or die "Can't turn off maintaince mode: $!"; }



##################################################################################################
## Admin: Repair

sub Show_AdminRepairDialog
{
  Action_Error("The current database type can't be repaired by this version of X-Forum!") unless CAN_REPAIR;
  LoadSupport('dlg_confirm');
  Show_ConfirmDialog('Recount', 'Are you sure you want to validate and repair everything in the database?');
}

sub Action_AdminRepair
{
  Action_Error("The current database type can't be repaired by this version of X-Forum!") unless CAN_REPAIR;
  LoadSupport('dlg_confirm');
  Action_Confirm();

  # Load other files, and perl checks their syntax first, because we go in maintaince.
  LoadSupport('admin_repair');
  LoadSupport('html_template');

  print_header;
  print_header_HTML('Repair Database', 'Repair Database');
  print_bodystart_HTML();
  print "<PRE>\n";

  {
    local($SIG{'__DIE__'})  = \&print_the_error; # Abort!
    local($SIG{'__WARN__'}) = \&print_the_error; # Abort!

    Action_AdminMaintainceOn();                  # This might take a while...
    print "Activated maintaince mode\n";


    Action_AdminDoRecount();                     # GO!
    print "\n\n\n";


    unless($Maintaince)
    {
      Action_AdminMaintainceOff();
      print "Deactivated maintaince mode\n";
    }

    print "DONE</PRE>\n";
    print qq[<P><A href="$THIS_URL?show=admin_center">Return to the Admin Center</A></P>\n];
    print_log('REPAIRDB','', "STATUS=DONE");
  }

  print_footer_HTML();
}

sub print_the_error
{ my($Error) = @_;
  chomp $Error;

  {
    no strict 'vars';
    $Error =~ s/\Q$main::THIS_PATH\E/\./g      unless(not defined $main::THIS_PATH);
    $Error =~ s/\Q$main::THIS_UPPATH\E/\.\./g  unless(not defined $main::THIS_PATH);
    use strict 'vars';
  }

  print qq[\n\n\n<FONT color="#FF0000">Aborting reparation due fatal error</FONT>: $Error\n];
  unless($Maintaince)
  {
    Action_AdminMaintainceOff();
    Action_AdminRepairOff();
    print "Deactivated maintaince mode\n";
    print qq[<FONT color="#FF0000">ABORTED</FONT></PRE>\n];
    print qq[<P><A href="$THIS_URL?show=admin_center">Return to the Admin Center</A></P>\n];
    print_footer_HTML();
  }
  print_log('REPAIRERR','', "ERROR=$Error");
}


1;
