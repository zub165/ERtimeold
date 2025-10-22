package com.easytechnologiez.ERTime;

import location.data.PlaceInfo;

public interface UserWaitListener {
    void onWait(PlaceInfo info);
    void onEmpty(PlaceInfo info);
}
