-- =====================================================================
-- SkillMate – өгөгдлийн сангийн схем (Supabase / PostgreSQL)
-- Supabase Dashboard → SQL Editor дээр бүтнээр нь нэг удаа ажиллуулна.
-- =====================================================================

-- 1) Хүснэгтүүд ------------------------------------------------------
create table profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  full_name       text not null default '',
  university      text,
  major           text,
  year            int check (year between 1 and 8),
  bio             text,
  avatar_url      text,
  mbti            text check (mbti ~ '^[EI][NS][TF][JP]$'),
  zodiac          text,
  location        text,
  values_list     text[] not null default '{}',
  mbti_public     boolean not null default false,   -- эмзэг мэдээлэл анхдагчаар нуугдана
  values_public   boolean not null default false,
  show_university boolean not null default true,
  is_verified     boolean not null default false,
  role            text not null default 'user' check (role in ('user','admin')),
  created_at      timestamptz not null default now()
);

create table skill_categories (
  id   bigint generated always as identity primary key,
  name text not null unique
);

create table skills (
  id          bigint generated always as identity primary key,
  category_id bigint references skill_categories(id) on delete set null,
  name        text not null unique
);

create table user_skills (
  id       bigint generated always as identity primary key,
  user_id  uuid   not null references profiles(id) on delete cascade,
  skill_id bigint not null references skills(id) on delete cascade,
  type     text   not null check (type in ('offer','want')),
  level    text   not null default 'beginner' check (level in ('beginner','intermediate','advanced')),
  unique (user_id, skill_id, type)
);

create table hobbies (
  id   bigint generated always as identity primary key,
  name text not null unique
);

create table user_hobbies (
  user_id  uuid   not null references profiles(id) on delete cascade,
  hobby_id bigint not null references hobbies(id) on delete cascade,
  primary key (user_id, hobby_id)
);

create table availability (
  id      bigint generated always as identity primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  slot    text not null check (slot in ('morning','afternoon','evening')),
  unique (user_id, weekday, slot)
);

-- Нийцлийн оноог MVP-д апп дотор тооцдог. Энэ хүснэгт нь цаашид кэш хийх зориулалттай.
create table matches (
  id          bigint generated always as identity primary key,
  user_a      uuid not null references profiles(id) on delete cascade,
  user_b      uuid not null references profiles(id) on delete cascade,
  score       int  not null check (score between 0 and 100),
  reasons     jsonb not null default '[]',
  computed_at timestamptz not null default now(),
  unique (user_a, user_b),
  check (user_a <> user_b)
);

create table requests (
  id               bigint generated always as identity primary key,
  sender_id        uuid   not null references profiles(id) on delete cascade,
  receiver_id      uuid   not null references profiles(id) on delete cascade,
  offered_skill_id bigint not null,
  wanted_skill_id  bigint not null,
  message          text,
  status           text   not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at       timestamptz not null default now(),
  constraint requests_offered_skill_id_fkey foreign key (offered_skill_id) references skills(id),
  constraint requests_wanted_skill_id_fkey  foreign key (wanted_skill_id)  references skills(id),
  check (sender_id <> receiver_id),
  unique (sender_id, receiver_id)
);

create table messages (
  id         bigint generated always as identity primary key,
  request_id bigint not null references requests(id) on delete cascade,
  sender_id  uuid   not null references profiles(id) on delete cascade,
  content    text   not null check (length(content) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table blocks (
  blocker_id   uuid not null references profiles(id) on delete cascade,
  blocked_id   uuid not null references profiles(id) on delete cascade,
  blocked_name text not null default '',
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table reports (
  id          bigint generated always as identity primary key,
  reporter_id uuid not null references profiles(id) on delete cascade,
  reported_id uuid not null references profiles(id) on delete cascade,
  reason      text not null,
  status      text not null default 'open' check (status in ('open','reviewed','dismissed')),
  created_at  timestamptz not null default now()
);

-- 2) Индексүүд -------------------------------------------------------
create index on user_skills (skill_id, type);
create index on user_skills (user_id);
create index on requests (receiver_id, status);
create index on requests (sender_id);
create index on messages (request_id, created_at);
create index on availability (user_id);

-- 3) Бүртгэл: профайл автоматаар үүсгэх, их сургуулийн имэйл шаардах ---
-- Профайлыг auth.users-д мөр орсны ДАРАА үүсгэнэ (FK зөрчихгүйн тулд after insert).
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name, university)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name',''),
          upper(split_part(split_part(new.email,'@',2),'.',1)));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- Зөвхөн их сургуулийн (.edu.mn) имэйлийг зөвшөөрөх.
-- Туршиж үзэх үедээ энэ trigger-ийг түр устгаж болно: drop trigger on_auth_user_domain on auth.users;
create or replace function check_email_domain() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.email not like '%.edu.mn' then
    raise exception 'Зөвхөн их сургуулийн (.edu.mn) имэйлээр бүртгүүлнэ';
  end if;
  return new;
end $$;
create trigger on_auth_user_domain before insert on auth.users
  for each row execute function check_email_domain();

create or replace function handle_email_confirmed() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.email_confirmed_at is not null then
    update profiles set is_verified = true where id = new.id;
  end if;
  return new;
end $$;
create trigger on_auth_user_confirmed after update of email_confirmed_at on auth.users
  for each row execute function handle_email_confirmed();

-- 4) Бусдад харагдах профайлын view (нууцлал + блок хамгаалалт) -------
create view public_profiles as
select p.id, p.full_name,
       case when p.show_university then p.university end as university,
       p.major, p.year, p.bio, p.avatar_url, p.location, p.is_verified,
       case when p.mbti_public   then p.mbti end        as mbti,
       case when p.values_public then p.values_list else '{}'::text[] end as values_list
from profiles p
where not exists (
  select 1 from blocks b
  where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
     or (b.blocker_id = p.id and b.blocked_id = auth.uid())
);
grant select on public_profiles to authenticated;

-- 5) Row Level Security ------------------------------------------------
alter table profiles         enable row level security;
alter table skill_categories enable row level security;
alter table skills           enable row level security;
alter table user_skills      enable row level security;
alter table hobbies          enable row level security;
alter table user_hobbies     enable row level security;
alter table availability     enable row level security;
alter table matches          enable row level security;
alter table requests         enable row level security;
alter table messages         enable row level security;
alter table blocks           enable row level security;
alter table reports          enable row level security;

create policy "own profile read"   on profiles for select using (id = auth.uid());
create policy "own profile update" on profiles for update using (id = auth.uid()) with check (id = auth.uid());
-- role, is_verified-ийг хэрэглэгч өөрчилж чадахгүй (column-level эрх):
revoke update on profiles from authenticated;
grant update (full_name, university, major, year, bio, avatar_url, mbti, zodiac, location,
              values_list, mbti_public, values_public, show_university) on profiles to authenticated;

create policy "categories read" on skill_categories for select to authenticated using (true);
create policy "skills read"     on skills for select to authenticated using (true);
create policy "skills insert"   on skills for insert to authenticated with check (true);
create policy "hobbies read"    on hobbies for select to authenticated using (true);

create policy "user_skills read"   on user_skills for select to authenticated using (true);
create policy "user_skills write"  on user_skills for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_hobbies read"  on user_hobbies for select to authenticated using (true);
create policy "user_hobbies write" on user_hobbies for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "availability read"  on availability for select to authenticated using (true);
create policy "availability write" on availability for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "matches read" on matches for select using (user_a = auth.uid() or user_b = auth.uid());

create policy "requests read" on requests for select using (sender_id = auth.uid() or receiver_id = auth.uid());
create policy "requests insert" on requests for insert with check (
  sender_id = auth.uid()
  and not exists (select 1 from blocks b
                  where (b.blocker_id = receiver_id and b.blocked_id = sender_id)
                     or (b.blocker_id = sender_id and b.blocked_id = receiver_id)));
create policy "requests respond" on requests for update using (receiver_id = auth.uid()) with check (receiver_id = auth.uid());
revoke update on requests from authenticated;
grant update (status) on requests to authenticated;

create policy "messages read" on messages for select using (
  exists (select 1 from requests r where r.id = request_id and r.status = 'accepted'
          and auth.uid() in (r.sender_id, r.receiver_id)));
create policy "messages insert" on messages for insert with check (
  sender_id = auth.uid()
  and exists (select 1 from requests r where r.id = request_id and r.status = 'accepted'
              and auth.uid() in (r.sender_id, r.receiver_id)
              and not exists (select 1 from blocks b
                              where (b.blocker_id = r.sender_id and b.blocked_id = r.receiver_id)
                                 or (b.blocker_id = r.receiver_id and b.blocked_id = r.sender_id))));

create policy "blocks own"       on blocks  for all using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());
create policy "reports insert"   on reports for insert with check (reporter_id = auth.uid());
create policy "reports read own" on reports for select using (reporter_id = auth.uid());

-- 6) Realtime (чат) ----------------------------------------------------
alter publication supabase_realtime add table messages;

-- 7) Анхны өгөгдөл -----------------------------------------------------
insert into skill_categories (name) values ('Хөгжим'),('Програмчлал'),('Хэл'),('Дизайн'),('Спорт'),('Тоглоом');
insert into skills (category_id, name) values
 (1,'Guitar'),(1,'Piano'),(2,'Python'),(2,'JavaScript'),(2,'Flutter'),
 (3,'English'),(3,'Korean'),(3,'Japanese'),(4,'Photoshop'),(4,'Figma'),
 (5,'Basketball'),(5,'Swimming'),(6,'Chess');
insert into hobbies (name) values ('Шатар'),('Кино'),('Хөгжим'),('Аялал'),('Ном унших'),('Зураг авалт'),('Спорт'),('Тоглоом'),('Хоол хийх');
