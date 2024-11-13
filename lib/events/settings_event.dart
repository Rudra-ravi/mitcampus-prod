abstract class SettingsEvent {}

class ShowAboutDialog extends SettingsEvent {
  ShowAboutDialog();
}

class UpdateDisplayName extends SettingsEvent {
  final String newDisplayName;

  UpdateDisplayName({required this.newDisplayName});
}

class CreateNewUser extends SettingsEvent {
  final String email;
  final String password;
  final String displayName;

  CreateNewUser({
    required this.email,
    required this.password,
    required this.displayName,
  });
}
