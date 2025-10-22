package com.easytechnologiez.ERTime.utils;

import java.util.ArrayList;

public class FeedbackResponse
{
    ArrayList<FeedbackInfo> feedbackInfos;
    String mStatus;
    String mMessage;

    public ArrayList<FeedbackInfo> getFeedbackInfos() {
        return feedbackInfos;
    }

    public String getmMessage() {
        return mMessage;
    }

    public String getmStatus() {
        return mStatus;
    }

    public void setFeedbackInfos(ArrayList<FeedbackInfo> feedbackInfos) {
        this.feedbackInfos = feedbackInfos;
    }

    public void setmMessage(String mMessage) {
        this.mMessage = mMessage;
    }

    public void setmStatus(String mStatus) {
        this.mStatus = mStatus;
    }


}
