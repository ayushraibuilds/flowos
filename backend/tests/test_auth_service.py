"""Unit tests for backend/services/auth_service.py."""

import os
import sys
import time
import unittest
from pathlib import Path
import jwt

# Ensure project root is in sys.path
root_dir = Path(__file__).resolve().parent.parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

try:
    from backend.services.auth_service import get_current_user_id
except ImportError:
    from services.auth_service import get_current_user_id

SECRET = "super-secret-test-key-12345"

class TestAuthService(unittest.TestCase):
    def setUp(self):
        self.orig_secret = os.environ.get("SUPABASE_JWT_SECRET")
        self.orig_url = os.environ.get("SUPABASE_URL")
        os.environ["SUPABASE_JWT_SECRET"] = SECRET
        if "SUPABASE_URL" in os.environ:
            del os.environ["SUPABASE_URL"]

    def tearDown(self):
        if self.orig_secret is not None:
            os.environ["SUPABASE_JWT_SECRET"] = self.orig_secret
        elif "SUPABASE_JWT_SECRET" in os.environ:
            del os.environ["SUPABASE_JWT_SECRET"]

        if self.orig_url is not None:
            os.environ["SUPABASE_URL"] = self.orig_url
        elif "SUPABASE_URL" in os.environ:
            del os.environ["SUPABASE_URL"]

    def test_missing_jwt_secret_throws_500(self):
        del os.environ["SUPABASE_JWT_SECRET"]
        if "JWT_SECRET" in os.environ:
            del os.environ["JWT_SECRET"]
        
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="any-token")
        with self.assertRaises(HTTPException) as ctx:
            get_current_user_id(creds)
        self.assertEqual(ctx.exception.status_code, 500)

    def test_valid_token_returns_user_id(self):
        payload = {
            "sub": "user_abc_123",
            "aud": "authenticated",
            "exp": int(time.time()) + 3600
        }
        token = jwt.encode(payload, SECRET, algorithm="HS256")
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        
        user_id = get_current_user_id(creds)
        self.assertEqual(user_id, "user_abc_123")

    def test_expired_token_throws_401(self):
        payload = {
            "sub": "user_abc_123",
            "aud": "authenticated",
            "exp": int(time.time()) - 3600
        }
        token = jwt.encode(payload, SECRET, algorithm="HS256")
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        
        with self.assertRaises(HTTPException) as ctx:
            get_current_user_id(creds)
        self.assertEqual(ctx.exception.status_code, 401)
        self.assertIn("expired", ctx.exception.detail.lower())

    def test_missing_sub_claim_throws_401(self):
        payload = {
            "aud": "authenticated",
            "exp": int(time.time()) + 3600
        }
        token = jwt.encode(payload, SECRET, algorithm="HS256")
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        
        with self.assertRaises(HTTPException) as ctx:
            get_current_user_id(creds)
        self.assertEqual(ctx.exception.status_code, 401)

    def test_issuer_mismatch_throws_401(self):
        os.environ["SUPABASE_URL"] = "https://my-project.supabase.co"
        payload = {
            "sub": "user_abc_123",
            "aud": "authenticated",
            "iss": "https://wrong-project.supabase.co/auth/v1",
            "exp": int(time.time()) + 3600
        }
        token = jwt.encode(payload, SECRET, algorithm="HS256")
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        
        with self.assertRaises(HTTPException) as ctx:
            get_current_user_id(creds)
        self.assertEqual(ctx.exception.status_code, 401)
        self.assertIn("issuer", ctx.exception.detail.lower())
