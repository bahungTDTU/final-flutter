import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../state/app_controller.dart';
import 'home.dart';
import 'design_system.dart';

class NoteTogetherApp extends StatefulWidget {
  const NoteTogetherApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<NoteTogetherApp> createState() => _NoteTogetherAppState();
}

class _NoteTogetherAppState extends State<NoteTogetherApp>
    with WidgetsBindingObserver {
  AppController get controller => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      return MaterialApp(
        title: 'NoteTogether',
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        themeAnimationDuration:
            WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 300),
        themeAnimationCurve: Curves.easeInOutCubic,
        debugShowCheckedModeBanner: false,
        theme: noteTheme(Brightness.light),
        darkTheme: noteTheme(Brightness.dark),
        themeMode: controller.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => PrismBackdrop(
          child: Theme(
            data: Theme.of(context).copyWith(
              scaffoldBackgroundColor: Colors.transparent,
              splashFactory: MediaQuery.disableAnimationsOf(context)
                  ? NoSplash.splashFactory
                  : InkRipple.splashFactory,
            ),
            child: child ?? const SizedBox(),
          ),
        ),
        home: !controller.ready
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : controller.user == null
            ? AuthScreen(controller: controller)
            : HomeScreen(controller: controller),
      );
    },
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      confirm = TextEditingController();
  bool register = false, showPassword = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (widget.controller.busy || !form.currentState!.validate()) return;
    await widget.controller.authenticate(
      register: register,
      email: email.text.trim(),
      password: password.text,
      name: name.text.trim(),
      confirmation: confirm.text,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        if (MediaQuery.sizeOf(context).width >= 1000 &&
            MediaQuery.sizeOf(context).height >= 700 &&
            MediaQuery.textScalerOf(context).scale(1) < 1.5)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: PrismReveal(
                child: SurfacePanel(
                  tinted: true,
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MetadataPill(
                        'GHI LẠI · SẮP XẾP · CHIA SẺ',
                        icon: Icons.edit_note_outlined,
                      ),
                      const SizedBox(height: 36),
                      Text(
                        "Một nơi cho những\ný tưởng đáng giữ.",
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontSize: 40,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Từ ghi chú buổi học đến kế hoạch của nhóm.\nGiữ mọi điều quan trọng trong một không gian.',
                      ),
                      const SizedBox(height: 40),
                      const PrismArtwork(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SurfacePanel(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
                  ),
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Brand(),
                        const SizedBox(height: 36),
                        Text(
                          register
                              ? 'Bắt đầu không gian của bạn'
                              : 'Chào mừng trở lại',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ghi lại hôm nay. Dễ dàng tìm lại ngày mai.',
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const Key('auth-email'),
                          controller: email,
                          enabled: !widget.controller.busy,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (v) =>
                              v == null ||
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(v.trim())
                              ? 'Nhập email hợp lệ'
                              : null,
                        ),
                        if (register) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('auth-name'),
                            controller: name,
                            enabled: !widget.controller.busy,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                            ),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Nhập tên hiển thị' : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('auth-password'),
                          controller: password,
                          enabled: !widget.controller.busy,
                          obscureText: !showPassword,
                          textInputAction: register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: [
                            register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: showPassword
                                  ? 'Ẩn mật khẩu'
                                  : 'Hiện mật khẩu',
                              onPressed: () =>
                                  setState(() => showPassword = !showPassword),
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (_) =>
                              register ? null : unawaited(submit()),
                          validator: (v) => v == null || v.length < 10
                              ? 'Ít nhất 10 ký tự'
                              : null,
                        ),
                        if (register) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('auth-confirmation'),
                            controller: confirm,
                            enabled: !widget.controller.busy,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            obscureText: !showPassword,
                            decoration: const InputDecoration(
                              labelText: 'Nhập lại mật khẩu',
                            ),
                            validator: (v) => v != password.text
                                ? 'Mật khẩu chưa khớp'
                                : null,
                            onFieldSubmitted: (_) => unawaited(submit()),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (widget.controller.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: StatusNotice(
                              message: friendlyError(widget.controller.error!),
                              error: true,
                              icon: Icons.error_outline,
                            ),
                          ),
                        if (widget.controller.sessionRemovalFailed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: OutlinedButton.icon(
                              onPressed: () async => widget.controller.logout(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử xóa phiên trên thiết bị'),
                            ),
                          ),
                        PrismAction(
                          key: const Key('auth-submit'),
                          onPressed: widget.controller.busy ? null : submit,
                          child: Text(
                            widget.controller.busy
                                ? 'Đang xử lý…'
                                : register
                                ? 'Đăng ký'
                                : 'Đăng nhập',
                          ),
                        ),
                        TextButton(
                          onPressed: widget.controller.busy
                              ? null
                              : () => setState(() {
                                  register = !register;
                                  form.currentState?.reset();
                                }),
                          child: Text(
                            register
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: widget.controller.busy
                                  ? null
                                  : () => _forgot(context),
                              child: const Text('Quên mật khẩu'),
                            ),
                            TextButton(
                              onPressed: widget.controller.busy
                                  ? null
                                  : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => TokenScreen(
                                          controller: widget.controller,
                                        ),
                                      ),
                                    ),
                              child: const Text('Kích hoạt / đặt lại'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _forgot(BuildContext context) async {
    final value = await askText(
      context,
      'Email khôi phục',
      initial: email.text,
    );
    if (value == null) return;
    try {
      final result = await widget.controller.api.call(
        'POST',
        '/auth/forgot',
        body: {'email': value},
      );
      if (context.mounted) {
        if (result['email_delivery'] == 'not_configured') {
          showMessage(context, emailDeliveryMessage('not_configured'));
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TokenScreen(
                controller: widget.controller,
                initialReset: true,
                initialEmail: value,
              ),
            ),
          );
          showMessage(
            context,
            'Nếu email có tài khoản, mã khôi phục sẽ được gửi. Kiểm tra hộp thư và spam.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) showMessage(context, friendlyError(e));
    }
  }
}

class TokenScreen extends StatefulWidget {
  const TokenScreen({
    super.key,
    required this.controller,
    this.initialReset = false,
    this.initialEmail = '',
  });
  final AppController controller;
  final bool initialReset;
  final String initialEmail;
  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final form = GlobalKey<FormState>();
  final token = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController(),
      resetEmail = TextEditingController();
  late bool reset;
  bool busy = false, checked = false, complete = false;
  String? message;
  @override
  void initState() {
    super.initState();
    reset = widget.initialReset;
    resetEmail.text = widget.initialEmail;
  }

  @override
  void dispose() {
    token.dispose();
    password.dispose();
    confirm.dispose();
    resetEmail.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || complete || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (reset && !checked) {
        await widget.controller.api.call(
          'POST',
          '/auth/reset/check',
          body: {'token': token.text.trim()},
        );
        if (mounted) {
          setState(() {
            checked = true;
            message = 'Mã hợp lệ. Nhập mật khẩu mới.';
          });
        }
        return;
      }
      await widget.controller.api.call(
        'POST',
        reset ? '/auth/reset' : '/auth/verify',
        body: {
          'token': token.text.trim(),
          if (reset) 'password': password.text,
          if (reset) 'confirmation': confirm.text,
        },
      );
      if (reset) {
        await widget.controller.logout();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          showMessage(
            context,
            'Đã đặt lại mật khẩu. Đăng nhập bằng mật khẩu mới.',
          );
        }
      } else {
        await widget.controller.synchronize();
        if (mounted) {
          setState(() {
            complete = true;
            token.clear();
            message = 'Mã xác minh đã được chấp nhận.';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => message = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (busy || (!reset && widget.controller.token == null)) return;
    if (reset &&
        (resetEmail.text.trim().isEmpty || resetEmail.text.length > 254)) {
      setState(() => message = 'Nhập email nhận mã khôi phục.');
      return;
    }
    setState(() => busy = true);
    final sessionToken = widget.controller.token;
    try {
      final result = await widget.controller.api.call(
        'POST',
        reset ? '/auth/forgot' : '/auth/resend',
        token: reset ? null : sessionToken,
        body: reset ? {'email': resetEmail.text.trim()} : null,
      );
      if (!reset && widget.controller.token != sessionToken) return;
      if (!reset) {
        widget.controller.recordEmailDelivery(
          result['email_delivery'] as String,
        );
      }
      if (mounted) {
        setState(
          () => message = emailDeliveryMessage(
            result['email_delivery'] as String,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => message = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkDelivery() async {
    final sessionToken = widget.controller.token;
    if (busy || reset || sessionToken == null) return;
    setState(() => busy = true);
    try {
      final result = await widget.controller.api.call(
        'GET',
        '/auth/email-status',
        token: sessionToken,
      );
      if (!mounted || widget.controller.token != sessionToken) return;
      final status = result['email_delivery'] as String;
      widget.controller.recordEmailDelivery(status);
      setState(() => message = emailDeliveryMessage(status));
    } catch (e) {
      if (mounted && widget.controller.token == sessionToken) {
        setState(() => message = friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kích hoạt / đặt lại mật khẩu')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 520,
          child: SurfacePanel(
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeading(
                    reset ? 'Khôi phục tài khoản' : 'Xác minh email',
                    detail: reset
                        ? checked
                              ? 'Bước 2 · Chọn mật khẩu mới'
                              : 'Bước 1 · Kiểm tra mã trong email'
                        : 'Nhập mã nhận được để hoàn tất xác minh.',
                    icon: reset
                        ? Icons.password_outlined
                        : Icons.mark_email_read_outlined,
                  ),
                  SwitchListTile(
                    title: const Text('Đặt lại mật khẩu'),
                    value: reset,
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            reset = v;
                            checked = false;
                            complete = false;
                            message = null;
                            token.clear();
                            password.clear();
                            confirm.clear();
                          }),
                  ),
                  TextFormField(
                    key: const Key('email-code'),
                    controller: token,
                    enabled: !busy && !complete,
                    readOnly: checked,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty || (v ?? '').length > 128
                        ? 'Nhập mã trong email (tối đa 128 ký tự).'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Mã xác minh trong email',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (reset && checked) ...[
                    TextFormField(
                      key: const Key('email-reset-password'),
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      validator: (v) =>
                          (v ?? '').length < 10 || (v ?? '').length > 128
                          ? 'Dùng 10–128 ký tự'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('email-reset-confirmation'),
                      controller: confirm,
                      enabled: !busy,
                      obscureText: true,
                      validator: (v) =>
                          v != password.text ? 'Hai mật khẩu chưa khớp' : null,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('email-code-submit'),
                    onPressed: busy || complete ? null : submit,
                    child: Text(
                      busy
                          ? 'Đang xử lý…'
                          : reset && !checked
                          ? 'Kiểm tra mã'
                          : 'Xác nhận',
                    ),
                  ),
                  if (reset && checked)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              checked = false;
                              message = null;
                              password.clear();
                              confirm.clear();
                            }),
                      child: const Text('Nhập mã khác'),
                    ),
                  if (reset && !checked) ...[
                    TextField(
                      key: const Key('reset-email'),
                      controller: resetEmail,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email nhận mã khôi phục',
                      ),
                    ),
                    TextButton(
                      key: const Key('resend-reset-code'),
                      onPressed: busy ? null : resend,
                      child: const Text('Yêu cầu gửi lại mã'),
                    ),
                  ],
                  if (!reset &&
                      !complete &&
                      widget.controller.user != null) ...[
                    TextButton(
                      key: const Key('resend-email-code'),
                      onPressed: busy ? null : resend,
                      child: const Text('Gửi lại mã xác minh'),
                    ),
                    TextButton(
                      key: const Key('email-delivery-status'),
                      onPressed: busy ? null : checkDelivery,
                      child: const Text('Kiểm tra trạng thái gửi'),
                    ),
                  ],
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: StatusNotice(
                        message: message!,
                        icon: complete
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nhập mã dùng một lần trong email NoteTogether. Mã hết hạn sau 30 phút; gửi lại sẽ thay mã cũ. Bạn vẫn dùng được ghi chú khi chưa xác minh.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String emailDeliveryMessage(String status) => switch (status) {
  'queued' => 'Mã đang chờ gửi. Server sẽ tự thử lại nếu dịch vụ email gặp lỗi; bạn vẫn dùng được ghi chú.',
  'retrying' => 'Gửi email chưa thành công. Server đang tự thử lại; không cần tạo mã mới ngay.',
  'expired' ||
  'cancelled' => 'Mã đã hết hạn hoặc được thay thế. Yêu cầu gửi mã mới.',
  'not_requested' =>
    'Chưa có yêu cầu gửi mã. Chọn gửi lại để nhận mã xác minh.',
  'failed' =>
    'Server đã dừng thử gửi mã này. Yêu cầu mã mới; ghi chú vẫn dùng được.',
  'smtp_accepted' => 'Dịch vụ gửi thư đã nhận email. Kiểm tra hộp thư và spam; mã hết hạn sau 30 phút.',
  'requested' => 'Nếu email có tài khoản, yêu cầu gửi mã đã được ghi nhận. Kiểm tra hộp thư và spam.',
  'already_verified' =>
    'Tài khoản đã xác minh. Quay lại và cập nhật danh sách ghi chú.',
  'not_configured' =>
    'Dịch vụ email chưa sẵn sàng. Bạn vẫn dùng được ghi chú; hãy thử lại sau.',
  'test_only' => 'Đang dùng dịch vụ kiểm thử; chưa gửi đến hộp thư ngoài.',
  _ => 'Chưa gửi được email. Đợi một phút rồi thử gửi lại. Tài khoản vẫn dùng được ghi chú.',
};

Future<String?> askText(
  BuildContext context,
  String title, {
  String initial = '',
  String? Function(String)? validator,
}) async {
  final input = TextEditingController(text: initial);
  final form = GlobalKey<FormState>();
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: DialogHeading(title, icon: Icons.edit_outlined),
      content: Form(
        key: form,
        child: TextFormField(
          decoration: InputDecoration(labelText: title),
          controller: input,
          validator: (value) => validator?.call(value ?? ''),
          autofocus: true,
          onFieldSubmitted: (v) {
            if (form.currentState!.validate()) Navigator.pop(context, v);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context, input.text);
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  );
  // Dialog route removal animation can still reference its controller.
  Future<void>.delayed(const Duration(milliseconds: 350), input.dispose);
  return value;
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

String friendlyError(Object error) {
  final text = '$error';
  if (text.contains('phiên đăng nhập trên thiết bị')) return text;
  if (text.contains('Thiếu khóa') ||
      text.contains('kho phục hồi mã hóa') ||
      text.contains('khóa phiên đăng nhập') ||
      text.contains('Kho phiên đăng nhập') ||
      text.contains('Phiên đăng nhập đã lưu')) {
    return 'Không thể mở hoặc lưu phiên trên thiết bị. Phiên đã lưu và dữ liệu ghi chú vẫn được giữ. Kiểm tra bộ nhớ thiết bị rồi thử lại.';
  }
  if (text.contains('Invalid email or password')) {
    return 'Email hoặc mật khẩu chưa đúng.';
  }
  if (text.contains('Account already exists')) {
    return 'Email này đã có tài khoản. Hãy đăng nhập.';
  }
  if (text.contains('Current password incorrect')) {
    return 'Mật khẩu hiện tại chưa đúng.';
  }
  if (text.contains('Passwords do not match')) return 'Hai mật khẩu chưa khớp.';
  if (text.contains('expired or reused token')) {
    return 'Mã chưa hợp lệ, đã hết hạn hoặc đã được sử dụng.';
  }
  if (text.contains('Try again later')) {
    return 'Bạn đã thử nhiều lần. Vui lòng đợi rồi thử lại.';
  }
  if (text.contains('Session expired')) {
    return 'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.';
  }
  return 'Chưa thể hoàn tất yêu cầu. Kiểm tra thông tin và kết nối rồi thử lại.';
}
