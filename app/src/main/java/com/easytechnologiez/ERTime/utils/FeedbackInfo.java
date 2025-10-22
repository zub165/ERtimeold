package com.easytechnologiez.ERTime.utils;

public class FeedbackInfo
{
    String comments;
    String hospital;
    float rating;
    float waitTime;
    String email;


    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }



    public float getWaitTime() {
        return waitTime;
    }

    public float getRating() {
        return rating;
    }

    public String getComments() {
        return comments;
    }


    public String getHospital() {
        return hospital;
    }


    public void setComments(String comments) {
        this.comments = comments;
    }

    public void setHospital(String hospital) {
        this.hospital = hospital;
    }

    public void setRating(Float rating) {
        this.rating = rating;
    }

    public void setWaitTime(Float waitTime) {
        this.waitTime = waitTime;
    }
}
