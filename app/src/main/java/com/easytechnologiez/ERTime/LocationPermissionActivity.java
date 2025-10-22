package com.easytechnologiez.ERTime;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.location.LocationManager;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.util.Log;
import android.widget.TextView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.Utils;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.PendingResult;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResult;
import com.google.android.gms.location.LocationSettingsStatusCodes;

import java.util.List;

public class LocationPermissionActivity extends AppCompatActivity implements GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener {

    TextView textView;
    protected static final String TAG = "LocationOnOff";
    private GoogleApiClient googleApiClient;
    final static int REQUEST_LOCATION = 199;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        this.setFinishOnTouchOutside(true);


        // Todo Location Already on  ... start
        final LocationManager manager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        if (manager.isProviderEnabled(LocationManager.GPS_PROVIDER) && hasGPSDevice(LocationPermissionActivity.this)) {
            Toast.makeText(LocationPermissionActivity.this,"Gps already enabled",Toast.LENGTH_SHORT).show();
            finish();
        }
        // Todo Location Already on  ... end

        if(!hasGPSDevice(LocationPermissionActivity.this)){
            Toast.makeText(LocationPermissionActivity.this,"Gps not Supported",Toast.LENGTH_SHORT).show();
        }

        if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER) && hasGPSDevice(LocationPermissionActivity.this)) {
            Log.e("Ahmad","Gps enabled now : ");
            Toast.makeText(LocationPermissionActivity.this,"Gps not enabled",Toast.LENGTH_SHORT).show();
            enableLoc(this);
        }else{
            Log.e("Ahmad","Gps already enabled");
            Toast.makeText(LocationPermissionActivity.this,"Gps already enabled",Toast.LENGTH_SHORT).show();
        }



          /*  Elements answerers = document.select("#ER Wait Time .wait details");
            for (Element answerer : answerers) {
                System.out.println("Fetched DAta: " + answerer.text());
            }*/




    }


    public static boolean hasGPSDevice(Context context) {
        final LocationManager mgr = (LocationManager) context
                .getSystemService(Context.LOCATION_SERVICE);
        if (mgr == null)
            return false;
        final List<String> providers = mgr.getAllProviders();
        if (providers == null)
            return false;
        return providers.contains(LocationManager.GPS_PROVIDER);
    }

    public  void enableLoc( final Context context) {

        if (googleApiClient == null) {
            googleApiClient = new GoogleApiClient.Builder(context)
                    .addApi(LocationServices.API)
                    .addConnectionCallbacks(this)
                    .addOnConnectionFailedListener(this).build();
            googleApiClient.connect();

            LocationRequest locationRequest = LocationRequest.create();
            locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
            locationRequest.setInterval(10 * 1000);
            locationRequest.setFastestInterval(5 * 1000);
            LocationSettingsRequest.Builder builder = new LocationSettingsRequest.Builder()
                    .addLocationRequest(locationRequest);

            builder.setAlwaysShow(true);

            PendingResult<LocationSettingsResult> result =
                    LocationServices.SettingsApi.checkLocationSettings(googleApiClient, builder.build());
            result.setResultCallback(new ResultCallback<LocationSettingsResult>() {
                @Override
                public void onResult(LocationSettingsResult result) {
                    final Status status = result.getStatus();
                    switch (status.getStatusCode()) {
                        case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                            try {
                                // Show the dialog by calling startResolutionForResult(),
                                // and check the result in onActivityResult().
                                status.startResolutionForResult((Activity) context, REQUEST_LOCATION);
                                Intent intent = new Intent();
                                intent.putExtra("location_Permission",true);
                                ((Activity) context).setResult(Utils.RESULT_LOCATION_PERMISSION_CODE,intent);
                                ((Activity) context).finish();
                            } catch (IntentSender.SendIntentException e) {
                                // Ignore the error.
                                e.printStackTrace();
                            }
                            break;
                    }
                }
            });
        }
    }



        @Override
        public void onConnectionFailed(ConnectionResult connectionResult) {

            Log.d("Location error","Location error " + connectionResult.getErrorCode());
        }



        @Override
        public void onConnected(Bundle bundle) {

        }

        @Override
        public void onConnectionSuspended(int i) {
            googleApiClient.connect();
        }



}
