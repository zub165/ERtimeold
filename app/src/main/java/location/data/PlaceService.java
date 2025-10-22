package location.data;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;

public class PlaceService {
    private String API_KEY;

    public PlaceService(String apikey) {
        this.API_KEY = apikey;
    }

    public void setApiKey(String apikey) {
        this.API_KEY = apikey;
    }

    public ArrayList<PlaceData> findPlaces(double latitude, double longitude, String placeSpacification , int radious)
    {

        String urlString = makeUrl(latitude, longitude,placeSpacification,  radious);


        try {
            String json = getJSON(urlString);

            System.out.println(json);
            JSONObject object = new JSONObject(json);

            JSONArray array = object.getJSONArray("results");
            String status = object.getString("status");
            Log.v("status  ", ""+status);
            ArrayList<PlaceData> arrayList = new ArrayList<PlaceData>();
            for (int i = 0; i < array.length(); i++) {
                try {
                    PlaceData place = (PlaceData) PlaceData.jsonToPontoReference((JSONObject) array.get(i));

                    Log.v("Places Services ", ""+place);


                    arrayList.add(place);
                } catch (Exception e) {
                }
            }
            return arrayList;
        } catch (JSONException ex) {
            Logger.getLogger(PlaceService.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }
    //https://maps.googleapis.com/maps/api/place/search/json?location=28.632808,77.218276&radius=500&types=atm&sensor=false&key=apikey
    private String makeUrl(double latitude, double longitude,String place, int radious) {
        StringBuilder urlString = new StringBuilder("https://maps.googleapis.com/maps/api/place/search/json?");

        if (place.equals("")) {
            urlString.append("&location=");
            urlString.append(Double.toString(latitude));
            urlString.append(",");
            urlString.append(Double.toString(longitude));
            urlString.append("&radius="+radious);
            //   urlString.append("&types="+place);
            urlString.append("&sensor=false&key=" + API_KEY);
        } else {
            urlString.append("&location=");
            urlString.append(Double.toString(latitude));
            urlString.append(",");
            urlString.append(Double.toString(longitude));
            urlString.append("&radius="+radious);
            urlString.append("&types="+place);
            urlString.append("&sensor=false&key=" + API_KEY);
        }


        return urlString.toString();
    }


    public  PlaceInfo findPlaceDetails(String placeId1)
    {


        String urlString = makeUrlForPlaceDetails(placeId1);


        try {
            String json = getJSON(urlString);

            System.out.println(json);
            JSONObject object = new JSONObject(json);

            JSONObject array = object.getJSONObject("result");
            String status = object.getString("status");
            Log.v("status  ", ""+status);

            if (status.equalsIgnoreCase("OK")) {
                try {
                    PlaceInfo place = (PlaceInfo) PlaceData.jsonToPontoReferencePlaceDetails(array);

                    Log.v("Places Services ", "" + place);


                    return place;
                } catch (Exception e) {e.printStackTrace();return null;
                }
            }

            return null;
        } catch (JSONException ex) {
            Logger.getLogger(PlaceService.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
    }

    public PlaceInfo getDistance(String originLati,String originLongi , String destiLai,String destiLongi,String units)
    {
        StringBuilder urlString = new StringBuilder("https://maps.googleapis.com/maps/api/distancematrix/json?");


            urlString.append("&units="+units);
            urlString.append("&origins="+originLati+","+originLongi);
            urlString.append("&destinations="+destiLai+","+destiLongi);
            //  urlString.append(",");
            urlString.append("&key=" + API_KEY);
            Log.i("urlLink",urlString.toString());

            String url2 = urlString.toString();

            /////////////////////////////
        StringBuilder content = new StringBuilder();

        try {
            URL url = new URL(url2);
            URLConnection urlConnection = url.openConnection();
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()), 8);
            String line;
            while ((line = bufferedReader.readLine()) != null)
            {
                content.append(line + "\n");
            }

            bufferedReader.close();
        }

        catch (Exception e)
        {

            e.printStackTrace();

        }

        try {
            String contentResponse = content.toString();
            return  PlaceData.jsonToDistanceString(new JSONObject(contentResponse));
        }catch (JSONException e){e.printStackTrace();}
        return  null;
    }

    private String makeUrlForPlaceDetails(String placeId) {
        StringBuilder urlString = new StringBuilder("https://maps.googleapis.com/maps/api/place/details/json?");

        if (placeId != null) {
            urlString.append("&placeid=");
            urlString.append(placeId);
          //  urlString.append(",");
            urlString.append("&key=" + API_KEY);
           // Log.i("urlLink",urlString.toString());
        }


        return urlString.toString();
    }




    protected String getJSON(String url) {
        return getUrlContents(url);
    }


    protected String getJSonePlaceDetails(String url)
    {
        return getUrlContents(url);
    }

    private String getUrlContents(String theUrl)
    {
        StringBuilder content = new StringBuilder();

        try {
            URL url = new URL(theUrl);
            URLConnection urlConnection = url.openConnection();
            BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()), 8);
            String line;
            while ((line = bufferedReader.readLine()) != null)
            {
                content.append(line + "\n");
            }

            bufferedReader.close();
        }

        catch (Exception e)
        {

            e.printStackTrace();

        }

        return content.toString();
    }
}
