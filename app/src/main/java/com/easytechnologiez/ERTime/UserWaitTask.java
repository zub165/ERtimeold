package com.easytechnologiez.ERTime;

import android.content.Context;
import android.os.AsyncTask;
import android.os.Handler;
import android.util.Log;

import com.easytechnologiez.ERTime.utils.FeedbackResponse;

import location.data.PlaceInfo;

public class UserWaitTask extends AsyncTask<Void,Void,FeedbackResponse>
{

    Context context;
    //  String mEmail;
    //   String mPassword;
    String mHospital;
    UserWaitListener listener;
    PlaceInfo info;
    //HttpURLConnection conn = null;
    Handler mHandler;
    UserWaitTask(Context context   ,  UserWaitListener listener2, PlaceInfo placeInfo )
    {
        this.context = context;
        //  this.mEmail = email;
        //  this.mPassword = password;
        this.mHospital = placeInfo.getmPlaceName();
        this.listener = listener2;
        this.info = placeInfo;
        mHandler = new Handler();
    }

    @Override
    protected void onPreExecute() {
        super.onPreExecute();
    }



    @Override
    protected FeedbackResponse doInBackground(Void... voids) {

     /* final  FeedbackResponse feedbackResponse = new FeedbackResponse();
        //  HttpURLConnection conn = null;

                try {

                    URL url = new URL("http://mywaitime.com/averagefeedback.php"); // here is your URL path

                    JSONObject postDataParams = new JSONObject();

                    // postDataParams.put("pass_email", Utils.encryptedPassword(mEmail, mPassword));
                    // postDataParams.put("email", mEmail);
                    postDataParams.put("hospital", mHospital);
                    // Log.e("params", postDataParams.toString());

                    conn = (HttpURLConnection) url.openConnection();
                    conn.setReadTimeout(15000);
                    conn.setConnectTimeout(15000);
                    conn.setRequestMethod("POST");
                    conn.setFixedLengthStreamingMode(DataServices.getPostDataString(postDataParams).length());
                    // conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

                    //conn.setRequestProperty("Connection", "close");
                    conn.setDoInput(true);
                    conn.setDoOutput(true);

                    OutputStream os = conn.getOutputStream();
                    BufferedWriter writer = new BufferedWriter(
                            new OutputStreamWriter(os, "UTF-8"));
                    writer.write(DataServices.getPostDataString(postDataParams));

                    writer.flush();
                    writer.close();
                    os.close();
                }catch (Exception e){e.printStackTrace();}


                    try{

                    int responseCode = conn.getResponseCode();

                    if (responseCode == HttpsURLConnection.HTTP_OK) {

                        BufferedReader in = new BufferedReader(
                                new InputStreamReader(
                                        conn.getInputStream()));
                        StringBuffer sb = new StringBuffer("");
                        String line = "";

                        ArrayList<FeedbackInfo> infoList = new ArrayList<FeedbackInfo>();

                        while ((line = in.readLine()) != null) {

                            sb.append(line);
                           // break;
                        }


                        in.close();
                        JSONArray array = new JSONArray(sb.toString());

                        Log.i("Average" , sb.toString());

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
                                break;

                            }else {
                                String email1 = object.getString("email");
                                String hospital = object.getString("hospital");
                                String rating = object.getString("rating");
                                String feedback_text = object.getString("feedback_text");
                                String wait_time = object.getString("wait_time");

                                float ratingnew = Float.parseFloat(rating);
                                FeedbackInfo info = new FeedbackInfo();
                                info.setComments(feedback_text);
                                info.setRating(ratingnew);
                                info.setWaitTime(Float.parseFloat(wait_time));
                                info.setEmail(email1);
                                info.setHospital(hospital);
                                infoList.add(info);
                            }


                        }

                        feedbackResponse.setFeedbackInfos(infoList);
                        return feedbackResponse;

                        //  Toast.makeText(context,jsnobject.toString(),Toast.LENGTH_SHORT).show();


                    } else {
                        BufferedReader in = new BufferedReader(
                                new InputStreamReader(
                                        conn.getErrorStream()));
                        StringBuffer sb = new StringBuffer("");
                        String line = "";

                        ArrayList<FeedbackInfo> infoList = new ArrayList<FeedbackInfo>();

                        while ((line = in.readLine()) != null) {

                            sb.append(line);
                            // break;
                        }


                        in.close();
                        feedbackResponse.setmMessage(sb.toString());
                        feedbackResponse.setmStatus("fail");
                        info.setUserWaitAvaliable(false);
                        return feedbackResponse;
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    feedbackResponse.setmMessage("Exception is occour");
                    feedbackResponse.setmStatus("fail");
                    return feedbackResponse;
                } finally {
                    if (conn != null)
                    {
                        conn.disconnect();
                    }
                }

*/

     FeedbackResponse response =   DataServices.AverageUserWaitMethod(mHospital);
     /*try {
         Thread.sleep(5000);
     }catch (Exception e){e.printStackTrace();}*/

     return  response;

    }

    @Override
    protected void onPostExecute(FeedbackResponse infos) {
        super.onPostExecute(infos);


        if (infos != null && infos.getmStatus() !=null)
        {
         //   Toast.makeText(context,infos.getmMessage(), Toast.LENGTH_SHORT).show();
            info.setUserWaitAvaliable(false);
            Log.i("TAG",infos.getmMessage());
            listener.onEmpty(info);
        }else if (infos != null && infos.getFeedbackInfos() != null){

            if (infos.getFeedbackInfos().size()>0) {
                Float wait = infos.getFeedbackInfos().get(0).getWaitTime();
                //Toast.makeText(context,infos.getFeedbackInfos().toString(), Toast.LENGTH_SHORT).show();
                Log.i("TAG", "" + wait);
                info.setmUserWait(wait + " min");
                info.setUserWaitAvaliable(false);
                listener.onWait(info);
            }else{
                info.setUserWaitAvaliable(false);
                listener.onEmpty(info);
            }

        }

    }
}
