# Survey Surver

A small server to surve surveys to survey participants written in [Nim](https://nim-lang.org/).

# Building

```bash
nim c surve
```

# Running

```bash
surve -c <config_file> [-p <port> -d <results_data_file>]
```

See `surver.config.json` for an example config file. It essentially just provides a mapping between survey names and files containing the survey questions.

Once the surver is running, connect to it with any web browser (e.g. if you are running the surver on the same PC as your web browser with the default settings, connect to `localhost:8080`).

Integer IDs are created for each new connection to the surver, and if any existing entries were found in the data file (`-d`) specified on the commandline the IDs will pick up where they left off.

#### NOTE:

This surver was written with the intended environment being a *closed* network. **Do NOT** run this on a server with the intent of serving surveys over the general internet! The software is NOT secure and no guarantees can be made about your safety if you allow arbitrary connections. It was written to be very small and to support the minimum set of features necessary to serve surveys in a closed lab context. If you need something more than that, you should use a real web server (e.g. [mofuw](https://github.com/2vg/mofuw) ).

Surver has also only been tested in single-client scenarios so far (i.e. one participant filling out one survey at a time, not multiple participants filling surveys out simultaneously) and it is very possible that multi-client use could uncover more bugs.

# Making Your Own Surveys

See the `surveys` directory for several examples. Surveys are written in JSON, and the required fields vary a bit depending on the survey type. The surveys displayed to users are defined by the `surveyOrder` field on the main client app data object (see the bottom of `index.html`).

## Likert Scale Surveys

```json
{
  "title": "Title of Survey",
  "subtitle": "Survey Subtitle displayed along with each question",
  "instructions": "General instructions displayed along with each question",
  "type" : "likert",
  "scales_range": [-3, -2, -1, 1, 2, 3],
  "scales": [
    {
      "title": "Question title or prompt",
      "min": "Label for minimal value on scale",
      "max": "Label for maximal value on scale"
    },
    {
      "title": "I enjoyed this survey.",
      "min": "Strongly Disagree",
      "max": "Strongly Agree"
    },
    {
      "min": "Strongly Disagree",
      "max": "Strongly Agree"
    }
  ]
}
```

**title** `optional` : The overall title of the survey. Not displayed next to questions.

**subtitle** `optional` : Survey subtitle. Displayed with every question.

**instructions** `optional` : General instructions which should be displayed next to every question.

**type** `required` : Must be `likert`

**scales_range** `required` : An array of discrete values used for participants' answers. The first value will be used for the left-most side of the scale, while the last value will be used for the right-most side of the scale.

**scales** `required` : An array of the actual survey questions and labels for the min/max sides of the scale. The `title` field on individual questions is optional.


## Task Load Index Surveys

Included are the [NASA TLX](https://humansystems.arc.nasa.gov/groups/TLX/) surveys, but if you want to make your own using a similar scale (or create a translation of the English version) this can easily be done.

```json
{
  "title": "Survey title",
  "type" : "tlx",
  "scales_range": [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 75, 80, 85, 90, 95, 100],
  "scales": [
    {
      "title": "Mental Demand",
      "explanation": "How mentally demanding was the task?",
      "min": "Very Low",
      "max": "Very High"
    }
  ]
}
```

**title** `optional` : The overall title of the survey. Not displayed next to questions.

**type** `required` : Must be `tlx`

**scales_range** `required` : An array of discrete values used for participants' answers. The first value will be used for the left-most side of the scale, while the last value will be used for the right-most side of the scale.

**scales** `required` : An array of the actual survey questions and labels for the min/max sides of the scale. The `title` and `explanation` fields on individual questions are optional.


## Messages

To display a message in between surveys, you can use the `message` survey type. This can be used, for example to give people additional questions, tell them to take a break, etc.

```json
{
  "title": "Main page title",
  "type" : "message",
  "message": "Please wait for further instructions"
}
```

**title** `optional` : A title to display at the top of the page (e.g. "Please Pause", "Wait For Instructions", etc).

**type** `required` : Must be `message`

**message** `optional` : A short text message to display to users.


## Long-Form Text

Surveys with the `comments` type will present a large textbox for participants to enter large amounts of text into.

```json
{
    "title": "Any additional comments or suggestions?",
    "type": "comments"
}
```

## Custom Form Fields

```json
{
  "title": "Form Title",
  "type" : "formdata",
  "fields": [
    {
      "name": "Age",
      "field": "age",
      "type": "number",
      "required": true
    },
    {
      "name": "Sex",
      "field": "sex",
      "type": "selection",
      "options": ["M", "F"],
      "required": true
    },
    {
      "name": "Personal statement",
      "field": "statement",
      "type": "string",
      "note": "Something short"
    },
    {
      "name": "Height",
      "field": "height",
      "type": "number",
      "note": "cm",
      "required": true
    },
    {
      "name": "Feeling Happy?",
      "field": "happy",
      "type": "bool"
    }
  ]
}
```

Custom form fields can be created in order to collect specific data about a participant as part of a study.

**title** `optional` : Title to be displayed at the top of the page.

**type** `required` : Must be `formdata`

**fields** `required` : Array of form fields.

Several types of form fields are available:

### Numeric Fields
Numeric Fields only accept numeric values. They will display an error state if the user enters something which is not a number. They will be stored in the JSON output as a number.

```json
    {
      "name": "Height",
      "field": "height",
      "type": "number",
      "note": "cm",
      "required": true
    }
```

**name** `required` : The name of the field. Will be displayed as part of the field on the page.

**field** `required` : The field name to store the entered data in (e.g. `height` will be written to `data[i].height` in the output file).

**type** `required` : Must be `number`

**note** `optional` : A small note to be displayed next to the field (e.g. to give additional instructions, unit label, etc)

**required** `optional` : If `true`, the participant cannot move past the form until they give a value to this field.


### Selection Fields
Selection fields provide a drop-down menu for users to select from a pre-defined set of options.

```json
    {
      "name": "Sex",
      "field": "sex",
      "type": "selection",
      "options": ["M", "F"],
      "required": true
    }
```

**name** `required` : The name of the field. Will be displayed as part of the field on the page.

**field** `required` : The field name to store the entered data in (e.g. `height` will be written to `data[i].height` in the output file).

**type** `required` : Must be `selection`

**options** `required` : An array of options available to choose from.

**required** `optional` : If `true`, the participant cannot move past the form until they give a value to this field.


### Boolean Fields
Boolean fields will display a checkbox for users to provide a clear yes/no answer to a question or statement.

```json
    {
      "name": "I like Bool",
      "field": "likesbool",
      "type": "bool"
    }
```

**name** `required` : The name of the field. Will be displayed as part of the field on the page.

**field** `required` : The field name to store the entered data in.

**type** `required` : Must be `bool`

**required** `optional` : If `true`, the participant cannot move past the form until they give a value to this field.


### Text Fields
Text fields will display a small one-line textbox for users to enter text in.

```json
    {
      "name": "Text Input",
      "field": "txtfield",
      "type": "string",
      "note": "Something short"
    }
```

**name** `required` : The name of the field. Will be displayed as part of the field on the page.

**field** `required` : The field name to store the entered data in.

**type** `required` : Must be `string`

**note** `optional` : A small bit of additional text to display alongside the field.

**required** `optional` : If `true`, the participant cannot move past the form until they give a value to this field.


# Advanced Usage

There is not yet a nice and usable JS API for handling the surveys on the client side (if there is demand, though, this may be added in the future).

### Changing the structure of the results data

All information about the current participant and their survey answers is stored in `data.participant_data`. This includes some pre-existing fields for storing survey answers, and this is the data which is sent to the server to save the results after each survey. If you need some specific structure for your data or some default values to questions you plan to ask, this should be done here.

### Callbacks on survey answers

Each time a user makes a selection for a question, a corresponding callback is called. These are set in `loadSurvey` and essentially just write the answer into the correct field of `data.participant_data`. If you need to do something special, like display a message, perform some validation, or write the answer to a different field, you should replace the callbacks here.

## Communicating With The Surver

For simple surveys this may not be necessary (the scripts in `index.html` will automatically get a fresh ID for a participant when the page loads and send the participant's data to the server each time they complete a survey), but if you want to implement your own client-side behavior, or integrate surver with some existing client, you may need to handle some of the communication yourself.

Surver responds to regular HTTP requests as normal, except **any** request with `$` in the URL string. Any URL containing `$` is assumed to contain a command the surver needs to handle itself. Commands follow the `$` and any preceding characters are ignored. Parameters can be passed to a command as JSON-formatted strings in a POST message.

Every command will generate a response. All responses are JSON strings which contain, at minimum, a field labeled `status` which can be checked to verify the command was handled successfully. If no errors were encountered, `status` will contain the value `success`. If the command failed, `status` will contain a short message about why the command could not be processed.

### Surver Commands

#### new_user

##### Parameters:
`none`

##### Response:
```json
{
  "status" : "success",
  "id"     : number,
  "group"  : "A" / "B"
}
```

Used to create a new entry in the server-side storage of survey data. Returns a new unique integer ID for the participant, and alternates between `"A"` and `"B"` for the participant's group name.

#### list_surveys

##### Parameters:
`none`

##### Response:
```json
{
  "status"  : "success",
  "surveys" : [ "survey_1", "survey_2" ]
}
```

Used to retrieve a list of all available surveys the surver can surve. Each survey can be assumed to be a valid survey name which can be passed to `get_survey`.

#### get_survey

##### Parameters:
```json
{
  "survey" : "survey_name"
}
```

##### Response:
```json
{
  "status" : "success",
  "survey" : { ... }
}
```

The `survey` field will contain the contents of the corresponding survey file (as defined in the surver config file) on the server. NOTE: The survey JSON will be parsed on the server-side before being sent.

#### submit_result

##### Parameters:
```json
{
  ...
}
```

##### Response:
```json
{
  "status" : "success"
}
```

The data sent to the server should be exactly the data you want stored for a given participant. It **must** include at minimum the `id` returned by `new_user` in order to update the correct record on the server-side. The rest of the data is free to be defined by you as you want (see `data.participant_data` for an example).
