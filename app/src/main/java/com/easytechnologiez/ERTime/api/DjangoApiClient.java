package com.easytechnologiez.ERTime.api;

import android.content.Context;
import android.util.Log;
import com.easytechnologiez.ERTime.config.ApiConfig;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import javax.net.ssl.HttpsURLConnection;

/**
 * Django REST API Client
 * Handles communication with Django backend
 */
public class DjangoApiClient {
    
    private static final String TAG = "DjangoApiClient";
    private Context context;
    private String authToken;
    
    public DjangoApiClient(Context context) {
        this.context = context;
    }
    
    public void setAuthToken(String token) {
        this.authToken = token;
    }
    
    /**
     * Make a POST request to Django backend
     * @param endpoint API endpoint URL
     * @param jsonData JSON data to send
     * @return Response as JSON string
     */
    public String makePostRequest(String endpoint, JSONObject jsonData) {
        try {
            URL url = new URL(endpoint);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            
            // Set request properties for Django REST API
            conn.setReadTimeout(15000);
            conn.setConnectTimeout(15000);
            conn.setRequestMethod("POST");
            conn.setDoInput(true);
            conn.setDoOutput(true);
            
            // Set headers
            conn.setRequestProperty("Content-Type", ApiConfig.CONTENT_TYPE);
            conn.setRequestProperty("Accept", ApiConfig.ACCEPT);
            conn.setRequestProperty("User-Agent", "ERTime-Android-App/1.0.3");
            
            // Add CSRF token for Django (if needed)
            conn.setRequestProperty("X-CSRFToken", getCsrfToken());
            
            // Add authentication header if available
            if (authToken != null && !authToken.isEmpty()) {
                conn.setRequestProperty("Authorization", ApiConfig.getAuthHeader(authToken));
            }
            
            // Send JSON data
            BufferedWriter writer = new BufferedWriter(
                new OutputStreamWriter(conn.getOutputStream(), "UTF-8"));
            writer.write(jsonData.toString());
            writer.flush();
            writer.close();
            
            int responseCode = conn.getResponseCode();
            Log.d(TAG, "Response Code: " + responseCode);
            
            // Read response
            BufferedReader reader;
            if (responseCode >= 200 && responseCode < 300) {
                reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            } else {
                reader = new BufferedReader(new InputStreamReader(conn.getErrorStream()));
            }
            
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            reader.close();
            
            Log.d(TAG, "Response: " + response.toString());
            return response.toString();
            
        } catch (Exception e) {
            Log.e(TAG, "Error making POST request", e);
            return null;
        }
    }
    
    /**
     * Make a GET request to Django backend
     * @param endpoint API endpoint URL
     * @return Response as JSON string
     */
    public String makeGetRequest(String endpoint) {
        try {
            URL url = new URL(endpoint);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            
            // Set request properties
            conn.setReadTimeout(15000);
            conn.setConnectTimeout(15000);
            conn.setRequestMethod("GET");
            
            // Set headers
            conn.setRequestProperty("Accept", ApiConfig.ACCEPT);
            conn.setRequestProperty("User-Agent", "ERTime-Android-App/1.0.3");
            
            // Add authentication header if available
            if (authToken != null && !authToken.isEmpty()) {
                conn.setRequestProperty("Authorization", ApiConfig.getAuthHeader(authToken));
            }
            
            int responseCode = conn.getResponseCode();
            Log.d(TAG, "GET Response Code: " + responseCode);
            
            // Read response
            BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream()));
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            reader.close();
            
            Log.d(TAG, "GET Response: " + response.toString());
            return response.toString();
            
        } catch (Exception e) {
            Log.e(TAG, "Error making GET request", e);
            return null;
        }
    }
    
    /**
     * Login to Django backend
     * @param email User email
     * @param password User password
     * @return Login response with JWT token
     */
    public String login(String email, String password) {
        try {
            JSONObject loginData = new JSONObject();
            loginData.put("email", email);
            loginData.put("password", password);
            
            String response = makePostRequest(ApiConfig.LOGIN_ENDPOINT, loginData);
            
            // Parse token from response and store it
            if (response != null) {
                JSONObject responseJson = new JSONObject(response);
                if (responseJson.has("token")) {
                    String token = responseJson.getString("token");
                    setAuthToken(token);
                }
            }
            
            return response;
            
        } catch (Exception e) {
            Log.e(TAG, "Error during login", e);
            return null;
        }
    }
    
    /**
     * Register new user
     * @param userData User registration data
     * @return Registration response
     */
    public String register(JSONObject userData) {
        return makePostRequest(ApiConfig.REGISTER_ENDPOINT, userData);
    }
    
    /**
     * Get hospitals near location
     * @param latitude User latitude
     * @param longitude User longitude
     * @param radius Search radius
     * @return Hospitals JSON response
     */
    public String getHospitalsNearby(double latitude, double longitude, double radius) {
        String endpoint = ApiConfig.HOSPITALS_SEARCH_ENDPOINT + 
            "?lat=" + latitude + "&lng=" + longitude + "&radius=" + radius;
        return makeGetRequest(endpoint);
    }
    
    /**
     * Get wait times for hospital
     * @param hospitalId Hospital ID
     * @return Wait times JSON response
     */
    public String getWaitTimes(String hospitalId) {
        String endpoint = ApiConfig.WAIT_TIMES_ENDPOINT + "?hospital_id=" + hospitalId;
        return makeGetRequest(endpoint);
    }
    
    /**
     * Submit feedback for hospital
     * @param feedbackData Feedback data
     * @return Submission response
     */
    public String submitFeedback(JSONObject feedbackData) {
        return makePostRequest(ApiConfig.SUBMIT_FEEDBACK_ENDPOINT, feedbackData);
    }
    
    /**
     * Get CSRF token for Django (implement based on your Django setup)
     * @return CSRF token or empty string
     */
    private String getCsrfToken() {
        // You might need to implement this based on your Django CSRF setup
        // For API-only Django apps, this might not be needed
        return "";
    }
    
    /**
     * Test connection to Django backend
     * @return true if backend is reachable
     */
    public boolean testConnection() {
        try {
            String response = makeGetRequest(ApiConfig.HEALTH_CHECK_ENDPOINT);
            return response != null;
        } catch (Exception e) {
            Log.e(TAG, "Connection test failed", e);
            return false;
        }
    }
}
