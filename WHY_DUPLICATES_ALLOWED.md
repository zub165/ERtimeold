# Why Duplicate Users Were Allowed - Root Cause Analysis

## The Problem

The backend database allowed **2 users** with the same email `zm_199@hotmail.com` to be created.

## Why This Happened

### 1. Django's Default User Model **Does NOT** Enforce Email Uniqueness

By default, Django's built-in `User` model has:
```python
class AbstractUser(AbstractBaseUser, PermissionsMixin):
    username = models.CharField(max_length=150, unique=True)  # ✅ UNIQUE
    email = models.EmailField(blank=True)                      # ❌ NOT UNIQUE
```

**Key Points:**
- `username` is unique by default
- `email` is **NOT unique** by default
- Django allows multiple users to share the same email address
- This is intentional - Django assumes some systems may need this flexibility

### 2. Backend Registration Endpoint Lacks Email Validation

Looking at the backend registration flow, it likely does:

```python
# BAD: No email uniqueness check
def register(request):
    email = request.data.get('email')
    password = request.data.get('password')
    username = request.data.get('username')
    
    # Only checks if username exists
    if User.objects.filter(username=username).exists():
        return error("Username already exists")
    
    # ❌ MISSING: Check if email exists!
    # Should have: if User.objects.filter(email=email).exists(): ...
    
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password
    )
    return success()
```

### 3. No Database-Level Constraint

The database table doesn't have a UNIQUE constraint on the email column:

```sql
-- Current (BAD):
CREATE TABLE auth_user (
    id INT PRIMARY KEY,
    username VARCHAR(150) UNIQUE,
    email VARCHAR(254)  -- ❌ No UNIQUE constraint
);

-- Should be:
CREATE TABLE auth_user (
    id INT PRIMARY KEY,
    username VARCHAR(150) UNIQUE,
    email VARCHAR(254) UNIQUE  -- ✅ Add UNIQUE constraint
);
```

## How Duplicates Happened

**Scenario 1: Registration Called Twice**
```
1. User tries to register with zm_199@hotmail.com
2. Backend creates user with username "zm_199" 
3. Later, user tries again or someone else uses same email
4. Backend generates different username (maybe "zm_199_2" or full email)
5. Both users have same email but different usernames
6. ✅ Username check passes (different usernames)
7. ❌ No email check, so duplicate is created
```

**Scenario 2: Manual Admin Creation**
- Admin might have manually created duplicate users via Django admin panel

**Scenario 3: Database Migration Issues**
- Old data imported without validation

## The Fix - Three Levels

### Level 1: Model-Level (Django)
```python
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    email = models.EmailField(unique=True)  # ✅ Add unique=True
    
    class Meta:
        # Additional constraint
        constraints = [
            models.UniqueConstraint(
                fields=['email'],
                name='unique_user_email'
            )
        ]
```

### Level 2: View/Serializer Validation
```python
def register(request):
    email = request.data.get('email')
    username = request.data.get('username')
    
    # Check username
    if User.objects.filter(username=username).exists():
        return error("Username already exists")
    
    # ✅ Check email
    if User.objects.filter(email=email).exists():
        return error("Email already registered")
    
    # Now safe to create
    user = User.objects.create_user(...)
    return success()
```

### Level 3: Database-Level
```sql
-- Add unique constraint directly in database
ALTER TABLE auth_user 
ADD CONSTRAINT unique_email UNIQUE (email);
```

## Current State Analysis

Based on the error `"get() returned more than one User -- it returned 2!"`, the backend login view is using:

```python
# Current (PROBLEMATIC):
user = User.objects.get(email=email)  # ❌ Assumes only one user per email
```

This fails when duplicates exist because `.get()` expects exactly one result.

Should be:
```python
# Better:
user = User.objects.filter(email=email).first()
# Or even better - use username for login:
user = User.objects.get(username=username)
```

## Immediate Actions Needed

### Backend Developer Must:

1. **Clean up duplicates:**
   ```sql
   -- Find duplicates
   SELECT email, COUNT(*) 
   FROM auth_user 
   GROUP BY email 
   HAVING COUNT(*) > 1;
   
   -- Delete duplicates (keep oldest)
   DELETE FROM auth_user 
   WHERE id NOT IN (
       SELECT MIN(id) 
       FROM auth_user 
       GROUP BY email
   );
   ```

2. **Add model constraint:**
   ```python
   # models.py
   class CustomUser(AbstractUser):
       email = models.EmailField(unique=True)
   ```

3. **Run migration:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

4. **Update registration endpoint:**
   Add email uniqueness check before creating user

5. **Update login endpoint:**
   Use username (not email) for authentication, or handle duplicates gracefully

## Prevention

### Good Practice:
```python
from django.contrib.auth import get_user_model
from rest_framework import serializers

class RegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = get_user_model()
        fields = ['username', 'email', 'password']
        extra_kwargs = {
            'email': {'required': True, 'allow_blank': False}
        }
    
    def validate_email(self, value):
        if get_user_model().objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already registered")
        return value
    
    def validate_username(self, value):
        if get_user_model().objects.filter(username=value).exists():
            raise serializers.ValidationError("Username already exists")
        return value
```

## Why Django Doesn't Do This By Default

Django's philosophy:
- **Flexibility over restrictions** - Some systems legitimately need multiple users per email (family accounts, etc.)
- **Opt-in constraints** - Developers choose what constraints make sense for their app
- **Backward compatibility** - Changing default behavior would break existing apps

But for **most modern apps**, email should be unique!

## Summary

**Root Cause:** Django doesn't enforce email uniqueness by default, and the backend registration didn't validate for duplicate emails.

**Solution:** Add unique constraint to email field at model, view, and database levels.

**Immediate Workaround:** Clean up existing duplicates and add validation to registration endpoint.
