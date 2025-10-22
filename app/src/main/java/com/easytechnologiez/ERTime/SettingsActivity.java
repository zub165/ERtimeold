package com.easytechnologiez.ERTime;

import android.content.Context;
import android.content.res.Configuration;
import android.graphics.Typeface;
import android.graphics.drawable.ColorDrawable;
import android.os.AsyncTask;
import android.os.Bundle;
import android.preference.PreferenceActivity;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.UserInfo;
import com.easytechnologiez.ERTime.utils.Utils;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
// import com.google.android.gms.ads.interstitial.InterstitialAd;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

/**
 * A {@link PreferenceActivity} that presents a set of application settings. On
 * handset devices, settings are presented as a single list. On tablets,
 * settings are split by category, with category headers shown to the left of
 * the list of settings.
 * <p>
 * See <a href="http://developer.android.com/design/patterns/settings.html">
 * Android Design: Settings</a> for design guidelines and the <a
 * href="http://developer.android.com/guide/topics/ui/settings.html">Settings
 * API Guide</a> for more information on developing a Settings UI.
 */
public class SettingsActivity extends AppCompatActivity  implements View.OnClickListener , AdapterView.OnItemClickListener{

    /**
     * A preference value change listener that updates the preference's summary
     * to reflect its new value.
     */


    /**
     * Helper method to determine if the device has an extra-large screen. For
     * example, 10" tablets are extra-large.
     */
    private static boolean isXLargeTablet(Context context) {
        return (context.getResources().getConfiguration().screenLayout
                & Configuration.SCREENLAYOUT_SIZE_MASK) >= Configuration.SCREENLAYOUT_SIZE_XLARGE;
    }

    /**
     * Binds a preference's summary to its value. More specifically, when the
     * preference's value is changed, its summary (line of text below the
     * preference title) is updated to reflect the value. The summary is also
     * immediately updated upon calling this method. The exact display format is
     * dependent on the type of preference.
     ***/
    UserInfo user;
    ArrayList <String> SettingDatalist = new ArrayList<String>();
    SettingAdapter listAdapter;
    ListView listView;
    // InterstitialAd interstitialAd;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setupActionBar();
        setContentView(R.layout.activity_setting);
         listView = (ListView) findViewById(R.id.setting_list);
       getData();

        AdView adView = (AdView) findViewById(R.id.Ads);
        adView.loadAd(new AdRequest.Builder().build());

        listView.setOnItemClickListener(this);
        // interstitialAd = new InterstitialAd(this); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.setAdUnitId(getString(R.string.admob_interstitial_id)); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.loadAd(new AdRequest.Builder().build()); // TODO: Fix InterstitialAd for new Google Ads API
    }

    /**
     * Set up the {@link android.app.ActionBar}, if the API is available.
     */
    private void setupActionBar() {
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            // Show the Up button in the action bar.
            actionBar.setDisplayHomeAsUpEnabled(true);
            actionBar.setHomeButtonEnabled(true);

        }
    }

    public void getData()
    {
        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(this);
        user = local.retriveUserInfo();
        if (SettingDatalist != null && SettingDatalist.size()>0)
        {
            SettingDatalist.clear();
        }
        SettingDatalist.add(user.getmFirstName());
        SettingDatalist.add(user.getmLastName());
        SettingDatalist.add(user.getmGender());
        SettingDatalist.add(user.getmEmail());
        SettingDatalist.add(user.getmHeight());
        SettingDatalist.add(user.getmWieght());
        SettingDatalist.add(user.getmBloodGroup());
        SettingDatalist.add(user.getmPassword());

       // SettingDatalist.add("Health Card");

        listAdapter = new SettingAdapter();
        listView.setAdapter(listAdapter);
    }

    @Override
    public void onClick(View v) {

        if (v.getId() == R.id.ok)
        {
            Utils.Holder text = (Utils.Holder) v.getTag();
            EditText editText = text.updatedData;
            String string = editText.getText().toString();
            if (string != null && !string.isEmpty())
            {
                int position  = (Integer) text.positon;
                UpdateTask task = new UpdateTask(position,string ,text.dialog);
                task.execute();

            }else{
             Toast.makeText(this,"Data is empty",Toast.LENGTH_SHORT).show();
            }
        }else if (v.getId() == R.id.cancel)
        {
            Utils.Holder dialog = (Utils.Holder) v.getTag();
            if (dialog != null && dialog.dialog.isShowing())
            {
                dialog.dialog.dismiss();
            }
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {


        switch (item.getItemId()) {
            case android.R.id.home:
                onBackPressed();
                return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        if ( position==3)
        {
            Toast.makeText(this , "Email cannot be changed",Toast.LENGTH_SHORT).show();
        }else if (position ==2){
            Toast.makeText(this , "Gender cannot be changed",Toast.LENGTH_SHORT).show();
        }else {
            showDialog(this, SettingDatalist.get(position), position);

        }
    }

    class SettingAdapter extends BaseAdapter{



        @Override
        public Object getItem(int position) {
            return SettingDatalist.get(position);
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {

            if (convertView == null)
            {
                convertView = getLayoutInflater().inflate(R.layout.setting_items , null);
            }

            TextView mTextView = (TextView) convertView.findViewById(R.id.item_title);
            TextView mTextViewLabel = (TextView) convertView.findViewById(R.id.item_title_lebel);
            ImageView icon = (ImageView) convertView.findViewById(R.id.icon);

            if (position == 2 || position == 3)
            {
                //icon.setVisibility(View.GONE);
                icon.setImageResource(R.drawable.ic_action_lock);

            }

            if (position == 0){
                mTextViewLabel.setText("FirstName");
            }else if (position == 1){
                mTextViewLabel.setText("LastName");
            }else if (position == 2){
                mTextViewLabel.setText("Gender");
            }else if (position == 3){
                mTextViewLabel.setText("Email");
            }else if (position == 4){
                mTextViewLabel.setText("Height");
            }else if (position == 5){
                mTextViewLabel.setText("Weight");
            }else if (position == 6){
                mTextViewLabel.setText("Blood");
            }else if (position == 7){
                mTextViewLabel.setText("Password");
            }else if (position == 8){
                mTextViewLabel.setText("");
            }

            if (position == 7)
            {
                String encryptedPassword = SettingDatalist.get(position);

                mTextView.setText(Utils.DecryptedPassword(encryptedPassword));
                mTextView.setTypeface(Typeface.createFromAsset(SettingsActivity.this.getAssets(), "Raleway-SemiBold.ttf"));

            }else {
                mTextView.setText(SettingDatalist.get(position));
                mTextView.setTypeface(Typeface.createFromAsset(SettingsActivity.this.getAssets(), "Raleway-SemiBold.ttf"));
            }

            return convertView;
        }

        @Override
        public int getCount() {
            return SettingDatalist.size();
        }

        @Override
        public long getItemId(int position) {
            return 0;
        }
    }




    public  void showDialog(Context context , String text , final int postion)
    {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        View mView = getLayoutInflater().inflate(R.layout.dialog_update,null);
        builder.setView(mView);
        EditText editText = (EditText) mView.findViewById(R.id.editName);
        if (postion == 7)
        {
            editText.setText(Utils.DecryptedPassword(text));
        }else {
            editText.setText(text);
        }
        Button ok = (Button) mView.findViewById(R.id.ok);

        Button cancel = (Button) mView.findViewById(R.id.cancel);

        ok.setOnClickListener(this);
        cancel.setOnClickListener(this);

        AlertDialog dialog = builder.create();
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.getWindow().setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
        Utils.Holder holder = new Utils.Holder();
        holder.dialog = dialog;
        holder.positon = postion;
        holder.updatedData = editText;
        cancel.setTag(holder);
        ok.setTag(holder);
        dialog.show();

    }

    class UpdateTask extends AsyncTask <Void, Void,String>
    {
        int position;
        String userData;
        AlertDialog dialog;
        UpdateTask( int positon , String text , AlertDialog dialog)
        {
            position = positon;
            userData = text;
            this.dialog = dialog;
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
                        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(SettingsActivity.this);
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
                        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(SettingsActivity.this);
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
                        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(SettingsActivity.this);
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
                        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(SettingsActivity.this);
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
                        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(SettingsActivity.this);
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
                        DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(SettingsActivity.this);
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
                Toast.makeText(SettingsActivity.this,"Successfully update",Toast.LENGTH_LONG).show();
                getData();
            }else{
                Toast.makeText(SettingsActivity.this,"Update failed",Toast.LENGTH_LONG).show();
            }
        }
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        // if (interstitialAd != null && interstitialAd.isLoaded()) // TODO: Fix InterstitialAd for new Google Ads API
        {
        // interstitialAd.show(); // TODO: Fix InterstitialAd for new Google Ads API
        }
    }
}
