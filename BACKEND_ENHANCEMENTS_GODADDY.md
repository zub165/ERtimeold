# Django Backend Enhancement List - GoDaddy Deployment

**Backend URL:** `https://api.mywaitime.com/api`  
**Database:** PostgreSQL  
**Date:** January 28, 2026

---

## 🔴 CRITICAL - Fix Immediately

### 1. Fix Duplicate User Email Issue
**Priority:** CRITICAL  
**Impact:** Authentication broken for affected users  

**Problem:**
- Multiple users exist with same email address
- Login fails with: `"get() returned more than one User -- it returned 2!"`
- Example: `zm_199@hotmail.com` has 2 user records

**Solution:**
```python
# Step 1: Clean up existing duplicates in database
from django.contrib.auth import get_user_model
User = get_user_model()

# Find duplicates
from django.db.models import Count
duplicates = User.objects.values('email').annotate(
    count=Count('email')
).filter(count__gt=1)

# For each duplicate email, keep oldest, delete others
for dup in duplicates:
    users = User.objects.filter(email=dup['email']).order_by('date_joined')
    for user in users[1:]:  # Keep first, delete rest
        user.delete()

# Step 2: Add unique constraint to model
class CustomUser(AbstractUser):
    email = models.EmailField(unique=True, blank=False)

# Step 3: Run migration
python manage.py makemigrations
python manage.py migrate

# Step 4: Add database-level constraint
ALTER TABLE auth_user ADD CONSTRAINT unique_user_email UNIQUE (email);
```

### 2. Add Email Validation to Registration Endpoint
**Priority:** CRITICAL  
**Impact:** Prevents future duplicate user registrations  

**Current Code (Problematic):**
```python
def register(request):
    username = request.data.get('username')
    if User.objects.filter(username=username).exists():
        return error("Username already exists")
    # ❌ Missing email check
    user = User.objects.create_user(...)
```

**Fixed Code:**
```python
def register(request):
    email = request.data.get('email')
    username = request.data.get('username')
    
    # Validate username
    if User.objects.filter(username=username).exists():
        return Response({
            "status": "error",
            "message": "Username already exists"
        }, status=400)
    
    # ✅ Validate email
    if User.objects.filter(email=email).exists():
        return Response({
            "status": "error",
            "message": "Email already registered"
        }, status=400)
    
    # Validate email format
    from django.core.validators import validate_email
    try:
        validate_email(email)
    except ValidationError:
        return Response({
            "status": "error",
            "message": "Invalid email format"
        }, status=400)
    
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password
    )
```

### 3. Fix Login Endpoint to Handle Edge Cases
**Priority:** CRITICAL  
**Impact:** Prevents 500 errors during login  

**Current Code (Causes 500 error):**
```python
user = User.objects.get(email=email)  # ❌ Breaks if duplicates exist
```

**Fixed Code:**
```python
from django.contrib.auth import authenticate

def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    # Use Django's built-in authenticate (uses username, not email)
    user = authenticate(username=username, password=password)
    
    if user is not None:
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            "status": "success",
            "message": "Login successful",
            "data": {
                "user_id": user.id,
                "username": user.username,
                "email": user.email,
                "is_authenticated": True,
                "token": token.key,
                "auth_type": "session+token"
            }
        })
    else:
        return Response({
            "status": "error",
            "message": "Invalid username or password"
        }, status=401)
```

---

## 🟠 HIGH PRIORITY - Fix This Week

### 4. Add Rate Limiting to Authentication Endpoints
**Priority:** HIGH  
**Impact:** Prevents brute force attacks  

```python
from rest_framework.throttling import AnonRateThrottle

class LoginRateThrottle(AnonRateThrottle):
    rate = '5/hour'  # 5 login attempts per hour

class RegisterRateThrottle(AnonRateThrottle):
    rate = '3/day'  # 3 registrations per day from same IP

# In views:
class LoginView(APIView):
    throttle_classes = [LoginRateThrottle]
```

### 5. Implement Password Strength Requirements
**Priority:** HIGH  
**Impact:** Improves security  

```python
from django.core.exceptions import ValidationError
import re

def validate_password_strength(password):
    """
    Verify password meets security requirements:
    - At least 8 characters
    - Contains uppercase and lowercase
    - Contains numbers
    - Contains special characters
    """
    if len(password) < 8:
        raise ValidationError("Password must be at least 8 characters long")
    
    if not re.search(r'[A-Z]', password):
        raise ValidationError("Password must contain at least one uppercase letter")
    
    if not re.search(r'[a-z]', password):
        raise ValidationError("Password must contain at least one lowercase letter")
    
    if not re.search(r'\d', password):
        raise ValidationError("Password must contain at least one number")
    
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise ValidationError("Password must contain at least one special character")
    
    return True

# In registration:
try:
    validate_password_strength(password)
except ValidationError as e:
    return Response({"status": "error", "message": str(e)}, status=400)
```

### 6. Add Request Logging and Monitoring
**Priority:** HIGH  
**Impact:** Better debugging and security monitoring  

```python
# Install: pip install django-request-logging

# settings.py
MIDDLEWARE = [
    # ... other middleware
    'request_logging.middleware.LoggingMiddleware',
]

LOGGING = {
    'version': 1,
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/var/log/django/api.log',
            'maxBytes': 1024 * 1024 * 15,  # 15MB
            'backupCount': 10,
        },
    },
    'loggers': {
        'django.request': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

### 7. Enable CORS Properly
**Priority:** HIGH  
**Impact:** Ensures Flutter app can communicate with backend  

```python
# Install: pip install django-cors-headers

# settings.py
INSTALLED_APPS = [
    'corsheaders',
    # ...
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    # ... (must be before CommonMiddleware)
]

# For production:
CORS_ALLOWED_ORIGINS = [
    "https://mywaitime.com",
    "https://www.mywaitime.com",
]

# For development only:
# CORS_ALLOW_ALL_ORIGINS = True
```

### 8. Add Email Verification for New Registrations
**Priority:** HIGH  
**Impact:** Prevents fake accounts and spam  

```python
from django.core.mail import send_mail
from django.contrib.auth.tokens import default_token_generator
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes

def register(request):
    # ... create user ...
    user.is_active = False  # Don't activate until verified
    user.save()
    
    # Generate verification token
    token = default_token_generator.make_token(user)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    
    # Send verification email
    verification_link = f"https://api.mywaitime.com/auth/verify/{uid}/{token}/"
    send_mail(
        'Verify your ER Wait Time account',
        f'Click here to verify: {verification_link}',
        'noreply@mywaitime.com',
        [user.email],
    )
    
    return Response({
        "status": "success",
        "message": "Registration successful. Please check your email to verify your account."
    })
```

---

## 🟡 MEDIUM PRIORITY - Fix This Month

### 9. Add API Versioning
**Priority:** MEDIUM  
**Impact:** Allows backward-compatible API changes  

```python
# urls.py
urlpatterns = [
    path('api/v1/', include('api.v1.urls')),
    path('api/v2/', include('api.v2.urls')),  # Future version
]

# OR use DRF versioning:
REST_FRAMEWORK = {
    'DEFAULT_VERSIONING_CLASS': 'rest_framework.versioning.URLPathVersioning',
    'DEFAULT_VERSION': 'v1',
    'ALLOWED_VERSIONS': ['v1', 'v2'],
}
```

### 10. Implement Proper Error Responses
**Priority:** MEDIUM  
**Impact:** Better client-side error handling  

```python
# Create custom exception handler
from rest_framework.views import exception_handler
from rest_framework.response import Response

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    
    if response is not None:
        response.data = {
            'status': 'error',
            'message': str(exc),
            'data': None,
            'errors': response.data if isinstance(response.data, dict) else None
        }
    
    return response

# settings.py
REST_FRAMEWORK = {
    'EXCEPTION_HANDLER': 'myapp.utils.custom_exception_handler'
}
```

### 11. Add Data Pagination
**Priority:** MEDIUM  
**Impact:** Better performance for large datasets  

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50
}

# For hospitals search:
class HospitalSearchView(APIView):
    def get(self, request):
        hospitals = Hospital.objects.filter(...)[:50]  # Limit results
        return Response({
            "status": "success",
            "data": hospitals,
            "pagination": {
                "page": 1,
                "per_page": 50,
                "total": Hospital.objects.count()
            }
        })
```

### 12. Add Database Indexes for Performance
**Priority:** MEDIUM  
**Impact:** Faster queries  

```python
class Hospital(models.Model):
    name = models.CharField(max_length=255, db_index=True)
    latitude = models.FloatField(db_index=True)
    longitude = models.FloatField(db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['latitude', 'longitude']),
            models.Index(fields=['name']),
            models.Index(fields=['-created_at']),
        ]

class Feedback(models.Model):
    hospital = models.ForeignKey(Hospital, on_delete=models.CASCADE, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['hospital', '-created_at']),
        ]
```

### 13. Implement Caching for Frequent Queries
**Priority:** MEDIUM  
**Impact:** Reduces database load  

```python
from django.core.cache import cache

def get_hospitals_search(lat, lon, radius):
    cache_key = f'hospitals_{lat}_{lon}_{radius}'
    hospitals = cache.get(cache_key)
    
    if hospitals is None:
        hospitals = Hospital.objects.filter(...)
        cache.set(cache_key, hospitals, 300)  # Cache for 5 minutes
    
    return hospitals

# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://127.0.0.1:6379/1',
    }
}
```

### 14. Add Health Check Endpoint
**Priority:** MEDIUM  
**Impact:** Better monitoring and uptime tracking  

```python
# views.py
from django.db import connection
from django.http import JsonResponse

def health_check(request):
    try:
        # Check database
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        return JsonResponse({
            "status": "healthy",
            "database": "connected",
            "timestamp": timezone.now().isoformat()
        })
    except Exception as e:
        return JsonResponse({
            "status": "unhealthy",
            "error": str(e)
        }, status=503)

# urls.py
path('health/', health_check, name='health_check'),
```

---

## 🟢 LOW PRIORITY - Nice to Have

### 15. Add Admin Dashboard Improvements
**Priority:** LOW  
**Impact:** Better backend management  

```python
# admin.py
from django.contrib import admin

@admin.register(Hospital)
class HospitalAdmin(admin.ModelAdmin):
    list_display = ['name', 'address', 'rating', 'created_at']
    list_filter = ['created_at', 'rating']
    search_fields = ['name', 'address']
    ordering = ['-created_at']

@admin.register(Feedback)
class FeedbackAdmin(admin.ModelAdmin):
    list_display = ['hospital', 'rating', 'user', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['hospital__name', 'comment']
    readonly_fields = ['created_at']
```

### 16. Implement Automated Backups
**Priority:** LOW  
**Impact:** Data recovery protection  

```bash
# Create backup script: backup.sh
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgres"
DB_NAME="erwaittime"

# Backup database
pg_dump -U postgres $DB_NAME > $BACKUP_DIR/backup_$DATE.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete

# Cron job (run daily at 2 AM):
# 0 2 * * * /path/to/backup.sh
```

### 17. Add API Documentation with Swagger
**Priority:** LOW  
**Impact:** Better developer experience  

```python
# Install: pip install drf-yasg

# urls.py
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
    openapi.Info(
        title="ER Wait Time API",
        default_version='v1',
        description="API for ER Wait Time tracking app",
    ),
    public=True,
)

urlpatterns = [
    path('swagger/', schema_view.with_ui('swagger'), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc'), name='schema-redoc'),
]
```

### 18. Add Soft Delete for Important Models
**Priority:** LOW  
**Impact:** Recovery from accidental deletions  

```python
from django.db import models
from django.utils import timezone

class SoftDeleteManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)

class Hospital(models.Model):
    # ... fields ...
    deleted_at = models.DateTimeField(null=True, blank=True)
    
    objects = SoftDeleteManager()
    all_objects = models.Manager()  # Include deleted
    
    def delete(self, *args, **kwargs):
        self.deleted_at = timezone.now()
        self.save()
    
    def hard_delete(self):
        super().delete()
```

### 19. Implement User Activity Logging
**Priority:** LOW  
**Impact:** Better analytics and debugging  

```python
class UserActivity(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    action = models.CharField(max_length=100)
    endpoint = models.CharField(max_length=255)
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

# Middleware to log activities
class ActivityLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        if request.user.is_authenticated:
            UserActivity.objects.create(
                user=request.user,
                action=request.method,
                endpoint=request.path,
                ip_address=self.get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
        return self.get_response(request)
```

### 20. Add Notification System
**Priority:** LOW  
**Impact:** Better user engagement  

```python
class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']

# Send notification when new feedback is submitted
def notify_hospital_review(hospital, feedback):
    # Notify hospital admins
    admins = User.objects.filter(is_staff=True, hospital=hospital)
    for admin in admins:
        Notification.objects.create(
            user=admin,
            title="New Review Submitted",
            message=f"New {feedback.rating}-star review for {hospital.name}"
        )
```

---

## 📊 Summary by Priority

| Priority | Count | Focus Area |
|----------|-------|------------|
| 🔴 CRITICAL | 3 | Authentication & Data Integrity |
| 🟠 HIGH | 5 | Security & Monitoring |
| 🟡 MEDIUM | 6 | Performance & Developer Experience |
| 🟢 LOW | 6 | Nice-to-Have Features |

---

## 🚀 Recommended Implementation Order

### Week 1 (CRITICAL):
1. ✅ Fix duplicate user emails
2. ✅ Add email validation to registration
3. ✅ Fix login endpoint edge cases

### Week 2 (HIGH):
4. ✅ Add rate limiting
5. ✅ Implement password strength requirements
6. ✅ Add request logging

### Week 3 (HIGH):
7. ✅ Configure CORS properly
8. ✅ Add email verification

### Week 4 (MEDIUM):
9. ✅ Implement API versioning
10. ✅ Standardize error responses
11. ✅ Add pagination

### Month 2:
- Continue with MEDIUM and LOW priority items as needed

---

## 📝 Testing Checklist After Each Enhancement

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing on development server
- [ ] Deploy to staging
- [ ] Test with Flutter app
- [ ] Monitor error logs
- [ ] Deploy to production (GoDaddy)
- [ ] Verify with production monitoring

---

## 🔧 GoDaddy-Specific Considerations

### 1. **Static Files Serving**
```python
# settings.py
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Run after deployment:
python manage.py collectstatic --noinput
```

### 2. **HTTPS Configuration**
```python
# settings.py (Production)
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
```

### 3. **Database Connection Pooling**
```python
# For better performance on shared hosting
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'CONN_MAX_AGE': 600,  # Keep connections for 10 minutes
    }
}
```

### 4. **Environment Variables**
```bash
# Use .env file for sensitive data
# Never commit to git!
SECRET_KEY=your-secret-key
DATABASE_URL=postgres://user:pass@host:5432/db
DEBUG=False
ALLOWED_HOSTS=api.mywaitime.com,mywaitime.com
```

---

## 📚 Additional Resources

- Django Security Checklist: https://docs.djangoproject.com/en/stable/howto/deployment/checklist/
- DRF Best Practices: https://www.django-rest-framework.org/
- PostgreSQL Optimization: https://wiki.postgresql.org/wiki/Performance_Optimization
- GoDaddy Django Deployment: https://www.godaddy.com/help/django

---

**Total Enhancements:** 20  
**Estimated Implementation Time:** 4-6 weeks  
**Immediate Action Required:** Items 1-3 (Critical)
