package com.easytechnologiez.ERTime;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.preference.PreferenceManager;
import androidx.appcompat.app.AppCompatActivity;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ListView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.Utils;

import java.util.ArrayList;

import location.data.PlaceData;
import location.data.PlaceInfo;

public class MapsActivity extends AppCompatActivity implements GetPlaceListener,UserWaitListener {

    ExpandableAdapter listAdapter;
    ListView expListView;
    ArrayList<PlaceInfo> listDataHeader;
    Handler mHandler;
  //  Location mCurrentLocation;
   // private boolean mLocationPermissionGranted;
   // private Location mLastKnownLocation;
    //private FusedLocationProviderClient mFusedLocationProviderClient;


   //  List<PlaceInfo> listDataChild;
   int radious ;
   double currentLatitude;
    double currentLongitude;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.list_layout);
      //  mFusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(this);
        // Construct a GeoDataClient.


        mHandler = new Handler();
        // get the listview
        expListView = (ListView) findViewById(R.id.listview);




        expListView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                String placeId = listDataHeader.get(position).getmPlaceId();
                if (placeId != null) {
                    Intent intent = new Intent(MapsActivity.this, PlaceDetailsActivity.class);
                    intent.putExtra("place_id", placeId);
                    startActivity(intent);
                }
            }
        });

        // preparing list data
      //  prepareListData();
        try {
            Intent intent = getIntent();
            Bundle bundle = intent.getExtras();
            if (bundle != null) {
                radious = bundle.getInt("radious");
            }
            if (getSupportActionBar() != null) {
                getSupportActionBar().setElevation(0);
            }
        }catch (NullPointerException e){e.printStackTrace();}
        if ( radious <1)
        {
            radious = 1;
        }



       String Radious_Unit = PreferenceManager.getDefaultSharedPreferences(this).getString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY,"km");

       if (Radious_Unit.equalsIgnoreCase("mile")) {

           radious = radious * 1609;
       }else{
           radious = radious*1000;
       }

        currentLatitude = getIntent().getDoubleExtra("latitude",0);
         currentLongitude = getIntent().getDoubleExtra("longitude",0);

        FindPlacesTask placestask = new FindPlacesTask(MapsActivity.this,radious,MapsActivity.this , currentLatitude , currentLongitude);
        placestask.execute();

    }


    @Override
    protected void onStart() {
        super.onStart();
      //  getDeviceLocationAndFindPlaces();
    }

    /*
     * Preparing the list data
     */

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        getMenuInflater().inflate(R.menu.sort,menu);

       // menu.findItem(R.id.sortByDistance).setVisible(false);
        return super.onCreateOptionsMenu(menu);
    }


    @Override
    public boolean onOptionsItemSelected(MenuItem item) {


        if (item.getItemId() == R.id.sortByName)
        {
            listDataHeader = Utils.sortByPlaceName(listDataHeader);
            listAdapter = new ExpandableAdapter(MapsActivity.this,listDataHeader);
            // setting list adapter
            expListView.setAdapter(listAdapter);
            listAdapter.notifyDataSetChanged();
            expListView.requestLayout();

        }else if (item.getItemId() == R.id.sortByDistance)
        {
            PlaceInfo item2 = listDataHeader.get(listDataHeader.size()-1);
            if (item2 != null && !item2.getmPlaceDistance().equalsIgnoreCase("Loading...")) {

                listDataHeader = Utils.sortByPlaceDistance(listDataHeader);
                listAdapter = new ExpandableAdapter(MapsActivity.this, listDataHeader);
                // setting list adapter
                expListView.setAdapter(listAdapter);
                listAdapter.notifyDataSetChanged();
                expListView.requestLayout();
            }else {
                Toast.makeText(this,getString(R.string.wait_message), Toast.LENGTH_SHORT).show();
            }

        }else if (item.getItemId() == R.id.sortByDuration)
        {
            PlaceInfo item2 = listDataHeader.get(listDataHeader.size()-1);
            if (item2 !=null &&!item2.getmTravelDuration().equalsIgnoreCase("Loading...")) {
                listDataHeader = Utils.sortDuration(listDataHeader);
                listAdapter = new ExpandableAdapter(MapsActivity.this, listDataHeader);
                // setting list adapter
                expListView.setAdapter(listAdapter);
                listAdapter.notifyDataSetChanged();
                expListView.requestLayout();
            }else {
                Toast.makeText(this,getString(R.string.wait_message), Toast.LENGTH_SHORT).show();
            }

        }
        return super.onOptionsItemSelected(item);
    }




   /* private void getLocationPermission()
    {
        *//*
         * Request location permission, so that we can get the location of the
         * device. The result of the permission request is handled by a callback,
         * onRequestPermissionsResult.
         *//*
        if (ContextCompat.checkSelfPermission(this.getApplicationContext(),
                android.Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED) {
            mLocationPermissionGranted = true;
            statusCheck();
            Log.i("Permission" ,"Permission is true now");
        } else {
            ActivityCompat.requestPermissions(this,
                    new String[]{android.Manifest.permission.ACCESS_FINE_LOCATION},
                    1);

            Log.i("Permission", "Permission is not true reqest is intilaized");
        }
    }
    private void getDeviceLocationAndFindPlaces()
    {
        *//*
         * Get the best and most recent location of the device, which may be null in rare
         * cases when a location is not available.
         *//*

        getLocationPermission();
        try {
            if (mLocationPermissionGranted) {
                Task<Location> locationResult = mFusedLocationProviderClient.getLastLocation();
                locationResult.addOnCompleteListener(this, new OnCompleteListener<Location>() {
                    @Override
                    public void onComplete(@NonNull Task<Location> task) {
                        if (task.isSuccessful() && task.getResult() != null) {
                            // Set the map's camera position to the current location of the device.
                            mLastKnownLocation = task.getResult();
                            Log.i("current",task.toString());

                            // Current Locations
                            Double currentLongitude = mLastKnownLocation.getLongitude();
                            Double currentLatitude = mLastKnownLocation.getLatitude();
                            FindPlacesTask placestask = new FindPlacesTask(MapsActivity.this,radious,MapsActivity.this , currentLatitude , currentLongitude);
                            placestask.execute();
                            // Location of new york City


                            //     Double newYorkLatitude = 40.730610;
                            //     Double newYorkLongitude = -73.935242;

                         //   getAddress(currentLatitude,currentLongitude);
                   *//*         if (currentLatitude != null)
                            {
                                SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(ProfileScreen.this);
                                pref.edit().putString("CurrentLatitude",String.valueOf(currentLatitude)).commit();
                                // Toast.makeText(ProfileScreen.this , "Current Latitude : "+currentLatitude,Toast.LENGTH_SHORT).show();
                            }
                            if (currentLongitude != null)
                            {
                                SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(ProfileScreen.this);
                                pref.edit().putString("CurrentLongitude",String.valueOf(currentLongitude)).commit();
                                //Toast.makeText(ProfileScreen.this , "Current Longitude : "+currentLongitude,Toast.LENGTH_SHORT).show();

                            }*//*


                        }else{
                            Toast.makeText(MapsActivity.this,"task result not completed",Toast.LENGTH_SHORT).show();
                            finish();
                        }
                    }
                });

                locationResult.addOnFailureListener(new OnFailureListener() {
                    @Override
                    public void onFailure(@NonNull Exception e) {
                        Toast.makeText(MapsActivity.this,"Something Wrong"+e.getMessage(),Toast.LENGTH_SHORT).show();
                    }
                });

                locationResult.addOnSuccessListener(new OnSuccessListener<Location>() {
                    @Override
                    public void onSuccess(Location location) {
                        if (location != null)
                        {
                            mLastKnownLocation = location;
                        Toast.makeText(MapsActivity.this, "on success called : Latitude : " + location.getLatitude() + " Longitude :" + location.getLongitude(), Toast.LENGTH_SHORT).show();
                    }
                }
                });
            }
        } catch (SecurityException e)  {
            Log.e("Exception: %s", e.getMessage());
        }
    }*/

    @Override
    public void OnDataComplete(ArrayList<PlaceData> placeData) {


        listDataHeader   = new ArrayList<PlaceInfo>();
        //DatabaseServiceLocal databaseServiceLocal = DatabaseServiceLocal.getInstance(this);
        //databaseServiceLocal.insertPlaceInfo(placeData);


        for (int i=0;i<placeData.size();i++)
        {
            final PlaceData data = placeData.get(i);
            PlaceInfo info = new PlaceInfo();
            info.setmPlaceName(data.getName());
            info.setmPlaceId(data.getId());
            info.setmTravelDuration("Loading...");
            info.setmPlaceDistance("Loading...");
            listDataHeader.add(info);
            PlaceDistanceTask distanceTask = new PlaceDistanceTask(MapsActivity.this , data ,MapsActivity.this , currentLatitude,currentLongitude);
            distanceTask.execute();




        }
        listAdapter = new ExpandableAdapter(MapsActivity.this,listDataHeader);
        // setting list adapter
        expListView.setAdapter(listAdapter);

    }


    @Override
    public void OnItemComplete( final  PlaceInfo placeData) {


        if (mHandler == null)
        {
            mHandler = new Handler();
        }

        for (int i=0 ;i<listDataHeader.size();i++)
        {
            if (placeData.getmPlaceId().equalsIgnoreCase(listDataHeader.get(i).getmPlaceId()))
            {
                placeData.setUserWaitAvaliable(true);
                listDataHeader.set(i,placeData);
                listAdapter.notifyDataSetChanged();

                mHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        UserWaitTask taskWait = new UserWaitTask(MapsActivity.this,MapsActivity.this,placeData);
                        taskWait.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
                    }
                },3000);
                break;
            }
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(this);
        boolean isFeedbackUpdate = pref.getBoolean("FeedbackUpdate",false);
        if (isFeedbackUpdate){
            waitMethod();
        }
    }

    public void waitMethod()
    {
        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(this);
        pref.edit().putBoolean("FeedbackUpdate",false).apply();
        if (listDataHeader != null)
        {
            for (int i=0 ;i<listDataHeader.size();i++)
            {
                PlaceInfo placeData = listDataHeader.get(i);
                    placeData.setUserWaitAvaliable(true);
                    listDataHeader.set(i,placeData);
                    listAdapter.notifyDataSetChanged();
                    UserWaitTask taskWait = new UserWaitTask(this,this,placeData);
                    taskWait.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);


            }
        }
    }


    @Override
    public void onWait( PlaceInfo info) {


        for (int i=0 ;i<listDataHeader.size();i++)
        {
            if (info.getmPlaceId().equalsIgnoreCase(listDataHeader.get(i).getmPlaceId()))
            {
                listDataHeader.set(i,info);
                listAdapter.notifyDataSetChanged();
                break;
            }
        }
    }

    @Override
    public void onEmpty(PlaceInfo info) {
        for (int i=0 ;i<listDataHeader.size();i++)
        {
            if (info.getmPlaceId().equalsIgnoreCase(listDataHeader.get(i).getmPlaceId()))
            {
                listDataHeader.set(i,info);
                listAdapter.notifyDataSetChanged();
                break;
            }
        }
    }

    @Override
    public void onError() {

    }

}