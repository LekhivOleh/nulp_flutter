part of 'log_cubit.dart';

sealed class LogState {}

final class LogInitial extends LogState {}

final class LogLoaded extends LogState {
  LogLoaded(this.logs);

  final List<AccessLog> logs;
}
