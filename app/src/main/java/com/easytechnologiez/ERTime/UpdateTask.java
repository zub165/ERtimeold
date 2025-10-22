package com.easytechnologiez.ERTime;

import android.content.Context;
import android.os.AsyncTask;
import androidx.appcompat.app.AlertDialog;
import android.widget.TextView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.UserInfo;
import com.easytechnologiez.ERTime.utils.Utils;

import org.json.JSONException;
import org.json.JSONObject;

public class UpdateTask extends AsyncTask<Void, Void,String>
{

    int position;
    String userData;
    AlertDialog dialog;
    Context context;
    UserInfo user;
    TextView mTextView;
    UpdateTask(Context context, int positon , String text , AlertDialog dialog , TextView mView)
    {
        position = positon;
        userData = text;
        this.dialog = dialog;
        this.context = context;
        user =  DatabaseServiceLocal.getInstance(context).retriveUserInfo();
        mTextView = mView;
    }
    @Override
    protected String doInBackground(Void... voids) {

        if (position ==0 )
        {
            String status = DataServices.UpdateFirstName(user, userData);
            try {
                JSONObject object = new JSONObject(status);
                String string = object.getString("status");

                if (string.equalsIgnoreCase("success"))
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    user.setmFirstName(userData);
                    local.insertUserInfo(user);
                }

                return string;
            }catch (JSONException e){e.printStackTrace();return null;}
        }else if (position == 1)
        {
            String status = DataServices.UpdateLastName(user, userData);
            try {
                JSONObject object = new JSONObject(status);
                String string = object.getString("status");

                if (string.equalsIgnoreCase("success"))
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    user.setmLastName(userData);
                    local.insertUserInfo(user);
                }

                return string;
            }catch (JSONException e){e.printStackTrace();return null;}
        }else if (position == 4)
        {
            String status = DataServices.UpdateHeight(user, userData);
            try {
                JSONObject object = new JSONObject(status);
                String string = object.getString("status");

                if (string.equalsIgnoreCase("success"))
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    user.setmHeight(userData);
                    local.insertUserInfo(user);
                }

                return string;
            }catch (JSONException e){e.printStackTrace();return null;}
        }else if (position == 5)
        {
            String status = DataServices.UpdateWeight(user, userData);
            try {
                JSONObject object = new JSONObject(status);
                String string = object.getString("status");

                if (string.equalsIgnoreCase("success"))
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    user.setmWieght(userData);
                    local.insertUserInfo(user);
                }

                return string;
            }catch (JSONException e){e.printStackTrace();return null;}
        }else if (position == 6)
        {
            String status = DataServices.Updateblood(user, userData);
            try {
                JSONObject object = new JSONObject(status);
                String string = object.getString("status");
                if (string.equalsIgnoreCase("success"))
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    user.setmBloodGroup(userData);
                    local.insertUserInfo(user);
                }
                return string;
            }catch (JSONException e){e.printStackTrace();return null;}
        }else if (position == 7)
        {
            String status = DataServices.Updatepassword(user, userData);
            try {
                JSONObject object = new JSONObject(status);
                String string = object.getString("status");
                if (string.equalsIgnoreCase("success"))
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    user.setmPassword(Utils.encryptedPassword(user.getmEmail(), userData));
                    local.insertUserInfo(user);
                }
                return string;
            }catch (JSONException e){e.printStackTrace();return null;}
        }

        return null;
    }

    @Override
    protected void onPostExecute(String s) {
        super.onPostExecute(s);

        if (dialog != null && dialog.isShowing())
        {
            dialog.dismiss();
        }
        if (s != null && s.equalsIgnoreCase("success"))
        {
            Toast.makeText(context,"Successfully update",Toast.LENGTH_LONG).show();
            if (mTextView != null)
            {
                if (position == 4)
                {
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    UserInfo info = local.retriveUserInfo();
                    mTextView.setText(info.getmHeight());
                }else if (position ==5){
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    UserInfo info = local.retriveUserInfo();
                    mTextView.setText(info.getmWieght());
                }else if (position == 6){
                    DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
                    UserInfo info = local.retriveUserInfo();
                    mTextView.setText(info.getmBloodGroup());
                }
            }
            //getData();
        }else{
            Toast.makeText(context,"Update failed",Toast.LENGTH_LONG).show();
        }
    }

}
