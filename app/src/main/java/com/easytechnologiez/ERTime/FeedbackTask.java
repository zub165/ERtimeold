package com.easytechnologiez.ERTime;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.UserInfo;
import com.easytechnologiez.ERTime.utils.Utils;

public class FeedbackTask extends AsyncTask <Void,Void,String> {



        private  ProgressDialog dialog;
        private final UserInfo info;
        private final String mFeedback;
        private final String mWait;
        private final String mHospital;
        private final String mRating;
        private final Context context;

    FeedbackTask(Context context, String mFeedback , String mWait , String mHospital , String mRating) {
            this.mHospital = mHospital;
            this.mFeedback = mFeedback;
            this.context = context;
            this.mWait = mWait;
            this.mRating = mRating;
            DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
             info = local.retriveUserInfo();
        }

    @Override
    protected void onPreExecute() {
        super.onPreExecute();
        dialog = new ProgressDialog(context);
        dialog.setCancelable(true);
        dialog.setMessage("Loading..");
        dialog.setCancelable(false);
        dialog.isIndeterminate();
        dialog.show();
    }

    @Override
        protected String doInBackground(Void... params) {
            // TODO: attempt authentication against a network service.

            String string = null;
            try {
                // Simulate network access.
                Thread.sleep(2000);
                string = DataServices.FeedbackMethod(context,mFeedback,mWait,mHospital,mRating,info);
            } catch (InterruptedException e) {
                return string;
            }



            // TODO: register the new account here.
            return string;
        }

        @Override
        protected void onPostExecute(final String success) {


        if (dialog != null && dialog.isShowing())
        {
            dialog.dismiss();
        }

            if (success != null && success.equalsIgnoreCase("success")) {

                Intent intent = new Intent();
                intent.putExtra("feedback",success);
                ((Activity)context).setResult(Utils.RESULT_FEEDBACK_SUCCESS_UPDATE_CODE,intent);
                ((Activity)context).finish();

                  Toast.makeText(context , success,Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(context , "Some error for feedback "+success,Toast.LENGTH_SHORT).show();
            }
        }

        @Override
        protected void onCancelled() {

        }

}
