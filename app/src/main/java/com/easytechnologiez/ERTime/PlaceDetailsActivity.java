package com.easytechnologiez.ERTime;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.preference.PreferenceManager;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import android.text.SpannableString;
import android.text.method.LinkMovementMethod;
import android.text.style.UnderlineSpan;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.RatingBar;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.utils.FeedbackInfo;
import com.easytechnologiez.ERTime.utils.UserInfo;
import com.easytechnologiez.ERTime.utils.Utils;
import com.google.android.gms.ads.AdRequest;
// import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;

import java.util.ArrayList;

import location.data.PlaceData;
import location.data.PlaceInfo;
public class PlaceDetailsActivity extends AppCompatActivity implements GetPlaceListener,ViewFeedbackListener ,View.OnClickListener,OnMapReadyCallback{
    TextView phone;
    TextView name;
  //  TextView icon;
    ImageView iconImage;
    TextView url;
    TextView address;
    ProgressBar progress;
    Button feedbackButton;
    RelativeLayout feedbackLayout;
    RelativeLayout averageLayout;
   // TextView location;
    PlaceInfo mPlaceInfo;
    // InterstitialAd interstitialAd;
    GoogleMap map;
    SupportMapFragment    mapFragment;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_place_details);

         phone = (TextView) findViewById(R.id.place_phone);
         name = (TextView) findViewById(R.id.place_name);
         progress = (ProgressBar) findViewById(R.id.progressBar);
         url = (TextView) findViewById(R.id.place_url);
         address = (TextView) findViewById(R.id.place_address);
         feedbackButton = (Button) findViewById(R.id.click);
         feedbackLayout = (RelativeLayout) findViewById(R.id.feedback_layout);
         averageLayout = (RelativeLayout) findViewById(R.id.feedback_layout_avg);
       //  location = (TextView) findViewById(R.id.place_location);

        Typeface tf1 = Typeface.createFromAsset(getAssets(), "Raleway-Regular.ttf");
        Typeface tf2 = Typeface.createFromAsset(getAssets(), "Raleway-SemiBold.ttf");


        phone.setTypeface(tf1);
        name.setTypeface(tf1);
        url.setTypeface(tf1);
        address.setTypeface(tf1);
        feedbackButton.setTypeface(tf1);

        // interstitialAd = new InterstitialAd(this); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.setAdUnitId(getString(R.string.admob_interstitial_id)); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.loadAd(new AdRequest.Builder().build()); // TODO: Fix InterstitialAd for new Google Ads API


         url.setOnClickListener(this);
         feedbackButton.setOnClickListener(this);
        address.setMovementMethod(LinkMovementMethod.getInstance());
         address.setOnClickListener(this);
         iconImage = (ImageView) findViewById(R.id.PlaceIcon);
    //    icon = (TextView) findViewById(R.id.place_icon);

            mapFragment = (SupportMapFragment) getSupportFragmentManager().findFragmentById(R.id.map);




         if (getSupportActionBar() != null)
         {
             getSupportActionBar().setElevation(0);
         }

        Intent intent = getIntent();
        if (intent != null)
        {
           String placeId = intent.getExtras().getString("place_id");
           PlaceDetailsTask task = new PlaceDetailsTask(this,placeId,this);
           task.execute();
        }
        mapFragment.getMapAsync(this);

    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.place_url)
        {
            if (mPlaceInfo.getmPlaceWebsite().equalsIgnoreCase("Not found"))
            {
                Toast.makeText(PlaceDetailsActivity.this , "Website not found",Toast.LENGTH_SHORT).show();
            }else {
                Intent intent = new Intent(PlaceDetailsActivity.this, WebActivity.class);
                intent.putExtra("url", mPlaceInfo.getmPlaceWebsite());
                startActivity(intent);
            }
        }else if (v.getId() == R.id.place_address)
        {
            PlaceInfo info  = (PlaceInfo) v.getTag();
            if (info != null) {

             //   https://www.google.com/maps/search/?api=1&query=Eiffel%20Tower&query_place_id=ChIJLU7jZClu5kcR4PcOOO6p3I0

                String name = info.getmPlaceName();
                name.replaceAll(" ","%20");
                String url = "https://www.google.com/maps/search/?api=1&query="+name+"&query_place_id="+info.getmPlaceId();
                Log.i("Address : ",url);
                Uri gmmIntentUri = Uri.parse(url);
                Intent mapIntent = new Intent(Intent.ACTION_VIEW, gmmIntentUri);
                mapIntent.setPackage("com.google.android.apps.maps");
                if (mapIntent.resolveActivity(getPackageManager()) != null) {
                    startActivity(mapIntent);
                }
            }
        }else if (v.getId() == R.id.map)
        {
            PlaceInfo info  = (PlaceInfo) v.getTag();
            if (info != null) {



                String name = info.getmPlaceName();
                name.replaceAll(" ","%20");
                String url = "https://www.google.com/maps/search/?api=1&query="+name+"&query_place_id="+info.getmPlaceId();
                Log.i("Address : ",url);
                Uri gmmIntentUri = Uri.parse(url);
                Intent mapIntent = new Intent(Intent.ACTION_VIEW, gmmIntentUri);
                mapIntent.setPackage("com.google.android.apps.maps");
                if (mapIntent.resolveActivity(getPackageManager()) != null) {
                    startActivity(mapIntent);
                }
            }
        }else if (v.getId() == R.id.edit_rating)
        {
            FeedbackInfo info = (FeedbackInfo) v.getTag();
            Intent intent = new Intent(this,FeedbackActivity.class);
            intent.putExtra("wait",  info.getWaitTime());
            intent.putExtra("hospital",mPlaceInfo.getmPlaceName());
            intent.putExtra("rating",(Float)info.getRating());
            intent.putExtra("comment",info.getComments());
            startActivityForResult(intent,Utils.REQUEST_FEEDBACK_UPDATE_FOR_RESULT);
        }else if (v.getId() == R.id.click){
            UserInfo database = DatabaseServiceLocal.getInstance(PlaceDetailsActivity.this).retriveUserInfo();
            if (database != null && database.getmEmail() !=null) {
                Intent intent = new Intent(PlaceDetailsActivity.this, FeedbackActivity.class);
                intent.putExtra("hospital", mPlaceInfo.getmPlaceName());
                startActivityForResult(intent,Utils.REQUEST_FEEDBACK_UPDATE_FOR_RESULT);
            }else{
                Intent intent = new Intent(PlaceDetailsActivity.this, LoginActivity.class);
                intent.putExtra("hospital", mPlaceInfo.getmPlaceName());
                startActivity(intent);
            }
        }
    }

    @Override
    public void onMapReady(GoogleMap googleMap) {
        map = googleMap;
        map.setInfoWindowAdapter(new GoogleMap.InfoWindowAdapter() {

            @Override
            // Return null here, so that getInfoContents() is called next.
            public View getInfoWindow(Marker arg0) {
                return null;
            }

            @Override
            public View getInfoContents(Marker marker) {
                // Inflate the layouts for the info window, title and snippet.
                View infoWindow = getLayoutInflater().inflate(R.layout.custom_info_window,
                        (FrameLayout) findViewById(R.id.map), false);

                TextView title = ((TextView) infoWindow.findViewById(R.id.title));
                title.setText(marker.getTitle());

                TextView snippet = ((TextView) infoWindow.findViewById(R.id.snippet));
                snippet.setText(marker.getSnippet());

                return infoWindow;
            }
        });
        map.animateCamera(CameraUpdateFactory.newLatLng(new LatLng(35.25,28.4562)));
    }

 /*   @Override
    public void showImage(Bitmap bitmap) {
        if (bitmap != null)
        {
            if (iconImage != null)
            {
                iconImage.setImageBitmap(bitmap);
            }
        }
    }*/

    @Override
    public void OnItemComplete(PlaceInfo placeData) {

        mPlaceInfo=placeData;
        phone.setText(placeData.getmPlacePhone());
        name.setText(placeData.getmPlaceName());
      //  feedbackButton.setTag(placeData.getmPlaceName());
    //    icon.setText(placeData.getmPlaceIcon());
        UserInfo database = DatabaseServiceLocal.getInstance(this).retriveUserInfo();

       // address.setText(placeData.getmPlaceAddress());
        SpannableString content = new SpannableString(placeData.getmPlaceAddress());
        content.setSpan(new UnderlineSpan(), 0, content.length(), 0);
        address.setText(content);
        url.setText(placeData.getmPlaceWebsite());
      //  location.setText(placeData.getmError());
        address.setTag(placeData);

        if (map != null)
        {
            map.addMarker(new MarkerOptions().title(placeData.getmPlaceName()).position(new LatLng(Double.parseDouble(placeData.getmPlaceLatitude()),Double.parseDouble(placeData.getmPlaceLongitude()))));
            map.animateCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(Double.parseDouble(placeData.getmPlaceLatitude()),Double.parseDouble(placeData.getmPlaceLongitude())), 15));
        }

      //  placeId.setText(placeData.getmPlaceId());
      //  DownlaodImage image = new DownlaodImage(this , this);
       // image.execute(placeData.getmPlaceIcon());

        if (database.getmEmail() != null) {
            AverageRatingTask task = new AverageRatingTask(this, database.getmEmail(), placeData.getmPlaceName(), this ,placeData);
            task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
        }else{
            feedbackButton.setVisibility(View.VISIBLE);
            feedbackLayout.setVisibility(View.GONE);
           UserWaitTaskForDetailsActivity user = new UserWaitTaskForDetailsActivity(this,this,placeData);
           user.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
        }

      /*  if (database != null && database.getmEmail() != null)
        {
            AverageRatingTask task = new AverageRatingTask(this,database.getmEmail(),placeData.getmPlaceName(),database.getmPassword(),this);
            task.execute();
        }else {

            showFeedbackButton();
        }*/

    }

    @Override
    public void onError() {
        Toast.makeText(this,"Something went wrong",Toast.LENGTH_SHORT).show();
    }

    @Override
    public void OnDataComplete(ArrayList<PlaceData> placeData) {

    }

    @Override
    public void showFeedbackButton() {

        if (progress != null)
        {
            progress.setVisibility(View.GONE);
        }

        if (feedbackButton != null)
        {
            feedbackButton.setVisibility(View.VISIBLE);

        }

        if (feedbackLayout != null)
        {
            feedbackLayout.setVisibility(View.GONE);
        }
    }

    @Override
    public void showAverage(PlaceInfo info) {

        if (progress != null)
        {
            progress.setVisibility(View.GONE);
        }
      /*  if (feedbackLayout != null)
        {
            feedbackLayout.setVisibility(View.GONE);
        }
        if (feedbackButton != null)
        {

            feedbackButton.setVisibility(View.VISIBLE);
            feedbackButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    UserInfo database = DatabaseServiceLocal.getInstance(PlaceDetailsActivity.this).retriveUserInfo();
                    if (database != null && database.getmEmail() !=null) {
                        Intent intent = new Intent(PlaceDetailsActivity.this, FeedbackActivity.class);
                        intent.putExtra("hospital", mPlaceInfo.getmPlaceName());
                        startActivityForResult(intent,Utils.REQUEST_FEEDBACK_UPDATE_FOR_RESULT);
                    }else{
                        Intent intent = new Intent(PlaceDetailsActivity.this, LoginActivity.class);
                        intent.putExtra("hospital", mPlaceInfo.getmPlaceName());
                        startActivity(intent);
                    }
                }
            });
        }*/

        if (averageLayout != null)
        {

            averageLayout.setVisibility(View.VISIBLE);
            TextView wait = (TextView) averageLayout.findViewById(R.id.min_avg);
            RatingBar rating = (RatingBar) averageLayout.findViewById(R.id.ratingBar_avg);
           // TextView comment = (TextView) averageLayout.findViewById(R.id.comment_avg);
           /* FeedbackInfo last = infos.get(infos.size()-1);
            if (last != null)
            {
                comment.setText(last.getComments());
            }
*/
            rating.setRating(info.getmRating());
            wait.setText( info.getmUserWait());
        }

    }

    @Override
    public void showMineRating(FeedbackInfo info) {

        if (progress != null)
        {
            progress.setVisibility(View.GONE);
        }
        if (feedbackButton != null)
        {
            feedbackButton.setVisibility(View.GONE);
        }

        if (feedbackLayout != null)
        {
            feedbackLayout.setVisibility(View.VISIBLE);
            TextView wait = (TextView) feedbackLayout.findViewById(R.id.min);
            RatingBar rating = (RatingBar) feedbackLayout.findViewById(R.id.ratingBar);
            TextView comment = (TextView) feedbackLayout.findViewById(R.id.comment);
            TextView edit = (TextView) feedbackLayout.findViewById(R.id.edit_rating);
            DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(this);
            edit.setOnClickListener(this);
           // UserInfo info = local.retriveUserInfo();

            if (info != null) {
                wait.setText(info.getWaitTime() + "min");
                rating.setRating((int) info.getRating());
                comment.setText(info.getComments());
                edit.setTag(info);
            }






        }
       /* if (averageLayout != null){
            averageLayout.setVisibility(View.VISIBLE);
            TextView wait = (TextView) averageLayout.findViewById(R.id.min_avg);
            RatingBar rating = (RatingBar) averageLayout.findViewById(R.id.ratingBar_avg);
            TextView comment = (TextView) averageLayout.findViewById(R.id.comment_avg);
            FeedbackInfo last = infos.get(infos.size()-1);
            if (last != null)
            {
                comment.setText(last.getComments());
            }

            rating.setRating(Utils.AverageRating(infos));
            wait.setText(Utils.AverageWaitTime(infos)+"Min");

        }*/


    }


    @Override
    public void onBackPressed() {
        super.onBackPressed();
        // if (interstitialAd != null && interstitialAd.isLoaded()) // TODO: Fix InterstitialAd for new Google Ads API
        {
        // interstitialAd.show(); // TODO: Fix InterstitialAd for new Google Ads API
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == Utils.REQUEST_FEEDBACK_UPDATE_FOR_RESULT) {
            if (resultCode == Utils.RESULT_FEEDBACK_SUCCESS_UPDATE_CODE) {
                String feedback = data.getStringExtra("feedback");
                if (feedback != null && feedback.equalsIgnoreCase("success")) {
                    UserInfo info = DatabaseServiceLocal.getInstance(this).retriveUserInfo();
                    AverageRatingTask task = new AverageRatingTask(this, info.getmEmail(), mPlaceInfo.getmPlaceName(), this ,mPlaceInfo);
                    task.execute();
                    SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(this);
                    pref.edit().putBoolean("FeedbackUpdate",true).commit();
                }
            }
        }
    }
}
