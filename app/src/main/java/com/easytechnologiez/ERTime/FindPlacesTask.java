package com.easytechnologiez.ERTime;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;

import com.easytechnologiez.ERTime.utils.Utils;

import java.util.ArrayList;

import location.data.PlaceData;
import location.data.PlaceService;

public class FindPlacesTask extends AsyncTask<Void,Void,Void> {

    private ProgressDialog dialog;
    private Context context;
    ArrayList<PlaceData> DataList ;
    public GetPlaceListener listener;
    int Radious;
    Double latitude;
    Double longitude;

    public FindPlacesTask(Context context , int radious , GetPlaceListener listen , Double lati , Double longi) {
        // TODO Auto-generated constructor stub
        this.context = context;
        Radious = radious;
        listener = listen;
        latitude = lati;
        longitude = longi;
    }



    @Override
    protected void onPreExecute() {
        // TODO Auto-generated method stub
        super.onPreExecute();
        dialog = new ProgressDialog(context);
        dialog.setCancelable(true);
        dialog.setMessage("Loading..");
        dialog.setCancelable(false);
        dialog.isIndeterminate();
        dialog.show();
    }

    @Override
    protected Void doInBackground(Void... locations) { //Latitude : 31.46927 Logitude74.3024867
        // TODO Auto-generated method stub
        PlaceService service = new PlaceService(Utils.API_KEY);
       // SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(context);
       // String latitude = pref.getString("CurrentLatitude","0");
      //  String longitude = pref.getString("CurrentLongitude","1");
      // double latitude = locations[0].getLatitude();
      // double longitude = locations[0].getLongitude();
        ArrayList<PlaceData> findPlaces = service.findPlaces(latitude, longitude, "hospital" , Radious);  // hospiral for hospital
        // atm for ATM

        if (findPlaces != null && findPlaces.size()>0) {
            DataList = new ArrayList<PlaceData>();


            for (int i = 0; i < findPlaces.size(); i++) {

                PlaceData placeDetail = findPlaces.get(i);


                DataList.add(placeDetail);

            }
        }
        return null;
    }


    @Override
    protected void onPostExecute(Void result) {
        // TODO Auto-generated method stub
        super.onPostExecute(result);
        dialog.dismiss();
        if (DataList != null && DataList.size()>0) {
            listener.OnDataComplete(DataList);
        }else
        {
            listener.onError();
        }

    }

}
