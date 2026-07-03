from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import settings

ALGORITHM = "HS256"
DEFAULT_EXPIRE_MINUTES = 60 * 8  # 8 часов

# bcrypt работает максимум с 72 байтами пароля и на длинном вводе кидает
# ValueError. Обрезаем сами — и при хешировании, и при проверке, одинаково,
# иначе длинный пароль нельзя было бы ни задать, ни ввести.
_BCRYPT_MAX_BYTES = 72


def _prepare(password: str) -> bytes:
    return password.encode("utf-8")[:_BCRYPT_MAX_BYTES]


def hash_password(password: str) -> str:
    return bcrypt.hashpw(_prepare(password), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(_prepare(plain_password), password_hash.encode("utf-8"))
    except ValueError:
        # Битый/чужого формата хеш в БД — это не «пароль подошёл».
        return False


def create_access_token(data: dict, expires_minutes: int = DEFAULT_EXPIRE_MINUTES) -> str:
    """data должен содержать как минимум {"sub": <id>, "type": "staff"|"client"} —
    поле "type" разделяет токены сотрудников и клиентов, чтобы один не подходил
    вместо другого."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=expires_minutes)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Бросает jwt.PyJWTError (или подклассы), если токен невалиден/просрочен."""
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
