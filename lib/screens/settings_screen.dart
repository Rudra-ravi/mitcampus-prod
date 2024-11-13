import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../blocs/auth_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../events/settings_event.dart';
import '../repositories/user_repository.dart';
import '../states/settings_state.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final SettingsBloc _settingsBloc = SettingsBloc();

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showProfileDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final TextEditingController controller = TextEditingController(
      text: user?.displayName ?? user?.email?.split('@')[0] ?? ''
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: _settingsBloc,
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Profile',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
                content: state is SettingsLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.email,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                actions: [
                  TextButton(
                    onPressed: state is SettingsLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: state is SettingsLoading
                      ? null
                      : () async {
                          if (controller.text.isNotEmpty) {
                            context.read<SettingsBloc>().add(
                              UpdateDisplayName(newDisplayName: controller.text)
                            );
                          }
                        },
                    child: state is SettingsLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2563EB),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold
                          )
                        ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final displayNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading
      builder: (BuildContext context) {
        return BlocProvider.value(
          value: _settingsBloc,
          child: BlocConsumer<SettingsBloc, SettingsState>(
            listener: (context, state) {
              if (state is UserCreated) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is SettingsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.person_add, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text(
                      'Create New User',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
                content: state is SettingsLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF2563EB)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                if (!value.endsWith('@mvit.edu.in')) {
                                  return 'Email must be from mvit.edu.in domain';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.emailAddress,
                              enabled: state is! SettingsLoading,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF2563EB)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              obscureText: true,
                              enabled: state is! SettingsLoading,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: displayNameController,
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.badge, color: Color(0xFF2563EB)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a display name';
                                }
                                return null;
                              },
                              enabled: state is! SettingsLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                actions: [
                  TextButton(
                    onPressed: state is SettingsLoading 
                      ? null 
                      : () => Navigator.pop(context),
                    child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: state is SettingsLoading
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            context.read<SettingsBloc>().add(
                              CreateNewUser(
                                email: emailController.text.trim(),
                                password: passwordController.text,
                                displayName: displayNameController.text.trim(),
                              ),
                            );
                          }
                        },
                    child: state is SettingsLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create',
                          style: TextStyle(
                            fontWeight: FontWeight.bold
                          )
                        ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      bloc: _settingsBloc,
      listener: (context, state) {
        if (state is SettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        } else if (state is DisplayNameUpdated) {
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ShowAboutDialogState) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('About', 
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.developerInfo,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2937)
                      )
                    ),
                    const SizedBox(height: 8),
                    Text(state.version,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600]
                      )
                    ),
                    const SizedBox(height: 16),
                    const Text('Connect with me:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)
                      )
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Image.asset('assets/img/linkedin.png',
                            width: 32, height: 32),
                          onPressed: () => _launchURL('https://www.linkedin.com/in/ravi-kumar-e'),
                        ),
                        IconButton(
                          icon: Image.asset('assets/img/website.png',
                            width: 32, height: 32),
                          onPressed: () => _launchURL('https://ravikumar-dev.me'),
                        ),
                        IconButton(
                          icon: Image.asset('assets/img/whatsapp.png',
                            width: 32, height: 32),
                          onPressed: () => _launchURL('https://wa.me/qr/WXCYGAAJSITSK1'),
                        ),
                      ],
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                actions: <Widget>[
                  TextButton(
                    child: const Text('Close',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold
                      )
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings',
              style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF2563EB),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.person,
                        color: Color(0xFF2563EB)),
                    ),
                    title: const Text('Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)
                      )
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF2563EB), size: 16),
                    onTap: () {
                      _showProfileDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.info,
                        color: Color(0xFF2563EB)),
                    ),
                    title: const Text('About',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)
                      )
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF2563EB), size: 16),
                    onTap: () {
                      _settingsBloc.add(ShowAboutDialog());
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.logout,
                        color: Color(0xFF2563EB)),
                    ),
                    title: const Text('Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)
                      )
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                      color: Color(0xFF2563EB), size: 16),
                    onTap: () {
                      BlocProvider.of<AuthBloc>(context).add(LogoutEvent());
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: UserRepository().isUserHOD(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.person_add,
                              color: Color(0xFF2563EB)),
                          ),
                          title: const Text('Create User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937)
                            )
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF2563EB), size: 16),
                          onTap: () => _showCreateUserDialog(context),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
