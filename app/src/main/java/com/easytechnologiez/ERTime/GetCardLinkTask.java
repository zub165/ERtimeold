package com.easytechnologiez.ERTime;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.AsyncTask;

import com.easytechnologiez.ERTime.camera.ShowDownloadImage;
import com.easytechnologiez.ERTime.utils.UserInfo;

public class GetCardLinkTask extends AsyncTask<Void,Void,String> {


    private ProgressDialog dialog;
    private final UserInfo info;
    private final Context context;
    ShowDownloadImage showDownloadImage;

    GetCardLinkTask(Context context , ShowDownloadImage image) {
        this.context = context;
        showDownloadImage = image;
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
            string = DataServices.DownloadHealthCardLink(context,info);
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
       // Toast.makeText(context,success,Toast.LENGTH_SHORT).show();

        if (success != null && success.equalsIgnoreCase(info.getmEmail())) {

            showDownloadImage.showLink(1);
        } else {
            showDownloadImage.showLink(2);
        }
    }

    @Override
    protected void onCancelled() {

    }

}
