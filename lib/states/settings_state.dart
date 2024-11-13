abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;

  SettingsError({required this.message});
}

class ShowAboutDialogState extends SettingsState {
  final String developerInfo;
  final String version;

  ShowAboutDialogState({required this.developerInfo, required this.version});
}

class DisplayNameUpdated extends SettingsState {
  final String newDisplayName;

  DisplayNameUpdated({required this.newDisplayName});
}

class UserCreated extends SettingsState {}

class UserUpdated extends SettingsState {}

class UserDeleted extends SettingsState {}
