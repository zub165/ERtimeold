package com.easytechnologiez.ERTime;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.annotation.TargetApi;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.inputmethod.EditorInfo;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RadioButton;
import android.widget.TextView;
import android.widget.Toast;

/**
 * A login screen that offers login via email/password.
 */
public class Register extends AppCompatActivity  {

    /**

    /**
     * A dummy authentication store containing known user names and passwords.
     * TODO: remove after connecting to a real authentication system.
     */

    /**
     * Keep track of the login task to ensure we can cancel it if requested.
     */
    private UserLoginTask mAuthTask = null;

    // UI references.
    private AutoCompleteTextView mEmailView;
    private AutoCompleteTextView mFirstNameView;
    private AutoCompleteTextView mLastNameView;
   // private AutoCompleteTextView mUserHeightView;
   // private AutoCompleteTextView mUserWeightView;
  //  private Spinner mUserBloodView;
    private EditText mPasswordView;
    private EditText mPasswordConfirmView;
    private View mProgressView;
    private View mLoginFormView;
    RadioButton Male;
    RadioButton Female;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_register);
        // Set up the login form.
        mEmailView = (AutoCompleteTextView) findViewById(R.id.email);
        mFirstNameView = (AutoCompleteTextView) findViewById(R.id.f_name);
        mLastNameView = (AutoCompleteTextView) findViewById(R.id.l_name);
     //   mUserHeightView = (AutoCompleteTextView) findViewById(R.id.user_height);
     //   mUserWeightView = (AutoCompleteTextView) findViewById(R.id.user_weight);
     //   mUserBloodView = (Spinner) findViewById(R.id.user_blood);

        TextView mRadioGroup = (TextView) findViewById(R.id.GenderText);
        getSupportActionBar().setElevation(0);

         Male = (RadioButton) findViewById(R.id.male);
         Female= (RadioButton) findViewById(R.id.female);

        TextView title = (TextView) findViewById(R.id.title);
        Typeface tf = Typeface.createFromAsset(getAssets(), "Kaushan.otf");
        Typeface tf1 = Typeface.createFromAsset(getAssets(), "Raleway-Regular.ttf");
        Typeface tf2 = Typeface.createFromAsset(getAssets(), "Raleway-SemiBold.ttf");
        title.setTypeface(tf);
        mRadioGroup.setTypeface(tf2);
        Male.setTypeface(tf1);
        Female.setTypeface(tf1);

      //   String[] items= new String[]{"A+","B+","O+","AB+","A-","B-","O-","AB-"};
        // here you can use array or list
       // SpinnerAdapter adapter = new SpinnerAdapter(items);

       // mUserBloodView.setAdapter(adapter);

        mPasswordView = (EditText) findViewById(R.id.password);
        mPasswordConfirmView = (EditText) findViewById(R.id.password_confirm);
        mPasswordView.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView textView, int id, KeyEvent keyEvent) {
                if (id == EditorInfo.IME_ACTION_DONE || id == EditorInfo.IME_NULL) {
                    attemptLogin();
                    return true;
                }
                return false;
            }
        });

        Button mEmailSignInButton = (Button) findViewById(R.id.email_sign_in_button);
        mEmailSignInButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                attemptLogin();
               // Intent intent = new Intent(Register.this , MapsActivity.class);
              //  startActivity(intent);
            }
        });

        mLoginFormView = findViewById(R.id.email_login_form);
        mProgressView = findViewById(R.id.login_progress);
    }



    /**
     * Attempts to sign in or register the account specified by the login form.
     * If there are form errors (invalid email, missing fields, etc.), the
     * errors are presented and no actual login attempt is made.
     */
    private void attemptLogin() {
        if (mAuthTask != null) {
            return;
        }

        // Reset errors.
        mEmailView.setError(null);
        mPasswordView.setError(null);

        // Store values at the time of the login attempt.
        String email = mEmailView.getText().toString();

        String firstName = mFirstNameView.getText().toString();
        String LastName = mLastNameView.getText().toString();
       // String userHeight = mUserHeightView.getText().toString();
      //  String userWeight = mUserWeightView.getText().toString();
       // String userBlood = (String) mUserBloodView.getSelectedItem();
        String password = mPasswordView.getText().toString();
        String confirm = mPasswordConfirmView.getText().toString();

        boolean cancel = false;
        View focusView = null;

        // Check for a valid password, if the user entered one.
        if (!TextUtils.isEmpty(password) && !isPasswordValid(password)) {
            mPasswordView.setError(getString(R.string.error_invalid_password));
            focusView = mPasswordView;
            cancel = true;
        }

        if (!TextUtils.isEmpty(password) && !isPasswordValid(password)) {
            mPasswordConfirmView.setError(getString(R.string.error_invalid_password));
            focusView = mPasswordConfirmView;
            cancel = true;
        }
        if (!TextUtils.equals(password , confirm))
        {
            mPasswordConfirmView.setError(getString(R.string.error_matched_password));
            focusView = mPasswordConfirmView;
            cancel = true;
        }

        // Check for a valid email address.
        if (TextUtils.isEmpty(email)) {
            mEmailView.setError(getString(R.string.error_field_required));
            focusView = mEmailView;
            cancel = true;
        } else if (!isEmailValid(email)) {
            mEmailView.setError(getString(R.string.error_invalid_email));
            focusView = mEmailView;
            cancel = true;
        }

        if (TextUtils.isEmpty(firstName)) {
            mFirstNameView.setError(getString(R.string.error_field_required));
            focusView = mFirstNameView;
            cancel = true;
        } else if (!isFirstNameValid(firstName)) {
            mFirstNameView.setError(getString(R.string.error_invalid_name));
            focusView = mFirstNameView;
            cancel = true;
        }


        if (TextUtils.isEmpty(LastName)) {
            mLastNameView.setError(getString(R.string.error_field_required));
            focusView = mLastNameView;
            cancel = true;
        } else if (!isFirstNameValid(firstName)) {
            mLastNameView.setError(getString(R.string.error_invalid_name));
            focusView = mLastNameView;
            cancel = true;
        }

        boolean gender ;
        if (Male.isChecked())
        {
            gender = true;
        }else
        {
            gender = false;
        }


        if (cancel) {
            // There was an error; don't attempt login and focus the first
            // form field with an error.
            focusView.requestFocus();
        } else {
            // Show a progress spinner, and kick off a background task to
            // perform the user login attempt.
            showProgress(true);
            mAuthTask = new UserLoginTask(email, password , firstName,LastName  , gender);
            mAuthTask.execute((Void) null);
        }
    }

    private boolean isEmailValid(String email) {
        //TODO: Replace this with your own logic
        return email.contains("@");
    }

    private boolean isPasswordValid(String password) {
        //TODO: Replace this with your own logic
        return password.length() > 4;
    }

    private boolean isFirstNameValid(String fName)
    {
        return fName.length() >2;
    }
    private boolean isLastNameValid(String fName)
    {
        return fName.length() >2;
    }

    private boolean isPasswordMatch(String password, String password_confirm)
    {
        return  password.equalsIgnoreCase(password_confirm);
    }

    private boolean isUsernameValid(String fName)
    {
        return fName.length() >3;
    }

    /**
     * Shows the progress UI and hides the login form.
     */
    @TargetApi(Build.VERSION_CODES.HONEYCOMB_MR2)
    private void showProgress(final boolean show) {
        // On Honeycomb MR2 we have the ViewPropertyAnimator APIs, which allow
        // for very easy animations. If available, use these APIs to fade-in
        // the progress spinner.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR2) {
            int shortAnimTime = getResources().getInteger(android.R.integer.config_shortAnimTime);

            mLoginFormView.setVisibility(show ? View.GONE : View.VISIBLE);
            mLoginFormView.animate().setDuration(shortAnimTime).alpha(
                    show ? 0 : 1).setListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    mLoginFormView.setVisibility(show ? View.GONE : View.VISIBLE);
                }
            });

            mProgressView.setVisibility(show ? View.VISIBLE : View.GONE);
            mProgressView.animate().setDuration(shortAnimTime).alpha(
                    show ? 1 : 0).setListener(new AnimatorListenerAdapter() {
                @Override
                public void onAnimationEnd(Animator animation) {
                    mProgressView.setVisibility(show ? View.VISIBLE : View.GONE);
                }
            });
        } else {
            // The ViewPropertyAnimator APIs are not available, so simply show
            // and hide the relevant UI components.
            mProgressView.setVisibility(show ? View.VISIBLE : View.GONE);
            mLoginFormView.setVisibility(show ? View.GONE : View.VISIBLE);
        }
    }



    /**
     * Represents an asynchronous login/registration task used to authenticate
     * the user.
     */
    public class UserLoginTask extends AsyncTask<Void, Void, String> {

        private final String mEmail;
        private final String mPassword;
        private final String mFirstName;
        private final String mLastName;
       // private final String mUserHeight;
       // private final String mUserWeight;
       // private final String mUserBlood;
        private final String mGender;

        UserLoginTask(String email, String password , String fName , String lName  , boolean
                       gender) {
            mEmail = email;
            mPassword = password;
            mFirstName = fName;
            mLastName = lName;
         //   mUserHeight = height;
         //   mUserBlood = blood;
         //   mUserWeight = weight;
            if (gender){
                mGender = "Male";
            }else{
                mGender = "Female";
            }
        }



        @Override
        protected String doInBackground(Void... params) {
            // TODO: attempt authentication against a network service.

            String string = null;
            try {
                // Simulate network access.
                Thread.sleep(2000);
                string = DataServices.NewFetchMethodRegistred(Register.this,mFirstName,mLastName,mEmail,mPassword,mGender);
            } catch (InterruptedException e) {
                return string;
            }


            // TODO: register the new account here.
            return string;
        }

        @Override
        protected void onPostExecute(final String success) {
            mAuthTask = null;
            showProgress(false);

            if (success != null && success.equalsIgnoreCase("success")) {
                Intent intent = new Intent(Register.this , ProfileScreen.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
                intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
                startActivity(intent);
                finish();
              //  Toast.makeText(Register.this , success,Toast.LENGTH_SHORT).show();
            }else if(success != null && success.equalsIgnoreCase("verify") ){
                Toast.makeText(Register.this,"Please! Verify your email to clicking on the link",Toast.LENGTH_LONG).show();
                Intent intent = new Intent(Register.this , LoginActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
                intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
                startActivity(intent);
                finish();
            } else {
                mPasswordView.setError(getString(R.string.error_user_email_already_register));
                mPasswordView.requestFocus();
            }
        }

        @Override
        protected void onCancelled() {
            mAuthTask = null;
            showProgress(false);
        }
    }



}

