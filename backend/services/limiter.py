"""Rate Limiter Service — slowapi configuration to prevent circular imports."""

import os
import logging
import jwt
from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address

logger = logging.getLogger("flowos.limiter")

def get_user_or_ip_key(request: Request) -> str:
    """Determine the rate limiting key: user ID if authenticated, fallback to client IP."""
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        try:
            token = auth_header.split(" ")[1]
            jwt_secret = os.getenv("SUPABASE_JWT_SECRET") or os.getenv("JWT_SECRET")
            if jwt_secret:
                # Decode payload without signature check for rate-limiting key extraction
                payload = jwt.decode(token, jwt_secret, algorithms=["HS256"], options={"verify_signature": False})
                user_id = payload.get("sub")
                if user_id:
                    return f"user:{user_id}"
        except Exception:
            pass
    return f"ip:{get_remote_address(request)}"

redis_url = os.getenv("REDIS_URL")
if redis_url:
    logger.info("Initializing Rate Limiter with Redis storage.")
    limiter = Limiter(key_func=get_user_or_ip_key, storage_uri=redis_url)
else:
    logger.warning("REDIS_URL not configured. Rate limiting falls back to process-local memory.")
    limiter = Limiter(key_func=get_user_or_ip_key)
