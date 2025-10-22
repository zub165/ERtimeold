package com.easytechnologiez.ERTime;

import android.content.Context;
import android.os.AsyncTask;

import com.easytechnologiez.ERTime.utils.Utils;

import location.data.PlaceInfo;
import location.data.PlaceService;

public class PlaceDetailsTask extends AsyncTask<Void, Void,PlaceInfo>
{

    String placeId;
    Context context;
    GetPlaceListener listener;
    PlaceDetailsTask(Context context , final String placeId, GetPlaceListener listener )
    {
        this.placeId = placeId;
        this.context = context;
        this.listener = listener;
    }
    @Override
    protected PlaceInfo doInBackground(Void... s) {

        PlaceService service = new PlaceService(Utils.API_KEY);
        PlaceInfo infoList = service.findPlaceDetails(placeId);
        if (infoList != null )
        {
            return  infoList;
            //  Toast.makeText(MapsActivity.this , "Name: "+in1.getmPlaceName()+" Address : "+in1.getmPlaceAddress()+" Website : "+in1.getmPlaceWebsite(),Toast.LENGTH_SHORT).show();
        }else{
            return null;
            // Toast.makeText(MapsActivity.this , "No Place found ",Toast.LENGTH_SHORT).show();
        }

        // return null;
    }

    @Override
    protected void onPostExecute(PlaceInfo info) {
        super.onPostExecute(info);




        if (info != null)
        {

            listener.OnItemComplete(info);
           /* Intent intent = new Intent(context,PlaceDetailsActivity.class);
            intent.putExtra("Name",info.getmPlaceName());
            intent.putExtra("Phone",info.getmPlacePhone());
            intent.putExtra("Address",info.getmPlaceAddress());
            intent.putExtra("Location",info.getmPlaceLatitude()+" , "+info.getmPlaceLongitude());
            intent.putExtra("Website",info.getmPlaceWebsite());
            intent.putExtra("Icon",info.getmPlaceIcon());
            intent.putExtra("PlaceId",info.getmPlaceId());
            context.startActivity(intent);*/
            //Toast.makeText(MapsActivity.this , "Name: "+info.getmPlaceName()+" Address : "+info.getmPlaceAddress()+" Website : "+info.getmPlaceWebsite(),Toast.LENGTH_SHORT).show();

        }else{
            listener.onError();
        }

    }
}
