"""Восстанавливает БД travel_agency_db из бэкапа, сделанного backup_db.py.

Запуск: scripts/restore-db.bat [путь_к_файлу.backup]
Если путь не указан — берётся самый свежий файл из scripts/backups/.
Параметры подключения — из backend/.env. ВНИМАНИЕ: перезаписывает текущую БД.
"""
import glob
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _db_env import ENV_PATH, load_env, URL_RE  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
BACKUPS_DIR = os.path.join(HERE, "backups")


def find_pg_restore() -> str:
    found = shutil.which("pg_restore")
    if found:
        return found
    candidates = sorted(
        glob.glob(r"C:\Program Files\PostgreSQL\*\bin\pg_restore.exe"),
        reverse=True,
    )
    if candidates:
        return candidates[0]
    print(
        "ERROR: pg_restore не найден ни в PATH, ни в C:\\Program Files\\PostgreSQL\\*\\bin.",
        file=sys.stderr,
    )
    sys.exit(1)


def pick_backup_file() -> str:
    if len(sys.argv) > 1:
        path = sys.argv[1]
        if not os.path.exists(path):
            print(f"ERROR: файл не найден: {path}", file=sys.stderr)
            sys.exit(1)
        return path

    candidates = sorted(glob.glob(os.path.join(BACKUPS_DIR, "*.backup")))
    if not candidates:
        print(
            f"ERROR: в {BACKUPS_DIR} нет файлов *.backup и путь не передан.\n"
            "Использование: restore-db.bat [путь_к_файлу.backup]",
            file=sys.stderr,
        )
        sys.exit(1)
    return candidates[-1]


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

    backup_file = pick_backup_file()
    pg_restore = find_pg_restore()

    print(f"Восстановить {backup_file}")
    print(f"  в базу {dbname}@{host}:{port} (СУЩЕСТВУЮЩИЕ ДАННЫЕ БУДУТ ЗАМЕНЕНЫ)")
    answer = input("Продолжить? [y/N]: ").strip().lower()
    if answer != "y":
        print("Отменено.")
        return

    cmd = [
        pg_restore,
        "-h", host,
        "-p", port,
        "-U", user,
        "-d", dbname,
        "--clean",
        "--if-exists",
        backup_file,
    ]

    proc_env = os.environ.copy()
    proc_env["PGPASSWORD"] = password

    result = subprocess.run(cmd, env=proc_env)
    if result.returncode != 0:
        print(
            "pg_restore завершился с предупреждениями/ошибками (код "
            f"{result.returncode}) — это нормально для --clean на пустой БД, "
            "проверьте вывод выше.",
        )
        return

    print("Готово.")


if __name__ == "__main__":
    main()
