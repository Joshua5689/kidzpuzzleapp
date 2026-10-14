/**
 * Creates the "Doodle Bee – Tester Feedback" Google Form (and a Google Sheet
 * that collects the answers) in your own Google account.
 *
 * How to use:
 *   1. Go to https://script.google.com and click "New project".
 *   2. Delete everything in the editor and paste this whole file in.
 *   3. Click Save (disk icon), then Run (▶). Choose "createDoodleBeeFeedbackForm" if asked.
 *   4. Allow the permissions Google asks for (it needs to create a form and a sheet in YOUR Drive).
 *   5. Open "Execution log" at the bottom: it prints the link to share and the edit link.
 */
function createDoodleBeeFeedbackForm() {
  var form = FormApp.create('Doodle Bee – Tester Feedback');
  form.setDescription(
    'Thank you for testing Doodle Bee – Puzzle and Play! 🐝\n' +
    'Your answers help Joshua & Preethi (Little Hive Studio) make the game better for little ones.\n' +
    'It takes about 3 minutes. You can fill it in more than once if you find something new.\n\n' +
    'Please don\'t include your child\'s name. We don\'t need it.');
  form.setCollectEmail(false);
  form.setProgressBar(true);
  form.setConfirmationMessage('Thank you so much! 💛 Your feedback really helps. – Joshua & Preethi');

  // --- About you -----------------------------------------------------------
  form.addSectionHeaderItem().setTitle('About you and your device');
  form.addTextItem().setTitle('Your first name (optional)');
  form.addMultipleChoiceItem()
      .setTitle('Which device did you play on?')
      .setChoiceValues(['Android phone', 'Android tablet', 'Both'])
      .setRequired(true);
  form.addTextItem()
      .setTitle('Device model (optional)')
      .setHelpText('e.g. Samsung Galaxy Tab A8. You can find it in Settings → About phone/tablet.');
  form.addCheckboxItem()
      .setTitle('How old is the child (or children) who played?')
      .setChoiceValues(['2', '3', '4', '5', '6', '7', '8', 'Older than 8'])
      .setRequired(true);
  form.addMultipleChoiceItem()
      .setTitle('How often did your child play during the test?')
      .setChoiceValues(['Once or twice', 'A few times a week', 'Most days', 'Every day'])
      .setRequired(true);

  // --- Fun -------------------------------------------------------------------
  form.addPageBreakItem().setTitle('Fun and difficulty');
  form.addScaleItem()
      .setTitle('How much did your child enjoy Doodle Bee?')
      .setBounds(1, 5)
      .setLabels('Not at all', 'Loved it!')
      .setRequired(true);
  form.addCheckboxItem()
      .setTitle('Which games did your child enjoy most?')
      .setChoiceValues([
        'Jigsaw puzzles', 'Counting / adding / taking away', 'Spot the difference',
        'Hidden object hunts', 'Colouring', 'Mazes', 'Tracing numbers and letters',
        'Memory pairs', 'Follow the bee (sequences)', 'Sorting by colour / shape / shadow',
        'Patterns / what comes next', 'Sliding puzzle', 'Picture sudoku',
        'Connect the dots', 'Spelling'])
      .showOtherOption(true);
  form.addParagraphTextItem()
      .setTitle('Which games or levels were TOO HARD? (level numbers help!)')
      .setHelpText('e.g. "Level 42 sliding puzzle – my 5-year-old got stuck"');
  form.addParagraphTextItem()
      .setTitle('Which games or levels were TOO EASY or boring?');
  form.addMultipleChoiceItem()
      .setTitle('Could your child get the stars needed to open the next world?')
      .setChoiceValues(['Yes, easily', 'Yes, after replaying some levels', 'No, they got stuck', 'Not sure']);
  form.addMultipleChoiceItem()
      .setTitle('Did the voice (reading the questions aloud) help?')
      .setChoiceValues(['Yes, a lot', 'A little', 'Not really', 'We turned the voice off']);

  // --- Problems --------------------------------------------------------------
  form.addPageBreakItem().setTitle('Problems');
  form.addCheckboxItem()
      .setTitle('Did anything go wrong?')
      .setChoiceValues([
        'No problems', 'The app closed or crashed', 'The app froze / stopped responding',
        'A level could not be finished', 'Sound or voice problems',
        'Something looked wrong on screen', 'Progress or stars were lost'])
      .showOtherOption(true)
      .setRequired(true);
  form.addParagraphTextItem()
      .setTitle('If something went wrong, what happened?')
      .setHelpText('Which level, what your child was doing, and what you saw. A screenshot sent on WhatsApp is great too.');
  form.addScaleItem()
      .setTitle('How easy was it to join the test and install the app?')
      .setBounds(1, 5)
      .setLabels('Very hard', 'Very easy');

  // --- Overall ----------------------------------------------------------------
  form.addPageBreakItem().setTitle('Overall');
  form.addMultipleChoiceItem()
      .setTitle('Would you recommend Doodle Bee to other parents?')
      .setChoiceValues(['Definitely', 'Probably', 'Not sure', 'Probably not'])
      .setRequired(true);
  form.addParagraphTextItem()
      .setTitle('What would make Doodle Bee better? Any other ideas or comments?');
  form.addMultipleChoiceItem()
      .setTitle('May we quote your feedback anonymously (e.g. "a parent of a 5-year-old said…")?')
      .setChoiceValues(['Yes', 'No']);

  // Answers go into a Google Sheet in your Drive.
  var sheet = SpreadsheetApp.create('Doodle Bee – Tester Feedback (responses)');
  form.setDestination(FormApp.DestinationType.SPREADSHEET, sheet.getId());

  Logger.log('SHARE THIS LINK with testers: ' + form.getPublishedUrl());
  Logger.log('Edit the form here: ' + form.getEditUrl());
  Logger.log('Responses sheet: ' + sheet.getUrl());
}
