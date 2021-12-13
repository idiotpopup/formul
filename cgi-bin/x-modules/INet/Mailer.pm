package INet::Mailer;
my $packagename = 'INet::Mailer';

#
#       Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved
#
#       webmaster@codingdomain.com
#       http://www.codingdomain.com
#

use strict;

my $NETSMTP_SENDSESSION = 100;  # Reconnect when n e-mails sent
                                # using the same Net::SMTP connection

######################################################################################################
## Constants

my $MAILTYPE_SENDMAIL     =  1;
my $MAILTYPE_NETSMTP      =  2;
my $MAILTYPE_BLAT         =  3;

my $MAIL_SUCCESS          =  1;
my $MAILFAIL_PARAM        =  0;
my $MAILFAIL_UNAVAILABLE  = -1;
my $MAILFAIL_INIT         = -2;
my $MAILFAIL_FROM         = -3;
my $MAILFAIL_RCPT         = -4;
my $MAILFAIL_INITSEND     = -5;
my $MAILFAIL_SENDMSG      = -6;
my $MAILFAIL_SENDEND      = -7;
my $MAILFAIL_CLOSE        = -8;


BEGIN
{
  use vars      qw($VERSION);
  $VERSION      = 1.00;

  my $pkg       = caller()."::";
  {
    no strict 'refs';
    my $SUB_SendMail             = $pkg."SendMail";             *$SUB_SendMail             = \&SendMail;
    my $SUB_MakeMailMessage      = $pkg."MakeMailMessage";      *$SUB_MakeMailMessage      = \&MakeMailMessage;
    my $SUB_MAILTYPE_SENDMAIL    = $pkg."MAILTYPE_SENDMAIL";    *$SUB_MAILTYPE_SENDMAIL    = sub(){$MAILTYPE_SENDMAIL};
    my $SUB_MAILTYPE_NETSMTP     = $pkg."MAILTYPE_NETSMTP";     *$SUB_MAILTYPE_NETSMTP     = sub(){$MAILTYPE_NETSMTP};
    my $SUB_MAILTYPE_BLAT        = $pkg."MAILTYPE_BLAT";        *$SUB_MAILTYPE_BLAT        = sub(){$MAILTYPE_BLAT};
    my $SUB_MAIL_SUCCESS         = $pkg."MAIL_SUCCESS";         *$SUB_MAIL_SUCCESS         = sub(){$MAIL_SUCCESS};
    my $SUB_MAILFAIL_PARAM       = $pkg."MAILFAIL_PARAM";       *$SUB_MAILFAIL_PARAM       = sub(){$MAILFAIL_PARAM};
    my $SUB_MAILFAIL_UNAVAILABLE = $pkg."MAILFAIL_UNAVAILABLE"; *$SUB_MAILFAIL_UNAVAILABLE = sub(){$MAILFAIL_UNAVAILABLE};
    my $SUB_MAILFAIL_INIT        = $pkg."MAILFAIL_INIT";        *$SUB_MAILFAIL_INIT        = sub(){$MAILFAIL_INIT};
    my $SUB_MAILFAIL_FROM        = $pkg."MAILFAIL_FROM";        *$SUB_MAILFAIL_FROM        = sub(){$MAILFAIL_FROM};
    my $SUB_MAILFAIL_RCPT        = $pkg."MAILFAIL_RCPT";        *$SUB_MAILFAIL_RCPT        = sub(){$MAILFAIL_RCPT};
    my $SUB_MAILFAIL_INITSEND    = $pkg."MAILFAIL_INITSEND";    *$SUB_MAILFAIL_INITSEND    = sub(){$MAILFAIL_INITSEND};
    my $SUB_MAILFAIL_SENDMSG     = $pkg."MAILFAIL_SENDMSG";     *$SUB_MAILFAIL_SENDMSG     = sub(){$MAILFAIL_SENDMSG};
    my $SUB_MAILFAIL_SENDEND     = $pkg."MAILFAIL_SENDEND";     *$SUB_MAILFAIL_SENDEND     = sub(){$MAILFAIL_SENDEND};
    my $SUB_MAILFAIL_CLOSE       = $pkg."MAILFAIL_CLOSE";       *$SUB_MAILFAIL_CLOSE       = sub(){$MAILFAIL_CLOSE};
  }
}



##################################################################################################
# Taken from CGI.pm

sub server_name { return $ENV{'SERVER_NAME'} || 'localhost'; }

sub virtual_host
{
  my $vh = $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'} || 'localhost';
  $vh =~ s/:\d+$//;           # get rid of port number
  return $vh;
}


##################################################################################################
## Constructor

sub new ($$)
{
  my $classname = shift;
  my($Type) = pop;
  my ($PROG, $SMTP) = @_;
  $SMTP ||= $PROG;

  die "Usage: new $packagename([PROG], [RELAYHOST], MAILTYPE_SENDMAIL|MAILTYPE_NETSMTP|MAILTYPE_BLAT)".CallerLocation() unless(@_ == 2 || @_ == 1);

  # We don't allow these things:
  #   $x = PackageName::new();
  #   $y = $x->new();

  if(! defined $classname) { die "Syntax error: Class name expected after new".CallerLocation() }
  if(  ref     $classname) { die "Syntax error: Can't construct new ".ref($classname)." from another object".CallerLocation() }

  return ($MAILFAIL_PARAM, "Bad constant used".CallerLocation()) if !IsValidType($Type);

  # Instance fields
  my $this         = {};
  $this->{_TYPE}   = $Type;
  $this->{_PROG}   = $PROG;
  $this->{_SMTP}   = $SMTP;
  $this->{_H}      = undef;
  $this->{_N}      = 0;

  # Make the object 'self-aware';
  bless $this, $classname;           # Double argument version to enable Inheritance ;-)
  return $this;
}


##################################################################################################
# Methods

sub open
{
  my($this, $type, $H) = self(shift);
  my $isopen = defined $this->{_H};
  die "Can't open a connection that is already open".CallerLocation() if $isopen;

  if($type == $MAILTYPE_NETSMTP)
  {
    my $SMTP = $this->{_SMTP};   # Net::SMTP relay host
    $SMTP ||= virtual_host();

    {
      # Don't know why, but $! is set sometimes at
      # the eval() statement or a warning is generated.
      local($!);
      local($@);
      local($^W) = 0;

           eval('use Net::SMTP');                  if($@) { return($MAILFAIL_UNAVAILABLE, "Net::SMTP libary not available"); }
      $H = eval('return Net::SMTP->new($SMTP);');  if($@) { return($MAILFAIL_INIT, "Net::SMTP constructor failed: $@"); }

      if(not defined $H)                                  { return($MAILFAIL_INIT, "Failed to connect to $SMTP on SMTP port"); }
    }
    $this->{_H}    = $H;
    $this->{_SMTP} = $SMTP;
    return;
  }
  elsif($type == $MAILTYPE_SENDMAIL)
  {
    my $PROG = $this->{_PROG};  # sendmail program location
    $PROG ||= '/usr/lib/sendmail';
    if (! -e $PROG) { return($MAILFAIL_UNAVAILABLE, 'Sendmail location invalid'); }
    $this->{_PROG} = $PROG;
    return;
  }
  elsif($type == $MAILTYPE_BLAT)
  {
    my $PROG = $this->{_PROG};
    my $SMTP = $this->{_SMTP};
    $PROG ||= ($ENV{'SYSTEMROOT'} || 'C:\Windows') . '\System32\blat.exe';
    $SMTP ||= virtual_host();

    if (! -e $PROG) { return($MAILFAIL_UNAVAILABLE, 'Blat location invalid'); }
    $this->{_PROG} = $PROG;
    $this->{_SMTP} = $SMTP;
    return;
  }
}

sub abort
{
  my($this, $type, $H) = self(shift, 1);

  if($type == $MAILTYPE_NETSMTP)
  {
    $H->reset() or return($MAILFAIL_CLOSE, 'SMTP Close rset failed: '.reply($H));
    $H->quit()  or return($MAILFAIL_CLOSE, 'SMTP Close failed: '.reply($H));
    $H = undef;
    $this->{_H} = undef;
  }
}

sub close
{
  my($this, $type, $H) = self(shift, 1);

  if($type == $MAILTYPE_NETSMTP)
  {
    $H->quit() or return($MAILFAIL_CLOSE, 'SMTP Close failed: '.reply($H));
    $H = undef;
    $this->{_H} = undef;
  }
}

sub send
{
  my($this, $type, $H) = self(shift);
  my $isclosed = ! defined $this->{_H};

  die "Usage: \$mailobj->send(MESSAGE, FROM_EMAIL, TO_EMAIL, [TOEMAIL_N])".CallerLocation() unless(@_ >= 3);

  if($type == $MAILTYPE_NETSMTP)
  {
    die "Can't do anything with a closed connection".CallerLocation() if $isclosed;

    my $message = shift;
    my $from    = shift; # @to = @_;

    if($this->{_N} > 0 && ($this->{_N} % $NETSMTP_SENDSESSION) == 0)
    {
      # After each sending quite some e-mails, we re-connect to the SMTP server.
      $H = undef; # Also destroy this reference
      my @ret;
         @ret = $this->abort();   return @ret if(defined $ret[0]);
         @ret = $this->open();    return @ret if(defined $ret[0]);
      $H = $this->{_H};
    }

    $H->mail($from)        or return($MAILFAIL_FROM,     'SMTP mail from adres invalid: '.reply($H));  # MAIL FROM:<$from>
    $H->recipient(@_)      or return($MAILFAIL_RCPT,     'SMTP recipient (@_) invalid: '.reply($H));   # RCPT TO:<$to>
    $H->data()             or return($MAILFAIL_INITSEND, 'SMTP Init data stream failed: '.reply($H));  # DATA
    $H->datasend($message) or return($MAILFAIL_SENDMSG,  'SMTP Message sending failed: '.reply($H));   # The Message; will be converted into SMTP format
    $H->dataend()          or return($MAILFAIL_SENDEND,  'SMTP End data stream failed: '.reply($H));   # CRLF.CRLF
    $this->{_N}++;
  }
  elsif($type == $MAILTYPE_SENDMAIL)
  {
    my $message = shift;

    my $PROG = $this->{_PROG};
    local *MAIL;

    CORE::open(MAIL, "|$PROG -t -oi -odq") or return($MAILFAIL_INIT, "Failed to open sendmail pipe: $!");
    CORE::print MAIL $message;
    CORE::close(MAIL) or return($MAILFAIL_CLOSE, "Failed work woth sendmail pipe: $^E");
    $this->{_N}++;
  }
  elsif($type == $MAILTYPE_BLAT)
  {
    my $msg     = shift;
    my $from    = shift;
    my @to      = @_;

    my($header, $message) = ($msg =~ m/(.+?)\n\n(.+)/s);
    $header      = ''                                unless defined $header;
    $message     = $msg                              unless defined $message;
    my($XMailer) = ($header =~ m/^X-Mailer:\s*(.+)$/im);
    my($subject) = ($header =~ m/^Subject:\s*(.+)$/im);
    $XMailer     = "X-Mailer: INet::Mailer for Perl" unless defined $XMailer;
    $subject     = ''                                unless defined $subject;
    chomp $subject;

    my $PROG = $this->{_PROG};
    my $SMTP = $this->{_SMTP};
    local *MAIL;

    # That's the bad thing of blat: variables have to be send over
    # the shell command line (fortunately, Windows' Cmd doesn't
    # use all characters as the UNIX shell does)
    s{([^A-Za-z_0-9.@])} {\\$1}g for($from, @to, $SMTP);
    s{(\s)}              {\\$1}g for($from, @to. $SMTP);
    s{"}                 {\\"}g  for($subject, $XMailer);

#    my $TempFile = use_temp_file($message, 'blat');

    # -log \"blat.txt\"
    my $CMD = "$PROG"
#           . " $TempFile"               # Use with system() method
            . " -"                       # Use with pipeopen method
            . " -f $from"                # From
            . " -t ".join(",",@to)       # To
            . " -subject \"$subject\""   # Subject
            . " -server $SMTP"           # SMTP server
            . " -q"                      # Quiet
            . " -noh2"                   # No X-Mailer: blat header
            . " -x \"$XMailer\""         # Our own X-Mailer header
            ;

#    my $out = qx/$CMD/;
#    {
#      local $?
#      local $!;
#      unlink($TempFile) or return($MAILFAIL_CLOSE, "Failed to delete temp file for blat: $!");
#    }

#    $? = 3 if(!$? && $out=~/\nsyntax:\n/); # workaround syntax error that returns 0
#    $? and return($MAILFAIL_CLOSE, "Failed to use blat system call: $! $out");

    CORE::open(MAIL, "| $CMD") or return($MAILFAIL_INIT, "Failed to open blat pipe: $!");
    CORE::print MAIL $message;
    CORE::close(MAIL) or return($MAILFAIL_CLOSE, "Failed work with blat pipe: $^E");

    $this->{_N}++;
  }
  return($MAIL_SUCCESS, 'E-mail sent');
}

sub DESTROY
{
  my($this) = self(shift);
  $this->abort() if defined $this->{_H};
}

sub sendsimple ($$$$$$)
{
  my($this) = self(shift);
  my($FromName, $FromEmail, $ToName, $ToEmail, $Subject, $Body) = @_;
  die "Usage: \$mailobj->sendmsg(FROM_NAME, FROM_EMAIL, TO_NAME, TO_EMAIL, FROM_EMAIL, MESSAGE_SUBJECT, MESSAGE_BODY)".CallerLocation() unless(@_ == 6);

  my $message = MakeMailMessage($FromName, $FromEmail, $ToName, $ToEmail, $Subject, $Body);
  return $this->send($message, $FromEmail, $ToEmail);
}


######################################################################################
## Old functions from the original non-oo version:

sub SendMail #($$$$@)
{ my ($PROG, $SMTP, $Type, $Msg, $SMTPFrom, @SMTPTo) = @_;
  die "Usage: SendMail(PROGRAM, RELAYHOST, MAILTYPE, MESSAGE, FROM, TOARRAY)".CallerLocation() unless(@_ >= 5);
  return($MAILFAIL_PARAM, "Bad constant used".CallerLocation()) if !IsValidType($Type);
  my @r;
  my $mail = new INet::Mailer($PROG, $SMTP, $Type);
  @r=$mail->open();                         return @r if scalar @r;
  @r=$mail->send($Msg, $SMTPFrom, @SMTPTo); return @r if scalar @r;
  return($MAIL_SUCCESS, 'E-mail sent');
}

sub MakeMailMessage #($$$$$$)
{ my ($FromName, $FromEmail, $ToName, $ToEmail, $Subject, $Body) = @_;
  die "Usage: MakeMailMessage(FROM_NAME, FROM_EMAIL, TO_NAME, TO_EMAIL, FROM_EMAIL, MESSAGE_SUBJECT, MESSAGE_BODY)".CallerLocation() unless(@_ == 6);
  return <<SMTP_MESSAGE;
to: $ToName<$ToEmail>
from: $FromName<$FromEmail>
subject $Subject
X-Mailer: INet::Mailer for Perl

$Body
SMTP_MESSAGE
}


######################################################################################
## Private subroutines

sub reply
{
  my $SMTP = shift;
  my $code = $SMTP->code().' '.$SMTP->message();
  chomp($code);
  return $code;
}

sub use_temp_file
{
  require Fcntl;
  srand;

  my $id = $_[1] || '';

  my $filename = $id.$$.time.int(rand time).".tmp";

  my $tries = 0;

  until(sysopen(FH, $filename, Fcntl::O_WRONLY()|Fcntl::O_CREAT()|Fcntl::O_EXCL()))
  {
    # Again with a different filename
    $filename = $id.$$.time.int(rand time).".tmp";
    die "Can't create temp file (tried $tries times): $!" if($tries++ >= 200);
  }
  CORE::print FH $_[0];
  CORE::close(FH);

  return $filename;
}

sub CallerLocation (;$)
{
  my @c=caller(($_[0]||0)+1      -1);  ##EDIT##
  return "" unless @c;
  return " at $c[1] line $c[2]\n";
}

sub IsValidType
{ my($Type) = @_;
  return $Type == $MAILTYPE_NETSMTP
      || $Type == $MAILTYPE_SENDMAIL
      || $Type == $MAILTYPE_BLAT;
}

sub self ($)
{
  my $this = shift;
  if(! defined ref($this)) { die "Syntax error: Object expected".CallerLocation(+1) }
  return $this unless wantarray;
  return ($this, $this->{_TYPE}, $this->{_H});
}

1;


__END__

=head1 NAME

INet::Mailer - E-mails a message via SMTP

=head1 SYNOPSIS

  use INet::Mailer;

  # Generating a message quickly
  my $message1 = MakeMailMessage('Me', 'xx@yy.com', 'You', 'yy@@yy.com', 'Hello!', 'This is the message');
  my $message2 = MakeMailMessage('Me', 'xx@yy.com', 'You', 'zz@@zz.com', 'Hi!', 'This is the message');

  # Sending using the old functions
  SendMail('/usr/bin/sendmail', undef, MAILTYPE_SENDMAIL, 'xx@xx.com', 'yy@yy.com', $message1);
  SendMail(undef, 'mail.xx.com',       MAILTYPE_NETSMTP,  'xx@xx.com', 'yy@yy.com', $message1);
  SendMail('/blat.exe', 'mail.xx.com', MAILTYPE_BLAT,     'xx@xx.com', 'yy@yy.com', $message1);

  # Sending multiple e-mails using OO.
  my $mail = new INet::Mailer(undef, 'mail.xx.com', MAILTYPE_NETSMTP);
  $mail->open();
  $mail->send($message1, 'xx@xx.com', 'yy@yy.com');
  $mail->send($message2, 'xx@xx.com', 'zz@zz.com');
  $mail->close();


=head1 DESCRIPTION

This module can be used from any program written in Perl to send a e-mail.
This modules uses a OO style, which is faster to use when a lot of e-mails have to be sent.
The methods discussed belog will explain how this is done.
See RFC 821 for more details about sending e-mails with the SMTP protocol.

=head2 CREATING A NEW OBJECT

    $mailobj = new INet::Mailer( MAILPROG, MAILSERVER, CONSTANT );

The CONSTANT parameter is eiter MAILTYPE_SENDMAIL or MAILTYPE_NETSMTP.

The MAILPROG parameter contains the program used to send the e-mail, like sendmail or blat.

The MAILSERVER parameter defines when SMTP server to use for the Net::SMTP module or the blat program.
The SMTP-Server is a host that relays the e-mail. This is mail.yourdomain.com for example.

For both parameters, the module will use a default value if you don't provide it.

=head2 METHOD NOTES

The methods return nothing, or an empty list on success.
When something failed, they return an array containing 2 elements.
The first element contains a statuscode, which is also defined by some exported constant values.
The 2nd argument contains a string with a status text, explaining the error code.
Every status code below 1 implies an error occured.

The reason that this module doesn't throw any errors, is because that's difficult to handle
in a CGI environment.

=head2 METHODS

=over

=item open()

Opens the connection, using the parameters you passed through at the object creation.

=item sendsimple(FROM_NAME, FROM_EMAIL, TO_NAME, TO_EMAIL, SUBJECT, BODY)

Sends the e-mail. Unlike the send method, this method handles all the difficult work for you.
It formats the e-mail message in the right way. Internally, this simply calls the send method.

=item send(MESSAGE, FROM_EMAIL, TO_EMAIL, [TO_EMAIL2], [TO_EMAILN])

Sends the e-mail. You can call this method as many times as you need, without
closing or re-opening the connection. This reduces the time required to sent the e-mails,
if the Net::SMTP module is used. After a certain amount of e-mails, this method
will automatically close and re-open a connection. Some SMTP servers don't allow too much e-mails
being sent through the same connection.

The message argument contains the entire SMTP message, not just the body you always see in your e-mail program.
This message can be generated with the C<MakeMailMessage> subroutine, or you can make it yourself.
If this is too difficult for you, simply use the sendsimple method.

The Net::SMTP and blat approch requires that you specify the e-mail addresses before sending the e-mail itself.
That's why you need to pass those addresses to this method aswell. Although the sendmail program does not
require this approch, you'll have to do it anyway, since that makes this method portable for alternative
sending methods.

=item abort()

Aborts the connection. This resets everything, but this doesn't cancel any e-mails that have already been sent.

=item close()

Closes the connection.

=back

=head2 OLD FUNCTIONS (non methods)

These functions have been included to be compatible with older versions
of this module, that did not implement OO.

=over

=item SendMail( MailProg, MailServer, TypeConstant, Message, [YourEmail, ToEmailArray] )

Sends a e-mail. This actually implements the methods described above.

=item MakeMailMessage( YourName, YourEmail, HisName, HisEmail, Subject, MessageBody )

This is a helper routine of users who don't have experience with sending e-mails withour their e-mail program.
The message is generated, and can be passed though the SendMail routine, or the send method.

=back

=head2 EXPORTED CONSTANTS

The following constants are exported. The can either be used as parameter of the SendMail routine,
or they will be returned by the SendMail routine and object methods.

=over

=item MAILTYPE_SENDMAIL

This indicates that the UNIX program sendmail should be used to send the e-mail.
Any return value of the program is not trapped, so you'll never find out why the sending failed.

=item MAILTYPE_BLAT

This indicates that the Windows program blat should be used to send the e-mail.
Any return value of the program is not trapped, so you'll never find out why the sending failed.

=item MAILTYPE_NETSMTP

This indicates that the Net::SMTP module in Perl should be used to send the e-mail.
This module is part of the libnet package, and can also be used to send e-mail from windows computers.
Any step made in sending the e-mail will be trapped for errors, so a almost perfect error message will be available.


=item MAIL_SUCCESS

Successcode indicating that the e-mail has succesfully been sent.

=item MAILFAIL_PARAM

Errorcode indicating that the Type parameter is incorrect.

=item MAILFAIL_UNAVAILABLE

Errorcode indicating that either the Net::SMTP module or the sendmail/blat program is not found on the webserver's system.

=item MAILFAIL_INIT

Errorcode indicating that the system failed to initialize contact with the mail server, or making a pipe with sendmail.

=item MAILFAIL_FROM

Returned only when used Net::SMTP. The from e-mail address is not accepted by the mail server.

=item MAILFAIL_RCPT

Returned only when used Net::SMTP. One of the receipients e-mail addresses is not accepted by the mail server.

=item MAILFAIL_INITSEND

Returned only when used Net::SMTP. Some information sent to the mailserver wasn't ok and not trapped.
Now the mailserver prevents us from specifying the message to be sent.

=item MAILFAIL_SENDMSG

Returned only when used Net::SMTP. Strange, but the message is not accepted at all.
Something may be wrong in the message.

=item MAILFAIL_SENDEND

Returned only when used Net::SMTP. Strange, but the end-code for the message is not accepted,
or the message is considered incomplete.

=item MAILFAIL_CLOSE

Closing the connection with either the mailserver, or the sendmail/blat program failed.

=back

=head2 Message notes

A SMTP message should have this structure. Any other structure properly won't be permitted.
This kind of structure is generated aswell by the C<MakeMailMessage> subroutine.

  to: $ToName<$ToEmail>
  from: $FromName<$FromEmail>
  subject $Subject
  X-Mailer: INet::Mailer for Perl

  $Body

Please note the empty line between the header, and the body contents of the e-mail.
P.S. You don't need to convert any special escape characters in the mail contents.
The Net::SMTP module does that for your (just for SMTP experts ;-).

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut