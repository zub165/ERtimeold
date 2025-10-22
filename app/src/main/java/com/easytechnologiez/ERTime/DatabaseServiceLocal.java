package com.easytechnologiez.ERTime;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import com.easytechnologiez.ERTime.utils.HealthCardInfo;
import com.easytechnologiez.ERTime.utils.UserInfo;

import java.util.ArrayList;

import location.data.PlaceData;


public class DatabaseServiceLocal {
    //	SQLiteDatabase dataBase;
    Context context;

    public static String DATABASE_NAME = "ERTimeNew";


    private final int WRITE_MODE = 1;
    private final int READ_MODE = 2;

    private static DatabaseServiceLocal instance = null;
    private static DBHelper dbhelper;
    private int databaseVersion = 1;

    private DatabaseServiceLocal(Context context) {
        this.context = context;

    }

    public static DatabaseServiceLocal getInstance(Context context){
        if(instance == null){
            instance = new DatabaseServiceLocal(context);


        }
        if(dbhelper == null)
        {
            dbhelper = instance.new DBHelper();
        }

        return instance;
    }




    private class DBHelper extends SQLiteOpenHelper {
        public DBHelper() {
            super(context,DATABASE_NAME,null,databaseVersion);
            //this.setWriteAheadLoggingEnabled(true);
        }

        @Override
        public void onCreate(SQLiteDatabase db) {
            createAllTables(db);
        }

        @Override
        public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
            // Logs that the database is being upgraded
/*	        Log.w("Database", "Upgrading database from version " + oldVersion + " to "
	                   + newVersion + ", which will destroy all old data");
*/
            // Kills the table and existing data
            db.execSQL("DROP TABLE IF EXISTS UserInfo");
            db.execSQL("DROP TABLE IF EXISTS PlaceInfo");
            db.execSQL("DROP TABLE IF EXISTS HealthCardInfo");




            createAllTables(db);
        }
    }

    //=======================================================
    // Shop Group
    //=======================================================

    // Functions for creation of table

    public void createTableForUserInfo(SQLiteDatabase dataBase) {
        dataBase.execSQL("CREATE TABLE IF NOT EXISTS UserInfo (UserId long   PRIMARY KEY, FirstName VARCHAR , LastName VARCHAR ,"+ " Gender VARCHAR  , BloodGroup VARCHAR , Email VARCHAR," + "  Weight  VARCHAR , Height VARCHAR , Password VARCHAR);");
    }

    public void createTableForPlaceInfo(SQLiteDatabase dataBase) {
        dataBase.execSQL("CREATE TABLE IF NOT EXISTS PlaceInfo (Placemid int   PRIMARY KEY ,"+ " PlaceName VARCHAR , PlaceId VARCHAR, PlaceLatitude VARCHAR , PlaceLongitude VARCHAR);");
    }

    public void createTableForHealthCard(SQLiteDatabase dataBase) {
        dataBase.execSQL("CREATE TABLE IF NOT EXISTS HealthCardInfo (Cardid int   PRIMARY KEY ,"+ " Email VARCHAR , link VARCHAR);");
    }



    public UserInfo retriveUserInfo()
    {

        UserInfo UserInfo = new UserInfo();
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(READ_MODE);

        if(dataBase == null){} else {
            Cursor cursor = dataBase.rawQuery("SELECT * FROM UserInfo", null);

            if (cursor != null) {
                if (cursor.getCount() > 0) {

                    cursor.moveToFirst();

                    while (cursor.isAfterLast() == false) {

                        UserInfo.setmFirstName(cursor.getString(cursor.getColumnIndex("FirstName")));
                        UserInfo.setmLastName(cursor.getString(cursor.getColumnIndex("LastName")));
                        UserInfo.setmGender(cursor.getString(cursor.getColumnIndex("Gender")));
                        UserInfo.setmEmail(cursor.getString(cursor.getColumnIndex("Email")));
                        UserInfo.setmHeight(cursor.getString(cursor.getColumnIndex("Height")));
                        UserInfo.setmPassword(cursor.getString(cursor.getColumnIndex("Password")));
                        UserInfo.setmBloodGroup(cursor.getString(cursor.getColumnIndex("BloodGroup")));
                        UserInfo.setmWieght(cursor.getString(cursor.getColumnIndex("Weight")));


                        cursor.moveToNext();
                    }


                } else {
                   // shops.status = Status.DATABASE_EMPTY;
                }

                cursor.close();
            }
            this.close(dataBase);
        }
        return UserInfo;
    }

    public boolean insertCardInfo(HealthCardInfo UserInfos )
    {
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){} else {
            if (UserInfos != null) {
                //			dataBase.execSQL("DELETE FROM ShopList;");
                dataBase.delete("HealthCardInfo", null, null);
            }

            //UserInfo shop = UserInfos.get(i);

            ContentValues contentValues = new ContentValues();

            contentValues.put("link", UserInfos.getCardLink());
            contentValues.put("Email", UserInfos.getUserEmail());

            long staus = dataBase.insertWithOnConflict("HealthCardInfo", null, contentValues, SQLiteDatabase.CONFLICT_REPLACE);
            //   Toast.makeText(context , "Successfully Insert Data into database" + staus, Toast.LENGTH_SHORT).show();



            this.close(dataBase);
            return true;
        }
        return false;
    }

    public HealthCardInfo retriveHealthInfo()
    {

        HealthCardInfo UserInfo = new HealthCardInfo();
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(READ_MODE);

        if(dataBase == null){} else {
            Cursor cursor = dataBase.rawQuery("SELECT * FROM HealthCardInfo", null);

            if (cursor != null) {
                if (cursor.getCount() > 0) {

                    cursor.moveToFirst();

                    while (cursor.isAfterLast() == false) {

                        UserInfo.setCardLink(cursor.getString(cursor.getColumnIndex("link")));
                        UserInfo.setUserEmail(cursor.getString(cursor.getColumnIndex("Email")));


                        cursor.moveToNext();
                    }


                } else {
                    // shops.status = Status.DATABASE_EMPTY;
                }

                cursor.close();
            }
            this.close(dataBase);
        }
        return UserInfo;
    }


    public ArrayList<PlaceData> retrivePlaceInfo()
    {

        ArrayList<PlaceData> UserInfo = new ArrayList<PlaceData>();
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(READ_MODE);

        if(dataBase == null){} else {
            Cursor cursor = dataBase.rawQuery("SELECT * FROM PlaceInfo", null);

            if (cursor != null) {
                if (cursor.getCount() > 0) {

                    cursor.moveToFirst();

                    while (cursor.isAfterLast() == false) {

                        PlaceData data = new PlaceData();

                        data.setName(cursor.getString(cursor.getColumnIndex("PlaceName")));
                        data.setLatitude(cursor.getDouble(cursor.getColumnIndex("PlaceLatitude")));
                        data.setLongitude(cursor.getDouble(cursor.getColumnIndex("PlaceLongitude")));
                        data.setId(cursor.getString(cursor.getColumnIndex("PlaceId")));

                        UserInfo.add(data);
                        cursor.moveToNext();
                    }


                } else {
                    // shops.status = Status.DATABASE_EMPTY;
                }

                cursor.close();
            }
            this.close(dataBase);
        }
        return UserInfo;
    }


    public boolean insertPlaceInfo(ArrayList<PlaceData> UserInfos )
    {
        if (UserInfos == null)
        {
            return false;
        }
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){} else {
            if (UserInfos != null) {
                //			dataBase.execSQL("DELETE FROM ShopList;");
                dataBase.delete("PlaceInfo", null, null);
            }

            for (int i=0;i<UserInfos.size();i++) {
                PlaceData shop = UserInfos.get(i);

                ContentValues contentValues = new ContentValues();

                contentValues.put("PlaceName", shop.getName());
                contentValues.put("PlaceLatitude", shop.getLatitude());
                contentValues.put("PlaceLongitude", shop.getLongitude());
                contentValues.put("PlaceId", shop.getId());

                long staus = dataBase.insertWithOnConflict("PlaceInfo", null, contentValues, SQLiteDatabase.CONFLICT_REPLACE);
                //   Toast.makeText(context , "Successfully Insert Data into database" + staus, Toast.LENGTH_SHORT).show();

            }

            this.close(dataBase);
            return true;
        }
        return false;
    }

    public boolean Logout()
    {
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){
            return false;
        } else {

           int check =  dataBase.delete("UserInfo", null, null);

           if (check>0)
           {
               dataBase.delete("PlaceInfo", null, null);
               dataBase.delete("HealthCardInfo", null, null);
               return true;
           }else {
               return false;
           }
        }
    }


    public boolean insertUserInfo(UserInfo UserInfos )
    {
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){} else {
            if (UserInfos != null) {
                //			dataBase.execSQL("DELETE FROM ShopList;");
                dataBase.delete("UserInfo", null, null);
            }

                //UserInfo shop = UserInfos.get(i);

                ContentValues contentValues = new ContentValues();

                contentValues.put("FirstName", UserInfos.getmFirstName());
                contentValues.put("LastName", UserInfos.getmLastName());
                contentValues.put("Gender", UserInfos.getmGender());
                contentValues.put("Email", UserInfos.getmEmail());
                contentValues.put("BloodGroup", UserInfos.getmBloodGroup());
                contentValues.put("Password", UserInfos.getmPassword());
                contentValues.put("Height", UserInfos.getmHeight());
                contentValues.put("Weight", UserInfos.getmWieght());

                long staus = dataBase.insertWithOnConflict("UserInfo", null, contentValues, SQLiteDatabase.CONFLICT_REPLACE);
             //   Toast.makeText(context , "Successfully Insert Data into database" + staus, Toast.LENGTH_SHORT).show();



            this.close(dataBase);
            return true;
        }
        return false;
    }

    public boolean UpdateUserInfo(UserInfo info )
    {
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){} else {
            if (info != null) {
                //			dataBase.execSQL("DELETE FROM ShopList;");
                dataBase.delete("UserInfo", null, null);
            }

            //UserInfo shop = UserInfos.get(i);

            ContentValues contentValues = new ContentValues();

            contentValues.put("FirstName", info.getmFirstName());
            contentValues.put("LastName", info.getmLastName());
            contentValues.put("Gender", info.getmGender());
            contentValues.put("Email", info.getmEmail());
            contentValues.put("BloodGroup", info.getmBloodGroup());
            contentValues.put("Password", info.getmPassword());
            contentValues.put("Height", info.getmHeight());
            contentValues.put("Weight", info.getmWieght());


            long status= dataBase.updateWithOnConflict("UserInfo",contentValues,"Email",new String[]{info.getmEmail()},SQLiteDatabase.CONFLICT_REPLACE);
          //  long staus = dataBase.insertWithOnConflict("UserInfo", null, contentValues, SQLiteDatabase.CONFLICT_REPLACE);
            //   Toast.makeText(context , "Successfully Insert Data into database" + staus, Toast.LENGTH_SHORT).show();



            this.close(dataBase);
            return true;
        }
        return false;
    }




    public void close(SQLiteDatabase dataBase) {
		if (dataBase != null)
			dataBase.close();
	}

    public synchronized static SQLiteDatabase open(int mode)
    {
        try{

            return dbhelper.getWritableDatabase();
			/*switch(mode) {
			case WRITE_MODE:
					return db.getWritableDatabase();
			case READ_MODE:
					return db.getReadableDatabase();
			default:
					return db.getWritableDatabase();
			}*/
        }catch (Exception e) {
            e.printStackTrace();
            return null;
        }

    }


/*
    // Functions for UPDATE_TABLES of Meer Group

    public void updateFacebookUsername(String username) {
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){} else {
            ContentValues contentValues = new ContentValues();

            contentValues.put("username", username);

            dataBase.update("Facebook", contentValues, null,null);

            this.close(dataBase);
        }
    }

    public void updateTwitterUsername(String username){
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        if(dataBase == null){} else {
            ContentValues contentValues = new ContentValues();

            contentValues.put("username", username);

            dataBase.update("Twitter", contentValues, null,null);

            this.close(dataBase);
        }
    }

    public void updateGooglePlusUsername(String username){
        SQLiteDatabase dataBase = DatabaseServiceLocal.open(WRITE_MODE);

        ContentValues contentValues = new ContentValues();

        contentValues.put("username", username);

        dataBase.update("GooglePlus", contentValues, null,null);

        this.close(dataBase);
    }*/



    public void createAllTables(SQLiteDatabase dataBase)
    {
//		SQLiteDatabase dataBase = DatabaseService.open(WRITE_MODE);


        createTableForPlaceInfo(dataBase);
        createTableForUserInfo(dataBase);
        createTableForHealthCard(dataBase);

		//this.close(dataBase);
    }

}