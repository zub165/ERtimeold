# Backend: Delete Account Endpoint

## Why "Delete account" doesn't remove the user on the server

The app calls the backend to delete the account. If the backend does **not** expose a working delete-account endpoint, the account is only removed **on the device** (local logout); the user record stays on the server.

---

## What the app sends

- **URL:** `https://api.mywaitime.com/api/auth/delete-account/`
- **Method:** `DELETE` (and if that returns 404/405, the app tries `POST` with `{"confirm": true}`)
- **Headers:**
  - `Authorization: Token <user_token>`
  - `Content-Type: application/json`
  - `Accept: application/json`

The app only sends the request if the user is logged in (token is set).

---

## What the backend must do

1. **Implement the endpoint** (if not already):
   - Path: `/api/auth/delete-account/`
   - Method: `DELETE` (or `POST` if you prefer; the app will try both).
2. **Require authentication:** Accept `Authorization: Token <token>` and resolve the user from the token.
3. **Perform deletion (or deactivation):**
   - Either **hard delete** the user (and handle related data: tokens, feedback, etc.), or
   - **Soft delete / deactivate** (e.g. set `is_active=False`, clear sessions/tokens).
4. **Response:**
   - Success: HTTP **200** or **204** (no body required).
   - Failure: 4xx/5xx; the app will treat this as "server could not delete" and show the user a message to contact support.

---

## Example Django implementation (conceptual)

```python
# views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

@api_view(['DELETE', 'POST'])
@permission_classes([IsAuthenticated])
def delete_account(request):
    user = request.user
    # Optional: anonymize or delete related data (feedback, etc.)
    # Then deactivate or delete:
    user.is_active = False
    user.save()
    # Or: user.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)
```

Wire the view to `/api/auth/delete-account/` in your URLs.

---

## After the backend is fixed

- The app will call this URL with the user’s token.
- On 200/204, the app treats the account as deleted on the server.
- On error, the app still logs the user out locally and shows: *"Account removed from this device. Server could not delete account—contact support@easytechnologiez.com to remove your data."*

Once the endpoint is implemented and returns 200 or 204, "Delete account" will remove (or deactivate) the user on the backend as well.
