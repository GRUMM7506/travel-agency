"""client accounts: password_hash + is_registered on clients

Revision ID: 0004
Revises: 0003
Create Date: 2026-08-30 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0004'
down_revision = '0003'
branch_labels = None
depends_on = None


def upgrade():
    # Логин клиента живёт прямо на карточке клиента — отдельной таблицы нет,
    # т.к. это один и тот же человек: заведённый сотрудником вручную либо
    # зарегистрировавшийся сам.
    op.add_column('clients', sa.Column('password_hash', sa.String(255), nullable=True))
    op.add_column(
        'clients',
        sa.Column('is_registered', sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    # Быстрый поиск клиента по email при логине (регистронезависимо).
    op.create_index('ix_clients_email_lower', 'clients', [sa.text('lower(email)')])


def downgrade():
    op.drop_index('ix_clients_email_lower', table_name='clients')
    op.drop_column('clients', 'is_registered')
    op.drop_column('clients', 'password_hash')
