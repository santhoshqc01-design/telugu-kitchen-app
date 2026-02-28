import 'package:telugu_cooking_app/repositories/timer_learning_repository.dart';

/// Lightweight service locator — avoids adding get_it as a dependency.
/// Initialized once in main() before runApp().
///
/// Usage:
///   ServiceLocator.instance.learningRepo.getFactor(...)
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late TimerLearningRepository learningRepo;

  void init({required TimerLearningRepository learningRepo}) {
    this.learningRepo = learningRepo;
  }
}
