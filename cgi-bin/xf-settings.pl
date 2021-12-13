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
##  Last time overwritten: Wed Apr 10 13:50:58 2002 GMT



use strict;
$VERSIONS{'xf-settings.pl'} = 'Release 1.6';





##################################################################################################
## Define the settings:


# Folder Locations. Some Folders (with local paths) should actually be placed outsize the www root (if possible).
$IMAGE_URLPATH	= qq[$THIS_SITE/x-images];			# URL path to images folder
$LIBARY_URLPATH	= qq[$THIS_SITE/xf-libaries];			# Extra data files

$DATA_FOLDER	= qq[$THIS_PATH${S}x-data${S}forum];		# Full path to data folder
$LANG_FOLDER	= qq[$THIS_PATH${S}x-languages${S}forum];	# Full Path to language folder
$IMAGE_FOLDER	= qq[$THIS_DOCROOT${S}x-images];		# Full Path to images folder
$LIBARY_FOLDER	= qq[$THIS_DOCROOT${S}xf-libaries];		# Full path to libary folder


# File Locations
$SETTINGS_FILE	= qq[$THIS_PATH${S}xf-settings.pl];		# Used by admin center and file browser.
$TEMPLATE_FILE	= qq[xf-template.html];				# Cool Template


# Encryped passwords with compare key (READ 'Password Note' to create you own admin password).
$ADMIN_PASS = q[XFnUmLxaaLbPQNO/t0jGxS9w];			# Use the X-Forum password generator online for this.




# Forum Settings
$FORUM_TITLE	= qq[X-Forum];					# HTML Title
$LANGUAGE	= 'english';					# Language file

$HOT_POSTNUM	= 10;						# Topic is hot topic when more then x replies
$HOTHOT_POSTNUM	= 40;						# Topic is very hot topic  when more then x replies

$PAGE_TOPICS	= 100;						# Number of Topics per page
$PAGE_POSTS	= 25;						# Number of Posts per page

$MEMBER_TTL	= 60 * 15;					# Seconds before member is considered being logged out.




# Forum Appearance (some things are defined in the Forum Script)
$LIMIT_VIEW	= 1;						# Hide fields (eg. in profile) when not specified
$LOCBAR_HIDE    = 0;						# Use this to hide the location bar
$LOCBAR_LASTURL = 1;						# Doesn't make the last topic clickable when false,
$TOPIC_BUMPTOTOP= 1;						# Topics bump to top when reply added




# Forum Limitations
$CAN_KEEPLOGIN	= 1;						# Allows that users check the "Remember Me" option.

$GUEST_NOBTN	= 1;						# Don't show buttons that require login when user is guest
$GUEST_NOPOST	= 0;						# Don't let guests post
$GUEST_NOMAIL	= 1;						# Don't show e-mail adresses when user is guest

$ALLOW_ICONURL	= 1;						# When disabled, members can't specify their own icon by URL anymore.
$ALLOW_XBBC	= 1;						# To disable XBBC codes, set this to 0




# Data Limitations
$POST_MAX	= 4000;						# max bytes for posts (1kB = 1024 bytes; 1MB = 1024 kB)
$IM_MAX		= 3000;						# max characters in an instant message
$IM_SENDTOMAX	= '10';						# max members you can send a message to
$FLOOD_TIMEOUT	= 15;						# Seconds before new post is allowed by the save user.




# Forum General Colors
$FONT_COLOR	= qq[#FFFFFF];					# Used to display the default color in some hyperlinks.
$BTNT_COLOR	= qq[#FFFFFF];					# Text color of the toolbar buttons
$TABLHEAD_COLOR	= qq[#696969];					# Background color of the table header.
$TABLFONT_COLOR	= qq[#CCCCCC];					# Text color of the table header labels.

# Post Fields Colors
$POSTHEAD_COLOR	= qq[#555555];					# Background color of post header bar
$POSTCAPT_COLOR	= qq[#FFFFFF];					# Caption color of post header bar
$POSTFOOT_COLOR	= qq[#696969];					# Background color of the post footer/tool bar
$POSTBODY_COLOR	= qq[#999999];					# Background of the post contents
$POSTFONT_COLOR	= qq[#000000];					# Text color of the post contents

# Data Dialog Colors
$HEADBACK_COLOR	= qq[#FFFFFF];					# Background color of the group title. (above fields)
$HEADFONT_COLOR	= qq[#000000];					# Text color of the group title.
$CELL_COLOR	= qq[#999999];					# Cell color for information in dialogs (eg. profile)

# Input Dialog Colors
$DATABACK_COLOR	= qq[#888888];					# Background color behind the input fields.
$DATAFONT_COLOR	= qq[#000000];					# Text color of the text next to the input fields

# HTML codes used to format tables.
$TABLE_STYLE	= qq[border="2" align="center" bgcolor="#707070" bordercolor="#606060" bordercolorlight="#505050" bordercolordark="#7F7F7F" cellspacing="0"];
$TABLE_TBRSTYLE	= qq[border="2" height="11" align="center" bgcolor="#666666" bordercolor="#777777" bordercolorlight="#6F6F6F" bordercolordark="#707070" cellspacing="0" frame="box" rules="none"];
$REQ_HTML	= qq[<B><FONT color="#FF0000" size="1">&gt; </FONT></B>];




# E-mail settings
$MAIL_TYPE	= 1;						# 0=none, 1=sendmail, 2=Net::SMTP
$MAIL_PROG	= '/usr/sbin/sendmail';				# Location of sendmail                  (undef for default)
$MAIL_HOST	= undef;					# Mail server (ie. mail.yourdomain.com) (undef for default)
$WEBMASTER_MAIL	= 'your_email@here.com';			# Webmaster e-mail                      (can be undef for mailtype 0)




# HTTP Settings
$SEC_CONNECT	= 0;						# It's recommended setting this to 1 if your server can handle https connections
$FORUM_ISOLATED	= 1;						# Sets cookie path value (current path if 1, www root if 0). Recommended setting to 0 if login failes with a 'login error page', which could be caused by strange paths like 'My Cool Forum'.



1;
