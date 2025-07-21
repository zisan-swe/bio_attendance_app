import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.yourcompany.fingerprint";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("scanFingerprint")) {
                                String template = scanFingerprint(); // integrate SecuGen SDK here
                                result.success(template);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private String scanFingerprint() {
        // Placeholder for SecuGen SDK logic
        return "mock_fingerprint_template_base64";
    }
}
