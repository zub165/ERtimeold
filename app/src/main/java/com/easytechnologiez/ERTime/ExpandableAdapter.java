package com.easytechnologiez.ERTime;


import android.content.Context;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import java.util.ArrayList;

import location.data.PlaceInfo;

public class ExpandableAdapter extends BaseAdapter {

    Context context;
    private ArrayList<PlaceInfo> Datalist;


    ExpandableAdapter(Context con, ArrayList<PlaceInfo> list)
    {
        context = con;
        Datalist = list;
    }

    public void setDatalist(ArrayList<PlaceInfo> datalist) {
        Datalist = datalist;
    }

    public ArrayList<PlaceInfo> getDatalist() {
        return Datalist;
    }



    @Override
    public long getItemId(int position) {
        return 0;
    }

    @Override
    public int getCount() {
        return getDatalist().size();
    }

    @Override
    public Object getItem(int position) {
        return getDatalist().get(position);
    }



    @Override
    public View getView(int position, View convertView, ViewGroup parent) {

        final ViewHolder holder ;

       if (convertView == null) {
           holder = new ViewHolder();
           LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
           convertView = inflater.inflate(R.layout.list_item, null);
           holder.titleView = (TextView) convertView.findViewById(R.id.item_title);
           holder.userWait = (TextView) convertView.findViewById(R.id.user_wait);
           holder.userWaitLabel = (TextView) convertView.findViewById(R.id.user_wait_label);
           holder.distanceView = (TextView) convertView.findViewById(R.id.item_distance);
           holder.durationView = (TextView) convertView.findViewById(R.id.item_duration);
           holder.view = (LinearLayout) convertView.findViewById(R.id.user_wait_layout);
           holder.mProgressBar = (ProgressBar) convertView.findViewById(R.id.progressBar);
         //  holder.placeProgress = (ProgressBar) convertView.findViewById(R.id.placeProgress);

           Typeface tf1 = Typeface.createFromAsset(context.getAssets(), "Raleway-Regular.ttf");
           Typeface tf2 = Typeface.createFromAsset(context.getAssets(), "Raleway-SemiBold.ttf");
           holder.titleView.setTypeface(tf2);
           holder.durationView.setTypeface(tf1);
           holder.distanceView.setTypeface(tf1);
           holder.userWaitLabel.setTypeface(tf2);
           holder.userWait.setTypeface(tf2);
           convertView.setTag(holder);
       }else
       {
           holder = (ViewHolder) convertView.getTag();
       }

       final PlaceInfo info = getDatalist().get(position);

        holder.titleView.setText(info.getmPlaceName());
        if (info.getmPlaceDistance() == null){
            holder.distanceView.setText("Loading...");

        }else {
            holder.distanceView.setText(info.getmPlaceDistance());
        }

        if (info.getmPlaceDistance() == null){
            holder.durationView.setText("Loading...");
        }else {
            holder.durationView.setText(info.getmTravelDuration());
        }


        if (info.getmUserWait() == null)
        {
            holder.userWaitLabel.setVisibility(View.GONE);
            holder.userWait.setVisibility(View.GONE);
            holder.view.setVisibility(View.GONE);
        }else{
            holder.userWait.setVisibility(View.VISIBLE);
            holder.userWaitLabel.setVisibility(View.VISIBLE);
            holder.view.setVisibility(View.VISIBLE);
            holder.userWait.setText(info.getmUserWait());
        }

        if (info.isUserWaitAvaliable())
        {
            holder.mProgressBar.setVisibility(View.VISIBLE);
        }else{
            holder.mProgressBar.setVisibility(View.GONE);
        }


    //   PlaceDetailsTask task = new PlaceDetailsTask(context,info.getId(),holder.phoneView,holder.addressView,holder.placeProgress);
     //  task.execute();


        return convertView;
    }

    class ViewHolder
    {
        TextView titleView;
        TextView userWaitLabel;
        TextView userWait;
        TextView distanceView;
        TextView durationView;
        View view;
        ProgressBar mProgressBar;
    }
}
