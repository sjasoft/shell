# Nousplus + Authentik Integration Guide

## Configuration

**Authentik Server**: `http://localhost:9000`
**Client ID**: `vh3fvYHRLAZhlVq8bIMD3YTcsHormos6NEBIjX7P`
**Client Secret**: `VMfa8MBiz91u8FHUlkHZR3Vg7upD23RmX4lCyJSAGvmk8aQh72cF9gkQam21vpom4Hqs65ouVQNt6J0ABmjbaDuxkkv4M26ghyQamCga4Xc6XTZBH8zwlWSXBmcM7Lx5`

**Configured Redirect URIs**:
- `http://localhost:8888/callback` (desktop app)
- `http://localhost:3000/callback` (web dev)
- `nousplus://callback` (mobile app)

## Desktop App Integration (Python/Qt/Electron)

### 1. Install OAuth2 Library

```bash
# Python
pip install requests

# For JWT decoding (optional)
pip install pyjwt
```

### 2. Implementation Flow

```python
import hashlib
import base64
import secrets
import urllib.parse
import requests
import webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler

AUTH_SERVER = "http://localhost:9000"
CLIENT_ID = "vh3fvYHRLAZhlVq8bIMD3YTcsHormos6NEBIjX7P"
CLIENT_SECRET = "VMfa8MBiz91u8FHUlkHZR3Vg7upD23RmX4lCyJSAGvmk8aQh72cF9gkQam21vpom4Hqs65ouVQNt6J0ABmjbaDuxkkv4M26ghyQamCga4Xc6XTZBH8zwlWSXBmcM7Lx5"
REDIRECT_URI = "http://localhost:8888/callback"

# 1. Generate PKCE parameters
def generate_pkce():
    verifier = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode('utf-8')).digest()
    ).decode('utf-8').rstrip('=')
    return verifier, challenge

# 2. Build authorization URL and open browser
code_verifier, code_challenge = generate_pkce()
auth_url = f"{AUTH_SERVER}/application/o/authorize/?" + urllib.parse.urlencode({
    'client_id': CLIENT_ID,
    'response_type': 'code',
    'redirect_uri': REDIRECT_URI,
    'scope': 'openid email profile',
    'code_challenge': code_challenge,
    'code_challenge_method': 'S256',
    'state': secrets.token_urlsafe(16)
})

webbrowser.open(auth_url)

# 3. Receive callback (start simple HTTP server)
# See oauth2_flow_demo.py for full CallbackHandler implementation

# 4. Exchange code for JWTs
token_response = requests.post(
    f"{AUTH_SERVER}/application/o/token/",
    data={
        'grant_type': 'authorization_code',
        'code': authorization_code,
        'redirect_uri': REDIRECT_URI,
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'code_verifier': code_verifier
    }
)

tokens = token_response.json()
# tokens now contains:
# - access_token: Use for API authentication
# - id_token: User identity information
# - expires_in: Token validity period
```

### 3. Using the Access Token

```python
# Make authenticated API requests
headers = {
    'Authorization': f'Bearer {tokens["access_token"]}'
}
response = requests.get('https://your-api.com/endpoint', headers=headers)
```

### 4. Decoding the ID Token (User Info)

```python
import jwt

# Decode without verification (verification requires public key)
id_payload = jwt.decode(tokens['id_token'], options={"verify_signature": False})

# Access user information
user_email = id_payload['email']
user_name = id_payload['name']
user_groups = id_payload['groups']
```

## Mobile App Integration (iOS/Android)

### iOS (Swift)

```swift
import AuthenticationServices

let authURL = URL(string: "http://localhost:9000/application/o/authorize/?...")!
let callbackScheme = "nousplus"

let session = ASWebAuthenticationSession(
    url: authURL,
    callbackURLScheme: callbackScheme
) { callbackURL, error in
    guard let url = callbackURL,
          let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value else {
        return
    }

    // Exchange code for tokens
    exchangeCodeForTokens(code)
}

session.presentationContextProvider = self
session.start()
```

### Android (Kotlin)

```kotlin
import net.openid.appauth.*

val serviceConfig = AuthorizationServiceConfiguration(
    Uri.parse("http://localhost:9000/application/o/authorize/"),
    Uri.parse("http://localhost:9000/application/o/token/")
)

val authRequest = AuthorizationRequest.Builder(
    serviceConfig,
    CLIENT_ID,
    ResponseTypeValues.CODE,
    Uri.parse("nousplus://callback")
).setScope("openid email profile")
 .setCodeVerifier(codeVerifier)
 .build()

authService.performAuthorizationRequest(authRequest) { response, ex ->
    // Exchange authorization code for tokens
}
```

## Web App Integration (JavaScript/React)

```javascript
// Use a library like @authjs/core or oidc-client-ts

import { UserManager } from 'oidc-client-ts';

const userManager = new UserManager({
    authority: 'http://localhost:9000/application/o/nousplus/',
    client_id: 'vh3fvYHRLAZhlVq8bIMD3YTcsHormos6NEBIjX7P',
    redirect_uri: 'http://localhost:3000/callback',
    response_type: 'code',
    scope: 'openid email profile',
});

// Start login
userManager.signinRedirect();

// Handle callback
userManager.signinRedirectCallback()
    .then(user => {
        console.log('Access Token:', user.access_token);
        console.log('ID Token:', user.id_token);
    });
```

## Token Refresh (Long-lived Sessions)

To keep users logged in without re-authentication:

```python
# When access_token expires, use refresh_token
refresh_response = requests.post(
    f"{AUTH_SERVER}/application/o/token/",
    data={
        'grant_type': 'refresh_token',
        'refresh_token': tokens['refresh_token'],
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET
    }
)

new_tokens = refresh_response.json()
# Update access_token for continued API access
```

## Security Best Practices

1. **Never log or expose tokens** in console/logs
2. **Store tokens securely**:
   - Desktop: OS keychain (macOS Keychain, Windows Credential Manager)
   - Mobile: iOS Keychain, Android KeyStore
   - Web: HttpOnly cookies (not localStorage)
3. **Always use PKCE** (code_challenge/verifier)
4. **Validate ID token** signature before trusting claims
5. **Use HTTPS in production** (not http)

## Testing Users

- **Username**: `nous1`
- **Password**: `Untracked2-Fondly0-Mumbling0-Stardust4-Resonate4`

- **Admin Username**: `akadmin`
- **Admin Password**: (your admin password)

## Troubleshooting

### "invalid_grant" error
- Verify redirect URI matches exactly (including trailing slash)
- Check authorization code hasn't expired (use within 60 seconds)
- Ensure code_verifier matches the code_challenge used

### "redirect_uri_mismatch" error
- Add the redirect URI to Authentik provider configuration
- URIs must match character-for-character

### CORS errors (web apps)
- Configure CORS settings in your API backend
- Authentik allows OAuth2 requests from any origin

## Next Steps

1. **Implement in your app** using examples above
2. **Add custom claims** to JWTs via Authentik property mappings
3. **Set up user registration** flow if needed
4. **Configure refresh token** expiry for your use case

## Demo Script

Run the full demo:
```bash
cd ~/shell/docker/authentik
python3 oauth2_flow_demo.py
```

This demonstrates the complete OAuth2 flow and shows you the JWTs received from Authentik!
