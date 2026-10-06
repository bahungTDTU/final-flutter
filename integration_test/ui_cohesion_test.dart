// Reuse the real workflows; this suite is not three additional feature tests.
import 'ui_upgrade_test.dart' as core;
import 'writing_studio_test.dart' as studio;
import 'protected_editing_test.dart' as protection;

void main() {
  core.main();
  studio.main();
  protection.main();
}
