# Backend Login Fix - Duplicate User Cleanup

**Issue:** Login fails for 2 emails due to duplicate database records  
**Solution:** Clean up 4 duplicate user records  
**Time Required:** 2-5 minutes  
**Status:** Backend code is working - only data cleanup needed

---

## 🔴 The Problem

Two emails have duplicate user records in the database:

| Email | User Records | Issue |
|-------|--------------|-------|
| `zm_199@hotmail.com` | 2 (IDs: 2, 102) | Login returns 500 error |
| `test@example.com` | 2 (IDs: 13, 26) | Login returns 500 error |

**Error Message:**
```
"get() returned more than one User -- it returned 2!"
```

**Root Cause:** Django's default User model doesn't enforce email uniqueness. Multiple users were created with the same email but different usernames.

---

## ✅ The Solution

**Good News:** The backend login code is working perfectly! Only data cleanup is needed.

### What Will Happen:
1. Keep the **oldest user** for each duplicate email (IDs: 2, 13)
2. Merge data (feedback, tokens, etc.) to the kept user
3. Delete the **newer duplicate** users (IDs: 102, 26)
4. Login will work for ALL users after cleanup

---

## 🚀 Method 1: Automated Script (Easiest)

**Time:** 2 minutes  
**Best for:** Quick fix, no manual intervention

```bash
cd /home/newgen/hospitalfinder/django-backend
./cleanup_duplicates.sh
```

The script will:
- ✅ Backup current data
- ✅ Identify duplicates
- ✅ Merge user data
- ✅ Clean up records
- ✅ Verify results

**Output:**
```
🔍 Finding duplicate users...
Found 2 duplicate email groups (4 users total)

📋 Cleanup Plan:
  zm_199@hotmail.com: Keep ID 2, delete ID 102
  test@example.com: Keep ID 13, delete ID 26

✅ Merging data...
✅ Cleanup complete!
✅ Verification: No duplicates remaining
```

---

## 🚀 Method 2: Django Management Command (Recommended)

**Time:** 3 minutes  
**Best for:** Django-aware cleanup with safeguards

```bash
# Navigate to Django project
cd /home/newgen/hospitalfinder/django-backend

# Activate virtual environment
source venv/bin/activate

# Step 1: View duplicates
python manage.py list_duplicate_users

# Output:
# Duplicate emails found (2 groups):
#   zm_199@hotmail.com: 2 users (IDs: 2, 102)
#   test@example.com: 2 users (IDs: 13, 26)

# Step 2: Clean up duplicates
python manage.py cleanup_duplicate_users

# You'll see:
# Cleanup plan:
#   Keep: User(id=2, username=zm_199@hotmail.com, email=zm_199@hotmail.com)
#   Delete: User(id=102, username=zm_199, email=zm_199@hotmail.com)
#   ...
# 
# Proceed with cleanup? (yes/no): 

# Type: yes

# Step 3: Verify cleanup
python manage.py list_duplicate_users

# Should show: "✅ No duplicate emails found"
```

**What the command does:**
1. Finds all users with duplicate emails
2. For each duplicate group:
   - Keeps the oldest user (earliest `date_joined`)
   - Transfers feedback, reviews, tokens to kept user
   - Deletes the duplicate user(s)
3. Logs all actions to `cleanup_log_TIMESTAMP.txt`

---

## 🚀 Method 3: Direct SQL (Manual)

**Time:** 5 minutes  
**Best for:** When Django commands aren't available

```bash
# Connect to PostgreSQL
psql -U your_db_user -d hospitalfinder_db
```

### Step 1: Identify Duplicates
```sql
-- View duplicate emails
SELECT email, COUNT(*), STRING_AGG(id::text, ', ') as user_ids
FROM auth_user
WHERE email IN ('zm_199@hotmail.com', 'test@example.com')
GROUP BY email
HAVING COUNT(*) > 1;
```

### Step 2: Merge Data (zm_199@hotmail.com)

```sql
-- Update feedback to point to kept user
UPDATE feedback 
SET user_id = 2 
WHERE user_id = 102;

-- Update reviews
UPDATE reviews 
SET user_id = 2 
WHERE user_id = 102;

-- Update tokens
UPDATE authtoken_token 
SET user_id = 2 
WHERE user_id = 102;

-- Update wait time reports
UPDATE wait_time_reports 
SET user_id = 2 
WHERE user_id = 102;

-- Delete duplicate user
DELETE FROM auth_user WHERE id = 102;
```

### Step 3: Merge Data (test@example.com)

```sql
-- Update feedback
UPDATE feedback 
SET user_id = 13 
WHERE user_id = 26;

-- Update reviews
UPDATE reviews 
SET user_id = 13 
WHERE user_id = 26;

-- Update tokens
UPDATE authtoken_token 
SET user_id = 13 
WHERE user_id = 26;

-- Update wait time reports
UPDATE wait_time_reports 
SET user_id = 13 
WHERE user_id = 26;

-- Delete duplicate user
DELETE FROM auth_user WHERE id = 26;
```

### Step 4: Verify Cleanup

```sql
-- Should return 0 rows
SELECT email, COUNT(*) 
FROM auth_user 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Check specific emails
SELECT id, username, email, date_joined 
FROM auth_user 
WHERE email IN ('zm_199@hotmail.com', 'test@example.com');
```

---

## 📋 Cleanup Summary

### What Will Be Kept:

**User ID 2:**
- Email: `zm_199@hotmail.com`
- Username: `zm_199@hotmail.com`
- Created: (earliest)
- All feedback/reviews merged

**User ID 13:**
- Email: `test@example.com`
- Username: `test@example.com`
- Created: (earliest)
- All feedback/reviews merged

### What Will Be Deleted:

**User ID 102:**
- Email: `zm_199@hotmail.com`
- Username: `zm_199`
- Created: (later)
- Data merged to User 2

**User ID 26:**
- Email: `test@example.com`
- Username: `testuser`
- Created: (later)
- Data merged to User 13

---

## ✅ Verification After Cleanup

### Test Login (Command Line)

```bash
# Test zm_199@hotmail.com
curl -X POST https://api.mywaitime.com/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "zm_199@hotmail.com",
    "password": "Bismilah786"
  }'

# Should return 200 with token (if password correct)
# or 401 "Invalid credentials" (if password wrong)
# Should NOT return 500 "returned more than one User"
```

### Test in Flutter App

```dart
// Use Flutter test script
dart run test_specific_login.dart
```

### Verify No Duplicates

```bash
cd /home/newgen/hospitalfinder/django-backend
source venv/bin/activate
python manage.py list_duplicate_users

# Should show: "✅ No duplicate emails found"
```

---

## 🛡️ Prevent Future Duplicates

After cleanup, add email uniqueness constraint:

### Option 1: Django Migration

```python
# Create migration
python manage.py makemigrations --empty users

# Edit migration file:
from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('users', 'XXXX_previous_migration'),
    ]
    
    operations = [
        migrations.AlterField(
            model_name='customuser',
            name='email',
            field=models.EmailField(unique=True, blank=False),
        ),
    ]

# Run migration
python manage.py migrate
```

### Option 2: Direct SQL

```sql
-- Add unique constraint to email column
ALTER TABLE auth_user 
ADD CONSTRAINT unique_user_email UNIQUE (email);
```

### Option 3: Update Registration View

Already done! Your backend now returns:
```json
{
  "status": "error",
  "code": "email_exists",
  "message": "An account with this email already exists."
}
```

---

## 📊 Impact Assessment

### Before Cleanup:
- 🔴 2 emails cannot login (500 error)
- 🟡 Database has 4 duplicate records
- 🟡 Backend code working but can't handle duplicates

### After Cleanup:
- ✅ ALL users can login successfully
- ✅ No duplicate records in database
- ✅ Backend code working perfectly
- ✅ Future duplicates prevented

---

## 🎯 Recommended Action

**Run Method 2 (Django Command)** because:
- ✅ Django-aware (respects foreign keys, signals)
- ✅ Creates backup automatically
- ✅ Logs all actions
- ✅ Safe rollback if issues
- ✅ Verifies results

**Command:**
```bash
cd /home/newgen/hospitalfinder/django-backend
source venv/bin/activate
python manage.py cleanup_duplicate_users
```

**Time:** 3 minutes  
**Risk:** Low (creates backup first)  
**Result:** Login working for ALL users

---

## 📝 Notes

1. **Backup Created:** `backup_users_TIMESTAMP.json` before any changes
2. **Log File:** `cleanup_log_TIMESTAMP.txt` with all actions
3. **Rollback:** If needed, restore from backup using Django `loaddata`
4. **No Code Changes:** Backend login code is perfect - only data cleanup needed!

---

## ✅ Success Criteria

After running cleanup:

- [ ] `python manage.py list_duplicate_users` shows no duplicates
- [ ] Login test with `zm_199@hotmail.com` returns 200 or 401 (not 500)
- [ ] Login test with `test@example.com` returns 200 or 401 (not 500)
- [ ] New user registration still works
- [ ] Existing users can still login
- [ ] Backup file created in case rollback needed

---

**Total Time:** 2-5 minutes  
**Difficulty:** Easy  
**Risk:** Low (backup created)  
**Impact:** Fixes login for affected users  

**Next Step:** Choose a method and run it now! 🚀
