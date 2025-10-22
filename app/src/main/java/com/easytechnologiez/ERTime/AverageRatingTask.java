package com.easytechnologiez.ERTime;

import android.content.Context;
import android.os.AsyncTask;

import com.easytechnologiez.ERTime.utils.FeedbackInfo;
import com.easytechnologiez.ERTime.utils.FeedbackResponse;
import com.easytechnologiez.ERTime.utils.UserInfo;

import java.util.ArrayList;

import location.data.PlaceInfo;

public class AverageRatingTask extends AsyncTask<Void,Void,FeedbackResponse>
{

    Context context;
  //  String mEmail;
 //   String mPassword;
    String mHospital;
    String mEmail;
    ViewFeedbackListener listener;
    PlaceInfo mPlaceInfo;
    AverageRatingTask(Context context  , String email , String hospital , ViewFeedbackListener listener2 , PlaceInfo info)
    {
        this.context = context;
        this.mEmail = email;
      //  this.mPassword = password;
        this.mHospital = hospital;
        this.listener = listener2;
        this.mPlaceInfo=info;
    }

    @Override
    protected void onPreExecute() {
        super.onPreExecute();
    }



    @Override
    protected FeedbackResponse doInBackground(Void... voids) {
        return DataServices.MyRatingTask( mHospital,mEmail);

    }

    @Override
    protected void onPostExecute(FeedbackResponse infos) {
        super.onPostExecute(infos);

        UserWaitTaskForDetailsActivity user = new UserWaitTaskForDetailsActivity(context,listener,mPlaceInfo);
        user.executeOnExecutor(THREAD_POOL_EXECUTOR);
            if (infos != null && infos.getmStatus() !=null)
            {
                //Toast.makeText(context,infos.getmMessage(),Toast.LENGTH_SHORT).show();
                listener.showFeedbackButton();
            }else if (infos != null && infos.getFeedbackInfos() != null){

                if (infos.getFeedbackInfos().size()>0) {
                    listener.showMineRating(infos.getFeedbackInfos().get(0));
                }else{
                    listener.showFeedbackButton();
                }

            }

    }

    private boolean getMineRating(ArrayList<FeedbackInfo> list)
    {
        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
        UserInfo info = local.retriveUserInfo();
        for (int i=0;i<list.size();i++){

            FeedbackInfo feedbackInfo = list.get(i);
            if (info == null)
            {
                return false;
            }
            if (feedbackInfo.getEmail().equalsIgnoreCase(info.getmEmail())){
                return true;

            }
        }
        return false;
    }
}
