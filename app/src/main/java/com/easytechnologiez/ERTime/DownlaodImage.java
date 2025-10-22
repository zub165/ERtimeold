package com.easytechnologiez.ERTime;

import android.app.ProgressDialog;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;

import com.easytechnologiez.ERTime.camera.ShowDownloadImage;

import java.io.InputStream;


/**
 * Created by Admin on 11/22/2017.
 */

public class DownlaodImage extends AsyncTask<String, Void, Bitmap> {

    ShowDownloadImage downloadInfterface = null;
    ProgressDialog mProgressDialog;
    Context context;
    //ImageView image;
    DownlaodImage(Context context , ShowDownloadImage image ){

        this.context = context;
      downloadInfterface=  image;
    }
    @Override
    protected void onPreExecute() {
        super.onPreExecute();
        // Create a progressdialog
        mProgressDialog = new ProgressDialog(context);
        // Set progressdialog title
        mProgressDialog.setTitle("Download Image");
        // Set progressdialog message
        mProgressDialog.setMessage("Loading...");
        mProgressDialog.setIndeterminate(false);
        // Show progressdialog
        mProgressDialog.show();
    }

    @Override
    protected Bitmap doInBackground(String... URL) {

        String imageURL = URL[0];

        Bitmap bitmap = null;
        try {
            // Download Image from URL
            InputStream input = new java.net.URL(imageURL).openStream();
            // Decode Bitmap
            bitmap = BitmapFactory.decodeStream(input);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return bitmap;
    }

    @Override
    protected void onPostExecute(Bitmap result) {
        // Set the bitmap into ImageView
        try{

            downloadInfterface.showImage(result);

        //image.setImageBitmap(result);
        }catch (Exception e){}

        // Close progressdialog
        mProgressDialog.dismiss();
    }
}

