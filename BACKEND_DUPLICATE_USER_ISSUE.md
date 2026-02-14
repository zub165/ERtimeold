# Backend Database Issue Detected

## Problem
There are **duplicate users** with the email `zm_199@hotmail.com` in the backend database.

### Error from Backend
```
{"status":"error","message":"get() returned more than one User -- it returned 2!"}
```

This indicates:
- **2 user records** exist with the same email address
- This violates database integrity constraints
- The backend login cannot determine which user to authenticate

## Required Backend Fix

**Action needed on Django backend:**

1. Check the database for duplicate users:
```sql
SELECT id, username, email, date_joined 
FROM auth_user 
WHERE email = 'zm_199@hotmail.com';
```

2. Identify which user is the correct one (usually the oldest/first created)

3. Delete or merge the duplicate user(s)

4. Add a unique constraint on email field to prevent future duplicates:
```python
# In Django model:
class User(AbstractUser):
    email = models.EmailField(unique=True)
```

## Workaround for Testing

Until the backend database is fixed, you can:

1. **Register a NEW user** with a different email:
   ```
   Email: testuser@example.com
   Password: TestPass123!
   ```

2. **Use the app's registration screen** to create a fresh user

3. **Test login** with the newly created credentials

## Frontend Fix Applied

I've updated the app to try **both** login methods:
1. First tries with full email as username
2. If that fails, tries with derived username (email prefix)

This makes the app more flexible with different backend configurations.

## Next Steps

**For immediate testing:**
- Register a new user in the simulator
- Test all features with the new account

**For production:**
- Fix the duplicate users in the backend database
- Add email uniqueness constraint
- Consider adding a backend migration script to clean up duplicates
