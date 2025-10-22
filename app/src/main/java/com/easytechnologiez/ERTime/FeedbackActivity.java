package com.easytechnologiez.ERTime;

import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RatingBar;
import android.widget.TextView;

import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
// import com.google.android.gms.ads.interstitial.InterstitialAd;

import java.util.ArrayList;

public class FeedbackActivity extends AppCompatActivity implements  View.OnClickListener{
    //Spinner spinner;
    EditText wait;
    EditText comment;
    TextView min;
    TextView TitleView;
    RatingBar ratingBar;
    // InterstitialAd interstitialAd;
    ArrayList<String> listdata = new ArrayList<String>();
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_feedback);

        // interstitialAd = new InterstitialAd(this); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.setAdUnitId(getString(R.string.admob_interstitial_id)); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.loadAd(new AdRequest.Builder().build()); // TODO: Fix InterstitialAd for new Google Ads API
        TitleView = (TextView) findViewById(R.id.title);
        wait = (EditText) findViewById(R.id.wait);
        comment = (EditText) findViewById(R.id.comment);
        ratingBar = (RatingBar) findViewById(R.id.ratingBar);
        min = (TextView) findViewById(R.id.min);

        Button dd = (Button) findViewById(R.id.click);

       final AdView adView = (AdView) findViewById(R.id.Ads);
        adView.loadAd(new AdRequest.Builder().build());
        adView.setAdListener(new AdListener(){
            @Override
            public void onAdLoaded() {
                super.onAdLoaded();
                adView.setVisibility(View.VISIBLE);
            }
        });
        Intent intent = getIntent();

        if (intent != null)
        {
            String hospital = intent.getExtras().getString("hospital");
            TitleView.setText(hospital);
            Float wait1 = intent.getExtras().getFloat("wait");
            String comment1 = intent.getExtras().getString("comment");
            Float rating = intent.getExtras().getFloat("rating");

            if (wait1 != null)
            {
                wait.setText(wait1+"");
            }
            if (comment1 != null)
            {
                comment.setText(comment1);
            }
            if (rating >0)
            {
                ratingBar.setRating(rating);
            }


        }
        dd.setOnClickListener(this);
       // wait.setVisibility(View.GONE);
       // spinner.setVisibility(View.GONE);
       // comment.setVisibility(View.GONE);
      //  min.setVisibility(View.GONE);
        Typeface tf2 = Typeface.createFromAsset(getAssets(), "Raleway-SemiBold.ttf");
        wait.setTypeface(tf2);
        comment.setTypeface(tf2);
        min.setTypeface(tf2);

      //  int radious = 1500;
      ///  FindPlacesTask task = new FindPlacesTask(this,radious,this);
      //  task.execute();
    }
/*
    @Override
    public void OnDataComplete(ArrayList<PlaceData> placeData) {

        if (placeData != null && placeData.size()>0)
        {

            for (int i=0;i<placeData.size();i++)
            {
                listdata.add(placeData.get(i).getName());
                Log.i("Place Name","\n"+placeData.get(i).getName());

            }

            listdata.add("Other");

            SpinnerAdapter adapter = new SpinnerAdapter(this,listdata);
            spinner.setAdapter(adapter);
            wait.setVisibility(View.VISIBLE);
            // spinner.setVisibility(View.GONE);
            comment.setVisibility(View.VISIBLE);
            min.setVisibility(View.VISIBLE);

            spinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

                @Override
                public void onItemSelected(AdapterView<?> arg0, View arg1,
                                           int position, long arg3) {
                    PreferenceManager.getDefaultSharedPreferences(FeedbackActivity.this).edit().putString("hospital",listdata.get(position)).commit();

                }

                @Override
                public void onNothingSelected(AdapterView<?> arg0) {
                    // TODO Auto-generated method stub

                }
            });
        }
    }*/


    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.click)
        {

            String hospitalName = TitleView.getText().toString();
            String waitTime = wait.getText().toString();
            String rating = String.valueOf( ratingBar.getRating());
            String feedback = comment.getText().toString();

            FeedbackTask task = new FeedbackTask(this,feedback,waitTime,hospitalName,rating);
            task.execute();

        }
    }


    @Override
    public void onBackPressed() {
        super.onBackPressed();
        // if (interstitialAd != null && interstitialAd.isLoaded()){ // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.show(); // TODO: Fix InterstitialAd for new Google Ads API
        // }
    }
}
