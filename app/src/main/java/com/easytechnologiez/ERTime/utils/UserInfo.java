package com.easytechnologiez.ERTime.utils;

/**
 * Created by Admin on 9/29/2017.
 */

public class UserInfo
{
    private String mFirstName;
    private String mLastName;
    private String mGender;
    private String mHeight;
    private String mWieght;
    private String mBloodGroup;
    private String mEmail;
    private String mPassword;

    public void setmBloodGroup(String mBloodGroup) {
        this.mBloodGroup = mBloodGroup;
    }

    public void setmHeight(String mHeight) {
        this.mHeight = mHeight;
    }

    public void setmWieght(String mWieght) {
        this.mWieght = mWieght;
    }

    public String getmBloodGroup() {
        return mBloodGroup;
    }

    public String getmHeight() {
        return mHeight;
    }

    public String getmWieght() {
        return mWieght;
    }


    public void setmEmail(String mEmail) {
        this.mEmail = mEmail;
    }

    public void setmFirstName(String mFirstName) {
        this.mFirstName = mFirstName;
    }

    public void setmGender(String mGender) {
        this.mGender = mGender;
    }



    public void setmLastName(String mLastName) {
        this.mLastName = mLastName;
    }



    public void setmPassword(String mPassword) {
        this.mPassword = mPassword;
    }






    public String getmEmail() {
        return mEmail;
    }

    public String getmFirstName() {
        return mFirstName;
    }

    public String getmGender() {
        return mGender;
    }



    public String getmLastName() {
        return mLastName;
    }



    public String getmPassword() {
        return mPassword;
    }


    public String toString()
    {
        return mFirstName+" , "+mLastName+" , "+mEmail+" , "+mBloodGroup+" , "+mGender+" , "+mWieght+" , "+mHeight+" , "+mPassword;
    }

}
