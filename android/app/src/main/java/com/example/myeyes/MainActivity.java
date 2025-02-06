import com.amap.api.location.AMapLocationClient;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.android.FlutterActivity;
import android.os.Bundle;
import android.content.Context;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.myeyes/amap";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 高德SDK合规设置
        AMapLocationClient.updatePrivacyShow(getApplicationContext(), true, true);
        AMapLocationClient.updatePrivacyAgree(getApplicationContext(), true);
        
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("updatePrivacyShow")) {
                    boolean isContains = call.argument("isContains");
                    boolean isShow = call.argument("isShow");
                    AMapLocationClient.updatePrivacyShow(this, isContains, isShow);
                    result.success(null);
                } else if (call.method.equals("updatePrivacyAgree")) {
                    boolean isAgree = call.argument("isAgree");
                    AMapLocationClient.updatePrivacyAgree(this, isAgree);
                    result.success(null);
                }
            });
    }
} 