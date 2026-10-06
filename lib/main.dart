import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bloc/job_bloc.dart';
import 'bloc/job_event.dart';
import 'screens/home_screen.dart';
import 'services/job_persistence_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences for client-side session persistence.
  // Stores saved/applied/dismissed job states in browser localStorage
  // so interactions survive page refresh without requiring auth.
  final prefs = await SharedPreferences.getInstance();
  final persistence = JobPersistenceService(prefs);

  runApp(JobSearchApp(persistence: persistence));
}

class JobSearchApp extends StatelessWidget {
  final JobPersistenceService persistence;

  const JobSearchApp({super.key, required this.persistence});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobBloc(persistence: persistence)
        ..add(LoadPersistedState()),
      child: MaterialApp(
        title: 'JOB SeArCh • AI Semantic Job Matching Engine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
