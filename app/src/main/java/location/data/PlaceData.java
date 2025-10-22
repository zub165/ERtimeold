package location.data;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class PlaceData {
    private String id;
    private String icon;
    private String name;
    private String vicinity;
    private Double latitude;
    private Double longitude;
    private String website;

    public String getWebsite() {
        return website;
    }

    public void setWebsite(String website) {
        this.website = website;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getVicinity() {
        return vicinity;
    }

    public void setVicinity(String vicinity) {
        this.vicinity = vicinity;
    }

    static PlaceData jsonToPontoReference(JSONObject pontoReferencia) {
        try {
            PlaceData result = new PlaceData();
            JSONObject geometry = (JSONObject) pontoReferencia.get("geometry");
            JSONObject location = (JSONObject) geometry.get("location");
            result.setLatitude((Double) location.get("lat"));
            result.setLongitude((Double) location.get("lng"));
            result.setIcon(pontoReferencia.getString("icon"));
            result.setName(pontoReferencia.getString("name"));
            result.setVicinity(pontoReferencia.getString("vicinity"));
            result.setId(pontoReferencia.getString("place_id"));
           // result.setWebsite(pontoReferencia.getString("id"));
            return result;
        } catch (JSONException ex) {
            //Logger.getLogger(Place.class.getName()).log(Level.SEVERE, null, ex);
            ex.printStackTrace();
        }
        return null;
    }



    static PlaceInfo jsonToDistanceString(JSONObject pontoReferencia) {
        try {
            PlaceInfo result = new PlaceInfo();
           // Log.i("PlaceDistanceDetails",pontoReferencia.toString());
            String status = pontoReferencia.getString("status");
            if (status.equalsIgnoreCase("OK"))
            {
                String destination = pontoReferencia.getString("destination_addresses");
                JSONArray rows = pontoReferencia.getJSONArray("rows");
                if (rows != null)
                {
                    JSONObject elements = rows.getJSONObject(0);

                 //   Log.i("dlements",elements.toString());

                    JSONArray elements1 = elements.getJSONArray("elements");
                 //   Log.i("dlements1",elements1.toString());

                    JSONObject distance = elements1.getJSONObject(0);
                 //   Log.i("dlements dist",distance.toString());

                    String status1 = distance.getString("status");
                    if (status1.equalsIgnoreCase("OK")) {
                        JSONObject distanceValue = distance.getJSONObject("distance");
                        String valuedistance = distanceValue.getString("text");
                        JSONObject durationValue = distance.getJSONObject("duration");
                        String valueduration = durationValue.getString("text");
                        Log.i("TravelDuration : ",valueduration);
                        result.setmTravelDuration(valueduration);
                        result.setmPlaceDistance(valuedistance);
                    }else{
                        result.setmTravelDuration("not found");
                        result.setmPlaceDistance("not found");
                    }

                    return result;
                }
            }else
            {

                result.setmError(status);
                return result;
            }


/*

            JSONObject geometry = (JSONObject) pontoReferencia.get("geometry");
            JSONObject location = (JSONObject) geometry.get("location");
            result.setmPlaceLatitude( location.getString("lat"));
            result.setmPlaceLongitude( location.getString("lng"));
            result.setmPlaceIcon(pontoReferencia.getString("icon"));
            result.setmPlaceName(pontoReferencia.getString("name"));
            result.setmPlaceVicinity(pontoReferencia.getString("vicinity"));
            result.setmId(pontoReferencia.getString("id"));
            result.setmPlaceAddress(pontoReferencia.getString("formatted_address"));

            if (pontoReferencia.has("international_phone_number"))
            {
                result.setmPlacePhone(pontoReferencia.getString("international_phone_number"));
            }else if (pontoReferencia.has("formatted_phone_number"))
            {
                result.setmPlacePhone(pontoReferencia.getString("formatted_phone_number"));
            }

            result.setmPlaceWebsite(pontoReferencia.getString("url"));*/
            return result;
        } catch (JSONException ex) {
            ex.printStackTrace();
            return null;
        }

    }







    static PlaceInfo jsonToPontoReferencePlaceDetails(JSONObject pontoReferencia) {
        try {

            Log.i("PlaceDetailsData",pontoReferencia.toString());

            PlaceInfo result = new PlaceInfo();
            JSONObject geometry = (JSONObject) pontoReferencia.get("geometry");
            JSONObject location = (JSONObject) geometry.get("location");
            result.setmPlaceLatitude( location.getString("lat"));
            result.setmPlaceLongitude( location.getString("lng"));
            result.setmPlaceIcon(pontoReferencia.getString("icon"));
            result.setmPlaceName(pontoReferencia.getString("name"));
            result.setmPlaceVicinity(pontoReferencia.getString("vicinity"));
            result.setmId(pontoReferencia.getString("id"));
            result.setmPlaceAddress(pontoReferencia.getString("formatted_address"));

            if (pontoReferencia.has("international_phone_number"))
            {
                result.setmPlacePhone(pontoReferencia.getString("international_phone_number"));
            }else if (pontoReferencia.has("formatted_phone_number"))
            {
                result.setmPlacePhone(pontoReferencia.getString("formatted_phone_number"));
            }

            result.setmError(pontoReferencia.getString("url"));

            if (pontoReferencia.has("website"))
            {
                result.setmPlaceWebsite(pontoReferencia.getString("website"));
            }else {
                result.setmPlaceWebsite("Not found");
            }


            result.setmPlaceId(pontoReferencia.getString("place_id"));
            return result;
        } catch (JSONException ex) {
           // Logger.getLogger(Place.class.getName()).log(Level.SEVERE, null, ex);
            ex.printStackTrace();
        }
        return null;
    }


    @Override
    public String toString() {
        return "Place{" + "id=" + id + ", icon=" + icon + ", name=" + name + ", latitude=" + latitude + ", longitude=" + longitude + '}';
    }
}
