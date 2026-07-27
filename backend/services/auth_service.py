"""Authentication Service — verifies Supabase JWT and extracts user ID."""

import os
import jwt
from typing import Optional
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

def _get_jwt_secret() -> str:
    secret = os.getenv("SUPABASE_JWT_SECRET") or os.getenv("JWT_SECRET")
    if not secret:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="JWT secret not configured on the server."
        )
    return secret


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    request: Request = None,  # type: ignore
) -> str:
    """FastAPI dependency to verify Supabase JWT and return authenticated user ID."""
    token = credentials.credentials
    jwt_secret = _get_jwt_secret()

    try:
        # Decode and verify claims (expiration, signature, algorithms, and audience)
        payload = jwt.decode(
            token,
            jwt_secret,
            algorithms=["HS256"],
            audience="authenticated"
        )
        
        # Verify issuer matches Supabase URL auth endpoint if SUPABASE_URL is configured
        supabase_url = os.getenv("SUPABASE_URL")
        if supabase_url:
            expected_iss = f"{supabase_url.rstrip('/')}/auth/v1"
            if payload.get("iss") != expected_iss:
                raise jwt.InvalidIssuerError("Issuer mismatch")
                
        user_id = payload.get("sub")
        if not user_id or not isinstance(user_id, str):
            raise jwt.InvalidTokenError("Subject (sub) claim missing or invalid")
            
        return user_id
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired."
        )
    except jwt.InvalidAudienceError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token audience."
        )
    except jwt.InvalidIssuerError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token issuer."
        )
    except jwt.PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication token: {e}."
        )
