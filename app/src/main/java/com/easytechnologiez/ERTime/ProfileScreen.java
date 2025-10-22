package com.easytechnologiez.ERTime;

import android.app.Activity;
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
import android.preference.PreferenceManager;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AppCompatActivity;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.TypefaceSpan;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.UserInfo;
import com.easytechnologiez.ERTime.utils.Utils;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
// import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.PendingResult;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.common.api.Status;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResult;
import com.google.android.gms.location.LocationSettingsStatusCodes;

import java.io.IOException;
import java.util.List;
import java.util.Locale;

import static com.easytechnologiez.ERTime.utils.Utils.REQUEST_LOCATION_PERMISSION_FOR_RESULT;

/**
 * An example full-screen activity that shows and hides the system UI (i.e.
 * status bar and navigation/system bar) with user interaction.
 */
public class ProfileScreen extends AppCompatActivity implements View.OnClickListener,GoogleApiClient.OnConnectionFailedListener,GoogleApiClient.ConnectionCallbacks , com.google.android.gms.location.LocationListener{

    private boolean mLocationPermissionGranted;
    private Location mLastKnownLocation;
    private FusedLocationProviderClient mFusedLocationProviderClient;
    Location mLocation;

    // InterstitialAd interstitialAd;
    TextView mName;
    TextView mLocationView;
    TextView mBloodGroup;
    TextView mWeight;
    TextView mHeight;

    TextView mWeight_unit;
    TextView mHeight_unit;

    TextView mEmail;
    ImageView mProfile;
    String Radious_Unit;
     SeekBar radious;
    protected static final String TAG = "LocationOnOff";
    private GoogleApiClient mGoogleApiClient;
    private LocationRequest mLocationRequest;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_profile_screen);

        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .addApi(LocationServices.API)
                .build();

        mFusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(this);
        Typeface tf = Typeface.createFromAsset(getAssets(), "Kaushan.otf");
        Typeface tf1 = Typeface.createFromAsset(getAssets(), "Raleway-Regular.ttf");
        Typeface tf2 = Typeface.createFromAsset(getAssets(), "Raleway-SemiBold.ttf");
        getSupportActionBar().setElevation(0);
        getSupportActionBar().setHomeButtonEnabled(true);
        TypefaceSpan typefaceSpan = new TypefaceSpan("Raleway-Regular.ttf");
        SpannableString str = new SpannableString("Profile");
        str.setSpan(tf,0, str.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
        getSupportActionBar().setTitle(str);
       // MobileAds.initialize(this, getResources().getString(R.string.admob_app_id));
        final AdView adView = (AdView) findViewById(R.id.Ads);
        adView.loadAd(new AdRequest.Builder().build());
        adView.setAdListener(new AdListener(){
            @Override
            public void onAdLoaded() {
                super.onAdLoaded();
                adView.setVisibility(View.VISIBLE);
            }
        });

        // interstitialAd = new InterstitialAd(this); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.setAdUnitId(getString(R.string.admob_interstitial_id)); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.loadAd(new AdRequest.Builder().build()); // TODO: Fix InterstitialAd for new Google Ads API
         mName = (TextView) findViewById(R.id.f_name);

        LinearLayout a1 = (LinearLayout) findViewById(R.id.weight_layout1);
        LinearLayout a2 = (LinearLayout) findViewById(R.id.height_layout1);
        LinearLayout a3 = (LinearLayout) findViewById(R.id.blood_layout1);
         a1.setOnClickListener(this);
        a2.setOnClickListener(this);
        a3.setOnClickListener(this);
        TextView mBloodGroupLabel = (TextView) findViewById(R.id.blood_label);
         mBloodGroup = (TextView) findViewById(R.id.blood);
        TextView mHeightLabel = (TextView) findViewById(R.id.height_label);
        TextView mWeightLabel = (TextView) findViewById(R.id.weight_label);
        TextView card = (TextView) findViewById(R.id.card);
        mWeight = (TextView) findViewById(R.id.weight);
        mHeight = (TextView) findViewById(R.id.height);
        mWeight_unit = (TextView) findViewById(R.id.weight_unit);
        mHeight_unit = (TextView) findViewById(R.id.height_unit);
        mEmail = (TextView) findViewById(R.id.email);
         Radious_Unit = PreferenceManager.getDefaultSharedPreferences(this).getString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY,"km");
       final  TextView mUnits = (TextView) findViewById(R.id.units);
         radious= (SeekBar) findViewById(R.id.radious);
         mProfile = (ImageView) findViewById(R.id.profile);

        //radious.setTypeface(tf1);
        mLocationView = (TextView) findViewById(R.id.location);
        mLocationView.setOnClickListener(this);
        mBloodGroupLabel.setTypeface(tf2);
        mUnits.setTypeface(tf2);
        mHeightLabel.setTypeface(tf2);
        mWeightLabel.setTypeface(tf2);
        card.setTypeface(tf1);
        mBloodGroup.setTypeface(tf1);
        mHeight.setTypeface(tf1);
        mWeight.setTypeface(tf1);
        mWeight_unit.setTypeface(tf1);
        mHeight_unit.setTypeface(tf1);
        mEmail.setTypeface(tf1);
        mName.setTypeface(tf);

        mWeight.setOnClickListener(this);
        mHeight.setOnClickListener(this);
        mBloodGroup.setOnClickListener(this);
       card.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(ProfileScreen.this, CameraActivity.class);
                startActivity(intent);
            }
        });
        mLocationView.setTypeface(tf1);

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


        Button search = (Button) findViewById(R.id.search);
        search.setTypeface(tf2);
        mUnits.setText("10"+Radious_Unit);
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
                    Intent intent = new Intent(ProfileScreen.this, MapsActivity.class);
                    intent.putExtra("latitude",latitude);
                    intent.putExtra("longitude",longitude);
                    intent.putExtra("radious",  rad);
                    startActivity(intent);
                }else
                {
                   ProgressDialogTask task = new ProgressDialogTask(ProfileScreen.this);
                    task.execute();
                }

        // if (interstitialAd != null && interstitialAd.isLoaded()) // TODO: Fix InterstitialAd for new Google Ads API
                {
        // interstitialAd.show(); // TODO: Fix InterstitialAd for new Google Ads API
                }
            }
        });


    }


    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.ok)
        {
            Utils.Holder text = (Utils.Holder) v.getTag();
            EditText editText = text.updatedData;
            String string = editText.getText().toString();
            string = string.replaceAll("\\D+","");
            if (string != null && !string.isEmpty())
            {
                int position  = (Integer) text.positon;
                UpdateTask task = new UpdateTask(this, position,string ,text.dialog ,text.mTextView);
                task.execute();

            }else{
                Toast.makeText(this,"Data is empty",Toast.LENGTH_SHORT).show();
            }

        }else if (v.getId() == R.id.cancel)
        {
            Utils.Holder dialog = (Utils.Holder) v.getTag();
            if (dialog != null && dialog.dialog.isShowing())
            {
                dialog.dialog.dismiss();
            }
        }else if (v.getId() == R.id.height_layout1)
        {

            TextView textView = (TextView) v.findViewById(R.id.height);
            TextView textUnit = (TextView) v.findViewById(R.id.height_unit);
            Utils.showDialogForUpdateData(this,textView.getText().toString()+" "+textUnit.getText().toString(),4,this , textView);
        }else if (v.getId() == R.id.weight_layout1)
        {
            TextView textView = (TextView) v.findViewById(R.id.weight);
            TextView textUnit = (TextView) v.findViewById(R.id.weight_unit);
            Utils.showDialogForUpdateData(this,textView.getText().toString()+" "+textUnit.getText().toString(),5,this , textView);
        }else if (v.getId() == R.id.blood_layout1)
        {
            TextView textView = (TextView) v.findViewById(R.id.blood);
            Utils.showDialogForUpdateBlood(this,6,this,textView);
        }else if (v.getId() == R.id.cancel_blood)
        {
            Utils.Holder dialog = (Utils.Holder) v.getTag();
            if (dialog != null && dialog.dialog.isShowing())
            {
                dialog.dialog.dismiss();
            }
        }else if (v.getId() == R.id.ok_blood)
        {
            Utils.Holder text = (Utils.Holder) v.getTag();
            Spinner editText = text.mSpinner;
            String string = (String) editText.getSelectedItem();
            if (string != null && !string.isEmpty())
            {
                int position  = (Integer) text.positon;
                UpdateTask task = new UpdateTask(this, position,string ,text.dialog ,text.mTextView);
                task.execute();

            }else{
                Toast.makeText(this,"Data is empty",Toast.LENGTH_SHORT).show();
            }
        }else if (v.getId() == R.id.location){
            if (mLocation != null){
                getAddress(mLocation.getLatitude(),mLocation.getLongitude());
            }
        }
    }


    public void DataSetting()
    {
        DatabaseServiceLocal database = DatabaseServiceLocal.getInstance(this);
        UserInfo info = database.retriveUserInfo();
       String unit_H =  PreferenceManager.getDefaultSharedPreferences(this).getString(Utils.SHARED_PREFERENCE_HEIGHT_UNIT_KEY,"in");
       String unit_w = PreferenceManager.getDefaultSharedPreferences(this).getString(Utils.SHARED_PREFERENCE_WEIGHT_UNIT_KEY,"kg");

        mName.setText(info.getmFirstName()+" "+info.getmLastName());
        mName.setAllCaps(true);

        if (info.getmBloodGroup() == null)
        {
            mBloodGroup.setText("not set");
        }else{
            mBloodGroup.setText(info.getmBloodGroup());
        }



        if (info.getmWieght() == null)
        {
            mWeight.setText("not set");
            mWeight_unit.setText(unit_w);
            mWeight_unit.setVisibility(View.GONE);
        }else{

            mWeight.setText(info.getmWieght());
            mWeight_unit.setText(unit_w);
            mWeight_unit.setVisibility(View.VISIBLE);
        }


        if (info.getmHeight() == null)
        {
            mHeight.setText("not set");
            mHeight_unit.setText(unit_H);
            mHeight_unit.setVisibility(View.GONE);
        }else{

            mHeight.setText(info.getmHeight());
            mHeight_unit.setText(unit_H);
            mHeight_unit.setVisibility(View.VISIBLE);
        }

        mEmail.setText(info.getmEmail());

        if (info.getmGender().equalsIgnoreCase("Female"))
        {
            mProfile.setImageResource(R.mipmap.profile_female);
        }else{
            mProfile.setImageResource(R.mipmap.profile);
        }
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.menu_item,menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {

        if (item.getItemId() == R.id.option_logout){
            DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(this);
            boolean logout = local.Logout();
            if (logout){
                Intent intent = new Intent(this , MainActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
                finish();
            }else{
                Toast.makeText(this, "Logout not done properly", Toast.LENGTH_SHORT).show();
            }

        }else if (item.getItemId() == R.id.option_setting)
        {
            Intent intent = new Intent(this , SettingsActivity.class);
            startActivity(intent);
        }

        return super.onOptionsItemSelected(item);
    }

     ///////////////////////////////////

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


    ///////////////////////////////////
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
        DataSetting();
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
        try {
            getAddress(location.getLatitude(), location.getLongitude());
        }catch (Exception e){e.printStackTrace();}
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    class  ProgressDialogTask extends AsyncTask<Void, Void, String>
    {
        ProgressDialog dialog;
        Context context;
        ProgressDialogTask(Context context)
        {
            this.context = context;
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            dialog = new ProgressDialog(context);
            dialog.setCancelable(true);
            dialog.setMessage("Loading..");
            dialog.setCancelable(false);
            dialog.isIndeterminate();
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
                 getAddress(latitude,longitude);
                int rad = radious.getProgress();
                if (rad < 1) {
                    rad = 1;
                }
                Intent intent = new Intent(ProfileScreen.this, MapsActivity.class);
                intent.putExtra("latitude",latitude);
                intent.putExtra("longitude",longitude);
                intent.putExtra("radious",  rad);
                startActivity(intent);
            }


        }
    }
    ///////////////////////////////////
    ///////////////////////////////////

    public void getAddress(double lat, double lng) {

        try {
            Geocoder geocoder = new Geocoder(ProfileScreen.this, Locale.getDefault());
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
            mLocationView.setText(add);
            //  Log.v("IGA", "Address" + add);
            // Toast.makeText(this, "Address=>" + add,
            // Toast.LENGTH_SHORT).show();

            // TennisAppActivity.showDialog(add);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
           // Toast.makeText(this, e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

}
