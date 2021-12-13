/*
 *  >> Test Input <<
 *  This module is a part of the X-Forum CGI software program.
 *                                                                                                                                                                                            ##
 *  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved
 *
 */

// FORM_MSG_EMAIL = "The e-mail address isn't valid!\nIt should look like:\nyourname@domain.com";
// FORM_MSG_FILLIN = "You didn't fill in some of the fields.\nPlease fill them in.";

//  Note that settings are also defined elsewhere



// ---------------------------------------
// tests for input text values

function TestForm(form)
{
  if(! doFieldTest(form, form.test_required, isFilled, FORM_MSG_FILLIN ) ) { return false }
  if(! doFieldTest(form, form.test_email,    isEmail,  FORM_MSG_EMAIL  ) ) { return false }
  if(! doFieldTest(form, form.test_int,      isInt,    FORM_MSG_INT    ) ) { return false }
  if(! doFieldTest(form, form.test_uint,     isUInt,   FORM_MSG_UINT   ) ) { return false }
  if(! doFieldTest(form, form.test_float,    isFloat,  FORM_MSG_FLOAT  ) ) { return false }

  return true;
}

function doFieldTest(form, data, test, msg)
{ // null != form
  // data may contain null, since that implies the passed argument
  // field object is not provided in the HTML code.

  if(null != data)
  {
    var Names = data.value.split(',');
    for(var i=0; i<Names.length; i++)
    {
      var field = form.elements[Names[i]];

      if(field == null)
      {
        alert("Error: the field '" + Names[i] + "' is not defined in the HTML document\n\nPlease contact the webmaster of this site!");
        continue // with next item
      }

      if(field.value == null)
      {
        // Can't do anything with this field
        continue // with next item
      }

      if (! test(field.value))
      {
        alert(msg);
        if(field.select != null) { field.select(); }
        return false;
      }
    }
  }
  return true;
}


// ---------------------------------------
// checks selected items.

// Function returns checked item (form.radio[]...)
function getSelectedButton(buttonGroup)
{
  for (var i = 0; i < buttonGroup.length; i++)
  {
    if (buttonGroup[i].checked) return i
  }
  return 0
}

// Function returns selected option (form.select.options[]...)
function getSelectedItem(SelectedOption)
{
  for (var i=0; i<SelectedOption.length; i++)
  {
    if (SelectedOption.options[i].selected) return i
  }
  return 0
}


// ---------------------------------------
// Tests

// You should use the isFilled always.
// al the other tests asume you have used it,
// because we mark a field as 'it can have',
// not 'it should have' a value of type X

// We don't test for input length. That's tested in the
// HTML field, and should be re-tested by the cgi program.

// Is it empty?
function isFilled(inputStr)
{
  if (inputStr == null || inputStr == "") { return false }
  return true
}

// positive number?
function isUnSignedInteger(inputVal)
{ // RULE: inputVal is not empty

  inputStr = inputVal.toString()
  if(inputStr == '') { return true; }

  for (var i = 0; i < inputStr.length; i++)
  {
    var oneChar = inputStr.charAt(i)
    if (oneChar < "0" || oneChar > "9") { return false }
  }
  return true
}

// is it an integer?
function isSignedInteger(inputVal)
{ // RULE: inputVal is not empty

  inputStr = inputVal.toString()
  if(inputStr == '') { return true; }

  for (var i = 0; i < inputStr.length; i++)
  {
    var oneChar = inputStr.charAt(i)
    if (i == 0 && oneChar == "-") { continue }
    if (oneChar < "0" || oneChar > "9") { return false }
  }
  return true
}

isInteger  = isSignedInteger;
isInt      = isSignedInteger;

isUInteger = isUnSignedInteger;
isUInt     = isUnSignedInteger;


// is it an number? (with decimal point, below zero is still allowed)
function isFloat(inputVal)
{ // RULE: inputVal is not empty

  inputStr = inputVal.toString()
  if(inputStr == '') { return true; }

  oneDecimal = false

  for (var i = 0; i < inputStr.length; i++)
  {
    var oneChar = inputStr.charAt(i)
    if (i == 0 && oneChar == "-") { continue }
    if (oneChar == "." && !oneDecimal)
    {
      oneDecimal = true
      continue
    }
    if (oneChar < "0" || oneChar > "9") { return false }
  }
  return true
}


function isEmail(inputStr)
{ // RULE: inputVal is not empty

  if(inputStr == '') { return true; }

  var DotPos, AtPos;

  AtPos  = inputStr.indexOf('@');
  if(AtPos <= 1)                { return false; } //No @ as second char
  DotPos = inputStr.indexOf('.', AtPos + 1);
  if(AtPos > DotPos)            { alert("@=" + AtPos + " .=" + DotPos); return false; } // There must be a . after the @
  return true;
}


// ---------------------------------------
// remove the zeros at the begin!

function stripZeros(inputStr)
{
  var result = inputStr
  while (result.substring(0,1) == "0") { result = result.substring(1,result.length) }
  return result
}



// ---------------------------------------
// Not an input tester, although very useful,
// and used by x-forum.cgi (admin edit subject/group)

function SelectOption(select, optionValue)
{
  var ArrayIndex    = 0;
  var OldArrayIndex = 0;

  for (var OptionIndex = 0; OptionIndex < select.options.length; OptionIndex++)
  {
    if(select.options[OptionIndex].value == optionValue)
    {
      select.options[OptionIndex].selected = true;
    }
    else if(select.options[OptionIndex].selected)
    {
      // Only adjust if we have to (might speed up)
      select.options[OptionIndex].selected = false;
    }
  }
}

function SelectOptions(select, array, isSorted)
{
  var ArrayIndex    = 0;
  var OldArrayIndex = 0;

  for (var OptionIndex = 0; OptionIndex < select.options.length; OptionIndex++)
  {
    var IsSelected     = false;

    if(! isSorted)
    {
      // We can't assume something
      // We need to look through the entire array again.
      ArrayIndex = 0
    }
    else
    {
      // Save the index where we should start looking
      OldArrayIndex  = ArrayIndex
    }

    // Searches the remaining part of the array for that option
    while(ArrayIndex < array.length && ! IsSelected)
    {
      if(array[ArrayIndex] == select.options[OptionIndex].value)
      {
        IsSelected = true;
      }
      ArrayIndex++; // continues with next item
    }


    if(select.options[OptionIndex].selected != IsSelected)
    {
      // Only adjust if we have to (might speed up)
      select.options[OptionIndex].selected = IsSelected;
    }

    if(! IsSelected && isSorted)
    {
      // Didn't found it? - Forget we even looked in that array
      // We re-do the remaining part of the array next time
      ArrayIndex = OldArrayIndex
    }
  }
}