# Backend Enhancements List (If Needed)

**Backend:** `https://api.mywaitime.com/api`  
**Use this list to decide what to implement on the Django backend.**

---

## 🔴 CRITICAL – Do First

| # | Enhancement | Why | Status |
|---|-------------|-----|--------|
| 1 | **Fix duplicate user emails** | Login fails with "get() returned more than one User" for affected emails (e.g. zm_199@hotmail.com). | Run `python manage.py cleanup_duplicate_users` (see BACKEND_LOGIN_FIX.md). |
| 2 | **Enforce unique email at DB/model level** | Prevents new duplicates. | Add unique constraint on `email`; consider CustomUser with `email = EmailField(unique=True)`. |
| 3 | **Registration: check email exists** | Avoid creating a second account for same email. | Before create: `if User.objects.filter(email=email).exists(): return 400` with message "Email already registered". |
| 4 | **Login: use username only** | Avoid 500 when multiple users share same email. | Use `authenticate(username=username, password=password)`; do not look up by email with `.get()`. |

---

## 🟠 HIGH – Security & Reliability

| # | Enhancement | Why |
|---|-------------|-----|
| 5 | **Rate limiting (auth)** | Limit login/register attempts per IP (e.g. 5/hour login, 3/day register). |
| 6 | **Password strength** | Enforce min length, upper/lower/number/special character; return clear error messages. |
| 7 | **CORS** | Allow only your app origins (e.g. https://mywaitime.com); use `django-cors-headers`. |
| 8 | **Request/error logging** | Log auth failures and important API errors for debugging and security. |
| 9 | **Email verification (optional)** | Send verification link on register; activate account on verify to reduce spam/fake accounts. |

---

## 🟡 MEDIUM – API & App Alignment

| # | Enhancement | Why |
|---|-------------|-----|
| 10 | **Health check endpoint** | Flutter uses `GET /api/health/` to show "Django Backend: Connected". Return 200 and e.g. `{"status":"healthy"}`. |
| 11 | **Wait time in search response** | App shows "Est. X min wait" from backend when each hospital has a wait field. Include one of: `smart_wait_time`, `current_wait_time`, `estimated_wait_time`, or `predicted_wait_time` (minutes, int) per hospital in `GET /api/hospitals/search/` (or list) response. |
| 12 | **Wait-times endpoint** | App calls `GET /api/hospitals/wait-times/?hospital_id=<id>`. Return JSON with `current_wait_time` and/or `average_wait_time` (minutes). Enables AI-enhanced estimates (reviews, traffic, weather) to show in the app. |
| 13 | **Delete account endpoint** | App calls `DELETE /api/auth/delete-account/` (with auth token) for store compliance. Backend should deactivate/delete the user and clear related data (tokens, optional anonymization of feedback). |
| 14 | **Standard error format** | Use consistent body e.g. `{"status":"error","message":"..."}` and appropriate HTTP status codes so the app can show clear errors. |
| 15 | **Pagination** | Support `page` and `page_size` (or `limit`) for hospital list/search to avoid large responses. |
| 16 | **DB indexes** | Index hospital search fields (e.g. lat/lon, name) and feedback (e.g. hospital_id, created_at) for speed. |

---

## 🟢 LOW – Nice to Have

| # | Enhancement | Why |
|---|-------------|-----|
| 17 | **API versioning** | e.g. `/api/v1/` to allow future breaking changes safely. |
| 18 | **Caching** | Cache hospital search results for a short TTL (e.g. 5 min) to reduce DB load. |
| 19 | **Swagger/OpenAPI docs** | Document endpoints for easier integration and onboarding. |
| 20 | **Automated DB backups** | Daily backups and retention policy for recovery. |
| 21 | **Soft delete** | Mark records as deleted instead of hard delete for critical models if you need recovery/audit. |
| 22 | **Activity/audit log** | Log sensitive actions (login, delete account, etc.) for security and support. |

---

## Quick reference: endpoints the app uses

| Purpose | Method | Endpoint | Notes |
|--------|--------|----------|--------|
| Connection check | GET | `/api/health/` or `/api/` | 200 = Connected |
| Login | POST | `/api/auth/login/` | Body: `username`, `password`; return `token`. |
| Register | POST | `/api/auth/register/` | Body: `email`, `username`, `password`. |
| Delete account | DELETE | `/api/auth/delete-account/` | Auth: Token header. |
| Hospital search | GET | `/api/hospitals/search/?lat=&lon=&radius_m=&limit=` | Include wait time field per hospital for "Est. X min". |
| Wait times | GET | `/api/hospitals/wait-times/?hospital_id=` | Return `current_wait_time`, `average_wait_time`. |
| Feedback/review | POST | `/api/feedback/submit/` | Body: `hospital_id`, `wait_time`, ratings, `comment`, etc. |

---

## Suggested order

1. **This week:** 1–4 (critical auth/duplicates).  
2. **Next:** 5–9 (security), then 10–13 (health, wait time, delete account, errors).  
3. **When scaling:** 14–16 (pagination, indexes).  
4. **As needed:** 17–22 (versioning, cache, docs, backups, audit).

For full details and code snippets, see **BACKEND_ENHANCEMENTS_GODADDY.md** and **BACKEND_LOGIN_FIX.md**.
