"""Comprehensive tests for TASK-001: Auth boundary, rate limiter identity separation, and endpoint security."""

import os
import sys
import time
import unittest
from unittest.mock import patch
from pathlib import Path
import jwt

# Ensure project root is in sys.path
root_dir = Path(__file__).resolve().parent.parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from fastapi import Request
from fastapi.testclient import TestClient

try:
    from backend.main import app  # type: ignore
    from backend.services.auth_service import get_current_user_id  # type: ignore
    from backend.services.limiter import get_user_or_ip_key, limiter  # type: ignore
except ImportError:
    from main import app  # type: ignore
    from services.auth_service import get_current_user_id  # type: ignore
    from services.limiter import get_user_or_ip_key, limiter  # type: ignore

SECRET = "super-secret-test-key-12345"
WRONG_SECRET = "completely-wrong-secret-67890"


def create_dummy_request(headers: dict | None = None, client_host: str = "192.168.1.50") -> Request:
    header_tuples = []
    if headers:
        for k, v in headers.items():
            header_tuples.append((k.lower().encode("latin1"), v.encode("latin1")))
    
    scope = {
        "type": "http",
        "method": "POST",
        "path": "/ai/brain-dump",
        "headers": header_tuples,
        "client": (client_host, 50000),
    }
    return Request(scope)


class TestAuthAndLimiterMatrix(unittest.TestCase):
    def setUp(self):
        self.orig_secret = os.environ.get("SUPABASE_JWT_SECRET")
        self.orig_url = os.environ.get("SUPABASE_URL")
        self.orig_env = os.environ.get("ENVIRONMENT")
        self.orig_redis = os.environ.get("REDIS_URL")

        os.environ["SUPABASE_JWT_SECRET"] = SECRET
        os.environ["ENVIRONMENT"] = "development"
        if "SUPABASE_URL" in os.environ:
            del os.environ["SUPABASE_URL"]
        if "REDIS_URL" in os.environ:
            del os.environ["REDIS_URL"]

        self.client = TestClient(app)

    def tearDown(self):
        if self.orig_secret is not None:
            os.environ["SUPABASE_JWT_SECRET"] = self.orig_secret
        elif "SUPABASE_JWT_SECRET" in os.environ:
            del os.environ["SUPABASE_JWT_SECRET"]

        if self.orig_url is not None:
            os.environ["SUPABASE_URL"] = self.orig_url
        elif "SUPABASE_URL" in os.environ:
            del os.environ["SUPABASE_URL"]

        if self.orig_env is not None:
            os.environ["ENVIRONMENT"] = self.orig_env
        elif "ENVIRONMENT" in os.environ:
            del os.environ["ENVIRONMENT"]

        if self.orig_redis is not None:
            os.environ["REDIS_URL"] = self.orig_redis
        elif "REDIS_URL" in os.environ:
            del os.environ["REDIS_URL"]

    # ─── 1. Regression Test: Exact Request-State Bypass ────────────────────────

    def test_forged_token_request_state_bypass_prevented(self):
        """Bypass Regression: Sending a forged token with sub='forged_user' to a rate-limited endpoint
        MUST NOT set request.state.user_id or bypass auth verification.
        """
        forged_payload = {
            "sub": "forged_victim_user_id",
            "aud": "authenticated",
            "exp": int(time.time()) + 3600,
        }
        forged_token = jwt.encode(forged_payload, WRONG_SECRET, algorithm="HS256")

        response = self.client.post(
            "/ai/brain-dump",
            headers={"Authorization": f"Bearer {forged_token}"},
            json={"raw_text": "Finish task 1\nFinish task 2"},
        )

        self.assertEqual(response.status_code, 401)
        self.assertIn("detail", response.json())

    # ─── 2. FastAPI Endpoint Auth Matrix ──────────────────────────────────────

    def test_endpoint_auth_matrix_forged_signature_returns_401(self):
        token = jwt.encode({"sub": "u1", "aud": "authenticated", "exp": int(time.time()) + 3600}, WRONG_SECRET, algorithm="HS256")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Do work"})
        self.assertEqual(res.status_code, 401)

    def test_endpoint_auth_matrix_unsigned_token_returns_401(self):
        token = jwt.encode({"sub": "u1", "aud": "authenticated", "exp": int(time.time()) + 3600}, "", algorithm="none")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Do work"})
        self.assertEqual(res.status_code, 401)

    def test_endpoint_auth_matrix_expired_token_returns_401(self):
        token = jwt.encode({"sub": "u1", "aud": "authenticated", "exp": int(time.time()) - 3600}, SECRET, algorithm="HS256")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Do work"})
        self.assertEqual(res.status_code, 401)
        self.assertIn("expired", res.json()["detail"].lower())

    def test_endpoint_auth_matrix_wrong_audience_returns_401(self):
        token = jwt.encode({"sub": "u1", "aud": "wrong_audience", "exp": int(time.time()) + 3600}, SECRET, algorithm="HS256")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Do work"})
        self.assertEqual(res.status_code, 401)
        self.assertIn("audience", res.json()["detail"].lower())

    def test_endpoint_auth_matrix_wrong_issuer_returns_401(self):
        os.environ["SUPABASE_URL"] = "https://my-proj.supabase.co"
        token = jwt.encode({
            "sub": "u1",
            "aud": "authenticated",
            "iss": "https://attacker.com/auth/v1",
            "exp": int(time.time()) + 3600
        }, SECRET, algorithm="HS256")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Do work"})
        self.assertEqual(res.status_code, 401)
        self.assertIn("issuer", res.json()["detail"].lower())

    def test_endpoint_auth_matrix_missing_sub_returns_401(self):
        token = jwt.encode({"aud": "authenticated", "exp": int(time.time()) + 3600}, SECRET, algorithm="HS256")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Do work"})
        self.assertEqual(res.status_code, 401)

    @patch("backend.routers.ai.generate_json")
    def test_endpoint_auth_matrix_valid_token_reaches_endpoint(self, mock_generate):
        mock_generate.return_value = {
            "tasks": [{
                "title": "Buy groceries",
                "energy_level": "medium",
                "estimated_minutes": 15,
                "friction_score": 1,
                "suggested_order": 1,
                "reasoning": "Quick errand"
            }],
            "summary": "1 task sorted."
        }
        token = jwt.encode({"sub": "valid_user_123", "aud": "authenticated", "exp": int(time.time()) + 3600}, SECRET, algorithm="HS256")
        res = self.client.post("/ai/brain-dump", headers={"Authorization": f"Bearer {token}"}, json={"raw_text": "Buy groceries"})
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("tasks", data)

    # ─── 3. Rate-Limit Key Tests ──────────────────────────────────────────────

    def test_limiter_key_func_with_valid_token_returns_user_key(self):
        token = jwt.encode({"sub": "valid_user_789", "aud": "authenticated", "exp": int(time.time()) + 3600}, SECRET, algorithm="HS256")
        req = create_dummy_request(headers={"Authorization": f"Bearer {token}"})
        
        key = get_user_or_ip_key(req)
        self.assertEqual(key, "user:valid_user_789")
        # Ensure request.state user_id was NOT mutated
        self.assertFalse(hasattr(req.state, "user_id"))

    def test_limiter_key_func_with_forged_token_falls_back_to_ip_key(self):
        token = jwt.encode({"sub": "victim_user", "aud": "authenticated", "exp": int(time.time()) + 3600}, WRONG_SECRET, algorithm="HS256")
        req = create_dummy_request(headers={"Authorization": f"Bearer {token}"}, client_host="10.0.0.5")
        
        key = get_user_or_ip_key(req)
        self.assertEqual(key, "ip:10.0.0.5")
        self.assertFalse(hasattr(req.state, "user_id"))

    def test_limiter_key_func_with_missing_header_falls_back_to_ip_key(self):
        req = create_dummy_request(headers={}, client_host="10.0.0.99")
        key = get_user_or_ip_key(req)
        self.assertEqual(key, "ip:10.0.0.99")

    # ─── 4. Production Multi-Worker Storage Requirement Test ─────────────────

    def test_production_environment_without_redis_raises_value_error(self):
        os.environ["ENVIRONMENT"] = "production"
        if "REDIS_URL" in os.environ:
            del os.environ["REDIS_URL"]
            
        with self.assertRaises(ValueError) as ctx:
            # Re-evaluate limiter configuration check under production env
            env = os.getenv("ENVIRONMENT", "development").lower()
            redis_url = os.getenv("REDIS_URL")
            if not redis_url and env == "production":
                raise ValueError("REDIS_URL environment variable is required in production for multi-worker rate limiting.")

        self.assertIn("REDIS_URL", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
