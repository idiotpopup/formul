/*
 *  >> XBBC Toolbar JavaScript <<
 *  This module is a part of the X-Forum CGI software program.
 *                                                                                                                                                                                            ##
 *  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved
 *
 */


var XBBC_DO_DHTML = 0; // If DHTML problems occur (or unexpected crashes)



//  Note that settings are also defined elsewhere


// ================================================================================
// XBBC Codes

function Smiley_Happy()         { XBBC_Add(":)"); }
function Smiley_Wink()          { XBBC_Add(";)"); }
function Smiley_Cheesy()        { XBBC_Add(":D"); }
function Smiley_Grin()          { XBBC_Add(";D"); }
function Smiley_Angry()         { XBBC_Add(">:-("); }
function Smiley_Devious()       { XBBC_Add(">:-)"); }
function Smiley_Sad()           { XBBC_Add(":("); }
function Smiley_Shocked()       { XBBC_Add(":o"); }
function Smiley_Cool()          { XBBC_Add("8)"); }
function Smiley_Confused()      { XBBC_Add("???"); }
function Smiley_RollEyes()      { XBBC_Add("69)"); }
function Smiley_Tongue()        { XBBC_Add(":p"); }
function Smiley_Embarassed()    { XBBC_Add("{:-("); }
function Smiley_MouthShut()     { XBBC_Add(":-x"); }
function Smiley_Undecided()     { XBBC_Add(":-/"); }
function Smiley_Kiss()          { XBBC_Add(":-*"); }
function Smiley_Cry()           { XBBC_Add(":'("); }
function Smiley_Sleeping()      { XBBC_Add("N:)"); }

function XBBC_Bold()            { XBBC_AddTag("b"); }
function XBBC_Italicize()       { XBBC_AddTag("i"); }
function XBBC_Underline()       { XBBC_AddTag("u"); }
function XBBC_AlignLeft()       { XBBC_AddTag("align=left"); }
function XBBC_AlignCenter()     { XBBC_AddTag("align=center"); }
function XBBC_AlignRight()      { XBBC_AddTag("align=right"); }
function XBBC_AlignJustify()    { XBBC_AddTag("align=justify"); }
function XBBC_Font()            { XBBC_AddTag("font=Arial,red,+1"); }
function XBBC_FontFace()        { XBBC_AddTag("font=Arial"); }
function XBBC_FontColor()       { XBBC_AddTag("color=red"); }
function XBBC_FontSize()        { XBBC_AddTag("size=+1"); }
function XBBC_StrikeThrough()   { XBBC_AddTag("s"); }
function XBBC_NoMarkup()        { XBBC_Add("[nomarkup]", "[/nomarkup]"); }
function XBBC_TypeWriter()      { XBBC_AddTag("tt"); }
function XBBC_HorizontalRule()  { XBBC_Add("[hr]"); }
function XBBC_BulletList()      { XBBC_Add("[list]\n  [-]\n  [-]\n  [-]\n[/]\n"); }
function XBBC_EnumList()        { XBBC_Add("[enum]\n  [-]\n  [-]\n  [-]\n[/]\n"); }
function XBBC_QuoteText()       { XBBC_AddTag("quote=optional_title"); }
function XBBC_Table()           { XBBC_Add("[table=0]\n  [row] [|] [|] [/row]\n  [row] [|] [|] [/row]\n[/]\n"); }
function XBBC_TableRow()        { XBBC_AddTag("row"); }
function XBBC_TableCol()        { XBBC_Add("[|]"); }
function XBBC_CodeLines()       { XBBC_Add("[code]", "[/code]"); }
function XBBC_SubScript()       { XBBC_AddTag("sub"); }
function XBBC_SuperScript()     { XBBC_AddTag("sup"); }
function XBBC_Marquee()         { XBBC_AddTag("move=2"); }
function XBBC_Indent()          { XBBC_AddTag("indent"); }
function XBBC_Shadow()          { XBBC_AddTag("shadow=gray,120"); }
function XBBC_Glow()            { XBBC_AddTag("glow=green,3"); }
function XBBC_URL()             { XBBC_AddTag("url=http://www.website.com", "Website Title"); }
function XBBC_FTP()             { XBBC_AddTag("url=ftp://ftp.website.com", "FTP Location Name"); }
function XBBC_Email()           { XBBC_AddTag("email=someone@somewhere.com", "Personal Name"); }
function XBBC_Image()           { XBBC_Add("[image=http://www.website.com/imagefile,optional_width,optional_height,optional_alttext]"); }
function XBBC_Flash()           { XBBC_Add("[flash=http://www.website.com/flashfile,width,height]"); }


// ================================================================================
// DHTML Dialogs for XBBC codes

var INSERT   = 0;
var SPAN     = 1;

var OPTIONAL = 0;
var REQUIRED = 1;
var NUMBER   = 2;
var COLOR    = 4;

function XBBC_Font_Dialog()
{
  if(! XBBC_ShowDialog('font', SPAN,
                       XBBC_MSG_FONT,  OPTIONAL,
                       XBBC_MSG_COLOR, OPTIONAL | COLOR,
                       XBBC_MSG_SIZE,  OPTIONAL | NUMBER
                      )) { XBBC_Font(); }
}

function XBBC_FontFace_Dialog()
{
  if(! XBBC_ShowDialog('font', SPAN,
                       XBBC_MSG_FONT,  REQUIRED
                      )) { XBBC_FontFace(); }
}

function XBBC_FontColor_Dialog()
{
  if(! XBBC_ShowDialog('color', SPAN,
                       XBBC_MSG_COLOR, REQUIRED | COLOR
                      )) { XBBC_FontColor(); }
}

function XBBC_FontSize_Dialog()
{
  if(! XBBC_ShowDialog('size', SPAN,
                       XBBC_MSG_FONT + " " + XBBC_MSG_SIZE, REQUIRED | NUMBER
                      )) { XBBC_FontSize(); }
}

function XBBC_QuoteText_Dialog()
{
  if(! XBBC_ShowDialog('quote', SPAN,
                       XBBC_MSG_CAPTION, OPTIONAL
                      )) { XBBC_QuoteText(); }
}

function XBBC_Glow_Dialog()
{
  if(! XBBC_ShowDialog('glow', SPAN,
                       XBBC_MSG_COLOR, REQUIRED | COLOR,
                       XBBC_MSG_SIZE,  REQUIRED | NUMBER
                      )) { XBBC_Glow(); }
}

function XBBC_Shadow_Dialog()
{
  if(! XBBC_ShowDialog('shadow', SPAN,
                       XBBC_MSG_COLOR, REQUIRED | COLOR,
                       XBBC_MSG_SIZE,  REQUIRED | NUMBER
                      )) { XBBC_Shadow(); }
}


function XBBC_Image_Dialog()
{
  if(! XBBC_ShowDialog('image', INSERT,
                       XBBC_MSG_URL,     REQUIRED,
                       XBBC_MSG_WIDTH,   OPTIONAL | NUMBER,
                       XBBC_MSG_HEIGHT,  OPTIONAL | NUMBER,
                       XBBC_MSG_CAPTION, OPTIONAL
                      )) { XBBC_Image(); }
}

function XBBC_Flash_Dialog()
{
  if(! XBBC_ShowDialog('flash', INSERT,
                       XBBC_MSG_URL,    REQUIRED,
                       XBBC_MSG_WIDTH,  OPTIONAL | NUMBER,
                       XBBC_MSG_HEIGHT, OPTIONAL | NUMBER
                      )) { XBBC_Flash(); }
}

function XBBC_URL_Dialog()
{
  if(! XBBC_ShowDialog('url', SPAN,
                       XBBC_MSG_URL,    OPTIONAL
                      )) { XBBC_URL(); }
}

function XBBC_FTP_Dialog()
{
  if(! XBBC_ShowDialog('ftp', SPAN,
                       XBBC_MSG_URL,    OPTIONAL
                      )) { XBBC_FTP(); }
}

function XBBC_Email_Dialog()
{
  if(! XBBC_ShowDialog('email', SPAN,
                       XBBC_MSG_EMAIL,  OPTIONAL
                      )) { XBBC_Email(); }
}













// ================================================================================
// JavaScript implementation for XBBC functions




// ================================================================================
// Test for browser version


var ver = parseFloat(navigator.appVersion);
var IsOKVer = 0;
if (
    (navigator.appName == "Netscape" && ver >= 3) ||
    (navigator.appName == "Microsoft Internet Explorer" && ver >= 4)
   )
   { IsOKVer = 1 }



// ================================================================================
// Store the caret cursor position

var XBBC_CANTSTORE = 0;
function XBBC_StoreCaret()
{
  if(! XBBC_CANTSTORE
  && document.xbbceditor
  && document.xbbceditor.msg)
  {
    var TextField = document.xbbceditor.msg;
    if (TextField.createTextRange) { TextField.CaretPos = document.selection.createRange().duplicate(); }
    else                           { TextField.CaretPos = null; }
  }
}

function XBBC_HasSelection()
{
  if (document.xbbceditor)
  {
    if (document.xbbceditor.msg)
    {
      var TextField = document.xbbceditor.msg;
      TextField.focus() // These lines prevent the user from overwriting other text in the document by XBBC Code!
      XBBC_StoreCaret() // Initialize after focus; (but don't place this into the onFocus= event!)


      if (TextField.createTextRange && TextField.CaretPos)
      {
        var CaretPos = TextField.CaretPos;
        if (CaretPos.text.length)
        {
          return true;
        }
      }
    }
  }
  return false;
}


// ================================================================================
// Add codes to the XBBC window

function XBBC_Add(XBBCOpenCode, XBBCCloseCode, DefaultText)
{
  if (document.xbbceditor)
  {
    if (document.xbbceditor.msg)
    {
      var TextField = document.xbbceditor.msg;
      TextField.focus() // These lines prevent the user from overwriting other text in the document by XBBC Code!
      XBBC_StoreCaret() // Initialize after focus; (but don't place this into the onFocus= event!)

      if (TextField.createTextRange && TextField.CaretPos)
      {
        var CaretPos = TextField.CaretPos;
        if (XBBCCloseCode)
        {
          if (CaretPos.text.length)
          {
            // Insert the text, prompt if no text is found
            var Insert = (CaretPos.text || DefaultText);
            if(null == Insert)
            {
              TextField.focus()
              return false;
            }
            else
            {
              CaretPos.text = XBBCOpenCode + Insert + XBBCCloseCode;
            }
          }
          else
          {
            // You need to select something first!!
            alert(XBBC_MSG_SELECT);
          }
        }
        else
        {
          CaretPos.text += XBBCOpenCode
        }
      }
      else
      {
        // We don't know how where to insert the text, so append it.
        if (XBBCCloseCode)
        {
          // What should be insert?
          var Insert = prompt(XBBC_MSG_INSERT, DefaultText || '');
          if(null == Insert)
          {
            TextField.focus()
            return false;
          }
          TextField.value += XBBCOpenCode + Insert + XBBCCloseCode;
          TextField.focus()
        }
        else
        {
          // This is a non-closing tag just add it
          TextField.value += XBBCOpenCode;
        }
      }
      TextField.focus()
      XBBC_StoreCaret()

      return true;
    }
  }
  alert("Internal XBBC JavaScript error; Can't find textarea containing the posted message!");
  return false;
}


function XBBC_AddTag(XBBCTag, DefaultText)
{
  XBBC_Add("[" + XBBCTag + "]", "[/]", DefaultText);
}


function XBBC_AddCode(Code)
{
  XBBC_Add(Code, "", "");
}













// ================================================================================
// DHTML Functionality Features

var useAll   = (document.all    != null);
var useLayer = (document.layers != null);
var isNav    = false;
var isIE     = false;
var layerRef = ""
var styleRef = ""

if (parseInt(navigator.appVersion) >= 4)
{
  if (navigator.appName == "Netscape" && useLayer)
  {
    isNav = true
    layerRef = "document.layers"
    styleRef = ""
  }
  else if(navigator.appName == "Microsoft Internet Explorer" && useAll)
  {
    isIE = true
    layerRef = "document.all"
    styleRef = ".style"
  }
}


function XBBC_GetDialog()
{
  return eval(layerRef + "['XBBCDialog']" + styleRef);
}

function XBBC_GetDialogTest()
{
  var test;
  test = eval(layerRef);
         if(test == null) { return null }
  test = eval(layerRef + "['XBBCDialog']");
         if(test == null) { return null }
  test = eval(layerRef + "['XBBCDialog']" + styleRef);
         if(test == null) { return null }
  return test;
}

function XBBC_WriteInDialog(newContents)
{
  var dialog = eval(layerRef + "['XBBCDialog']");
  if(isIE)
  {
    dialog.innerHTML = newContents;
  }
  else if(isNS)
  {
    dialog.document.write(newContents);
    dialog.document.close();
  }
}

function ucfirst(text)
{
  return text.substring(0, 1).toUpperCase() + text.substring(1);
}


var LIST_FIRST = 2;
var FORM_FIRST = 3;

function XBBC_ShowDialog(tag, type)
{
  var dialog = XBBC_GetDialogTest();
  if(arguments == null || dialog == null || ! XBBC_DO_DHTML)
  {
    return false;
  }

  if((type & SPAN) == SPAN)
  {
    if(! XBBC_HasSelection())
    {
      alert(XBBC_MSG_SELECT);
      return true; // Assume this dialog worked
    }
  }

  var title  = ucfirst(tag);
  var nel    = (arguments.length - LIST_FIRST) / 2;
  var html   = ''
             + '<FORM name="XBBC_DialogForm">'
             + '<INPUT type="hidden" name="XBBCinputTag"  value="'  + tag  + '">'
             + '<INPUT type="hidden" name="XBBCinputFlag" value="'  + type + '">'
             + '<INPUT type="hidden" name="XBBCinputNEl"  value="'  + nel  + '">'
             + '<TABLE width="400" ' + XBBC_TableStyle + '>'
             + '<TR><TH colspan="2" bgcolor="' + XBBC_DlgHeadClr + '"><FONT color="' + XBBC_DlgCaptClr + '">&nbsp;' + title + " " + XBBC_MSG_TITLE + '&nbsp;</FONT></TH></TR>'
             + '<TR height="6"><TD></TD><TD></TD></TR>'

  var NR = 0;
  for(var I = LIST_FIRST; I < arguments.length; I+=2)
  {
    var label = arguments[I+0];
    var flags = arguments[I+1];
    var required = (flags & REQUIRED) == REQUIRED;
    NR++;

    var flagField = '<INPUT type="hidden" name="XBBCinput' + NR + 'f" value="' + flags + '">'

    html     += ''
             + '<TR><TD width="100" align="right" class="InputLabel" valign="top">'
             + (required ? XBBC_DlgLabel0 : '')
             + XBBC_DlgLabel1
             + label
             + XBBC_DlgLabel2
             + '</TD><TD>'
             + '<INPUT type="text" name="XBBCinput' + NR + '" size="38" class="CoolTextDlg">'
             + flagField
             + '</TD></TR>'
  }
  html       += ''
             + '<TR height="6"><TD></TD><TD></TD></TR>'
             + '<TR><TD></TD><TD>'
             + '<INPUT type="button" class="CoolButton" value="' + XBBC_MSG_ADD   + '" onClick="XBBC_ExecDialog(this.form)">'
             + '<INPUT type="button" class="CoolButton" value="' + XBBC_MSG_CLOSE + '" onClick="XBBC_HideDialog()">'
             + '</TD></TR>'
             + '</TABLE>'
             + '</FORM>'

  if((type & SPAN) == SPAN) { XBBC_CANTSTORE = 1; }
  XBBC_WriteInDialog(html);
  dialog.visibility = 'visible';
  if(document.XBBC_DialogForm != null)
  {
    document.XBBC_DialogForm.elements[FORM_FIRST].focus();
  }
  return true;
}

function XBBC_ExecDialog(form)
{
  var items = parseInt(form.elements.XBBCinputNEl.value)
  var type  = parseInt(form.elements.XBBCinputFlag.value)
  var tag   = form.elements.XBBCinputTag.value
  var code  = tag

  for(var I = 1; I <= items; I++)
  {
    var field = form.elements['XBBCinput'+I];
    var val   = form.elements['XBBCinput'+I].value;
    var flags = parseInt(form.elements['XBBCinput'+I+'f'].value);
    var req   = (flags & REQUIRED) == REQUIRED;
    var num   = (flags & NUMBER)   == NUMBER;
    var clr   = (flags & COLOR)    == COLOR;

    if(req)
    {
      if(val == "")
      {
        alert(XBBC_MSG_FILLIN);
        field.focus();
        field.select();
        return;
      }
    }
    if(val)
    {
      if(num)
      {
        if(isNaN(val) || val.indexOf('.') != -1)
        {
          alert(XBBC_MSG_NUMBER);
          field.focus();
          field.select();
          return;
        }
      }

      if(clr)
      {
        if(val.substring(0,1) == "#")
        {
          if(val.length != 7)
          {
            alert(XBBC_MSG_BADCLR);
            field.focus();
            field.select();
            return;
          }


          var val2 = val.toUpperCase()
          for(var i = 1; i < val.length; i++)
          {
            var char = val2.charAt(i);
            if(! ("0" <= char && char <= "9"
               || "A" <= char && char <= "F"))
            {
              alert(XBBC_MSG_BADCLR);
              field.focus();
              field.select();
              return;
            }
          }
        }
        else
        {
          var val2 = val.toUpperCase()
          for(var i = 1; i < val.length; i++)
          {
            var char = val2.charAt(i);
            if(! ("A" <= char && char <= "Z"))
            {
              alert(XBBC_MSG_BADCLR);
              field.focus();
              field.select();
              return;
            }
          }
        }
      }


      if(val.substring(0,1)                     == '"'
      || val.substring(val.length-1,val.length) == '"'
      || val.indexOf(',')                       != -1)
      {
        val = '"' + val + '"';
      }
    }

    code   += (I > 1 ? "," : '=')
           +  val;
  }
  while(code.substring(code.length-1,code.length+0) == ',')
  {
    code = code.substring(0, code.length-1);
  }
  if(code.substring(code.length-1,code.length+0) == '=')
  {
    code = code.substring(0, code.length-1);
  }

  if((type & SPAN) == SPAN)
  {
    XBBC_AddTag(code)
  }
  else
  {
    XBBC_Add("[" + code + "]")
  }

  XBBC_CANTSTORE = 0;
  var dialog = XBBC_GetDialog();
  dialog.visibility = 'hidden';
  XBBC_WriteInDialog("");
}

function XBBC_HideDialog()
{
  var dialog = XBBC_GetDialog();
  dialog.visibility = 'hidden';
  XBBC_WriteInDialog("");
}






// ================================================================================
// Toolbar Image Changer


var XBBC_Images   = new Array();
var ICON_Images   = new Array();
var XBBC_Path     = XBBC_ImagePath + '/xbbc/';
var ICON_Path     = XBBC_ImagePath + '/posticons/';

function LoadXBBCImages()
{
  if(IsOKVer)
  {
    var Index = 0;
    for(I = 0; I < arguments.length; I++)
    {
      var name = arguments[I];
      XBBC_Images[Index] = new Image(22, 23);
      XBBC_Images[Index].src = XBBC_Path + name + '_1.gif';
      XBBC_Images[Index].name = name + "1"
      Index++;
      XBBC_Images[Index] = new Image(22, 23);
      XBBC_Images[Index].src = XBBC_Path + name + '_2.gif';
      XBBC_Images[Index].name = name + "2"
      Index++;
    }
  }
}

function LoadIconImages()
{
  if(IsOKVer)
  {
    var Index = 0;
    for(I = 0; I < arguments.length; I++)
    {
      var name = arguments[I];
      ICON_Images[Index] = new Image(16, 16);
      ICON_Images[Index].src = ICON_Path + name + '.gif';
      ICON_Images[Index].name = name;
      Index++;
    }
  }
}


function XBBC_SelImg(ImageObj)   { return XBBC_DoSelImg(ImageObj, "_2"); }
function XBBC_UnSelImg(ImageObj) { return XBBC_DoSelImg(ImageObj, "_1"); }

function XBBC_DoSelImg(ImageObj, After)
{
  After += ".gif";
  if(IsOKVer)
  {
    Name = ImageObj.src.substring(XBBC_Path.length, ImageObj.src.length - 6);
    for(var I = 0; I < XBBC_Images.length; I++)
    {
      if(XBBC_Images[I].src == XBBC_Path + Name + After)
      {
        ImageObj.src = XBBC_Images[I].src;
      }
    }
  }
  return true;
}



// ================================================================================
// Display the posticon

function DisplayIcon(icons)
{
  var icon = icons.options[icons.selectedIndex].value
  document.viewicon.src = XBBC_ImagePath + "/posticons/" + icon + ".gif";
}


// ================================================================================
// Popup preview window

function OpenPreview(form)
{
  if(! TestForm(form))
  {
    return false
  }

  var PrevWin = window.open('', 'XForum_Preview', 'menubar,resizable,scrollbars,top=20');
  form.target = 'XForum_Preview'

  PrevWin.focus();
}
