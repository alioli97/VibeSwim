import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites.dart';
import 'workout_history.dart';
import 'workout_picker.dart';

class AppState extends ChangeNotifier {
  static const String keyLanguage = 'language_code';
  static const String keyDifficulty = 'difficulty_filter';

  String _currentLanguage = 'en'; // 'en', 'es', 'ca'
  String get currentLanguage => _currentLanguage;

  final SharedPreferences prefs;

  /// Workouts the user has finished, stored on the device.
  final WorkoutHistory history;

  /// Starred workouts, stored on the device.
  final Favorites favorites;

  AppState(this.prefs)
      : history = WorkoutHistory(prefs),
        favorites = Favorites(prefs) {
    _currentLanguage = prefs.getString(keyLanguage) ?? 'en';
    _difficulty = DifficultyFilter.values.asNameMap()[prefs.getString(keyDifficulty)] ??
        DifficultyFilter.any;
  }

  /// Difficulty filter chosen on the home screen (persisted).
  DifficultyFilter _difficulty = DifficultyFilter.any;
  DifficultyFilter get difficulty => _difficulty;

  void setDifficulty(DifficultyFilter filter) {
    if (_difficulty == filter) return;
    _difficulty = filter;
    prefs.setString(keyDifficulty, filter.name);
    notifyListeners();
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
  String get tHistory => _tr('History', 'Historial', 'Historial');
  String get tSetCustom => _tr('SET CUSTOM', 'PERSONALIZAR', 'PERSONALITZAR');
  String get tCustom => _tr('CUSTOM', 'OTRO', 'ALTRE');
  String get tDifficultyLabel => _tr('Difficulty', 'Dificultad', 'Dificultat');
  String get tAnyDifficulty => _tr('Any', 'Cualquiera', 'Qualsevol');
  String get tBeginner => _tr('Beginner', 'Principiante', 'Principiant');
  String get tIntermediate => _tr('Intermediate', 'Intermedio', 'Intermedi');
  String get tAdvanced => _tr('Advanced', 'Avanzado', 'Avançat');
  String difficultyName(DifficultyFilter f) => switch (f) {
        DifficultyFilter.any => tAnyDifficulty,
        DifficultyFilter.beginner => tBeginner,
        DifficultyFilter.intermediate => tIntermediate,
        DifficultyFilter.advanced => tAdvanced,
      };
  String tNoWorkoutsForDifficulty(String level) => _tr(
        'No $level workouts match. Try another difficulty.',
        'No hay entrenos de nivel $level que encajen. Prueba otra dificultad.',
        "No hi ha entrenaments de nivell $level que encaixin. Prova una altra dificultat.",
      );
  String get tFavorites => _tr('Favorites', 'Favoritos', 'Preferits');
  String get tAddFavorite => _tr('Add to favorites', 'Añadir a favoritos', 'Afegir a preferits');
  String get tRemoveFavorite => _tr('Remove from favorites', 'Quitar de favoritos', 'Treure de preferits');
  String get tAddedToFavorites => _tr('Added to favorites', 'Añadido a favoritos', 'Afegit a preferits');
  String get tRemovedFromFavorites => _tr('Removed from favorites', 'Quitado de favoritos', 'Tret de preferits');
  String get tNoFavoritesYet => _tr('No favorites yet. Tap ☆ on a workout to save it here.', 'Aún no tienes favoritos. Pulsa ☆ en un entreno para guardarlo aquí.', 'Encara no tens preferits. Prem ☆ en un entrenament per desar-lo aquí.');
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
  String get tBackup => _tr('Backup', 'Copia de seguridad', 'Còpia de seguretat');
  String get tExportBackup => _tr('Export backup', 'Exportar copia', 'Exportar còpia');
  String get tImportBackup => _tr('Import backup', 'Importar copia', 'Importar còpia');
  String get tExportFailed => _tr('Could not export the history', 'No se ha podido exportar el historial', "No s'ha pogut exportar l'historial");
  String get tImportFailed => _tr('Could not open the file', 'No se ha podido abrir el archivo', "No s'ha pogut obrir el fitxer");
  String get tNotABackup => _tr('This file is not a SwimVibe backup', 'Este archivo no es una copia de SwimVibe', 'Aquest fitxer no és una còpia de SwimVibe');
  String tImported(int n) => _tr(
        n == 1 ? '1 workout imported' : '$n workouts imported',
        n == 1 ? '1 entreno importado' : '$n entrenos importados',
        n == 1 ? '1 entrenament importat' : '$n entrenaments importats',
      );
  String tCompletedOf(String done, String goal) => _tr(
        '$done of $goal completed',
        '$done de $goal completados',
        '$done de $goal completats',
      );

  // Progress
  String get tYourProgress => _tr('Your Progress', 'Tu progreso', 'El teu progrés');
  String get tLastWeeks => _tr('Last 8 weeks', 'Últimas 8 semanas', 'Últimes 8 setmanes');
  String get tGoalLine => _tr('Goal', 'Objetivo', 'Objectiu');
  String get tTotals => _tr('Totals', 'Totales', 'Totals');
  String get tTotalTime => _tr('Total Time', 'Tiempo total', 'Temps total');
  String get tAvgPerWorkout => _tr('Avg. per Workout', 'Media por entreno', 'Mitjana per entrenament');
  String get tLongestWorkout => _tr('Longest Workout', 'Entreno más largo', 'Entrenament més llarg');
  String get tThisMonth => _tr('This Month', 'Este mes', 'Aquest mes');
  String get tMonthComparison => _tr('This month vs last', 'Este mes vs el anterior', "Aquest mes vs l'anterior");
  String get tLastMonth => _tr('Last Month', 'Mes anterior', 'Mes anterior');
  String get tStreak => _tr('Streak', 'Racha', 'Ratxa');
  String get tCurrentStreak => _tr('Current', 'Actual', 'Actual');
  String get tBestStreak => _tr('Best', 'Mejor', 'Millor');
  String get tStreakHint => _tr('Weeks in a row meeting your weekly goal', 'Semanas seguidas cumpliendo el objetivo semanal', "Setmanes seguides complint l'objectiu setmanal");
  String tWeeks(int n) => _tr(
        n == 1 ? '1 week' : '$n weeks',
        n == 1 ? '1 semana' : '$n semanas',
        n == 1 ? '1 setmana' : '$n setmanes',
      );
  String get tNoStatsYet => _tr('Log your first workout to see your stats.', 'Guarda tu primer entreno para ver tus estadísticas.', 'Desa el teu primer entrenament per veure les teves estadístiques.');

  /// Meters with the language's thousands separator (12,450m / 12.450m).
  String formatMeters(int meters) =>
      '${NumberFormat.decimalPattern(_currentLanguage).format(meters)}m';

  /// "45 min" or "3 h 05 min".
  String formatMinutes(int minutes) => minutes < 60
      ? '$minutes min'
      : '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';

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
