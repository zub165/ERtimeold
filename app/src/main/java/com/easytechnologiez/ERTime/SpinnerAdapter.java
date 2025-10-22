package com.easytechnologiez.ERTime;

import android.app.Activity;
import android.content.Context;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.TextView;

import java.util.ArrayList;

public class SpinnerAdapter extends BaseAdapter
{

    private LayoutInflater mInflater;
    ArrayList<String> myData ;
    Context con;

    public SpinnerAdapter(Activity con , ArrayList<String> list) {
        // TODO Auto-generated constructor stub
    	this.con = con;
        mInflater = LayoutInflater.from(con);
         myData =  list;
    }

    @Override
    public int getCount() {
        // TODO Auto-generated method stub
        return myData.size();
    }

    @Override
    public Object getItem(int position) {
        // TODO Auto-generated method stub
        return position;
    }

    @Override
    public long getItemId(int position) {
        // TODO Auto-generated method stub
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        // TODO Auto-generated method stub
        final ListContent holder;
        View v = convertView;
        if (v == null) {
            v = mInflater.inflate(R.layout.spinner_item, null);
            holder = new ListContent();

            holder.name = (TextView) v.findViewById(R.id.textView1);

            v.setTag(holder);
        } else {

            holder = (ListContent) v.getTag();
        }

        holder.name.setTypeface(Typeface.createFromAsset(con.getAssets(), "Raleway-SemiBold.ttf"));
        holder.name.setText("" + myData.get(position));

        return v;
    }
    
    static class ListContent {

        TextView name;

    }
}


