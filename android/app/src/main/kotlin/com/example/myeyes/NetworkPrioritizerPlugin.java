package com.example.myeyes;
import android.net.ConnectivityManager;

public class NetworkPrioritizerPlugin {
    private ConnectivityManager connectivityManager;

    public NetworkPrioritizerPlugin(ConnectivityManager connectivityManager) {
        this.connectivityManager = connectivityManager;
    }

    public void prioritizeNetworkConnection() {
        // Set the network preference to prefer mobile data
        connectivityManager.setNetworkPreference(ConnectivityManager.TYPE_MOBILE);
    }
}
