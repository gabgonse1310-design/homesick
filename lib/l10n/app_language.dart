import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();
  static const _preferenceKey = 'preferred_language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _locale = Locale(preferences.getString(_preferenceKey) ?? 'en');
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, languageCode);
    notifyListeners();
  }
}

class AppTranslations {
  AppTranslations(this.locale);

  final Locale locale;

  static AppTranslations of(BuildContext context) {
    return AppTranslations(Localizations.localeOf(context));
  }

  String text(String key) {
    return (_values[locale.languageCode] ?? _values['en']!)[key] ??
        _values['en']![key] ??
        key;
  }

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'familyHub': 'Our Family',
      'familySubtitle': 'Plans, care and everyday moments in one place.',
      'today': 'Today',
      'agenda': 'Agenda',
      'tasks': 'Helping Hands',
      'updates': 'Family Updates',
      'addEvent': 'Add event',
      'addTask': 'Add task',
      'shareUpdate': 'Share an update',
      'eventTitle': 'Event title',
      'taskTitle': 'What needs doing?',
      'updateHint': 'What would you like your family to know?',
      'details': 'Details (optional)',
      'date': 'Date',
      'time': 'Time',
      'save': 'Save',
      'cancel': 'Cancel',
      'claim': 'I can help',
      'claimedBy': 'Claimed by',
      'complete': 'Mark complete',
      'completed': 'Completed',
      'noEvents': 'No family events yet.',
      'noTasks': 'No shared tasks yet.',
      'noUpdates': 'No family updates yet.',
      'createdBy': 'Shared by',
      'todayEmpty': 'Nothing is scheduled for today.',
      'familyWelcome':
          'A private space for the people who care for one another.',
      'connectedMembers': 'Connected family members can see this space.',
      'language': 'Language',
      'chooseLanguage': 'Choose a language',
      'english': 'English',
      'spanish': 'Spanish',
      'ad': 'Advertisement',
      'retry': 'Try again',
      'familyLoadError': 'We could not open your family space.',
      'requiredField': 'Please enter a title.',
      'post': 'Post',
      'elderMode': 'Easy-read mode',
      'elderModeHint': 'Larger text and clearer actions',
    },
    'es': {
      'familyHub': 'Nuestra Familia',
      'familySubtitle':
          'Planes, cuidados y momentos cotidianos en un solo lugar.',
      'today': 'Hoy',
      'agenda': 'Agenda',
      'tasks': 'Manos que ayudan',
      'updates': 'Novedades familiares',
      'addEvent': 'Añadir evento',
      'addTask': 'Añadir tarea',
      'shareUpdate': 'Compartir una novedad',
      'eventTitle': 'Título del evento',
      'taskTitle': '¿Qué hay que hacer?',
      'updateHint': '¿Qué quieres contarle a tu familia?',
      'details': 'Detalles (opcional)',
      'date': 'Fecha',
      'time': 'Hora',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'claim': 'Yo puedo ayudar',
      'claimedBy': 'Asignada a',
      'complete': 'Marcar como completada',
      'completed': 'Completada',
      'noEvents': 'Todavía no hay eventos familiares.',
      'noTasks': 'Todavía no hay tareas compartidas.',
      'noUpdates': 'Todavía no hay novedades familiares.',
      'createdBy': 'Compartido por',
      'todayEmpty': 'No hay nada programado para hoy.',
      'familyWelcome': 'Un espacio privado para quienes se cuidan mutuamente.',
      'connectedMembers': 'Los familiares conectados pueden ver este espacio.',
      'language': 'Idioma',
      'chooseLanguage': 'Elige un idioma',
      'english': 'Inglés',
      'spanish': 'Español',
      'ad': 'Publicidad',
      'retry': 'Intentar de nuevo',
      'familyLoadError': 'No pudimos abrir tu espacio familiar.',
      'requiredField': 'Por favor, escribe un título.',
      'post': 'Publicar',
      'elderMode': 'Modo de lectura fácil',
      'elderModeHint': 'Texto más grande y acciones más claras',
    },
  };
}

extension AppTranslationContext on BuildContext {
  String familyText(String key) => AppTranslations.of(this).text(key);
}
