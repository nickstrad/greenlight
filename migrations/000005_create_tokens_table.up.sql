create table if not exists tokens (
    password_hash bytea primary key,
    user_id bigint not null references users on delete cascade,
    expiry timestamp(0) with time zone not null,
    scope text not null
);