package com.easytechnologiez.ERTime.utils;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.drawable.ColorDrawable;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AlertDialog;
import android.util.Base64;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;

import com.easytechnologiez.ERTime.R;

import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Arrays;

import location.data.PlaceInfo;

/**
 * Created by Admin on 9/30/2017.
 */

public class Utils
{
    public static final String API_KEY = "AIzaSyB7iA3Bqquk4esrs2ZEZ70fAohMXvQX1IY";
    public static final String SHARED_PREFERENCE_DISTANCE_UNIT_KEY = "Distance_Unit";
    public static final String SHARED_PREFERENCE_HEIGHT_UNIT_KEY = "Height_Unit";
    public static final String SHARED_PREFERENCE_WEIGHT_UNIT_KEY = "Weight_Unit";
    public static final String DISTANCE_UNITS_KEY_API_SERVICE_IN_KM = "metric";
    public static final String DISTANCE_UNITS_KEY_API_SERVICE_IN_MILE = "imperial";
    public static final int PERMISSION_ALL = 111;
    public static final  int REQUEST_LOCATION_PERMISSION_FOR_RESULT = 123;
    public static final  int REQUEST_FEEDBACK_UPDATE_FOR_RESULT = 23;
    public static final  int RESULT_LOCATION_PERMISSION_CODE = 122;
    public static final  int RESULT_FEEDBACK_SUCCESS_UPDATE_CODE = 22;
    public static final String[] PERMISSIONS = {
            Manifest.permission.ACCESS_FINE_LOCATION,
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.READ_EXTERNAL_STORAGE,
            android.Manifest.permission.CAMERA
    };

    public static boolean hasInternetConnection(Context context)
    {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo wifiNetwork = cm.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
        if (wifiNetwork != null && wifiNetwork.isConnected())
        {
            return true;
        }
        NetworkInfo mobileNetwork = cm.getNetworkInfo(ConnectivityManager.TYPE_MOBILE);
        if (mobileNetwork != null && mobileNetwork.isConnected())
        {
            return true;
        }
        NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
        if (activeNetwork != null && activeNetwork.isConnected())
        {
            return true;
        }
        return false;
    }

    public static float AverageRating(ArrayList<FeedbackInfo> list)
    {
        float rating1 = 0;
        float rating2 = 0;
        float rating3 = 0;
        float rating4 = 0;
        float rating5 = 0;

        for (int i=0 ;i<list.size();i++)
        {
            FeedbackInfo item = list.get(i);
            float rating = item.getRating();
            if (rating == 1 || (rating < 1 && rating > 0))
            {
                rating1++;
            }else if (rating == 2 || (rating < 2 && rating > 1))
            {
                rating2++;
            }else if (rating == 3 || (rating < 3 && rating > 2))
            {
                rating3++;
            }else if (rating == 4 || (rating < 4 && rating > 3))
            {
                rating4++;
            }else if (rating == 5 || (rating < 5 && rating > 4)) {
                rating5++;
            }
        }

        return  ((rating1*1)+(rating2*2)+(rating3*3)+(rating4*4)+(rating5*5))/(rating1+rating2+rating3+rating4+rating5);
    }


    public static float AverageWaitTime(ArrayList<FeedbackInfo> infos)
    {
        float waitTime= 0;
        for (int i=0;i<infos.size();i++)
        {
            FeedbackInfo item = infos.get(i);
            waitTime = waitTime+item.getWaitTime();
           // Log.i("WaitTime ",waitTime+"");
        }
        float averageWait = waitTime/infos.size();

      //  float roundOff = Math.round(averageWait * 100.0) / 100.0;
      //  Log.i("WaitTime Average",averageWait+"");
      //  Log.i("WaitTime Hospital",infos.get(0).getHospital()+"");

        DecimalFormat decimalFormat = new DecimalFormat("#.##");
        return Float.valueOf(decimalFormat.format(averageWait));
    }
    @SuppressWarnings("unchecked")
    public static ArrayList<PlaceInfo> sortByPlaceName(ArrayList<PlaceInfo> items){
        ArrayList<PlaceInfo> sortedItems = new ArrayList<PlaceInfo>();
        items = (ArrayList<PlaceInfo>) items.clone();
        String[] itemsNameArray;

        itemsNameArray = new String[items.size()];
        for(int i = 0; i < items.size(); i++)
        {
            itemsNameArray[i] = items.get(i).getmPlaceName().toUpperCase();
        }

        Arrays.sort(itemsNameArray);

        for(int i = 0; i < itemsNameArray.length; i++)
        {
            for(int j = 0; j < items.size(); j++)
            {
                if(itemsNameArray[i].equalsIgnoreCase(items.get(j).getmPlaceName()))
                {
                    sortedItems.add(items.remove(j));
                }
            }
        }

        return (ArrayList<PlaceInfo>) sortedItems.clone();
    }

    public static void showDialogForUpdateData(Context context, String text, final int postion , View.OnClickListener listener , TextView textView)
    {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        View mView = ((Activity)context).getLayoutInflater().inflate(R.layout.dialog_update, null);
        builder.setView(mView);
        EditText editText = (EditText) mView.findViewById(R.id.editName);
        editText.setText(text);
        Button ok = (Button) mView.findViewById(R.id.ok);

        Button cancel = (Button) mView.findViewById(R.id.cancel);

        ok.setOnClickListener(listener);
        cancel.setOnClickListener(listener);

        AlertDialog dialog = builder.create();
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
        }
        Holder holder = new Holder();
        holder.dialog = dialog;
        holder.positon = postion;
        holder.updatedData = editText;
        holder.mTextView = textView;
        cancel.setTag(holder);
        ok.setTag(holder);
        dialog.show();

    }

    public static void showDialogForUpdateBlood(Context context, final int postion , View.OnClickListener listener , TextView textView)
    {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        View mView = ((Activity)context).getLayoutInflater().inflate(R.layout.dialog_update_blood,null);
        builder.setView(mView);
        Spinner spinner = (Spinner) mView.findViewById(R.id.blood_spinner);
      //  spinner.setText(text);
        Button ok = (Button) mView.findViewById(R.id.ok_blood);

        Button cancel = (Button) mView.findViewById(R.id.cancel_blood);

        ok.setOnClickListener(listener);
        cancel.setOnClickListener(listener);

        AlertDialog dialog = builder.create();
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
        }
        Holder holder = new Holder();
        holder.dialog = dialog;
        holder.positon = postion;
        holder.mSpinner = spinner;
        holder.mTextView = textView;
        cancel.setTag(holder);
        ok.setTag(holder);
        dialog.show();

    }

    public static class  Holder
    {
       public AlertDialog dialog;
        public EditText updatedData;
        public int positon;
        public TextView mTextView;
        public Spinner mSpinner;
    }

    @SuppressWarnings("unchecked")
    public static ArrayList<PlaceInfo> sortDuration(ArrayList<PlaceInfo> items){
        ArrayList<PlaceInfo> sortedItems = new ArrayList<PlaceInfo>();
        items = (ArrayList<PlaceInfo>) items.clone();
        Float[] itemsRatingArray;

        itemsRatingArray = new Float[items.size()];
        for(int i = 0; i < items.size(); i++)
        {
         //   itemsRatingArray[i] = Float.valueOf(items.get(i).getmTravelDuration());
            itemsRatingArray[i] = getNumericFromString(items.get(i).getmTravelDuration());
        }

        Arrays.sort(itemsRatingArray);

        for(int i = 0; i < itemsRatingArray.length; i++)
        {
            for(int j = 0; j < items.size(); j++)
            {
                if(itemsRatingArray[i].equals(getNumericFromString(items.get(j).getmTravelDuration())))
                {
                    sortedItems.add(items.remove(j));
                }
            }
        }

        return (ArrayList<PlaceInfo>) sortedItems.clone();
    }


    private static Float getNumericFromString(String string){
        try {
            if(string != null){
                String commaRemovedString = string.replaceAll(",","");
                String removespace = commaRemovedString.replaceAll(" ","");
                String newString = removespace.replaceAll("[A-z]+$", "");
                Log.i("newStringTravel",newString);
                return Float.parseFloat(newString);
                /*return Double.parseDouble(string.replaceAll("[^[0-9]+[.[0-9]]*]", "").trim());*/

            }
        }catch (NumberFormatException e){
            e.printStackTrace();
        }
        return 0f;
    }


  /*
    public static ArrayList<PlaceInfo> sortByPlaceDuration(ArrayList<PlaceInfo> items){
        ArrayList<PlaceInfo> sortedItems = new ArrayList<PlaceInfo>();
        items = (ArrayList<PlaceInfo>) items.clone();
        String[] itemsNameArray;

        itemsNameArray = new String[items.size()];
        for(int i = 0; i < items.size(); i++)
        {
            itemsNameArray[i] = items.get(i).getmTravelDuration().toUpperCase();
        }

        Arrays.sort(itemsNameArray);

        for(int i = 0; i < itemsNameArray.length; i++)
        {
            for(int j = 0; j < items.size(); j++)
            {
                if(itemsNameArray[i].equalsIgnoreCase(items.get(j).getmTravelDuration()))
                {
                    sortedItems.add(items.remove(j));
                }
            }
        }

        return (ArrayList<PlaceInfo>) sortedItems.clone();
    }

*/  @SuppressWarnings("unchecked")
    public static ArrayList<PlaceInfo> sortByPlaceDistance(ArrayList<PlaceInfo> items){
        ArrayList<PlaceInfo> sortedItems = new ArrayList<PlaceInfo>();
        items = (ArrayList<PlaceInfo>) items.clone();
        String[] itemsNameArray;

        itemsNameArray = new String[items.size()];
        for(int i = 0; i < items.size(); i++)
        {
            itemsNameArray[i] = items.get(i).getmPlaceDistance().toUpperCase();
        }

        Arrays.sort(itemsNameArray);

        for(int i = 0; i < itemsNameArray.length; i++)
        {
            for(int j = 0; j < items.size(); j++)
            {
                if(itemsNameArray[i].equalsIgnoreCase(items.get(j).getmPlaceDistance()))
                {
                    sortedItems.add(items.remove(j));
                }
            }
        }

        return (ArrayList<PlaceInfo>) sortedItems.clone();
    }



    ////////// Method for md5 String ///////
    public static  String md5(final String s) {
        try {
            // Create MD5 Hash
            MessageDigest digest = MessageDigest
                    .getInstance("MD5");
            digest.update(s.getBytes());
            byte messageDigest[] = digest.digest();

            // Create Hex String
            StringBuffer hexString = new StringBuffer();
            for (int i = 0; i < messageDigest.length; i++) {
                String h = Integer.toHexString(0xFF & messageDigest[i]);
                while (h.length() < 2)
                    h = "0" + h;
                hexString.append(h);
            }
            return hexString.toString();

        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        }
        return "";
    }


    public static  boolean mayRequestLocation(Activity context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true;
        }
        if (hasPermissions(context,PERMISSIONS)) {
            return true;
        }
        if(!hasPermissions(context, PERMISSIONS)){
            ActivityCompat.requestPermissions(context, PERMISSIONS, PERMISSION_ALL);
        }
        return false;
    }

    private static boolean hasPermissions(Context context, String... permissions) {
        if (context != null && permissions != null) {
            for (String permission : permissions) {
                if (ActivityCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
                    return false;
                }
            }
        }
        return true;
    }




    public static String encryptedPassword(String mEmail , String mPassword)
    {
       // String encryptedPassword = Utils.md5(mPassword);
        String concatinatedString = mEmail + ":" + mPassword;
        String encodedValue = /*"Basic "+*/ Base64.encodeToString(concatinatedString.getBytes(),Base64.NO_WRAP);
            return encodedValue;
    }


    public static String DecryptedPassword(String encryptedPassword)
    {
       // String encryptedPassword = Utils.md5(mPassword);
       // String concatinatedString = mEmail + ":" + encryptedPassword;
       // String encodedValue = "Basic "+ Base64.encodeToString(concatinatedString.getBytes(),Base64.NO_WRAP);
        byte[] base64 = null;
        if (encryptedPassword != null){
            base64 = Base64.decode(encryptedPassword,Base64.NO_WRAP);
        }

        String   encodedValue = null;
        try {
               encodedValue = new String(base64, "UTF-8");
        }catch (IOException e){e.printStackTrace();}
        String[] array = encodedValue.split(":");
        if (array.length >1){
            encodedValue = array[1];
            return  encodedValue;
        }
        return "";
    }




}
