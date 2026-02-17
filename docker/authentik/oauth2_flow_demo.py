#!/usr/bin/env python3
"""
OAuth2 Authorization Code Flow with PKCE - Demo
This demonstrates how to get JWTs from Authentik without generating them yourself.
"""

import hashlib
import base64
import secrets
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import requests
import json
import webbrowser

# Authentik configuration
AUTH_SERVER = "http://localhost:9000"
CLIENT_ID = "vh3fvYHRLAZhlVq8bIMD3YTcsHormos6NEBIjX7P"
CLIENT_SECRET = "VMfa8MBiz91u8FHUlkHZR3Vg7upD23RmX4lCyJSAGvmk8aQh72cF9gkQam21vpom4Hqs65ouVQNt6J0ABmjbaDuxkkv4M26ghyQamCga4Xc6XTZBH8zwlWSXBmcM7Lx5"
REDIRECT_URI = "http://localhost:8888/callback"
SCOPE = "openid email profile"

# PKCE helpers
def generate_code_verifier():
    """Generate a code verifier for PKCE"""
    return base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8').rstrip('=')

def generate_code_challenge(verifier):
    """Generate code challenge from verifier"""
    digest = hashlib.sha256(verifier.encode('utf-8')).digest()
    return base64.urlsafe_b64encode(digest).decode('utf-8').rstrip('=')

class CallbackHandler(BaseHTTPRequestHandler):
    """HTTP server to receive OAuth2 callback"""
    auth_code = None

    def do_GET(self):
        # Parse the authorization code from the callback URL
        parsed = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(parsed.query)

        if 'code' in params:
            CallbackHandler.auth_code = params['code'][0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(b"""
                <html><body>
                <h1>Authentication Successful!</h1>
                <p>You can close this window and return to your application.</p>
                <script>window.close();</script>
                </body></html>
            """)
        else:
            self.send_response(400)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            error = params.get('error', ['Unknown error'])[0]
            self.wfile.write(f"<html><body><h1>Error: {error}</h1></body></html>".encode())

    def log_message(self, format, *args):
        pass  # Suppress server logs

def main():
    print("=" * 70)
    print("OAuth2 Authorization Code Flow with PKCE - Demo")
    print("=" * 70)
    print()

    # Step 1: Generate PKCE parameters
    print("Step 1: Generating PKCE parameters...")
    code_verifier = generate_code_verifier()
    code_challenge = generate_code_challenge(code_verifier)
    state = secrets.token_urlsafe(16)
    print(f"  ✓ Code challenge generated")
    print()

    # Step 2: Build authorization URL
    print("Step 2: Building authorization URL...")
    auth_params = {
        'client_id': CLIENT_ID,
        'response_type': 'code',
        'redirect_uri': REDIRECT_URI,
        'scope': SCOPE,
        'state': state,
        'code_challenge': code_challenge,
        'code_challenge_method': 'S256',
    }
    auth_url = f"{AUTH_SERVER}/application/o/authorize/?" + urllib.parse.urlencode(auth_params)
    print(f"  ✓ Authorization URL ready")
    print()

    # Step 3: Start local server and open browser
    print("Step 3: Starting local callback server on port 8888...")
    server = HTTPServer(('localhost', 8888), CallbackHandler)
    server.timeout = 120  # 2 minutes timeout
    print("  ✓ Server started")
    print()

    print("Step 4: Opening browser for authentication...")
    print(f"  URL: {auth_url}")
    print()
    print("  → Please log in with:")
    print("     Username: nous1")
    print("     Password: Untracked2-Fondly0-Mumbling0-Stardust4-Resonate4")
    print()

    webbrowser.open(auth_url)

    # Wait for callback
    print("  ⏳ Waiting for authentication callback...")
    server.handle_request()
    server.server_close()

    if not CallbackHandler.auth_code:
        print("  ✗ No authorization code received")
        return

    print(f"  ✓ Authorization code received: {CallbackHandler.auth_code[:20]}...")
    print()

    # Step 5: Exchange code for tokens
    print("Step 5: Exchanging authorization code for JWT tokens...")
    token_url = f"{AUTH_SERVER}/application/o/token/"
    token_data = {
        'grant_type': 'authorization_code',
        'code': CallbackHandler.auth_code,
        'redirect_uri': REDIRECT_URI,
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'code_verifier': code_verifier,
    }

    try:
        response = requests.post(token_url, data=token_data)
        response.raise_for_status()
        tokens = response.json()

        print("  ✓ JWT tokens received from Authentik!")
        print()
        print("=" * 70)
        print("SUCCESS! Authentik-Generated JWTs:")
        print("=" * 70)
        print()
        print("Access Token (JWT):")
        print(f"  {tokens['access_token'][:80]}...")
        print()
        print("ID Token (JWT):")
        print(f"  {tokens['id_token'][:80]}...")
        print()
        print("Refresh Token:")
        print(f"  {tokens.get('refresh_token', 'N/A')[:80]}...")
        print()
        print("Token Type:", tokens.get('token_type', 'Bearer'))
        print("Expires In:", tokens.get('expires_in', 'N/A'), "seconds")
        print("Scope:", tokens.get('scope', 'N/A'))
        print()

        # Decode and show ID token payload (without verification for demo)
        print("=" * 70)
        print("ID Token Payload (decoded):")
        print("=" * 70)
        try:
            import jwt
            id_payload = jwt.decode(tokens['id_token'], options={"verify_signature": False})
            print(json.dumps(id_payload, indent=2))
        except ImportError:
            # Manually decode (not secure, just for demo)
            parts = tokens['id_token'].split('.')
            if len(parts) >= 2:
                payload = parts[1] + '=' * (4 - len(parts[1]) % 4)
                decoded = base64.urlsafe_b64decode(payload).decode('utf-8')
                print(json.dumps(json.loads(decoded), indent=2))
        print()

        print("=" * 70)
        print("Your app now has valid JWTs from Authentik!")
        print("Use these tokens to authenticate API requests.")
        print("=" * 70)

    except requests.exceptions.HTTPError as e:
        print(f"  ✗ Token exchange failed: {e}")
        print(f"  Response: {e.response.text}")
    except Exception as e:
        print(f"  ✗ Error: {e}")

if __name__ == '__main__':
    main()
