import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:note_together/data/api.dart';
import 'package:note_together/data/encrypted_account_store.dart';
import 'package:note_together/data/local_store.dart';
import 'package:note_together/state/app_controller.dart';
import 'package:note_together/ui/app.dart';
import 'package:note_together/ui/home.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('Profile continuous scroll with 500 server notes', (
    tester,
  ) async {
    // Debug timing is not an end-user performance measurement.
    expect(kProfileMode, isTrue, reason: 'Run flutter drive --profile');
    const email = String.fromEnvironment('PERFORMANCE_EMAIL');
    expect(email, isNotEmpty, reason: 'Run scripts/seed_performance.py first');
    final folder = await getApplicationSupportDirectory();
    final db = await databaseFactoryIo.openDatabase(
      path.join(
        folder.path,
        'frames-${DateTime.now().microsecondsSinceEpoch}.db',
      ),
    );
    final c = AppController(
      Api(const String.fromEnvironment('API_URL')),
      EncryptedAccountStore(SembastLocalStore(db), const DeviceRecoveryKeys()),
    );
    try {
      await c.initialize();
      expect(
        await c.authenticate(
          register: false,
          email: email,
          password: 'Performance-fixture-2026!',
        ),
        isTrue,
      );
      for (var i = 0; i < 120 && (c.syncing || c.notes.length != 500); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(c.notes, hasLength(500));
      expect(c.labels, hasLength(30));
      // Isolate rendering from retry/polling traffic; native functional tests
      // separately exercise the live API, persistence and autosave.
      c.setForeground(false);
      await tester.pumpWidget(NoteTogetherApp(controller: c));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byType(HomeScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      ScrollPosition position() =>
          tester.state<ScrollableState>(scrollable).position;
      Future<void> motion() async {
        await tester.runAsync(() async {
          await position().animateTo(
            3600,
            duration: const Duration(seconds: 4),
            curve: Curves.linear,
          );
          await position().animateTo(
            0,
            duration: const Duration(seconds: 4),
            curve: Curves.linear,
          );
        });
      }

      binding.reportData = {
        'mode': 'profile',
        'fixture': {'notes': 500, 'labels': 30},
        'workload': '3600 logical pixels down/up, 4 seconds each, linear',
        'network_during_scroll': 'foreground polling disabled',
        'fps_scope':
            'Flutter rendered frame cadence, not physical presentation',
        'sdk_summary_budget_ms': 16,
        'custom_budget_ms': 1000 / 60,
      };
      for (final grid in [true, false]) {
        // Fixture setting, no saved preference or server account update.
        c.preferences['grid'] = grid;
        c.notifyListeners();
        await tester.pumpAndSettle();
        await motion(); // Unreported warmup per layout.
        for (var run = 1; run <= 3; run++) {
          final name = '${grid ? 'grid' : 'list'}_$run';
          final timings = <FrameTiming>[];
          final TimingsCallback callback = timings.addAll;
          try {
            await binding.watchPerformance(() async {
              // watchPerformance first flushes old frame batches for 2 seconds.
              binding.addTimingsCallback(callback);
              await motion();
            }, reportKey: '${name}_sdk');
          } finally {
            binding.removeTimingsCallback(callback);
          }
          expect(timings.length, greaterThan(30));
          final builds =
              timings.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
                ..sort();
          final rasters =
              timings
                  .map((f) => f.rasterDuration.inMicroseconds / 1000)
                  .toList()
                ..sort();
          final vsync =
              timings
                  .map((f) => f.timestampInMicroseconds(FramePhase.vsyncStart))
                  .toList()
                ..sort();
          final intervals = [
            for (var i = 1; i < vsync.length; i++)
              (vsync[i] - vsync[i - 1]) / 1000,
          ]..sort();
          double percentile(List<double> values, double fraction) =>
              values[((values.length - 1) * fraction).ceil()];
          binding.reportData![name] = {
            'frame_count': timings.length,
            'active_span_ms': (vsync.last - vsync.first) / 1000,
            'rendered_fps':
                (vsync.length - 1) * 1000000 / (vsync.last - vsync.first),
            'build_p50_ms': percentile(builds, .50),
            'build_p95_ms': percentile(builds, .95),
            'raster_p50_ms': percentile(rasters, .50),
            'raster_p95_ms': percentile(rasters, .95),
            'build_over_16_667': builds.where((ms) => ms > 1000 / 60).length,
            'raster_over_16_667': rasters.where((ms) => ms > 1000 / 60).length,
            'interval_p95_ms': percentile(intervals, .95),
            'interval_over_25_ms': intervals.where((ms) => ms > 25).length,
          };
        }
      }
      expect(tester.takeException(), isNull);
      // Conversion changes the render surface: take screenshots AFTER measuring.
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('android-profile-home');
      await c.logout();
      await tester.pumpWidget(const SizedBox());
    } finally {
      c.dispose();
      final filename = db.path;
      await db.close();
      await databaseFactoryIo.deleteDatabase(filename);
    }
  });
}
