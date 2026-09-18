"""Достаёт параметры подключения к БД из backend/.env для batch-скриптов.

Печатает одну строку: user\tpassword\thost\tport\tdbname
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(HERE, "..", "backend", ".env")

URL_RE = re.compile(r"^postgresql(?:\+\w+)?://([^:]+):([^@]+)@([^:/]+):(\d+)/(.+)$")


def load_env(path: str) -> dict:
    env = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip()
    return env


def main() -> None:
    if not os.path.exists(ENV_PATH):
        print(
            f"ERROR: не найден {ENV_PATH}. Скопируйте backend/.env.example в "
            "backend/.env и укажите DATABASE_URL вашей локальной БД.",
            file=sys.stderr,
        )
        sys.exit(1)

    env = load_env(ENV_PATH)
    url = env.get("DATABASE_URL", "")
    match = URL_RE.match(url)
    if not match:
        print(f"ERROR: не удалось разобрать DATABASE_URL из .env: {url!r}", file=sys.stderr)
        sys.exit(1)

    user, password, host, port, dbname = match.groups()
    print(f"{user}\t{password}\t{host}\t{port}\t{dbname}")


if __name__ == "__main__":
    main()
