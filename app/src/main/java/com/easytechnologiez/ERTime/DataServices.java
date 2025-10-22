package com.easytechnologiez.ERTime;

import android.content.Context;
import android.util.Log;
import com.easytechnologiez.ERTime.api.DjangoApiClient;
import com.easytechnologiez.ERTime.config.ApiConfig;

import com.easytechnologiez.ERTime.utils.FeedbackInfo;
import com.easytechnologiez.ERTime.utils.FeedbackResponse;
import com.easytechnologiez.ERTime.utils.HealthCardInfo;
import com.easytechnologiez.ERTime.utils.UserInfo;
import com.easytechnologiez.ERTime.utils.Utils;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Iterator;

import javax.net.ssl.HttpsURLConnection;

public class DataServices {
    Context context;
    private DjangoApiClient djangoClient;

    DataServices(Context context) {
        this.context = context;
        this.djangoClient = new DjangoApiClient(context);
    }
    
    /**
     * Test connection to Django Hospital Finder backend
     */
    public boolean testDjangoConnection() {
        return djangoClient.testConnection();
    }
    
    /**
     * New Django-based login method
     */
    public String djangoLogin(String email, String password) {
        return djangoClient.login(email, password);
    }
    
    /**
     * Search hospitals using Django backend
     */
    public String searchHospitals(double latitude, double longitude, double radius) {
        return djangoClient.getHospitalsNearby(latitude, longitude, radius);
    }

    public static String NewFetchMethodSginIn(Context context, String mEmail, String mPassword) {
        try {

            URL url = new URL("http://mywaitime.com/login.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("pass_email", Utils.encryptedPassword(mEmail, mPassword));
            Log.e("params", postDataParams.toString());

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();

                JSONObject jsnobject = new JSONObject(sb.toString());

                //  Toast.makeText(context,jsnobject.toString(),Toast.LENGTH_SHORT).show();
                String email1 = jsnobject.getString("email");
                if (email1.equalsIgnoreCase(mEmail)) {
                    String weight = jsnobject.getString("user_weight");
                    String height = jsnobject.getString("user_height");
                    String blood = jsnobject.getString("user_blood_group");
                    String fName = jsnobject.getString("f_name");
                    String lName = jsnobject.getString("l_name");
                    if (fName != null)
                    {
                        try {
                            fName = URLDecoder.decode(fName,"utf-8");
                        }catch (Exception e){e.printStackTrace();}
                    }

                    if (lName != null)
                    {
                        try {
                            lName = URLDecoder.decode(lName,"utf-8");
                        }catch (Exception e){e.printStackTrace();}
                    }

                    String password = jsnobject.getString("password");
                    String gender = jsnobject.getString("gender");
                    int active = jsnobject.getInt("active");
                    DatabaseServiceLocal database = DatabaseServiceLocal.getInstance(context);
                    UserInfo info = new UserInfo();
                    info.setmWieght(weight);
                    info.setmHeight(height);
                    info.setmBloodGroup(blood);
                    info.setmPassword(password);
                    info.setmEmail(email1);
                    info.setmFirstName(fName);
                    info.setmLastName(lName);
                    info.setmGender(gender);
                    if (active == 1) {
                        database.insertUserInfo(info);
                        return "success";
                    }else{
                        return "not verify";
                    }
                } else {

                    return "fail";
                }

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }

    public static FeedbackResponse AverageUserWaitMethod( String mHospital ) {

        FeedbackResponse feedbackResponse = new FeedbackResponse();
      //  HttpURLConnection conn = null;
        HttpURLConnection conn = null;
        try {

            URL url = new URL("http://mywaitime.com/averagefeedback.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();
            mHospital =   URLEncoder.encode(mHospital,"utf-8");
           // postDataParams.put("pass_email", Utils.encryptedPassword(mEmail, mPassword));
           // postDataParams.put("email", mEmail);
            postDataParams.put("hospital", mHospital);


             conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(13000 );
            conn.setConnectTimeout(13000 );
            conn.setRequestMethod("POST");
           // conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
           // conn.setFixedLengthStreamingMode(getPostDataString(postDataParams).length());
          //  conn.setRequestProperty("Connection", "close");
            conn.setDoInput(true);
            conn.setDoOutput(true);
            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
          //  os.flush();

            os.close();
           // conn.connect();

            int responseCode = conn.getResponseCode();
            Log.e("params", responseCode+"");
            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()),8);
                StringBuffer sb = new StringBuffer("");
                String line = "";

                ArrayList<FeedbackInfo> infoList = new ArrayList<FeedbackInfo>();

                while ((line = in.readLine()) != null) {

                    sb.append(line+"\n");
                    Log.e("params", sb.toString());

                   // break;
                }
                in.close();

                JSONArray array = new JSONArray(sb.toString());

              //  Log.i("Average" , sb.toString());

               // JSONArray array = jsnobject.getJSONArray("data");



                for (int i=0;i<array.length();i++)
                {
                    JSONObject object = array.getJSONObject(i);
                        if (object.has("status"))
                        {
                            String message = object.getString("message");
                            String status = object.getString("status");
                            feedbackResponse.setmStatus(status);
                            feedbackResponse.setmMessage(message);
                            return feedbackResponse;

                        }else {
                          //  String email1 = object.getString("email");
                          //  String hospital = object.getString("hospital");
                            String rating = object.getString("average");
                         //   String feedback_text = object.getString("feedback_text");
                            String wait_time = object.getString("wait");
                            FeedbackInfo info = new FeedbackInfo();
                            if (rating != null && !rating.equalsIgnoreCase("null")) {
                                float ratingnew = Float.parseFloat(rating);
                                info.setRating(ratingnew);
                            }

                           // info.setComments(feedback_text);
                            if (wait_time != null &&!wait_time.equalsIgnoreCase("null")) {
                                info.setWaitTime(Float.parseFloat(wait_time));
                                mHospital = URLDecoder.decode(mHospital,"utf-8");
                                info.setHospital(mHospital);
                                infoList.add(info);
                            }
                         //   info.setEmail(email1);

                        }


                }

                feedbackResponse.setFeedbackInfos(infoList);

                return feedbackResponse;

                //  Toast.makeText(context,jsnobject.toString(),Toast.LENGTH_SHORT).show();


            } else {
                feedbackResponse.setmMessage("An error is occour");
                feedbackResponse.setmStatus("fail");
                return feedbackResponse;
            }
        } catch (Exception e) {
            e.printStackTrace();

            feedbackResponse.setmMessage(e.getMessage());
            feedbackResponse.setmStatus("fail");

            return feedbackResponse;
        }finally {
            if (conn != null)
            {
                conn.disconnect();
            }
        }
    }

   /* public static FeedbackResponse MyRatingTaskMethod(String email , String mHospital)
    {
        FeedbackResponse feedbackResponse = new FeedbackResponse();
        StringBuilder urlString = new StringBuilder("http://mywaitime.com/Myrating.php?");

       // mHospital = mHospital.replace(" ","%20");

        try {

         mHospital =   URLEncoder.encode(mHospital,"utf-8");

          //  mHospital = mHospital.replaceAll("\\+", "%20");
            Log.i("myrating",mHospital);
            urlString.append("&hospital="+mHospital);
        }catch (Exception e){e.printStackTrace();}




        urlString.append("&email="+email);
       *//* urlString.append("&destinations="+destiLai+","+destiLongi);
        //  urlString.append(",");
        urlString.append("&key=" + API_KEY);
        Log.i("urlLink",urlString.toString());*//*

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

            Log.i("Average" , contentResponse);

            JSONArray array = new JSONArray(contentResponse);



            // JSONArray array = jsnobject.getJSONArray("data");

            ArrayList<FeedbackInfo> infoList = new ArrayList<FeedbackInfo>();

            for (int i=0;i<array.length();i++)
            {
                JSONObject object = array.getJSONObject(i);
                if (object.has("status"))
                {
                    String message = object.getString("message");
                    String status = object.getString("status");
                    feedbackResponse.setmStatus(status);
                    feedbackResponse.setmMessage(message);
                    return feedbackResponse;

                }else {
                    String email1 = object.getString("email");
                    String hospital = null;
                    if (object.has("hospital")) {
                         hospital = object.getString("hospital");
                         try {
                             hospital = URLDecoder.decode(hospital,"utf-8");
                         }catch (Exception e){e.printStackTrace();}

                    }

                    String feedback_text = null;
                    if (object.has("feedback_text")) {
                        feedback_text = object.getString("feedback_text");
                        try {
                            feedback_text = URLDecoder.decode(feedback_text,"utf-8");
                        }catch (Exception e){e.printStackTrace();}

                    }

                    String rating = object.getString("rating");
                    //String feedback_text = object.getString("feedback_text");
                    String wait_time = object.getString("wait_time");

                    float ratingnew = Float.parseFloat(rating);
                    FeedbackInfo info = new FeedbackInfo();
                    if (feedback_text != null) {
                        info.setComments(feedback_text);
                    }
                    info.setRating(ratingnew);
                    info.setWaitTime(Float.parseFloat(wait_time));
                    info.setEmail(email1);
                    if (hospital != null) {
                        info.setHospital(hospital);
                    }
                    infoList.add(info);
                }


            }

            feedbackResponse.setFeedbackInfos(infoList);

            return feedbackResponse;
        }catch (JSONException e){e.printStackTrace();return null;}


    }*/


    public static FeedbackResponse MyRatingTask( String mHospital , String mEmail ) {

        FeedbackResponse feedbackResponse = new FeedbackResponse();
        //  HttpURLConnection conn = null;
        HttpURLConnection conn = null;
        try {

            URL url = new URL("http://mywaitime.com/Myrating.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();
            mHospital =   URLEncoder.encode(mHospital,"utf-8");
            // postDataParams.put("pass_email", Utils.encryptedPassword(mEmail, mPassword));
            // postDataParams.put("email", mEmail);
            postDataParams.put("hospital", mHospital);
            postDataParams.put("email", mEmail);


            conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(13000 );
            conn.setConnectTimeout(13000 );
            conn.setRequestMethod("POST");
            // conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            // conn.setFixedLengthStreamingMode(getPostDataString(postDataParams).length());
            //  conn.setRequestProperty("Connection", "close");
            conn.setDoInput(true);
            conn.setDoOutput(true);
            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            //  os.flush();

            os.close();


            int responseCode = conn.getResponseCode();
            Log.e("params", responseCode+"");
            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()),8);
                StringBuffer sb = new StringBuffer("");
                String line = "";

                ArrayList<FeedbackInfo> infoList = new ArrayList<FeedbackInfo>();

                while ((line = in.readLine()) != null) {

                    sb.append(line+"\n");
                    Log.e("params", sb.toString());

                    // break;
                }
                in.close();

                String contentResponse = sb.toString();

                JSONArray array = new JSONArray(contentResponse);

                for (int i=0;i<array.length();i++)
                {
                    JSONObject object = array.getJSONObject(i);
                    if (object.has("status"))
                    {
                        String message = object.getString("message");
                        String status = object.getString("status");
                        feedbackResponse.setmStatus(status);
                        feedbackResponse.setmMessage(message);
                        return feedbackResponse;

                    }else {
                        String email1 = object.getString("email");
                        String hospital = null;
                        if (object.has("hospital")) {
                            hospital = object.getString("hospital");
                            try {
                                hospital = URLDecoder.decode(hospital,"utf-8");
                            }catch (Exception e){e.printStackTrace();}

                        }

                        String feedback_text = null;
                        if (object.has("feedback_text")) {
                            feedback_text = object.getString("feedback_text");
                            try {
                                feedback_text = URLDecoder.decode(feedback_text,"utf-8");
                            }catch (Exception e){e.printStackTrace();}

                        }

                        String rating = object.getString("rating");
                        //String feedback_text = object.getString("feedback_text");
                        String wait_time = object.getString("wait_time");

                        float ratingnew = Float.parseFloat(rating);
                        FeedbackInfo info = new FeedbackInfo();
                        if (feedback_text != null) {
                            info.setComments(feedback_text);
                        }
                        info.setRating(ratingnew);
                        info.setWaitTime(Float.parseFloat(wait_time));
                        info.setEmail(email1);
                        if (hospital != null) {
                            info.setHospital(hospital);
                        }
                        infoList.add(info);
                    }


                }

                feedbackResponse.setFeedbackInfos(infoList);

                return feedbackResponse;

                //  Toast.makeText(context,jsnobject.toString(),Toast.LENGTH_SHORT).show();


            } else {
                feedbackResponse.setmMessage("An error is occour");
                feedbackResponse.setmStatus("fail");
                return feedbackResponse;
            }
        } catch (Exception e) {
            e.printStackTrace();

            feedbackResponse.setmMessage(e.getMessage());
            feedbackResponse.setmStatus("fail");

            return feedbackResponse;
        }finally {
            if (conn != null)
            {
                conn.disconnect();
            }
        }
    }

    public static String NewFetchMethodForgetPassowrd(String mEmail) {
        try {

            URL url = new URL("http://mywaitime.com/forget.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("email", mEmail);

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }

    public static String UpdateFirstName(UserInfo info, String fname) {
        try {

            URL url = new URL("http://mywaitime.com/updatefirstname.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();
            fname =   URLEncoder.encode(fname,"utf-8");
            postDataParams.put("f_name", fname);
            postDataParams.put("pass_email",  info.getmPassword());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }


    public static String UpdateLastName(UserInfo info, String lname) {
        try {

            URL url = new URL("http://mywaitime.com/updatelastname.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();
            lname =   URLEncoder.encode(lname,"utf-8");
            postDataParams.put("l_name", lname);
            postDataParams.put("pass_email",  info.getmPassword());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }


    public static String UpdateHeight(UserInfo info, String lname) {
        try {

            URL url = new URL("http://mywaitime.com/updateheight.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("user_height", lname);
            postDataParams.put("pass_email",  info.getmPassword());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }

    public static String UpdateWeight(UserInfo info, String lname) {
        try {

            URL url = new URL("http://mywaitime.com/updateweight.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("user_weight", lname);
            postDataParams.put("pass_email",  info.getmPassword());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }


    public static String Updateblood(UserInfo info, String lname) {
        try {

            URL url = new URL("http://mywaitime.com/updateblood.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("user_blood_group", lname);
            postDataParams.put("pass_email",  info.getmPassword());
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }

    public static String Updatepassword(UserInfo info, String lname) {
        try {

            URL url = new URL("http://mywaitime.com/updatepassword.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("new_password", Utils.encryptedPassword(info.getmEmail(), lname));
            postDataParams.put("password", info.getmPassword());
            postDataParams.put("email", info.getmEmail());
            postDataParams.put("pass_email", info.getmPassword());
            postDataParams.put("pass_email1", Utils.encryptedPassword(info.getmEmail(), lname));
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                return sb.toString();

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }

    public static String NewFetchMethodRegistred(Context context, String fName, String lName, String mEmail, String mPassword, String gender) {
        try {


            URL url = new URL("http://mywaitime.com/register.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();
            fName =   URLEncoder.encode(fName,"utf-8");
            lName =   URLEncoder.encode(lName,"utf-8");
            postDataParams.put("f_name", fName);
            postDataParams.put("l_name", lName);
            //  postDataParams.put("u_name", uName);

            postDataParams.put("email", mEmail);
           // postDataParams.put("user_height", height);
          //  postDataParams.put("user_weight", weight);
          //  pofstDataParams.put("user_blood_group", blood);
               // mPassword = mPassword+":ertime";


            postDataParams.put("pass_email", Utils.encryptedPassword(mEmail,mPassword));
            postDataParams.put("gender", gender);
            postDataParams.put("password", Utils.encryptedPassword(mEmail,mPassword));
            //   Log.e("params",postDataParams.toString());

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                JSONObject jsnobject = new JSONObject(sb.toString());

                String status = jsnobject.getString("status");

                if (status.equalsIgnoreCase("verify")) {
                   /* DatabaseServiceLocal database = DatabaseServiceLocal.getInstance(context);
                    UserInfo info = new UserInfo();
                  //  info.setmWieght(weight);
                  //  info.setmHeight(height);
                  //  info.setmBloodGroup(blood);
                    info.setmPassword(mPassword);
                    info.setmEmail(mEmail);
                    info.setmFirstName(fName);
                    info.setmLastName(lName);
                    info.setmGender(gender);
                    database.insertUserInfo(info);*/

                }

                return status;

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }


    public static String FeedbackMethod(Context context, String feedback, String waitTime, String hospital, String rating, UserInfo info)
    {
        try {


            URL url = new URL("http://mywaitime.com/feedback.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();
            hospital =   URLEncoder.encode(hospital,"utf-8");
            feedback =   URLEncoder.encode(feedback,"utf-8");
            postDataParams.put("hospital", hospital);
            postDataParams.put("rating", rating);
            //  postDataParams.put("u_name", uName);
            postDataParams.put("feedback_text", feedback);
            postDataParams.put("email", info.getmEmail());
            postDataParams.put("wait_time", waitTime);
            postDataParams.put("pass_email", info.getmPassword());

           //   Log.e("params",postDataParams.toString());
         //   Log.e("params",info.getmEmail() +" : "+info.getmPassword());

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK)
            {

                BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                   // break;
                }

                Log.i("myrating",sb.toString());
                in.close();
                JSONObject jsnobject = new JSONObject(sb.toString());

                String status = jsnobject.getString("status");
                String message = jsnobject.getString("message");
                if (status.equalsIgnoreCase("success")) {

                    return status;
                }

                return message;

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            return new String("Exception:" + e.getMessage());
        }
    }




    public static String DownloadHealthCardLink(Context context,UserInfo info)
    {
        try {


            URL url = new URL("http://mywaitime.com/downloadcard.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("email", info.getmEmail());
          //  postDataParams.put("email", "hujhu");

               Log.e("params",postDataParams.toString());

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 );
            conn.setConnectTimeout(15000 );
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);
         //   conn.connect();
           // conn.setRequestProperty("Content-Type","text/json");

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode = conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK)
            {

               /* BufferedReader in = new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line = "";

                while ((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();*/

             String str =   streamToString(conn.getInputStream());

              //  Log.i("healthcard",str);
                JSONObject jsnobject = new JSONObject(str);


                String email = jsnobject.getString("email");
                String url3 = jsnobject.getString("url");
                if (email.equalsIgnoreCase(info.getmEmail()) && url3 != null) {

                    HealthCardInfo info2 = new HealthCardInfo();
                    info2.setUserEmail(email);
                    info2.setCardLink(url3);
                    DatabaseServiceLocal databaseServiceLocal = DatabaseServiceLocal.getInstance(context);
                    databaseServiceLocal.insertCardInfo(info2);

                    return email;
                }

                return url3;

            } else {
                return new String("Fail:" + responseCode);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return new String("Exception:" + e.getMessage());
        }
    }

    public static String uploadHealthCarService( Context context , String mEmail , String mPassword, String imageString)
    {

        try {



            URL url = new URL("http://mywaitime.com/uploadimage.php"); // here is your URL path

            JSONObject postDataParams = new JSONObject();

            postDataParams.put("password", mPassword);
            postDataParams.put("email", mEmail);
            postDataParams.put("extension", "png");
            postDataParams.put("image", imageString);

            postDataParams.put("pass_email", mPassword);


               Log.e("HealthCard",postDataParams.toString());

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setReadTimeout(15000 /* milliseconds */);
            conn.setConnectTimeout(15000 /* milliseconds */);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);

            OutputStream os = conn.getOutputStream();
            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(os, "UTF-8"));
            writer.write(getPostDataString(postDataParams));

            writer.flush();
            writer.close();
            os.close();

            int responseCode=conn.getResponseCode();

            if (responseCode == HttpsURLConnection.HTTP_OK) {

                BufferedReader in=new BufferedReader(
                        new InputStreamReader(
                                conn.getInputStream()));
                StringBuffer sb = new StringBuffer("");
                String line="";

                while((line = in.readLine()) != null) {

                    sb.append(line);
                    break;
                }

                in.close();
                Log.i("uploadingImage",sb.toString());
                JSONObject jsnobject = new JSONObject(sb.toString());

                String status = jsnobject.getString("status");


                if (status.equalsIgnoreCase("success"))
                {

                    String link = jsnobject.getString("url");
                    String email = jsnobject.getString("email");

                    HealthCardInfo info = new HealthCardInfo();
                    info.setCardLink(link);
                    info.setUserEmail(email);
                    DatabaseServiceLocal database =  DatabaseServiceLocal.getInstance(context);
                    database.insertCardInfo(info);
                }

                return status;

            }
            else {
                return new String("Fail:"+responseCode);
            }
        }
        catch(Exception e){
            return new String("Exception:" + e.getMessage());
        }
        //return null;
    }



    public static String getPostDataString(JSONObject params) throws Exception {

        StringBuilder result = new StringBuilder();
        boolean first = true;

        Iterator<String> itr = params.keys();

        while(itr.hasNext()){

            String key= itr.next();
            Object value = params.get(key);

            if (first)
                first = false;
            else
                result.append("&");

            result.append(URLEncoder.encode(key, "UTF-8"));
            result.append("=");
            result.append(URLEncoder.encode(value.toString(), "UTF-8"));

        }
        return result.toString();
    }


    public String getStringFromJsonObject(JSONObject jo, String cellName){
        try{
            String string =  jo.getString(cellName);
            if(string == null){
                return "";
            }

            return string;
        }catch (Exception e){
            return "";
        }
    }

    public static String streamToString(InputStream is) throws IOException {
        StringBuilder sb = new StringBuilder();
        BufferedReader rd = new BufferedReader(new InputStreamReader(is));
        String line;
        while ((line = rd.readLine()) != null) {
            sb.append(line);
        }
        return sb.toString();
    }
    public int getIntFromJsonObject(JSONObject jo, String cellName){
        try{
            return Integer.parseInt(jo.getString(cellName));
        }catch (Exception e){
            return 0;
        }
    }

}
