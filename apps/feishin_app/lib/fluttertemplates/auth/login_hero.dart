// Adapted from Flutter Templates Login Screen (MIT). See ../LICENSE.
import 'package:core/core/theme/app_spacing.dart';
import 'package:core/core/ui/atoms/button.dart';
import 'package:flutter/material.dart';

import '../../constants/value_const.dart';
import '../../feature/home/domain/remote.dart';

class ConnectionForm extends StatefulWidget {
  const ConnectionForm({
    super.key,
    this.profile,
    this.initialPassword = '',
    required this.onSave,
    required this.onTest,
  });

  final RemoteProfile? profile;
  final String initialPassword;
  final Future<String?> Function(Uri endpoint, String username, String password)
  onTest;
  final void Function(
    String name,
    Uri endpoint,
    String username,
    String password,
    bool remember,
  )
  onSave;

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile?.name);
  late final _address = TextEditingController(
    text: widget.profile?.endpoint.toString(),
  );
  late final _username = TextEditingController(text: widget.profile?.username);
  late final _password = TextEditingController(text: widget.initialPassword);
  late bool _encrypted = widget.profile?.endpoint.scheme == 'wss';
  late bool _remember = widget.profile?.rememberPassword ?? true;
  bool _hidePassword = true;
  bool _testing = false;
  ({String message, bool ok})? _result;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final endpoint = remoteEndpoint(_address.text, encrypted: _encrypted);
    if (endpoint != null) {
      widget.onSave(
        _name.text.trim(),
        endpoint,
        _username.text.trim(),
        _password.text,
        _remember,
      );
    }
  }

  Future<void> _test() async {
    if (!_form.currentState!.validate()) return;
    final endpoint = remoteEndpoint(_address.text, encrypted: _encrypted);
    if (endpoint == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _testing = true;
      _result = null;
    });
    final error = await widget.onTest(
      endpoint,
      _username.text.trim(),
      _password.text,
    );
    if (mounted) {
      setState(() {
        _testing = false;
        _result = (
          message: error ?? 'Feishin responded. You can save this profile.',
          ok: error == null,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: ValueConst.profileName),
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value?.trim().isEmpty ?? true ? 'Enter a name.' : null,
        ),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.wifi_rounded),
              label: Text(ValueConst.lan),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.lock_outline_rounded),
              label: Text(ValueConst.encrypted),
            ),
          ],
          selected: {_encrypted},
          onSelectionChanged: (selection) => setState(() {
            _encrypted = selection.single;
            final text = _address.text;
            if (text.startsWith('ws://') || text.startsWith('wss://')) {
              _address.text = text.replaceFirst(RegExp(r'^wss?://'), '');
            }
          }),
        ),
        TextFormField(
          controller: _address,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: ValueConst.address,
            hintText: _encrypted ? ValueConst.secureHint : ValueConst.localHint,
          ),
          validator: (value) =>
              remoteEndpoint(value ?? '', encrypted: _encrypted) == null
              ? 'Enter a valid address for the selected transport.'
              : null,
        ),
        if (!_encrypted)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: AppSpacing.lg,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Text(
                  ValueConst.lanNotice,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        TextFormField(
          controller: _username,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: ValueConst.username),
          validator: (value) => value?.contains(':') ?? false
              ? 'Colons are unavailable in Feishin credentials.'
              : null,
        ),
        TextFormField(
          controller: _password,
          obscureText: _hidePassword,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: ValueConst.password,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              tooltip: _hidePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                _hidePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          validator: (value) => value?.contains(':') ?? false
              ? 'Colons are unavailable in Feishin credentials.'
              : null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(ValueConst.rememberPassword),
          value: _remember,
          onChanged: (value) => setState(() => _remember = value),
        ),
        if (_result case (:final message, :final ok))
          Semantics(
            liveRegion: true,
            child: Row(
              spacing: AppSpacing.xs,
              children: [
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  size: AppSpacing.xl2,
                  color: ok
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        AppButton(
          label: 'Test connection',
          variant: AppButtonVariant.secondary,
          state: _testing ? AppButtonState.loading : AppButtonState.idle,
          onTap: _test,
        ),
        AppButton(
          label: ValueConst.saveConnect,
          state: _testing ? AppButtonState.disabled : AppButtonState.idle,
          onTap: _save,
        ),
      ],
    ),
  );
}
