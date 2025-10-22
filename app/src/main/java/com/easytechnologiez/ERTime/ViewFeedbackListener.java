package com.easytechnologiez.ERTime;

import com.easytechnologiez.ERTime.utils.FeedbackInfo;

import location.data.PlaceInfo;

public interface ViewFeedbackListener {

     void showFeedbackButton();
     void showAverage(PlaceInfo info);
     void showMineRating(FeedbackInfo info);
}
