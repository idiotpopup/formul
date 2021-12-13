#!/usr/bin/perl -w      # PUT YOUR PERL PATH HERE! # The script should work then properly

##################################################################################################
##                                                                                  Release 1.6 ##
##      x-forum.cgi                                                               17 March 2002 ##
##                                                                                              ##
##                 Copyright (c) 2001 Diederik van der Boor - All Rights Reserved.              ##
##                                                                                              ##
##                 Originally published and documented at http://www.codingdomain.com           ##
##                 License to use is granted if and only if this                                ##
##                 entire copyright notice is included.                                         ##
##                                                                                              ##
##                 I like to maintain a list of implementations around the world,               ##
##                 and I'll properly let you know if something has changed, or bugs show up.    ##
##                 So just mail me at webmaster@codingdomain.com                                ##
##                                                                                              ##
##                                                                                              ##
##################################################################################################

use CGI qw(:cgi escape);                         # Yes, I like the standard safe way although this uses 0.14 CPU
use Fcntl qw(:DEFAULT :flock);                   # Standard file locking if supported by OS.
use 5.005;                                       # qr requires 5.005, a auto file-unlock on file-close requires 5.004
use strict;                                      # Strict Syntax, Pointers, Variable Declarations and Subroutine Names

use lib 'x-modules';
use CGI::Location;                               # Determines the current script location, and adds some new variables to the main package!!
use CGI::ErrorTrap;                              # Error Trapping
use File::PlainIO;                               # Database IO File routines
use Test::IPAddress;                             # IP Addresses


## Define Location Variables. (Global in Program)
## use vars can be replaced my the our statement in perl 5.6
use vars qw(%VERSIONS @MSG $LANGUAGE $LANGID @MONTHLENGTH $TemplateLoaded),
         qw($SETTINGS_FILE $TEMPLATE_FILE),
         qw($DATA_FOLDER $IMAGE_FOLDER $LIBARY_FOLDER $LANG_FOLDER $IMAGE_URLPATH $LIBARY_URLPATH),
         qw($POST_MAX $IM_MAX $IM_SENDTOMAX $FORUM_TITLE $FORUM_ISOLATED $GUEST_NOBTN $GUEST_NOPOST $GUEST_NOMAIL $LIMIT_VIEW $TOPIC_BUMPTOTOP $WRITE_MODE $HOT_POSTNUM $HOTHOT_POSTNUM $PAGE_TOPICS $PAGE_POSTS $WEBMASTER_MAIL $MAIL_TYPE $MAIL_HOST $MAIL_PROG $ADMIN_PASS $SEC_CONNECT $MEMBER_TTL $FLOOD_TIMEOUT),
         qw($ALLOW_XBBC $ALLOW_ICONURL $CAN_KEEPLOGIN $LOCBAR_HIDE $LOCBAR_LASTURL),
         qw($CELL_COLOR $FONT_COLOR $POSTHEAD_COLOR $POSTCAPT_COLOR $POSTBODY_COLOR $POSTFONT_COLOR $POSTFOOT_COLOR $HEADBACK_COLOR $HEADFONT_COLOR $DATABACK_COLOR $DATAFONT_COLOR $BTNT_COLOR $TABLHEAD_COLOR $TABLFONT_COLOR $SPLIT_HTML $TABLE_600_HTML $TABLE_MAX_HTML $TABLE_TBRSTYLE $RETURN_HTML $REQ_HTML $FONT_STYLE $FONTEX_STYLE $TABLE_STYLE),
         qw($XForumUser $XForumPass $XForumUserIP %MemberOnline %MemberBanned %MemberNames $XBBC_JS $FORM_JS $THIS_URLSEC $LINEBREAK_PATTERN $HEADER_PRINTED);

## Obsolete, but for backward compatibility..
use vars qw($BACK_COLOR);


## This is used for debugging only
##benchmark## use Benchmark;
##benchmark## my $BM_StartTime;
##benchmark## END { if($HEADER_PRINTED) {
##benchmark##   print qq[<FONT size="1" face="sans-serif" color="#CCCCCC">Debugging: Execution time is ] . timestr(timediff(new Benchmark, $BM_StartTime)) . qq[</FONT>];
##benchmark## } }




# Everything we want to let run first!
BEGIN {

##benchmark##   $BM_StartTime = new Benchmark();      # Benchmark for debugging


  $VERSIONS{'cgiscript'} = 'Release 1.6';


  ##------------------------------------------------------------------------------------------------
  ## Load other settings and subs form module.

  sub LoadSupport
  {
    eval(qq[require '$THIS_PATH${S}x-codelibs${S}forum${S}$_[0].pl']);
    $@ && die ("Error in loading $_[0] file: $@\n");
  }

  LoadSupport('initialize');
  InitializeBegin();

} # End BEGIN

InitializeRest();


##################################################################################################
## Check what to do: Main loop in program.

my $Show   = (param('show')   || '');
my $Action = (param('action') || '');


##################################################################################################
# Show a dialog?


if ($Show ne '')
{
  LoadSupport('html_template');
     if ($Show eq 'about')              { LoadSupport('dlg_small');            Show_AboutDialog();              }
  elsif ($Show eq 'addmember')          { LoadSupport('dlg_addmember');        Show_AddMemberDialog();          }
  elsif ($Show eq 'addpost')            { LoadSupport('dlg_addpost');          Show_AddPostDialog();            }
  elsif ($Show eq 'addtopic')           { LoadSupport('dlg_addtopic');         Show_AddTopicDialog();           }
  elsif ($Show eq 'admin_addgroup')     { LoadSupport('admin_chgroups');       Show_AdminAddGroupDialog();      }
  elsif ($Show eq 'admin_addsubject')   { LoadSupport('admin_chsubjects');     Show_AdminAddSubjectDialog();    }
  elsif ($Show eq 'admin_banusers')     { LoadSupport('admin_moderate');       Show_AdminBanUsersDialog();      }
  elsif ($Show eq 'admin_browser')      { LoadSupport('admin_browser');        Show_AdminBrowserDialog();       }
  elsif ($Show eq 'admin_censor')       { LoadSupport('admin_moderate');       Show_AdminCensorDialog();        }
  elsif ($Show eq 'admin_center')       { LoadSupport('admin_center');         Show_AdminCenterDialog();        }
  elsif ($Show eq 'admin_delsubject')   { LoadSupport('admin_chsubjects');     Show_AdminDeleteSubjectDialog(); }
  elsif ($Show eq 'admin_editgroup')    { LoadSupport('admin_chgroups');       Show_AdminEditGroupDialog();     }
  elsif ($Show eq 'admin_editsettings') { LoadSupport('admin_settings');       Show_AdminEditSettingsDialog();  }
  elsif ($Show eq 'admin_editsubject')  { LoadSupport('admin_chsubjects');     Show_AdminEditSubjectDialog();   }
  elsif ($Show eq 'admin_edittemplate') { LoadSupport('admin_settings');       Show_AdminEditTemplateDialog();  }
  elsif ($Show eq 'admin_logfiles')     { LoadSupport('admin_logfiles');       Show_AdminLogFilesDialog();      }
  elsif ($Show eq 'admin_maintaince')   { LoadSupport('admin_center');         Show_AdminMaintainceDialog();    }
  elsif ($Show eq 'admin_repair')       { LoadSupport('admin_center');         Show_AdminRepairDialog();        }
  elsif ($Show eq 'admin_sortsubjects') { LoadSupport('admin_chsubjects');     Show_AdminSortSubjectsDialog();  }
  elsif ($Show eq 'compose')            { LoadSupport('dlg_messages');         Show_ComposeDialog();            }
  elsif ($Show eq 'delmember')          { LoadSupport('dlg_delmember');        Show_DeleteMemberDialog();       }
  elsif ($Show eq 'delmessage')         { LoadSupport('dlg_messages');         Show_DeleteMessageDialog();      }
  elsif ($Show eq 'delpost')            { LoadSupport('dlg_delpost');          Show_DeletePostDialog();         }
  elsif ($Show eq 'deltopic')           { LoadSupport('dlg_deltopic');         Show_DeleteTopicDialog();        }
  elsif ($Show eq 'editmember')         { LoadSupport('dlg_editmember');       Show_EditMemberDialog();         }
  elsif ($Show eq 'editpassword')       { LoadSupport('dlg_editpassword');     Show_EditPasswordDialog();       }
  elsif ($Show eq 'editpost')           { LoadSupport('dlg_editpost');         Show_EditPostDialog();           }
  elsif ($Show eq 'help')               { LoadSupport('dlg_small');            Show_HelpDialog();               }
  elsif ($Show eq 'iconlist')           { LoadSupport('dlg_iconlist');         Show_IconListDialog();           }
  elsif ($Show eq 'locktopic')          { LoadSupport('dlg_locktopic');        Show_LockTopicDialog();          }
  elsif ($Show eq 'login')              { LoadSupport('dlg_loginout');         Show_LoginDialog();              }
  elsif ($Show eq 'logintest')          { LoadSupport('dlg_loginout');         Show_LoginTest();                }
  elsif ($Show eq 'logout')             { LoadSupport('dlg_loginout');         Show_LogoutDialog();             }
  elsif ($Show eq 'member')             { LoadSupport('dlg_member');           Show_Member();                   }
  elsif ($Show eq 'memberlist')         { LoadSupport('dlg_memberlist');       Show_MemberListDialog();         }
  elsif ($Show eq 'messages')           { LoadSupport('dlg_messages');         Show_MessagesDialog();           }
  elsif ($Show eq 'movetopic')          { LoadSupport('dlg_movetopic');        Show_MoveTopicDialog();          }
  elsif ($Show eq 'movetopics')         { LoadSupport('dlg_movetopics');       Show_MoveTopicsDialog();         }
  elsif ($Show eq 'smileylist')         { LoadSupport('dlg_smileylist');       Show_SmileyListDialog();         }
  elsif ($Show eq 'sticktopic')         { LoadSupport('dlg_sticktopic');       Show_StickTopicDialog();         }
  elsif ($Show eq 'subject')            { LoadSupport('dlg_subject');          Show_Subject();                  }
  elsif ($Show eq 'topic')              { LoadSupport('dlg_topic');            Show_Topic();                    }
  else                                  { Action_Error();                                                       }
  exit;
}

if (request_method ne 'POST')
{
  LoadSupport('html_template');
  LoadSupport('dlg_forum');
  Show_Forum();
  exit;
}

##################################################################################################
# Do something if this is not a HTTP-GET request (all html forms use POST method)

if ($Action ne '')
{
     if ($Action eq 'addmember')          { LoadSupport('dlg_addmember');        Action_AddMember();            }
  elsif ($Action eq 'addpost')            { LoadSupport('dlg_addpost');          Action_AddPost();              }
  elsif ($Action eq 'addtopic')           { LoadSupport('dlg_addtopic');         Action_AddTopic();             }
  elsif ($Action eq 'admin_addgroup')     { LoadSupport('admin_chgroups');       Action_AdminAddGroup();        }
  elsif ($Action eq 'admin_addsubject')   { LoadSupport('admin_chsubjects');     Action_AdminAddSubject();      }
  elsif ($Action eq 'admin_banusers')     { LoadSupport('admin_moderate');       Action_AdminBanUsers();        }
  elsif ($Action eq 'admin_browserdel')   { LoadSupport('admin_browser');        Action_AdminBrowserDelete();   }
  elsif ($Action eq 'admin_browseredit')  { LoadSupport('admin_browser');        Action_AdminBrowserEdit();     }
  elsif ($Action eq 'admin_censor')       { LoadSupport('admin_moderate');       Action_AdminCensor();          }
  elsif ($Action eq 'admin_delsubject')   { LoadSupport('admin_chsubjects');     Action_AdminDeleteSubject();   }
  elsif ($Action eq 'admin_editgroup')    { LoadSupport('admin_chgroups');       Action_AdminEditGroup();       }
  elsif ($Action eq 'admin_editsettings') { LoadSupport('admin_settings');       Action_AdminEditSettings();    }
  elsif ($Action eq 'admin_editsubject')  { LoadSupport('admin_chsubjects');     Action_AdminEditSubject();     }
  elsif ($Action eq 'admin_edittemplate') { LoadSupport('admin_settings');       Action_AdminEditTemplate();    }
  elsif ($Action eq 'admin_maintaince')   { LoadSupport('admin_center');         Action_AdminMaintaince();      }
  elsif ($Action eq 'admin_repair')       { LoadSupport('admin_center');         Action_AdminRepair();          }
  elsif ($Action eq 'admin_sortsubjects') { LoadSupport('admin_chsubjects');     Action_AdminSortSubjects();    }
  elsif ($Action eq 'compose')            { LoadSupport('dlg_messages');         Action_Compose();              }
  elsif ($Action eq 'delmember')          { LoadSupport('dlg_delmember');        Action_DeleteMember();         }
  elsif ($Action eq 'delmessage')         { LoadSupport('dlg_messages');         Action_DeleteMessage();        }
  elsif ($Action eq 'delpost')            { LoadSupport('dlg_delpost');          Action_DeletePost();           }
  elsif ($Action eq 'deltopic')           { LoadSupport('dlg_deltopic');         Action_DeleteTopic();          }
  elsif ($Action eq 'editmember')         { LoadSupport('dlg_editmember');       Action_EditMember();           }
  elsif ($Action eq 'editpassword')       { LoadSupport('dlg_editpassword');     Action_EditPassword();         }
  elsif ($Action eq 'editpost')           { LoadSupport('dlg_editpost');         Action_EditPost();             }
  elsif ($Action eq 'locktopic')          { LoadSupport('dlg_locktopic');        Action_LockTopic();            }
  elsif ($Action eq 'login')              { LoadSupport('dlg_loginout');         Action_Login();                }
  elsif ($Action eq 'movetopic')          { LoadSupport('dlg_movetopic');        Action_MoveTopic();            }
  elsif ($Action eq 'movetopics')         { LoadSupport('dlg_movetopics');       Action_MoveTopics();           }
  elsif ($Action eq 'sticktopic')         { LoadSupport('dlg_sticktopic');       Action_StickTopic();           }
  else                                    { Action_Error();                                                     }
  exit;
}
Action_Error();