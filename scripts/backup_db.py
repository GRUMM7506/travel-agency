"""Бэкап локальной БД travel_agency_db в scripts/backups/.

Запуск: scripts/backup-db.bat (или напрямую python scripts/backup_db.py)
Берёт параметры подключения из backend/.env.
"""
import glob
import os
import shutil
import subprocess
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _db_env import ENV_PATH, load_env, URL_RE  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BACKUPS_DIR = os.path.join(HERE, "backups")


def find_pg_dump() -> str:
    found = shutil.which("pg_dump")
    if found:
        return found
    candidates = sorted(
        glob.glob(r"C:\Program Files\PostgreSQL\*\bin\pg_dump.exe"),
        reverse=True,
    )
    if candidates:
        return candidates[0]
    print(
        "ERROR: pg_dump не найден ни в PATH, ни в C:\\Program Files\\PostgreSQL\\*\\bin. "
        "Установите PostgreSQL client tools или добавьте pg_dump в PATH.",
        file=sys.stderr,
    )
    sys.exit(1)


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

    pg_dump = find_pg_dump()
    os.makedirs(BACKUPS_DIR, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = os.path.join(BACKUPS_DIR, f"{dbname}_{timestamp}.backup")

    cmd = [
        pg_dump,
        "-h", host,
        "-p", port,
        "-U", user,
        "-d", dbname,
        "-F", "c",
        "-f", out_path,
    ]

    proc_env = os.environ.copy()
    proc_env["PGPASSWORD"] = password

    print(f"Бэкап {dbname}@{host}:{port} -> {out_path}")
    result = subprocess.run(cmd, env=proc_env)
    if result.returncode != 0:
        print("ERROR: pg_dump завершился с ошибкой.", file=sys.stderr)
        sys.exit(result.returncode)

    size_mb = os.path.getsize(out_path) / (1024 * 1024)
    print(f"Готово: {out_path} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
