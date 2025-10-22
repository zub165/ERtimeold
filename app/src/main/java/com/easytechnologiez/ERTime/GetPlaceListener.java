package com.easytechnologiez.ERTime;

import java.util.ArrayList;

import location.data.PlaceData;
import location.data.PlaceInfo;

public interface GetPlaceListener {

    public void OnDataComplete(ArrayList<PlaceData> placeData);
    public void OnItemComplete(PlaceInfo placeData);
    public void onError();

}
