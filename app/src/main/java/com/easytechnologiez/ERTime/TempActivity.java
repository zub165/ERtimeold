package com.easytechnologiez.ERTime;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.graphics.Typeface;
import android.location.Address;
import android.location.Geocoder;
import android.location.Location;
import android.location.LocationManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.preference.PreferenceManager;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AppCompatActivity;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.SeekBar;
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

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.IOException;
import java.util.List;
import java.util.Locale;

import static com.easytechnologiez.ERTime.utils.Utils.REQUEST_LOCATION_PERMISSION_FOR_RESULT;

public class TempActivity extends AppCompatActivity implements GoogleApiClient.OnConnectionFailedListener,GoogleApiClient.ConnectionCallbacks , com.google.android.gms.location.LocationListener{

     //TextView textView;
    protected static final String TAG = "LocationOnOff";
    private GoogleApiClient mGoogleApiClient;
    private Location mLocation;
    private LocationRequest mLocationRequest;
    TextView address;
    SeekBar radious;
    TextView mUnits;
    Handler myHandler;
    String Radious_Unit;
    private boolean isFirst = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_temp);

        myHandler = new Handler();
        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .addApi(LocationServices.API)
                .build();

       mUnits = (TextView) findViewById(R.id.units);
        Radious_Unit = PreferenceManager.getDefaultSharedPreferences(this).getString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY,"km");

        Button  search = (Button) findViewById(R.id.search);
        address = (TextView) findViewById(R.id.address);

        mUnits.setText(10+Radious_Unit);

        mUnits.setTypeface(Typeface.createFromAsset(getAssets(),"Raleway-SemiBold.ttf"));
        address.setTypeface(Typeface.createFromAsset(getAssets(),"Raleway-Regular.ttf"));

        search.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                if (mLocation != null)
                {
                    int rad = radious.getProgress();
                    if (rad < 1) {
                        rad = 1;
                    }
                    double latitude = mLocation.getLatitude();
                    double longitude = mLocation.getLongitude();
                    Intent intent = new Intent(TempActivity.this, MapsActivity.class);
                    intent.putExtra("latitude",latitude);
                    intent.putExtra("longitude",longitude);
                    intent.putExtra("radious",  rad);
                    startActivity(intent);
                }else
                {
                    ProgressDialogTask task = new ProgressDialogTask(TempActivity.this);
                    task.execute();
                }

            }
        });

        mUnits.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                 //  webDataTaskForWebSecrabing task = new webDataTaskForWebSecrabing();
                 //  task.execute();


                }
            });
        radious= (SeekBar) findViewById(R.id.radious);
        Radious_Unit = PreferenceManager.getDefaultSharedPreferences(this).getString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY,"km");

        radious.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {

                if (progress<1)
                {
                    progress = 1;
                }

                mUnits.setText(progress+" "+Radious_Unit);
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });


          /*  Elements answerers = document.select("#ER Wait Time .wait details");
            for (Element answerer : answerers) {
                System.out.println("Fetched DAta: " + answerer.text());
            }*/

          if (!isGPSEnable())
          {
             enableGPSLocation(this);
          }




    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.menu_login , menu);

        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {


        if (item.getItemId() == R.id.option_login)
        {
            Intent intent = new Intent(this, LoginActivity.class);
            startActivity(intent);
        }

        return super.onOptionsItemSelected(item);
    }



    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
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

    public boolean isGPSEnable()
    {
        final LocationManager manager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        if (manager.isProviderEnabled(LocationManager.GPS_PROVIDER) && hasGPSDevice(this)) {
           return true;
        }
        // Todo Location Already on  ... end

        if (!manager.isProviderEnabled(LocationManager.GPS_PROVIDER) && hasGPSDevice(this)) {
           return false;
        }else{
           return true;
        }
    }



    public  void enableGPSLocation( final Context context) {

        if (mGoogleApiClient == null) {
            mGoogleApiClient = new GoogleApiClient.Builder(context)
                    .addApi(LocationServices.API)
                    .addConnectionCallbacks(this)
                    .addOnConnectionFailedListener(this).build();
        }
            mGoogleApiClient.connect();

            LocationRequest locationRequest = LocationRequest.create();
            locationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
            locationRequest.setInterval(10 * 1000);
            locationRequest.setFastestInterval(5 * 1000);
            LocationSettingsRequest.Builder builder = new LocationSettingsRequest.Builder()
                    .addLocationRequest(locationRequest);

            builder.setAlwaysShow(true);

            PendingResult<LocationSettingsResult> result =
                    LocationServices.SettingsApi.checkLocationSettings(mGoogleApiClient, builder.build());
            result.setResultCallback(new ResultCallback<LocationSettingsResult>() {
                @Override
                public void onResult(LocationSettingsResult result) {
                    final Status status = result.getStatus();
                    switch (status.getStatusCode()) {
                        case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
                            try {
                                // Show the dialog by calling startResolutionForResult(),
                                // and check the result in onActivityResult().
                                status.startResolutionForResult((Activity) context, REQUEST_LOCATION_PERMISSION_FOR_RESULT);

                               // Toast.makeText(TempActivity.this,status.getStatusMessage(),Toast.LENGTH_SHORT).show();

                               // ((Activity) context).finish();
                            } catch (IntentSender.SendIntentException e) {
                                // Ignore the error.
                                e.printStackTrace();
                            }
                            break;

                    }
                }
            });

    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        switch (requestCode)
        {
            case REQUEST_LOCATION_PERMISSION_FOR_RESULT:
                switch (resultCode)
                {
                    case Activity.RESULT_OK:
                    {
                        // All required changes were successfully made
                       // Toast.makeText(this, "Location enabled by user!", Toast.LENGTH_LONG).show();
                        if (mGoogleApiClient != null && mGoogleApiClient.isConnected())
                        {
                            mGoogleApiClient.disconnect();
                        }
                        if (mGoogleApiClient != null && !mGoogleApiClient.isConnected())
                        {
                            mGoogleApiClient.connect();
                        }
                        break;
                    }
                    case Activity.RESULT_CANCELED:
                    {
                        // The user was asked to change settings, but chose not to
                        Toast.makeText(this, "Location not enabled, user cancelled.", Toast.LENGTH_LONG).show();
                        break;
                    }
                    default:
                    {
                        break;
                    }
                }
                break;
        }
    }




    public void getAddress(final double lat, final double lng) {
        Runnable addressThread = new Runnable() {
            @Override
            public void run() {
                Geocoder geocoder = new Geocoder(TempActivity.this, Locale.getDefault());
                try {
                    List<Address> addresses = geocoder.getFromLocation(lat, lng, 1);
                    Address obj = addresses.get(0);

                    String add = obj.getAddressLine(0);
                    //
                    //       add = add + "\n" + obj.getCountryCode();
                    add = add + "\n" + obj.getAdminArea();
                    add = add + "\n" + obj.getCountryName();
                    //       add = add + "\n" + obj.getPostalCode();
                    //       add = add + "\n" + obj.getSubAdminArea();
                    //       add = add + "\n" + obj.getLocality();
                    //       add = add + "\n" + obj.getSubThoroughfare();
                    if (address == null) {
                        address = (TextView) findViewById(R.id.address);
                    }

                    address.setText(add);
                    //  Log.v("IGA", "Address" + add);
                    //Toast.makeText(this, "Address=>" + add,
                    //Toast.LENGTH_SHORT).show();

                    // TennisAppActivity.showDialog(add);
                } catch (IOException e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                    Toast.makeText(TempActivity.this, e.getMessage(), Toast.LENGTH_SHORT).show();
                }
            }
        };

        if (myHandler == null)
        {
            myHandler = new Handler();
        }
        myHandler.postDelayed(addressThread,1500L);

    }
    @Override
    public void onConnected(Bundle bundle) {
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

            ActivityCompat.requestPermissions(this,new String[]{android.Manifest.permission.ACCESS_FINE_LOCATION},1);

            //Log.i("Permission", "Permission is not true reqest is intilaized");
        }
        if (!isGPSEnable())
        {
            enableGPSLocation(this);
        }else
        {
            startLocationUpdates();
            mLocation = LocationServices.FusedLocationApi.getLastLocation(mGoogleApiClient);
            // mLocation = LocationServices.getFusedLocationProviderClient(this).getLastLocation().getResult();
            if(mLocation == null){
                startLocationUpdates();
            }
            if (mLocation != null) {
                double latitude = mLocation.getLatitude();
                double longitude = mLocation.getLongitude();
                getAddress(latitude,longitude);
             /*   int rad = radious.getProgress();
                if (rad < 1) {
                    rad = 1;
                }
                Intent intent = new Intent(TempActivity.this, MapsActivity.class);
                intent.putExtra("latitude",latitude);
                intent.putExtra("longitude",longitude);
                intent.putExtra("radious",  rad);
                startActivity(intent);*/
            } else {
                Toast.makeText(this, "Location not Detected", Toast.LENGTH_SHORT).show();
               /* if (mGoogleApiClient != null && mGoogleApiClient.isConnected()) {
                    mGoogleApiClient.disconnect();
                }
                if (mGoogleApiClient != null && !mGoogleApiClient.isConnected())
                {
                    mGoogleApiClient.connect();
                }*/
            }
        }

    }

    protected void startLocationUpdates() {
        // Create the location request
        mLocationRequest = LocationRequest.create()
                .setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)
                .setInterval(20000)
                .setFastestInterval(10000);
        // Request location updates
       try {
           LocationServices.FusedLocationApi.requestLocationUpdates(mGoogleApiClient, mLocationRequest, this);
       }catch (SecurityException e)
       {
           e.printStackTrace();
       }
        Log.d("reque", "--->>>>");
    }

    @Override
    public void onConnectionSuspended(int i) {
        Log.i(TAG, "Connection Suspended");
        Toast.makeText(this, "on Connection Suspended called : ", Toast.LENGTH_SHORT).show();
        mGoogleApiClient.connect();
    }

    @Override
    public void onConnectionFailed(ConnectionResult connectionResult) {
        Log.i(TAG, "Connection failed. Error: " + connectionResult.getErrorCode());
        Toast.makeText(this, "on Connection failed called : ", Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onStart() {
        super.onStart();
        if (mGoogleApiClient != null && !mGoogleApiClient.isConnected())
        {
            mGoogleApiClient.connect();
        }


    }

    @Override
    public void onStop() {
        super.onStop();
        if (mGoogleApiClient.isConnected()) {
            mGoogleApiClient.disconnect();
        }
    }
    @Override
    public void onLocationChanged(Location location) {

        mLocation = location;
        getAddress(location.getLatitude(),location.getLongitude());
    }



    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    class  ProgressDialogTask extends AsyncTask<Void, Void, String>
    {
        AlertDialog dialog;
        Context context;
        ProgressDialogTask(Context context)
        {
            this.context = context;
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            ProgressDialog.Builder builder = new ProgressDialog.Builder(context);
            builder.setTitle("Data Loading...");
            dialog = builder.create();
            dialog.show();
        }

        @Override
        protected String doInBackground(Void... voids) {

            try {
                if (mGoogleApiClient != null && mGoogleApiClient.isConnected()) {
                    mGoogleApiClient.disconnect();
                }
                if (mGoogleApiClient != null && !mGoogleApiClient.isConnected())
                {
                    mGoogleApiClient.connect();
                }

                Thread.sleep(5000L);
            }catch (InterruptedException e){e.printStackTrace();}catch (Exception e){e.printStackTrace();}

            return null;
        }

        @Override
        protected void onPostExecute(String s) {
            super.onPostExecute(s);
            if (dialog != null && dialog.isShowing())
            {
                dialog.dismiss();
            }

            if (mLocation != null) {
                double latitude = mLocation.getLatitude();
                double longitude = mLocation.getLongitude();
               // getAddress(latitude,longitude);
                int rad = radious.getProgress();
                if (rad < 1) {
                    rad = 1;
                }
                Intent intent = new Intent(TempActivity.this, MapsActivity.class);
                intent.putExtra("latitude",latitude);
                intent.putExtra("longitude",longitude);
                intent.putExtra("radious",  rad);
                startActivity(intent);
            }


        }
    }

    class  webDataTaskForWebSecrabing extends AsyncTask<Void, Void, String>
    {
        AlertDialog dialog;
        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            ProgressDialog.Builder builder = new ProgressDialog.Builder(TempActivity.this);
             dialog = builder.create();
             dialog.show();
        }

        @Override
        protected String doInBackground(Void... voids) {

            try {
                String url = "http://www.upstate.edu/healthcare/wait.php";
                Document document = Jsoup.connect(url).get();
                String question = document.select("#title").text();
                System.out.println("Question : " + document.outerHtml());
               // System.out.println("Question : " + document.title());
                //textView.setText(question);
                return document.outerHtml();
            }catch (IOException e){e.printStackTrace();}catch (Exception ee){ee.printStackTrace();}

            return null;
        }

        @Override
        protected void onPostExecute(String s) {
            super.onPostExecute(s);
            if (dialog != null && dialog.isShowing())
            {
                dialog.dismiss();
            }
            if (mUnits != null)
            {
                mUnits.setText(s);
            }
        }
    }
}
