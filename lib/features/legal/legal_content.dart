import '../../core/config/app_info.dart';

enum LegalDocument { privacy, terms }

/// One titled part of a legal page. Lines starting with "• " are shown as a
/// list.
typedef LegalSection = ({String heading, List<String> lines});

/// The privacy policy and terms of use, in English and Macedonian. Kept in
/// code (not in the translation files) because they are long documents
/// rather than interface text.
///
/// They describe what the app actually does — update them whenever data
/// handling changes (new data collected, new service used, …).
List<LegalSection> legalSections(LegalDocument doc, String languageCode) {
  final mk = languageCode == 'mk';
  return switch (doc) {
    LegalDocument.privacy => mk ? _privacyMk : _privacyEn,
    LegalDocument.terms => mk ? _termsMk : _termsEn,
  };
}

const _email = AppInfo.supportEmail;

// ---------------------------------------------------------------------------
// Privacy policy — English
// ---------------------------------------------------------------------------
const List<LegalSection> _privacyEn = [
  (
    heading: '',
    lines: [
      'Nosiva is a marketplace where people in North Macedonia buy and sell '
          'second-hand fashion. This policy explains what information we '
          'collect, why we need it, and the control you have over it.',
      'Items are paid for in cash to the courier on delivery, so Nosiva never '
          'asks for or stores card or bank details.',
    ],
  ),
  (
    heading: 'What we collect',
    lines: [
      '• Account: your email address and username. Your password is stored '
          'encrypted by our sign-in provider; nobody at Nosiva can see it. If '
          'you sign in with Google, we receive the name and email address '
          'Google shares with us.',
      '• Profile: display name, bio, city and profile photo. Other people '
          'can see these.',
      '• Listings: photos, title, description, price, size, brand, colour, '
          'condition and city. Listings are public, including to people who '
          'are not signed in.',
      '• Messages and chat photos: visible only to you and the person you '
          'are talking to. Chat photos are stored privately and can only be '
          'opened by the two of you.',
      '• Orders and offers: the delivery address and phone number you enter '
          'are shared with the seller of that item so they can send it to you.',
      '• Activity: favourites, follows, reviews (reviews are public), and '
          'the reports and blocks you make. We count how many times a listing '
          'is viewed, without showing who viewed it.',
      '• Location: only when you tap "Use my location", to fill in your city. '
          'We keep the city name, not your exact position.',
      '• Kept only on your phone: recent searches, your last delivery '
          'details, and your language and theme choice.',
    ],
  ),
  (
    heading: 'What we never do',
    lines: [
      '• We don\'t show ads and we don\'t sell or rent your information.',
      '• We don\'t track you across other apps or websites.',
      '• We don\'t use advertising or analytics trackers.',
    ],
  ),
  (
    heading: 'Why we use it',
    lines: [
      '• To run your account and show your profile and listings.',
      '• To deliver messages, offers and orders between buyers and sellers.',
      '• To keep the community safe: handling reports, removing items or '
          'accounts that break the rules, and preventing abuse.',
      '• To keep your account secure.',
    ],
  ),
  (
    heading: 'Who else handles it',
    lines: [
      '• Supabase hosts our database, file storage and sign-in, and processes '
          'data only on our behalf.',
      '• Google, only if you choose to sign in with Google.',
      '• Couriers receive your address and phone from the seller who sends '
          'your item, not from Nosiva.',
      'We may share information if the law requires it, for example at the '
          'request of a court or the police.',
    ],
  ),
  (
    heading: 'How long we keep it',
    lines: [
      'We keep your information while your account exists. When you delete '
          'your account (Settings → Delete account), your profile, listings, '
          'photos, messages, offers, orders, reviews, favourites and follows '
          'are deleted straight away. This can\'t be undone. Copies in our '
          'hosting provider\'s backups are overwritten within a short time.',
      'An account can\'t be deleted while it has an order in progress, so the '
          'other person isn\'t left without their item or their money.',
    ],
  ),
  (
    heading: 'Your rights',
    lines: [
      'Under North Macedonia\'s Law on Personal Data Protection you can ask '
          'to see, correct or delete your information, ask for a copy of it, '
          'or object to how it is used. You can edit your profile and delete '
          'your account yourself in the app; for anything else, email us at '
          '$_email.',
      'If you think we have handled your information wrongly, you can '
          'complain to the Personal Data Protection Agency (azlp.mk).',
    ],
  ),
  (
    heading: 'Security',
    lines: [
      'All connections are encrypted. Your sign-in is kept in your phone\'s '
          'secure storage, and access rules on our servers make sure people '
          'can only reach what they are allowed to. No system is perfectly '
          'secure, so use a password you don\'t use anywhere else.',
    ],
  ),
  (
    heading: 'Children',
    lines: [
      'Nosiva is not meant for anyone under 16. If you believe a child under '
          '16 has an account, email us and we will remove it.',
    ],
  ),
  (
    heading: 'Changes and contact',
    lines: [
      'If we change this policy, we will update the date at the top and let '
          'you know in the app about important changes.',
      'Questions? Email $_email.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Privacy policy — Macedonian
// ---------------------------------------------------------------------------
const List<LegalSection> _privacyMk = [
  (
    heading: '',
    lines: [
      'Nosiva е пазар каде луѓето во Северна Македонија купуваат и продаваат '
          'облека од втора рака. Оваа политика објаснува кои податоци ги '
          'собираме, зошто ни се потребни и каква контрола имате врз нив.',
      'Предметите се плаќаат во готово на курирот при достава, па Nosiva '
          'никогаш не бара и не чува податоци за картички или банкарски сметки.',
    ],
  ),
  (
    heading: 'Што собираме',
    lines: [
      '• Сметка: вашата е-пошта и корисничко име. Лозинката е шифрирана кај '
          'нашиот давател за најава; никој во Nosiva не може да ја види. Ако '
          'се најавите со Google, го добиваме името и е-поштата што Google ги '
          'споделува со нас.',
      '• Профил: име за прикажување, биографија, град и профилна слика. '
          'Другите корисници можат да ги видат.',
      '• Огласи: фотографии, наслов, опис, цена, големина, бренд, боја, '
          'состојба и град. Огласите се јавни, вклучително и за луѓе што не '
          'се најавени.',
      '• Пораки и фотографии во разговор: ги гледате само вие и личноста со '
          'која разговарате. Фотографиите од разговорите се чуваат приватно и '
          'можат да ги отворат само двајцата.',
      '• Нарачки и понуди: адресата за достава и телефонот што ги внесувате '
          'се споделуваат со продавачот на тој предмет за да може да ви го '
          'испрати.',
      '• Активност: омилени, следења, оценки (оценките се јавни) и '
          'пријавите и блокирањата што ги правите. Броиме колку пати е '
          'прегледан оглас, без да прикажуваме кој го прегледал.',
      '• Локација: само кога ќе притиснете „Користи ја мојата локација“, за '
          'да се пополни градот. Го чуваме името на градот, не вашата точна '
          'позиција.',
      '• Само на вашиот телефон: последните пребарувања, последните податоци '
          'за достава и изборот на јазик и изглед.',
    ],
  ),
  (
    heading: 'Што никогаш не правиме',
    lines: [
      '• Не прикажуваме реклами и не ги продаваме ниту изнајмуваме вашите '
          'податоци.',
      '• Не ве следиме низ други апликации или веб-страници.',
      '• Не користиме рекламни или аналитички алатки за следење.',
    ],
  ),
  (
    heading: 'Зошто ги користиме',
    lines: [
      '• За да работи вашата сметка и да се прикажуваат профилот и огласите.',
      '• За да стигнуваат пораките, понудите и нарачките меѓу купувачи и '
          'продавачи.',
      '• За безбедна заедница: обработка на пријави, отстранување огласи или '
          'сметки што ги кршат правилата и спречување злоупотреби.',
      '• За безбедност на вашата сметка.',
    ],
  ),
  (
    heading: 'Кој друг ги обработува',
    lines: [
      '• Supabase ги хостира нашата база на податоци, складирањето датотеки и '
          'најавата, и ги обработува податоците само во наше име.',
      '• Google, само ако изберете најава со Google.',
      '• Куририте ја добиваат вашата адреса и телефон од продавачот што го '
          'испраќа предметот, не од Nosiva.',
      'Можеме да споделиме податоци ако тоа го бара законот, на пример на '
          'барање на суд или полиција.',
    ],
  ),
  (
    heading: 'Колку долго ги чуваме',
    lines: [
      'Ги чуваме вашите податоци додека постои сметката. Кога ќе ја избришете '
          'сметката (Поставки → Избриши сметка), профилот, огласите, '
          'фотографиите, пораките, понудите, нарачките, оценките, омилените и '
          'следењата се бришат веднаш. Ова не може да се врати. Копиите во '
          'резервните копии кај нашиот хостинг-давател се пребришуваат за '
          'кратко време.',
      'Сметката не може да се избрише додека има нарачка во тек, за другата '
          'страна да не остане без предметот или парите.',
    ],
  ),
  (
    heading: 'Вашите права',
    lines: [
      'Според Законот за заштита на личните податоци можете да побарате да '
          'ги видите, исправите или избришете вашите податоци, да добиете '
          'копија од нив или да приговорите на начинот на кој се користат. '
          'Профилот можете сами да го уредите, а сметката да ја избришете во '
          'апликацијата; за сè друго пишете ни на $_email.',
      'Ако сметате дека погрешно сме постапиле со вашите податоци, можете да '
          'поднесете приговор до Агенцијата за заштита на личните податоци '
          '(azlp.mk).',
    ],
  ),
  (
    heading: 'Безбедност',
    lines: [
      'Сите врски се шифрирани. Вашата најава се чува во безбедното '
          'складиште на телефонот, а правилата за пристап на нашите сервери '
          'осигуруваат секој да пристапува само до она што му е дозволено. '
          'Ниту еден систем не е совршено безбеден, затоа користете лозинка '
          'што не ја користите никаде на друго место.',
    ],
  ),
  (
    heading: 'Деца',
    lines: [
      'Nosiva не е наменета за лица помлади од 16 години. Ако мислите дека '
          'дете помладо од 16 години има сметка, пишете ни и ќе ја отстраниме.',
    ],
  ),
  (
    heading: 'Промени и контакт',
    lines: [
      'Ако ја промениме оваа политика, ќе го ажурираме датумот најгоре и ќе '
          'ве известиме во апликацијата за поважните промени.',
      'Прашања? Пишете на $_email.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Terms of use — English
// ---------------------------------------------------------------------------
const List<LegalSection> _termsEn = [
  (
    heading: '',
    lines: [
      'By creating an account or using Nosiva you agree to these terms. '
          'Please read them; they are short.',
    ],
  ),
  (
    heading: 'What Nosiva is',
    lines: [
      'Nosiva connects people who want to sell second-hand clothes, shoes and '
          'accessories with people who want to buy them. Each sale is an '
          'agreement between the buyer and the seller. Nosiva is not the '
          'seller, does not own the items, and does not take part in payment '
          'or delivery.',
    ],
  ),
  (
    heading: 'Your account',
    lines: [
      '• You must be at least 16. If you are under 18, you need permission '
          'from a parent or guardian.',
      '• Give true information and keep your password to yourself. You are '
          'responsible for what happens on your account.',
      '• One person, one account. Don\'t pretend to be someone else.',
    ],
  ),
  (
    heading: 'Selling',
    lines: [
      '• Only list items you own and are allowed to sell.',
      '• Describe items honestly, including any damage, and use your own '
          'photos.',
      '• Once you accept an offer or receive an order, send the item as '
          'agreed, or let the buyer know quickly if you can\'t.',
      '• Mark items as sold when they are no longer available.',
    ],
  ),
  (
    heading: 'Buying, payment and delivery',
    lines: [
      '• You pay the courier in cash when the item is delivered. Nosiva '
          'doesn\'t handle payments.',
      '• Delivery is arranged by the seller with a courier of their choice. '
          'Check the item\'s description and ask the seller questions before '
          'ordering.',
      '• Disagreements about an item (condition, size, delivery) are between '
          'the buyer and the seller. If someone acts dishonestly, report them '
          'and we will look into it.',
    ],
  ),
  (
    heading: 'Not allowed',
    lines: [
      '• Counterfeit or replica items, stolen goods, or anything illegal.',
      '• Used underwear and swimwear bottoms, weapons, medicines, or items '
          'that aren\'t fashion.',
      '• Harassment, hate, threats, spam, or sexual content.',
      '• Asking for payment outside the cash-on-delivery process, or trying '
          'to get people\'s personal data for other purposes.',
      '• Trying to break, overload or get around the app\'s security.',
    ],
  ),
  (
    heading: 'Reports and enforcement',
    lines: [
      'You can report listings and people, and block anyone. We may remove '
          'listings, limit features, or close accounts that break these terms, '
          'and we may do so without notice when it is needed to protect other '
          'people.',
    ],
  ),
  (
    heading: 'Your content',
    lines: [
      'You keep ownership of the photos and text you post. You allow Nosiva to '
          'show them in the app, including to people who are not signed in, '
          'and when listings are shared. This ends when you delete them or your '
          'account.',
    ],
  ),
  (
    heading: 'Liability',
    lines: [
      'We work hard to keep Nosiva running and safe, but we provide it "as '
          'is" and can\'t promise it will always be available or error-free. '
          'As far as the law allows, Nosiva is not responsible for items, '
          'payments or deliveries between users, or for losses from using the '
          'app.',
    ],
  ),
  (
    heading: 'Ending and changes',
    lines: [
      'You can stop using Nosiva and delete your account at any time in '
          'Settings. We may update these terms; if a change is important, we '
          'will tell you in the app before it applies.',
      'These terms are governed by the laws of North Macedonia.',
      'Questions? Email $_email.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Terms of use — Macedonian
// ---------------------------------------------------------------------------
const List<LegalSection> _termsMk = [
  (
    heading: '',
    lines: [
      'Со креирање сметка или користење на Nosiva се согласувате со овие '
          'услови. Ве молиме прочитајте ги; кратки се.',
    ],
  ),
  (
    heading: 'Што е Nosiva',
    lines: [
      'Nosiva ги поврзува луѓето што сакаат да продадат облека, обувки и '
          'додатоци од втора рака со луѓето што сакаат да ги купат. Секоја '
          'продажба е договор меѓу купувачот и продавачот. Nosiva не е '
          'продавач, не е сопственик на предметите и не учествува во плаќањето '
          'или доставата.',
    ],
  ),
  (
    heading: 'Вашата сметка',
    lines: [
      '• Мора да имате најмалку 16 години. Ако сте помлади од 18 години, '
          'потребна ви е дозвола од родител или старател.',
      '• Внесувајте вистинити податоци и не ја споделувајте лозинката. Вие '
          'сте одговорни за она што се случува на вашата сметка.',
      '• Една личност, една сметка. Не се претставувајте како друг.',
    ],
  ),
  (
    heading: 'Продавање',
    lines: [
      '• Објавувајте само предмети што ги поседувате и смеете да ги продадете.',
      '• Опишувајте ги предметите искрено, вклучително и оштетувањата, и '
          'користете свои фотографии.',
      '• Кога ќе прифатите понуда или ќе добиете нарачка, испратете го '
          'предметот како што е договорено, или брзо известете го купувачот '
          'ако не можете.',
      '• Означете ги предметите како продадени кога веќе не се достапни.',
    ],
  ),
  (
    heading: 'Купување, плаќање и достава',
    lines: [
      '• Плаќате во готово на курирот кога предметот ќе биде доставен. '
          'Nosiva не врши плаќања.',
      '• Доставата ја организира продавачот со курир по свој избор. Прочитајте '
          'го описот и поставете му прашања на продавачот пред да нарачате.',
      '• Несогласувањата за предмет (состојба, големина, достава) се меѓу '
          'купувачот и продавачот. Ако некој постапува нечесно, пријавете го и '
          'ќе го провериме.',
    ],
  ),
  (
    heading: 'Не е дозволено',
    lines: [
      '• Фалсификувани предмети или реплики, украдени предмети или било што '
          'незаконско.',
      '• Користена долна облека и долни делови од костими за капење, оружје, '
          'лекови или предмети што не се модни.',
      '• Вознемирување, говор на омраза, закани, спам или сексуална содржина.',
      '• Барање плаќање надвор од плаќањето во готово при достава, или '
          'обиди да се дојде до туѓи лични податоци за други цели.',
      '• Обиди да се оштети, преоптовари или заобиколи безбедноста на '
          'апликацијата.',
    ],
  ),
  (
    heading: 'Пријави и мерки',
    lines: [
      'Можете да пријавувате огласи и луѓе и да блокирате кого било. Можеме '
          'да отстраниме огласи, да ограничиме функции или да затвориме сметки '
          'што ги кршат овие услови, и тоа без претходно известување кога е '
          'потребно за заштита на другите.',
    ],
  ),
  (
    heading: 'Вашата содржина',
    lines: [
      'Вие останувате сопственик на фотографиите и текстот што ги објавувате. '
          'Му дозволувате на Nosiva да ги прикажува во апликацијата, '
          'вклучително и на луѓе што не се најавени, и кога огласите се '
          'споделуваат. Ова престанува кога ќе ги избришете нив или сметката.',
    ],
  ),
  (
    heading: 'Одговорност',
    lines: [
      'Вложуваме многу труд Nosiva да работи и да биде безбедна, но ја нудиме '
          '„таква каква што е“ и не можеме да ветиме дека секогаш ќе биде '
          'достапна или без грешки. Колку што дозволува законот, Nosiva не '
          'одговара за предметите, плаќањата или доставите меѓу корисниците, '
          'ниту за штети од користењето на апликацијата.',
    ],
  ),
  (
    heading: 'Престанок и промени',
    lines: [
      'Можете да престанете да ја користите Nosiva и да ја избришете сметката '
          'во секое време во Поставки. Можеме да ги ажурираме овие услови; ако '
          'промената е важна, ќе ве известиме во апликацијата пред да важи.',
      'За овие услови важат законите на Северна Македонија.',
      'Прашања? Пишете на $_email.',
    ],
  ),
];
