package com.easytechnologiez.ERTime;

import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import androidx.core.content.FileProvider;
import androidx.appcompat.app.AppCompatActivity;
import android.util.Base64;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;

import com.easytechnologiez.ERTime.camera.ShowDownloadImage;
import com.easytechnologiez.ERTime.utils.HealthCardInfo;
import com.easytechnologiez.ERTime.utils.UserInfo;
import com.google.android.gms.ads.AdRequest;
// import com.google.android.gms.ads.interstitial.InterstitialAd;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;

public class CameraActivity extends AppCompatActivity implements ShowDownloadImage{

    String TAG = "ERWaitTime";
    ImageView mImageView;
    UploadingImages uploadingImages;
     Button upload;
     // InterstitialAd interstitialAd;
    private static final int REQUEST_CAPTURE_IMAGE = 100;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_camera);

        mImageView =(ImageView) findViewById(R.id.camera_preview);
         upload = (Button) findViewById(R.id.upload_image);
        DatabaseServiceLocal database =  DatabaseServiceLocal.getInstance(this);
        HealthCardInfo info = database.retriveHealthInfo();

        // interstitialAd = new InterstitialAd(this); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.setAdUnitId(getString(R.string.admob_interstitial_id)); // TODO: Fix InterstitialAd for new Google Ads API
        // interstitialAd.loadAd(new AdRequest.Builder().build()); // TODO: Fix InterstitialAd for new Google Ads API
        if (info.getCardLink() == null)
        {
            GetCardLinkTask task = new GetCardLinkTask(this,this);
            task.execute();

        }else if (info.getCardLink() != null && !info.getCardLink().isEmpty()){

            DownlaodImage downlaodImage = new DownlaodImage(this,this);
            downlaodImage.execute(info.getCardLink());
            upload.setVisibility(View.GONE);
        }

        upload.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                if (uploadingImages == null) {
                    if (mImageView != null) {
                        uploadingImages = new UploadingImages(CameraActivity.this, ((BitmapDrawable) mImageView.getDrawable()).getBitmap());

                    }else{
                        Toast.makeText(CameraActivity.this,"Image is not loaded. Try again",Toast.LENGTH_SHORT).show();
                    }
                }

                uploadingImages.execute();

            }
        });


    }

    void showViews()
    {
        DatabaseServiceLocal database =  DatabaseServiceLocal.getInstance(this);
        HealthCardInfo info = database.retriveHealthInfo();

       if (info.getCardLink() != null && !info.getCardLink().isEmpty()){

            DownlaodImage downlaodImage = new DownlaodImage(this,this);
            downlaodImage.execute(info.getCardLink());
            upload.setVisibility(View.GONE);
        }else{
            openCameraIntent();
        }
    }

    @Override
    public void showImage(Bitmap bitmap) {
        if (bitmap != null){
            mImageView.setImageBitmap(bitmap);
        }
    }

    private void openCameraIntent() {
        Intent pictureIntent = new Intent( MediaStore.ACTION_IMAGE_CAPTURE );
        File fileDirectly = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
        String pictureName = getPictureName();

       // File newFileDirectly = new File(this.getFilesDir(),"images");
        File newImage = new File(fileDirectly,pictureName);
        //File newImage = new File(pictureName);
        Uri pictureURI;
        if (Build.VERSION.SDK_INT >=Build.VERSION_CODES.N) {
            pictureURI = FileProvider.getUriForFile(this, getPackageName() + ".my.package.name.provider", newImage);
        }else {
             pictureURI = Uri.fromFile(newImage);
        }
       // pictureIntent.putExtra(MediaStore.EXTRA_OUTPUT,pictureURI);

     //   pictureIntent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
     //   pictureIntent.setFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION);

        if(pictureIntent.resolveActivity(getPackageManager()) != null) {
            startActivityForResult(pictureIntent,
                    REQUEST_CAPTURE_IMAGE);
        }
    }

    String getPictureName()
    {
        SimpleDateFormat format = new SimpleDateFormat("yyyy_mmm_day");
        String name = format.format(new Date());
        return "myWaitime_"+name+".png";
    }
    @Override
    protected void onActivityResult(int requestCode, int resultCode,
                                    Intent data) {
        if (requestCode == REQUEST_CAPTURE_IMAGE &&
                resultCode == RESULT_OK) {
            if (data != null && data.getExtras() != null) {
                Bitmap imageBitmap = (Bitmap) data.getExtras().get("data");
                mImageView.setImageBitmap(imageBitmap);

            }
        }
    }

    @Override
    public void showLink(int value) {
        showViews();
    }

    class UploadingImages extends AsyncTask<Void,Void,String>
    {
        Context context ;
        Bitmap bitmap;
        private ProgressDialog mProgressBar;
        UploadingImages(Context context , Bitmap bitmap)
        {
            this.context = context;
            this.bitmap = bitmap;
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            if (mProgressBar == null)
            {
                mProgressBar = new  ProgressDialog(context);

            }

            try {
                mProgressBar.show();
            } catch (Exception e) {
                e.printStackTrace();
            }

        }

        @Override
        protected String doInBackground(Void... voids) {

            BitmapFactory.Options options = null;
            options = new BitmapFactory.Options();
            options.inSampleSize = 3;
         //   bitmap = BitmapFactory.decodeFile(imgPath, options);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            // Must compress the Image to reduce image size to make upload easy
           boolean newBitmap =  bitmap.compress(Bitmap.CompressFormat.PNG, 50, stream);
            byte[] byte_arr = stream.toByteArray();

            // Encode Image to String
         String    encodedString = Base64.encodeToString(byte_arr, 0);

            DatabaseServiceLocal local = DatabaseServiceLocal.getInstance(context);
            UserInfo info = local.retriveUserInfo();

            return DataServices.uploadHealthCarService(context,info.getmEmail(),info.getmPassword(),encodedString);

           // return null;
        }

        @Override
        protected void onPostExecute(String s) {
            super.onPostExecute(s);

            if (mProgressBar != null && mProgressBar.isShowing())
            {
                mProgressBar.dismiss();
            }

            if (s != null && s.equalsIgnoreCase("success"))
            {
                Toast.makeText(context,"healthcard successfully uploaded.", Toast.LENGTH_SHORT).show();
            }else
            {
                Toast.makeText(context,"Something wrong.",Toast.LENGTH_SHORT).show();
            }
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
