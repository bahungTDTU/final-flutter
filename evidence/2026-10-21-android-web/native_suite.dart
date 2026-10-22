import '../../integration_test/note_flow_test.dart' as notes;
import '../../integration_test/sharing_test.dart' as sharing;
import '../../integration_test/realtime_test.dart' as realtime;
import '../../integration_test/protected_editing_test.dart' as protection;
import '../../integration_test/owner_delete_recovery_test.dart' as recovery;

void main() {
  notes.main();
  sharing.main();
  realtime.main();
  protection.main();
  recovery.main();
}
