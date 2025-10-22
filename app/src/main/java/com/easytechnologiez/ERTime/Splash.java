package com.easytechnologiez.ERTime;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.preference.PreferenceManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.appcompat.app.AppCompatActivity;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.TypefaceSpan;
import android.widget.TextView;

import com.easytechnologiez.ERTime.utils.Utils;

import static com.easytechnologiez.ERTime.utils.Utils.PERMISSIONS;
import static com.easytechnologiez.ERTime.utils.Utils.PERMISSION_ALL;

public class Splash extends AppCompatActivity {

    Handler timer;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        //getWindow().requestFeature(Window.FEATURE_CONTENT_TRANSITIONS);
        setContentView(R.layout.activity_splash);

      /*  ImageView imageView = (ImageView) findViewById(R.id.icon);
        imageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                v.startAnimation(AnimationUtils.loadAnimation(Splash.this,R.anim.bounce));
            }
        });*/

        String locale = getResources().getConfiguration().locale.getCountry();

        if (locale.equalsIgnoreCase("GB") || locale.equalsIgnoreCase("US"))
        {
            String distance_unit = "mile";
            String height_unit = "cm";
            String weight_unit = "lbs";
           SharedPreferences.Editor editor =  PreferenceManager.getDefaultSharedPreferences(this).edit();
           editor.putString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY, distance_unit);
           editor.putString(Utils.SHARED_PREFERENCE_HEIGHT_UNIT_KEY, height_unit);
           editor.putString(Utils.SHARED_PREFERENCE_WEIGHT_UNIT_KEY,weight_unit);
           editor.commit();

        }else{
            String distance_unit = "km";
            String height_unit = "in";
            String weight_unit = "kg";
            SharedPreferences.Editor editor =  PreferenceManager.getDefaultSharedPreferences(this).edit();
            editor.putString(Utils.SHARED_PREFERENCE_DISTANCE_UNIT_KEY, distance_unit);
            editor.putString(Utils.SHARED_PREFERENCE_HEIGHT_UNIT_KEY, height_unit);
            editor.putString(Utils.SHARED_PREFERENCE_WEIGHT_UNIT_KEY,weight_unit);
            editor.commit();
        }

        TypefaceSpan typefaceSpan = new TypefaceSpan("Kaushan.otf");
        SpannableString str = new SpannableString(getString(R.string.app_name));
        str.setSpan(typefaceSpan,0, str.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);


        if (getSupportActionBar() != null) {
            getSupportActionBar().setElevation(0);
            getSupportActionBar().setTitle(str);
        }

        timer = new Handler();

        TextView textView = (TextView) findViewById(R.id.title);
        Typeface tf = Typeface.createFromAsset(getAssets(), "Kaushan.otf");
      //  Utils.mayRequestLocation(this);
        textView.setTypeface(tf);

        if (Utils.mayRequestLocation(this)) {

            if (timer == null)
            {
                timer = new Handler();
            }
            timer.postDelayed(runnable, 2500);
        }else{
            ActivityCompat.requestPermissions(this, PERMISSIONS, PERMISSION_ALL);
        }
    }


    Runnable runnable = new Runnable() {
        @Override
        public void run() {
            // Skip user info check and go directly to MainActivity
            Intent mainIntent = new Intent(Splash.this, MainActivity.class);
            mainIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(mainIntent);
            finish();
        }
    };


    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        if (requestCode == PERMISSION_ALL) {

            for (int i=0;i<grantResults.length;i++)
            {
                if (grantResults[i] == PackageManager.PERMISSION_GRANTED){
                    if (timer == null)
                    {
                        timer = new Handler();
                    }
                    timer.postDelayed(runnable, 800);
                }
               // populateAutoComplete();
            }
        }


    }


}
