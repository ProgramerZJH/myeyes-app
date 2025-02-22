import com.amap.api.location.AMapLocationClient;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.android.FlutterActivity;
import android.os.Bundle;
import android.content.Context;
import com.amap.api.maps.MapsInitializer;
import com.amap.api.services.core.ServiceSettings;
import com.amap.api.maps.AMapOptions;
import com.amap.api.maps.MapView;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.myeyes/amap";
    private MapView mMapView = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        try {
            // 地图隐私合规设置
            MapsInitializer.updatePrivacyShow(this, true, true);
            MapsInitializer.updatePrivacyAgree(this, true);
            
            // 定位隐私合规设置
            AMapLocationClient.updatePrivacyShow(this, true, true);
            AMapLocationClient.updatePrivacyAgree(this, true);
            
            // 初始化地图
            AMapOptions mapOptions = new AMapOptions();
            mMapView = new MapView(this, mapOptions);
            
            // 初始化定位
            AMapLocationClient locationClient = new AMapLocationClient(this);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "updatePrivacyShow":
                        boolean isContains = call.argument("isContains");
                        boolean isShow = call.argument("isShow");
                        MapsInitializer.updatePrivacyShow(this, isContains, isShow);
                        AMapLocationClient.updatePrivacyShow(this, isContains, isShow);
                        result.success(null);
                        break;
                        
                    case "updatePrivacyAgree":
                        boolean isAgree = call.argument("isAgree");
                        MapsInitializer.updatePrivacyAgree(this, isAgree);
                        AMapLocationClient.updatePrivacyAgree(this, isAgree);
                        result.success(null);
                        break;
                        
                    case "initAMapSDK":
                        try {
                            // 初始化其他配置
                            result.success(true);
                        } catch (Exception e) {
                            result.error("INIT_ERROR", e.getMessage(), null);
                        }
                        break;
                        
                    default:
                        result.notImplemented();
                }
            });
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mMapView != null) {
            mMapView.onDestroy();
        }
    }
} 