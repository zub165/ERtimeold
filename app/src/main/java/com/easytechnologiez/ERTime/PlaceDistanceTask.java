package com.easytechnologiez.ERTime;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.preference.PreferenceManager;
import android.util.Log;

import com.easytechnologiez.ERTime.utils.Utils;

import location.data.PlaceData;
import location.data.PlaceInfo;
import location.data.PlaceService;

public class PlaceDistanceTask extends AsyncTask<Void,Void,PlaceInfo>
{
    Context context;
    PlaceData data;
    GetPlaceListener listener;
    double mCurrentlatitude;
    double mCurrentlongitude;
    PlaceDistanceTask(Context context , final PlaceData data , GetPlaceListener mylisten , double lati,double longi)
    {
        this.context = context;
        this.data = data;
        this.listener = mylisten;
        mCurrentlatitude = lati;
        mCurrentlongitude = longi;
    }

    @Override
    protected void onPreExecute() {
        super.onPreExecute();

    }

    @Override
    protected PlaceInfo doInBackground(Void... voids) {

        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(context);
        //String curLati = pref.getString("CurrentLatitude","21.2548");
       // String curLongi = pref.getString("CurrentLongitude","75.2548");
        String Radious_Unit = PreferenceManager.getDefaultSharedPreferences(context).getString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY,"km");
        if (Radious_Unit.equalsIgnoreCase("mile"))
        {
            PlaceService service = new PlaceService(Utils.API_KEY);
            return  service.getDistance(""+mCurrentlatitude,""+mCurrentlongitude,String.valueOf(data.getLatitude()),String.valueOf(data.getLongitude()),Utils.DISTANCE_UNITS_KEY_API_SERVICE_IN_MILE);
        }else
        {
            PlaceService service = new PlaceService(Utils.API_KEY);
            return  service.getDistance(""+mCurrentlatitude,""+mCurrentlongitude,String.valueOf(data.getLatitude()),String.valueOf(data.getLongitude()),Utils.DISTANCE_UNITS_KEY_API_SERVICE_IN_KM);
        }



    }

    @Override
    protected void onPostExecute(PlaceInfo info1) {
        super.onPostExecute(info1);

        info1.setmPlaceId(data.getId());
        info1.setmPlaceName(data.getName());
        Log.i("DistanceTask" , "Place Name : "+data.getName()+" PlaceId : "+data.getId()+" Distance : "+info1.getmPlaceDistance()+" Duration: "+info1.getmTravelDuration());
        listener.OnItemComplete(info1);

    }
}
