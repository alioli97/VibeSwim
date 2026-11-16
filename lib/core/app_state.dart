import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const String keyLanguage = 'language_code';
  
  String _currentLanguage = 'en'; // 'en', 'es', 'ca'
  String get currentLanguage => _currentLanguage;

  final SharedPreferences prefs;

  AppState(this.prefs) {
    _currentLanguage = prefs.getString(keyLanguage) ?? 'en';
  }

  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      prefs.setString(keyLanguage, lang);
      notifyListeners();
    }
  }

  // Very basic localization
  String get tReadyForASet {
    switch (_currentLanguage) {
      case 'es': return '¿LISTO PARA ENTRENAR?';
      case 'ca': return 'LLEST PER ENTRENAR?';
      default: return 'READY FOR A SET?';
    }
  }

  String get tDefineSession {
    switch (_currentLanguage) {
      case 'es': return 'Define Tu\nSesión';
      case 'ca': return 'Defineix La\nTeva Sessió';
      default: return 'Define Your\nSession';
    }
  }

  String get tDistance {
    switch (_currentLanguage) {
      case 'es': return 'Distancia';
      case 'ca': return 'Distància';
      default: return 'Distance';
    }
  }
  
  String get tTargetMeters {
    switch (_currentLanguage) {
      case 'es': return 'Metros totales objetivo';
      case 'ca': return 'Metres totals objectiu';
      default: return 'Target total meters';
    }
  }
  
  String get tAvailableTime {
    switch (_currentLanguage) {
      case 'es': return 'Tiempo Disponible';
      case 'ca': return 'Temps Disponible';
      default: return 'Available Time';
    }
  }

  String get tLaneBooked {
    switch (_currentLanguage) {
      case 'es': return '¿Cuánto tiempo tienes?';
      case 'ca': return 'Quant de temps tens?';
      default: return 'How long is your lane booked?';
    }
  }

  String get tGenerateWorkout {
    switch (_currentLanguage) {
      case 'es': return 'Generar Entreno';
      case 'ca': return 'Generar Entrenament';
      default: return 'Generate Workout';
    }
  }

  String get tHistoryProgress {
    switch (_currentLanguage) {
      case 'es': return 'Historial y Progreso';
      case 'ca': return 'Historial i Progrés';
      default: return 'History & Progress';
    }
  }

  String get tSetCustom {
    switch (_currentLanguage) {
      case 'es': return 'PERSONALIZAR';
      case 'ca': return 'PERSONALITZAR';
      default: return 'SET CUSTOM';
    }
  }

  String get tCustom {
    switch (_currentLanguage) {
      case 'es': return 'OTRO';
      case 'ca': return 'ALTRE';
      default: return 'CUSTOM';
    }
  }

  String tNoWorkoutFits(int minutes) {
    switch (_currentLanguage) {
      case 'es': return 'No hay ningún entreno de $minutes min o menos';
      case 'ca': return 'No hi ha cap entrenament de $minutes min o menys';
      default: return 'No workout fits in $minutes min';
    }
  }

  String get tNoWorkouts {
    switch (_currentLanguage) {
      case 'es': return 'No hay entrenos disponibles';
      case 'ca': return 'No hi ha entrenaments disponibles';
      default: return 'No workouts available';
    }
  }

  String get tTime {
    switch (_currentLanguage) {
      case 'es': return 'Tiempo';
      case 'ca': return 'Temps';
      default: return 'Time';
    }
  }

  String get tGoBack {
    switch (_currentLanguage) {
      case 'es': return 'Volver';
      case 'ca': return 'Tornar';
      default: return 'Go Back';
    }
  }

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
