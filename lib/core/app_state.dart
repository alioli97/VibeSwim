import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_history.dart';

class AppState extends ChangeNotifier {
  static const String keyLanguage = 'language_code';

  String _currentLanguage = 'en'; // 'en', 'es', 'ca'
  String get currentLanguage => _currentLanguage;

  final SharedPreferences prefs;

  /// Workouts the user has finished, stored on the device.
  final WorkoutHistory history;

  AppState(this.prefs) : history = WorkoutHistory(prefs) {
    _currentLanguage = prefs.getString(keyLanguage) ?? 'en';
  }

  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      prefs.setString(keyLanguage, lang);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // UI translations. Every user-visible text goes here in all three languages.
  // ---------------------------------------------------------------------------

  String _tr(String en, String es, String ca) {
    switch (_currentLanguage) {
      case 'es': return es;
      case 'ca': return ca;
      default: return en;
    }
  }

  // Home
  String get tReadyForASet => _tr('READY FOR A SET?', '¿LISTO PARA ENTRENAR?', 'LLEST PER ENTRENAR?');
  String get tDefineSession => _tr('Define Your\nSession', 'Define Tu\nSesión', 'Defineix La\nTeva Sessió');
  String get tDistance => _tr('Distance', 'Distancia', 'Distància');
  String get tTargetMeters => _tr('Target total meters', 'Metros totales objetivo', 'Metres totals objectiu');
  String get tAvailableTime => _tr('Available Time', 'Tiempo Disponible', 'Temps Disponible');
  String get tTime => _tr('Time', 'Tiempo', 'Temps');
  String get tLaneBooked => _tr('How long is your lane booked?', '¿Cuánto tiempo tienes?', 'Quant de temps tens?');
  String get tMinutes => _tr('MINUTES', 'MINUTOS', 'MINUTS');
  String get tGenerateWorkout => _tr('Generate Workout', 'Generar Entreno', 'Generar Entrenament');
  String get tHistoryProgress => _tr('History & Progress', 'Historial y Progreso', 'Historial i Progrés');
  String get tSetCustom => _tr('SET CUSTOM', 'PERSONALIZAR', 'PERSONALITZAR');
  String get tCustom => _tr('CUSTOM', 'OTRO', 'ALTRE');
  String get tLanguage => _tr('Language', 'Idioma', 'Idioma');

  // Dialogs and common
  String get tCancel => _tr('Cancel', 'Cancelar', 'Cancel·lar');
  String get tSave => _tr('Save', 'Guardar', 'Desar');
  String get tGoBack => _tr('Go Back', 'Volver', 'Tornar');
  String tError(Object error) => _tr('Error: $error', 'Error: $error', 'Error: $error');

  // Bottom navigation
  String get tNavWorkouts => _tr('Workouts', 'Entrenos', 'Entrenaments');
  String get tNavHistory => _tr('History', 'Historial', 'Historial');
  String get tNavProgress => _tr('Progress', 'Progreso', 'Progrés');

  // Workout detail
  String tNoWorkoutFits(int minutes) => _tr(
        'No workout fits in $minutes min',
        'No hay ningún entreno de $minutes min o menos',
        'No hi ha cap entrenament de $minutes min o menys',
      );
  String get tNoWorkouts => _tr('No workouts available', 'No hay entrenos disponibles', 'No hi ha entrenaments disponibles');
  String get tWorkoutTarget => _tr('WORKOUT TARGET', 'OBJETIVO DEL ENTRENO', "OBJECTIU DE L'ENTRENAMENT");
  String get tSwimSession => _tr('Swim Session', 'Sesión de natación', 'Sessió de natació');
  String get tIntensity => _tr('INTENSITY', 'INTENSIDAD', 'INTENSITAT');
  String get tModerate => _tr('Moderate', 'Moderada', 'Moderada');
  String get tThePlan => _tr('The Plan', 'El plan', 'El pla');
  String get tWarmUp => _tr('Warm-up', 'Calentamiento', 'Escalfament');
  String get tWarmUpHint => _tr('Get the blood flowing', 'Entra en calor', 'Entra en calor');
  String get tMainSet => _tr('Main Set', 'Serie principal', 'Sèrie principal');
  String get tMainSetHint => _tr('Focus on quality', 'Céntrate en la técnica', "Centra't en la tècnica");
  String get tPushYourPace => _tr('Push your pace', 'Aprieta el ritmo', 'Apreta el ritme');
  String get tCoolDown => _tr('Cool down', 'Vuelta a la calma', 'Tornada a la calma');
  String get tCoolDownHint => _tr('Recovery and stretch', 'Recuperación y estiramientos', 'Recuperació i estiraments');
  String get tVeryRelaxed => _tr('Very relaxed', 'Muy suave', 'Molt suau');
  String get tFinishAndLog => _tr('Finish & Log', 'Terminar y guardar', 'Acabar i desar');
  String get tLogged => _tr('Logged', 'Guardado', 'Desat');
  String get tGenerateAnother => _tr('Generate another', 'Generar otro', 'Generar-ne un altre');
  String get tNoOtherWorkout => _tr('No other workout matches', 'No hay otro entreno que encaje', "No hi ha cap altre entrenament que encaixi");
  String get tShare => _tr('Share', 'Compartir', 'Compartir');
  String get tShareFailed => _tr('Could not share the workout', 'No se ha podido compartir el entreno', "No s'ha pogut compartir l'entrenament");
  String get tSavedToHistory => _tr('Saved to your history', 'Guardado en tu historial', "Desat al teu historial");

  // History
  String get tWorkoutHistory => _tr('Workout History', 'Historial de entrenos', "Historial d'entrenaments");
  String get tNoWorkoutsYet => _tr('No workouts yet. Go swim!', 'Aún no hay entrenos. ¡A nadar!', 'Encara no hi ha entrenaments. A nedar!');
  String get tWorkout => _tr('Workout', 'Entreno', 'Entrenament');
  String get tProgress => _tr('Progress', 'Progreso', 'Progrés');
  String get tTotalDistance => _tr('Total Distance', 'Distancia total', 'Distància total');
  String get tWorkoutsDone => _tr('Workouts', 'Entrenos', 'Entrenaments');
  String get tWeeklyGoal => _tr('Weekly Goal', 'Objetivo semanal', 'Objectiu setmanal');
  String get tEditWeeklyGoal => _tr('Change weekly goal', 'Cambiar objetivo semanal', "Canviar l'objectiu setmanal");
  String get tDelete => _tr('Delete', 'Borrar', 'Esborrar');
  String get tUndo => _tr('Undo', 'Deshacer', 'Desfer');
  String get tWorkoutDeleted => _tr('Workout deleted', 'Entreno borrado', 'Entrenament esborrat');
  String tCompletedOf(String done, String goal) => _tr(
        '$done of $goal completed',
        '$done de $goal completados',
        '$done de $goal completats',
      );

  // Translation getter for Supabase map
  String localizedDbField(Map<String, dynamic> row, String prefix) {
    // try exact match
    if (row['${prefix}_$_currentLanguage'] != null) {
      return row['${prefix}_$_currentLanguage'].toString();
    }
    // fallback
    return row['${prefix}_en'] ?? row['${prefix}_es'] ?? '';
  }
}
