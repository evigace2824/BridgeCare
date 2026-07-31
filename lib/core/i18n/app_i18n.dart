import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

/// Lightweight runtime i18n helper for app text.
///
/// We use phrase keys for speed and readability:
/// `context.tr('Health status')`
///
/// For dynamic values:
/// `context.tr('Connected to: {name}', {'name': 'Arben'})`
class AppI18n {
  static const Map<String, String> _sq = {
    'Good morning': 'Miremengjes',
    'Good afternoon': 'Miredita',
    'Good evening': 'Mirembrema',
    'Connected to: {name}': 'Lidhur me: {name}',
    'Status: Safe': 'Statusi: I sigurt',
    'Status: Action needed': 'Statusi: Kerkon veprim',
    'Status: Emergency': 'Statusi: Emergjence',
    'Status: Needs attention': 'Statusi: Kerkon vemendje',
    'Quick actions': 'Veprime te shpejta',
    'Call family': 'Telefono familjen',
    'One-tap call': 'Telefonate me nje prekje',
    'Request help': 'Kerko ndihme',
    'Ask a volunteer': 'Kerko vullnetar',
    '{count} left today': '{count} te mbetura sot',
    'My reminders': 'Kujtuesit e mi',
    'All done today': 'Gjithcka perfunduar sot',
    'Health status': 'Gjendja shendetesore',
    'Tap to record': 'Prek per regjistrim',
    'Next reminder': 'Kujtuesi i radhes',
    'See all': 'Shiko te gjitha',
    'Marked as done.': 'U shenua si e kryer.',
    'Snoozed for 15 minutes.': 'U shty per 15 minuta.',
    'Health Today': 'Shendeti sot',
    'Heart rate': 'Rrahjet e zemres',
    'Blood pressure': 'Tensioni i gjakut',
    'Enter health values': 'Vendos vlerat e shendetit',
    'Daily content': 'Permbajtja ditore',
    'Read': 'Lexo',
    'Listen': 'Degjo',
    'Health tip:': 'Keshille shendeti:',
    'Today': 'Sot',
    'Tomorrow': 'Neser',
    'Done': 'Kryer',
    'Snooze': 'Shtyje',
    'Home': 'Kreu',
    'Reminders': 'Kujtues',
    'Profile': 'Profili',
    'My Reminders': 'Kujtuesit e mi',
    'Medications and appointments for today.':
        'Medikamente dhe takime per sot.',
    'Add a new reminder': 'Shto nje kujtues te ri',
    '+ Add a new reminder': '+ Shto nje kujtues te ri',
    'Add reminder': 'Shto kujtues',
    'Reminder title': 'Titulli i kujtuesit',
    'Medication': 'Medikament',
    'Appointment': 'Takim',
    'Time: {time}': 'Ora: {time}',
    'Save reminder': 'Ruaj kujtuesin',
    'Reminder added.': 'Kujtuesi u shtua.',
    'Please enter a reminder title.': 'Ju lutem vendosni nje titull kujtuesi.',
    'You\'re all done for today!': 'I keni kryer te gjitha per sot!',
    'Health': 'Shendeti',
    'Track heart rate and blood pressure.':
        'Ndiq rrahjet e zemres dhe tensionin e gjakut.',
    'Track heart rate.': 'Ndiq rrahjet e zemres.',
    'Recent history': 'Historia e fundit',
    'Not recorded yet': 'Nuk eshte regjistruar ende',
    'No data': 'Pa te dhena',
    'Normal': 'Normale',
    'Warning': 'Paralajmerim',
    'Emergency': 'Emergjence',
    'Daily Content': 'Permbajtja Ditore',
    'Today\'s Health Tip': 'Keshilla e shendetit per sot',
    'More tips': 'Me shume keshilla',
    'Audio mode enabled.': 'Modaliteti audio u aktivizua.',
    'Audio mode disabled.': 'Modaliteti audio u caktivizua.',
    'Choose language': 'Zgjidh gjuhen',
    'English': 'Anglisht',
    'Albanian': 'Shqip',
    'Language set to {lang}.': 'Gjuha u vendos: {lang}.',
    'Request Help': 'Kerko ndihme',
    'What do you need\nhelp with?': 'Per cfare ju duhet\nndihme?',
    'A volunteer will be notified as soon as you send the request.':
        'Nje vullnetar do te njoftohet sapo te dergoni kerkesen.',
    'Grocery shopping': 'Blerje ushqimore',
    'Medical appointment': 'Takim mjekesor',
    'Collect pension': 'Terheq pensionin',
    'Daily assistance': 'Asistence ditore',
    'Other help': 'Ndihme tjeter',
    'When do you need help?': 'Kur ju duhet ndihma?',
    'Notes (optional)': 'Shenime (opsionale)',
    'Any details for the volunteer…': 'Detaje per vullnetarin…',
    'Send request': 'Dergo kerkesen',
    'Request sent!': 'Kerkesa u dergua!',
    'Back to home': 'Kthehu ne kreu',
    'Pending — waiting for a volunteer':
        'Ne pritje — ne pritje te nje vullnetari',
    'Emergency Contacts': 'Kontaktet e emergjences',
    'Add contact': 'Shto kontakt',
    'Name': 'Emri',
    'Phone': 'Telefoni',
    'Relationship': 'Marredhenia',
    'News & daily content': 'Lajme & permbajtje ditore',
    'Audio mode': 'Modaliteti audio',
    'Language': 'Gjuha',
    'Text size': 'Madhesia e tekstit',
    'Apply': 'Apliko',
    'Cancel': 'Anulo',
    'Sign out': 'Dil',
    'Sign out?': 'Te dilni?',
    'I NEED HELP': 'ME DUHET NDIHME',
    'Tap to call family + volunteers':
        'Prek per te thirrur familjen + vullnetaret',
    'Calling for help...': 'Po therras per ndihme...',
    'Your family and nearby volunteers will be notified. Tap cancel if this was a mistake.':
        'Familja juaj dhe vullnetaret afer do te njoftohen. Prek Anulo nese ishte gabim.',
    'Emergency alert sent to family and nearby volunteers.':
        'Sinjali i emergjences u dergua te familja dhe vullnetaret.',
    'No emergency contact found. Please add one in Profile.':
        'Nuk u gjet kontakt emergjence. Ju lutem shtojeni te Profili.',
    'Could not start the call. Check phone/dialer support on this device.':
        'Nuk u nis telefonata. Kontrolloni aplikacionin e thirrjeve ne kete pajisje.',
    'No family contact found. Add one in Profile.':
        'Nuk u gjet kontakt familjar. Shtojeni te Profili.',
    'Could not start call to {name}.':
        'Nuk u nis telefonata per {name}.',
    'Call {name}?': 'Telefono {name}?',
    'Call now': 'Telefono tani',
    'Call {name}': 'Telefono {name}',
    'No call app is configured on this device. Use this number directly:':
        'Nuk ka aplikacion telefonate ne kete pajisje. Perdorni kete numer:',
    'Emergency contact': 'Kontakti i emergjences',
    'Copy number': 'Kopjo numrin',
    'Phone number copied. Call it from your phone app.':
        'Numri u kopjua. Telefonojeni nga aplikacioni i telefonit.',
    'Just now': 'Tani',
    '{n} min ago': '{n} min me pare',
    '{n}h ago': '{n} o me pare',
    '{n}d ago': '{n} d me pare',
    'Use your home device and type the numbers below.':
        'Perdor pajisjen tende ne shtepi dhe shkruaj vlerat me poshte.',
    'Please enter at least one value.':
        'Ju lutem vendosni te pakten nje vlere.',
    'Systolic': 'Sistolik',
    'Diastolic': 'Diastolik',
    'Save': 'Ruaj',
    'Use your home blood pressure monitor and enter the values by tapping "Enter health values" above. Your family will be notified if a value is in the Warning or Emergency range.':
        'Perdorni aparatin e tensionit ne shtepi dhe vendosni vlerat duke prekur "Vendos vlerat e shendetit". Familja do te njoftohet nese vlerat jane ne nivel Paralajmerim ose Emergjence.',
    'Enter your heart rate by tapping "Enter health values" above. Your family will be notified if a value is in the Warning or Emergency range.':
        'Vendosni rrahjet e zemres duke prekur "Vendos vlerat e shendetit". Familja do te njoftohet nese vlera eshte ne nivel Paralajmerim ose Emergjence.',
    'You\'re all set for now': 'Jeni ne rregull tani',
    'No more reminders for today.': 'Nuk ka me kujtues per sot.',
    'Welcome': 'Mire se vini',
    'Emergency contacts': 'Kontaktet e emergjences',
    'Manage who is called first': 'Menaxho kush thirret i pari',
    'My family link code': 'Kodi im i lidhjes familjare',
    'Share this code with your family so they can connect to you.':
        'Ndaje kete kod me familjen tende qe te lidhen me ty.',
    'Copied to clipboard.': 'U kopjua.',
    'Sample text size': 'Shembull i madhesise se tekstit',
    "You'll need your email and password to sign back in.":
        'Do t\'ju duhet email-i dhe fjalekalimi per t\'u rikthyer.',
    'You are about to call your connected family member.':
        'Do te telefononi anetarin e lidhur te familjes suaj.',
    'Welcome to BridgeCare': 'Mire se erdhet ne BridgeCare',
    'Real-time health monitoring, instant assistance, and community support.':
        'Monitorimi i shendetit ne kohe reale, ndihme e menjehershme dhe mbeshtetje nga komuniteti.',
    'Log In': 'Hyr',
    'Create Account': 'Krijo llogarine',
    'Loading your dashboard…': 'Duke ngarkuar panelin tuaj…',
    'Easy tips for your wellbeing.':
        'Keshilla te thjeshta per mireqenien tuaj.',
    'Send emergency alert?': 'Te dergohet sinjali i emergjences?',
    'Your family and available helpers will be notified immediately.':
        'Familja juaj dhe ndihmesit e disponueshem do te njoftohen menjehere.',
    'Send Alert': 'Dergo sinjalin',
    'Sending…': 'Po dergohet…',
    'Notified recipients:': 'Marresit e njoftuar:',
    'Family member': 'Anetar familjeje',
    'Available volunteers': 'Vullnetare te disponueshem',
    'OK': 'OK',
    'Emergency alert sent': 'Sinjali i emergjences u dergua',
    'Emergency alert active': 'Sinjali i emergjences aktiv',
    'Dismiss': 'Mbyll',
    'Emergency alert sent. Your family and helpers were notified.':
        'Sinjali i emergjences u dergua. Familja dhe ndihmesit u njoftuan.',
    'Snooze reminder': 'Shty kujtuesin',
    '15 minutes': '15 minuta',
    '30 minutes': '30 minuta',
    'Snoozed for {n} minutes.': 'U shty per {n} minuta.',
    'Family link code copied': 'Kodi i lidhjes familjare u kopjua',
    'Text size updated.': 'Madhesia e tekstit u perditesua.',
    'Please enter your heart rate.': 'Ju lutem vendosni rrahjet e zemres.',
    'Enter a valid number.': 'Vendosni nje numer te vlefshem.',
    'Enter a heart rate between 30 and 220.':
        'Vendosni rrahjet e zemres midis 30 dhe 220.',
    'Your family would be notified about this reading.':
        'Familja juaj do te njoftohej per kete lexim.',
    'Reading saved.': 'Leximi u ruajt.',
    'Contact added.': 'Kontakti u shtua.',
    'Contact': 'Kontakt',
    'Daily task': 'Detyre ditore',
    'Reminder type': 'Lloji i kujtuesit',
    'Date': 'Data',
    'Time': 'Ora',
    'Repeat': 'Perseritje',
    'Does not repeat': 'Nuk perseritet',
    'Every day': 'Cdo dite',
    'Choose what you need help with.': 'Zgjidh per cfare ju duhet ndihme.',
    'Help picking up groceries': 'Ndihme per blerjen e ushqimeve',
    'Accompany to a medical visit': 'Shoqerim ne takim mjekesor',
    'Help collecting your pension': 'Ndihme per te terhequr pensionin',
    'Everyday errands and household help':
        'Detyra te perditshme dhe ndihme ne shtepi',
    'General daily assistance': 'Asistence e perditshme e pergjithshme',
    'Your request has been sent to available volunteers.':
        'Kerkesa juaj u dergua te vullnetaret e disponueshem.',
    'Choose date': 'Zgjidh daten',
    'Request: {type}': 'Kerkesa: {type}',
    'You and your family will be notified when a volunteer accepts.':
        'Ju dhe familja do te njoftoheni kur nje vullnetar e pranon.',
    'Accepted by a volunteer': 'E pranuar nga nje vullnetar',
    'Completed': 'E perfunduar',
    'Cancelled': 'E anuluar',
    'All': 'Te gjitha',
    'Upcoming': 'Ne vazhdim',
    'Saved on this device. Could not sync to the cloud.':
        'U ruajt ne kete pajisje. Nuk mund te sinkronizohej me ren.',
    'How are you today?': 'Si ndiheni sot?',
    'I feel good': 'Ndihem mire',
    'I feel okay': 'Ndihem ne rregull',
    'I do not feel well': 'Nuk ndihem mire',
    'Would you like to notify your family or request help?':
        'Deshironi te njoftoni familjen apo te kerkoni ndihme?',
    'Notify family': 'Njofto familjen',
    'Great to hear that you feel good today.':
        'Shume mire qe ndiheni mire sot.',
    'Thank you for checking in. We are here for you.':
        'Faleminderit per njoftimin. Jemi ketu per ju.',
    'Thanks for letting us know. We can help right away.':
        'Faleminderit qe na njoftuat. Mund t\'ju ndihmojme menjehere.',
    'Family connection': 'Lidhja me familjen',
    'Last contacted today': 'Kontaktuar se fundmi sot',
    'Call': 'Telefono',
    'Message': 'Mesazh',
    'Send I am okay': 'Dergo "Jam mire"',
    'Your family has been notified that you are okay.':
        'Familja juaj u njoftua qe jeni mire.',
    'Today\'s routine': 'Rutina e sotme',
    'Take morning medicine': 'Merr ilacin e mengjesit',
    'Drink water': 'Pini uje',
    'Take a short walk': 'Beni nje shetitje te shkurter',
    'Check blood pressure': 'Kontrollo tensionin',
    'Recent activity': 'Aktiviteti i fundit',
    'No recent activity yet.': 'Nuk ka ende aktivitet te fundit.',
    "Today's medication progress": 'Progresi i medikamenteve sot',
    '{done} of {total} completed': '{done} nga {total} te perfunduara',
    'Buy medicine': 'Blej ilace',
    'Need someone to help buy your medicine':
        'Keni nevoje per ndihme per te blere ilacet',
    'Doctor appointment': 'Takim me mjekun',
    'Transportation': 'Transport',
    'Help with transport to an appointment':
        'Ndihme me transportin per ne takim',
    'House help': 'Ndihme ne shtepi',
    'Talk to someone': 'Bisedo me dike',
    'A friendly volunteer can call and talk with you':
        'Nje vullnetar mund t\'ju telefonoje dhe te bisedoje me ju',
    'Other': 'Tjeter',
    'Describe what you need in the next step':
        'Pershkruani cfare ju duhet ne hapin tjeter',
    'Blood sugar (optional)': 'Sheqeri ne gjak (opsionale)',
    'Temperature (optional)': 'Temperatura (opsionale)',
    'No recent health history yet.':
        'Nuk ka ende histori te fundit shendetesore.',
    'Bigger text mode': 'Modaliteti i tekstit me te madh',
    'Bigger text mode enabled.': 'Modaliteti i tekstit me te madh u aktivizua.',
    'Bigger text mode disabled.':
        'Modaliteti i tekstit me te madh u caktivizua.',
    'High contrast mode': 'Modaliteti me kontrast te larte',
    'High contrast mode enabled.':
        'Modaliteti me kontrast te larte u aktivizua.',
    'High contrast mode disabled.':
        'Modaliteti me kontrast te larte u caktivizua.',
    'Enabled': 'Aktiv',
    'Disabled': 'Caktiv',
    'Health tip of the day': 'Keshilla shendetesore e dites',
    'Safety tip': 'Keshille sigurie',
    'Mental wellbeing tip': 'Keshille per mireqenie mendore',
    'Hydration reminder': 'Kujtese per hidratim',
    'Family connection suggestion': 'Sugjerim per lidhje me familjen',
    'Keep your phone nearby in case you need help.':
        'Mbajeni telefonin afer ne rast se ju duhet ndihme.',
    'Take five slow breaths and relax your shoulders.':
        'Merrni pese frymemarrje te ngadalta dhe relaksoni shpatullat.',
    'Drink a glass of water now.': 'Pini nje gote uje tani.',
    'Send a short message to your family today.':
        'Dergoni nje mesazh te shkurter familjes suaj sot.',
    'Message feature coming soon.': 'Funksioni i mesazheve vjen se shpejti.',
    'Your family has been notified you may need help.':
        'Familja juaj u njoftua qe mund t\'ju duhet ndihme.',
    'Family notified for wellbeing check':
        'Familja u njoftua per kontroll mireqenieje',
    'Patient reported feeling unwell.': 'Pacienti raportoi se nuk ndihet mire.',
    'Read aloud': 'Lexo me ze',
    'e.g. 78': 'p.sh. 78',
    '100%': '100%',
    '120%': '120%',
    '140%': '140%',
    'Contact our support team at:': 'Kontaktoni ekipin tone te mbeshtetjes ne:',
    'Support email copied.': 'Email-i i mbeshtetjes u kopjua.',
    'Copy email': 'Kopjo email-in',
    'Open email app': 'Hap aplikacionin e email-it',
    "Today's reminder progress": 'Progresi i kujtuesve sot',
    'Great job! You are all set for today.':
        'Shkelqyeshem! Jeni gati per sot.',
    'Keep going, you are doing great.':
        'Vazhdoni keshtu, po ia dilni shume mire.',
    'Emergency alert cleared': 'Sinjali i emergjences u hoq',
    'Patient marked they are safe now.':
        'Pacienti shenoi qe tani eshte i sigurt.',
    'Remove alert': 'Hiq sinjalin',
    'You can remove this alert in {m} min':
        'Mund ta hiqni kete sinjal pas {m} min',
  };

  static String tr(
    BuildContext context,
    String key, [
    Map<String, String>? args,
  ]) {
    final code = LocaleController.instance.code;
    String value = key;
    if (code == 'sq') {
      value = _sq[key] ?? key;
    }
    if (args != null) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }
}

extension AppI18nX on BuildContext {
  String tr(String key, [Map<String, String>? args]) =>
      AppI18n.tr(this, key, args);
}

