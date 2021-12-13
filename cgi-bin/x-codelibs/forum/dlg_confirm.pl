##################################################################################################
##                                                                                              ##
##  >> Confirmation of some hyperlink actions <<                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_confirm.pl'} = 'Release 1.6';


#################################################################################################
## Show Confirm Dialog


sub Show_ConfirmDialog ($$)
{ my($SubTitle, $Msg) = @_;

  LoadSupport('html_tables');
  LoadSupport('html_fields');

  my $NoQuery  = (referer || $THIS_URL);
  my $YesQuery = (query_string || '');
  $YesQuery   .= ($YesQuery ne '' ? '&confirm=1' : '?confirm=1');


  my @Actions;
  foreach my $Name (param)
  {
    my $Value = (param($Name) || '');
    $Name     = 'action' if ($Name eq 'show');
    push @Actions, ($Name => $Value);
  }


  # JavaScript
  my $CONFIRM_JS = <<CONFIRM_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
    function ConfirmNo()
    {
      if(history.length)
      {
        history.go(-1);
        return false;
      }
      else
      {
        return true;
      }
    }
    // --></SCRIPT>
CONFIRM_JS


  # HTML Header
  CGI::cache(1);
  print_header;
  print_header_HTML($SubTitle . " [$MSG[SUBTITLE_CONFIRM]]", $MSG[SUBTITLE_CONFIRM], undef, "$FORM_JS$CONFIRM_JS");
  print_bodystart_HTML();
  print_inputfields_HTML(
                          $TABLE_600_HTML        => undef,0,
                          @Actions,
                          'confirmback'          => $NoQuery,
                        );
  print_editcells_HTML(
                        $SubTitle               => 1,
                        $MSG[SUBTITLE_CONFIRM]  => $Msg
                      );
  print_buttoncells_HTML(
                          $MSG[CONFIRM_YES]      => q[name="submit_yes"],
                          $MSG[CONFIRM_NO]       => q[name="submit_no" type="submit" onClick="return ConfirmNo()"],
                          undef                  ,  undef,
                        );
  print_footer_HTML();
}




sub Action_Confirm ()
{
  my $Confirm = (param('confirm') || '');

  if(param('submit_yes'))
  {
    return
  }
  elsif(param('submit_no'))
  {
    my $PageNo = (param('confirmback') || $THIS_URL);
    print redirect($PageNo);
    exit;
  }
  else
  {
    Action_Error();
  }
}



1;
