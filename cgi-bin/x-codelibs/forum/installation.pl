##################################################################################################
##                                                                                              ##
##  >> Installation Info <<                                                                     ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'installation.pl'} = 'Release 1.6';



##################################################################################################

sub print_installinfo_HTML ()
{
  print <<ADMIN_INFO;
    <P>
    <HR>
    <B> Administrator Information </B>
    <P>
    <TABLE width="600" border="0"><TR><TD>
    Congratulations! Your X-Forum installation is almost complete!
    <P>
    You're through the most difficult part now. Now, you properly want
    to set up the rest of the forum, so users can work with it.
    Also, you need to verify if the forum functions are working.
    <P>
    Once you've created the forum subjects, this message will disappear.
    While that's not the case, pressing <A href="$THIS_URL">home</A> returns you to this window.
    </TD></TR></TABLE>
    <P>
    <B> Final Installation Steps </B><BR>
    <UL>
      <LI> First, the Administrator has to <A href="$THIS_URL?show=addmember">signup</A> too!
      <UL>
        <LI> Use the word 'admin' as your account name.
        <LI> Enter the correct Administrator password you defined in the xf-settings.pl file!
        <LI> You will automatically be promted to fill in more <A href="$THIS_URL?show=editmember&member=admin">profile information</A>.
      </UL>
    </UL>
    <UL>
      <LI> Check if <A href="$THIS_URL?show=member&member=admin">your admin account</A> is created.
    </UL>
    <UL>
      <LI> Customize your copy of X-Forum:
      <UL>
        <LI> Edit the <A href="$THIS_URL?show=admin_edittemplate">template settings</A> and colors to create a different appearance.
        <LI> Edit the <A href="$THIS_URL?show=admin_editsettings">forum settings</A> to customize the forum.
      </UL>
    </UL>
    <UL>
      <LI> Create some subjects
      <UL>
        <LI> Goto the the <A href="$THIS_URL?show=admin_center">Administrator Center</A>.
        <LI> Seek for the <A href="$THIS_URL?show=admin_addsubject">Add Subject</A> option.
      </UL>
    </UL>
    <UL>
      <LI> Verify if everything works, like the e-mailer or create topic dialog!
      <LI> Invite your users!
    </UL>
    <P>
    <B> About </B><BR>
    This message board is powered by X-Forum, created by <A href="mailto:webmaster\@codingdomain.com?subject=Reply%20about%20x-forum%20script%21">Diederik v/d Boor</A> [<A href="http://jp0013/cgi-bin/x-forum.cgi?show=help&help=about">more info</A>] <BR>
    <P>
    <B> Support Locations </B><BR>
    <UL>
      <LI> <A href="http://www.codingdomain.com" target="XFCDSupport">Coding Domain WebSite</A>
      <LI> <A href="mailto:webmaster\@codingdomain.com"> Coding Domain E-mail</A>
    </UL>
    <UL>
      <LI> <A href="http://www.codingdomain.com/cgi-bin/x-forum.cgi" target="XFCDSupport">Online Community</A>
      <LI> <A href="http://www.codingdomain.com/ui-pages/email.html" target="XFCDSupport">Contact Form</A>
      <LI> <A href="http://www.codingdomain.com/ui-pages/bugreport.html" target="XFCDSupport">Bug Reports</A>
    </UL>
    <UL>
      <LI> <A href="http://www.codingdomain.com/cgi-perl/downloads/x-forum/install" target="XFCDSupport">Installing X-Forum</A>
      <LI> <A href="http://www.codingdomain.com/cgi-perl/articles/install.html" target="XFCDSupport">Installing CGI Scripts</A>
    </UL>
    <UL>
      <LI> <A href="http://www.codingdomain.com/cgi-perl/downloads/x-forum" target="XFCDSupport">X-Forum Download Location</A>
      <LI> <A href="http://www.codingdomain.com/cgi-perl/downloads/x-forum/newpass.html" target="XFCDSupport">Generate a Password</A>
    </UL>
    <UL>
      <LI> <A href="http://jp0013/cgi-perl/downloads/x-forum/rate.html" target="XFCDSupport">Rating @ script index</A>
    </UL>
    </P>
ADMIN_INFO
}

1;
