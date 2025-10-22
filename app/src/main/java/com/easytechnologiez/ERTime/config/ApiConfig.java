package com.easytechnologiez.ERTime.config;

/**
 * API Configuration for Django Backend
 * Update the BASE_URL with your GoDaddy Django backend URL
 */
public class ApiConfig {
    
    // Django Hospital Finder Backend
    public static final String BASE_URL = "http://208.109.215.53:3015";
    
    // Hospital Finder Django API endpoints
    public static final String HOSPITAL_FINDER_ENDPOINT = BASE_URL + "/hospital-finder/";
    public static final String ANALYTICS_ENDPOINT = BASE_URL + "/analytics/";
    public static final String ADMIN_ENDPOINT = BASE_URL + "/admin/";
    
    // Authentication endpoints (you'll need to implement these in Django)
    public static final String LOGIN_ENDPOINT = BASE_URL + "/auth/login/";
    public static final String REGISTER_ENDPOINT = BASE_URL + "/auth/register/";
    public static final String FORGOT_PASSWORD_ENDPOINT = BASE_URL + "/auth/forgot-password/";
    
    // Hospital search and data endpoints
    public static final String HOSPITALS_SEARCH_ENDPOINT = BASE_URL + "/hospitals/search/";
    public static final String HOSPITAL_DETAILS_ENDPOINT = BASE_URL + "/hospitals/details/";
    public static final String WAIT_TIMES_ENDPOINT = BASE_URL + "/hospitals/wait-times/";
    public static final String HOSPITAL_RATINGS_ENDPOINT = BASE_URL + "/hospitals/ratings/";
    
    // Patient and user management
    public static final String PATIENT_PROFILE_ENDPOINT = BASE_URL + "/patients/profile/";
    public static final String MEDICAL_RECORDS_ENDPOINT = BASE_URL + "/patients/records/";
    public static final String UPDATE_PROFILE_ENDPOINT = BASE_URL + "/patients/update/";
    
    // Feedback and ratings
    public static final String SUBMIT_FEEDBACK_ENDPOINT = BASE_URL + "/feedback/submit/";
    public static final String AVERAGE_FEEDBACK_ENDPOINT = BASE_URL + "/feedback/average/";
    
    // System status and health check
    public static final String HEALTH_CHECK_ENDPOINT = BASE_URL + "/health/";
    public static final String SYSTEM_STATUS_ENDPOINT = BASE_URL + "/status/";
    
    // Map API configurations
    public static final boolean USE_GOOGLE_MAPS = true;
    public static final boolean USE_TOMTOM_MAPS = true;
    
    // Headers for Django REST API
    public static final String CONTENT_TYPE = "application/json";
    public static final String ACCEPT = "application/json";
    
    // Default admin credentials (use environment variables in production)
    public static final String DEFAULT_PASSWORD = "Bismilah165$";
    
    /**
     * Get authentication header for Django backend
     * @param token JWT token from login
     * @return Authorization header value
     */
    public static String getAuthHeader(String token) {
        return "Bearer " + token;
    }
    
    /**
     * Check if we're using HTTPS
     * @return true if using HTTPS
     */
    public static boolean isHttps() {
        return BASE_URL.startsWith("https://");
    }
}
