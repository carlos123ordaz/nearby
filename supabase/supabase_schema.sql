-- ═══════════════════════════════════════════════════════════════════════════
-- NEARBY APP — Supabase Schema
-- Run this in the Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- PROFILES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username         TEXT UNIQUE NOT NULL CHECK (username ~ '^[a-zA-Z0-9_]{3,20}$'),
  display_name     TEXT NOT NULL CHECK (length(display_name) >= 2 AND length(display_name) <= 60),
  avatar_url       TEXT,
  bio              TEXT CHECK (length(bio) <= 500),
  age              INTEGER CHECK (age IS NULL OR (age >= 13 AND age <= 120)),
  interests        TEXT[] DEFAULT '{}',
  status           TEXT NOT NULL DEFAULT 'inactive' CHECK (status IN ('active','invisible','blocked','inactive')),
  is_discoverable  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS profiles_username_idx ON profiles(username);
CREATE INDEX IF NOT EXISTS profiles_status_idx ON profiles(status);
CREATE INDEX IF NOT EXISTS profiles_discoverable_idx ON profiles(is_discoverable) WHERE is_discoverable = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- NEARBY SESSIONS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS nearby_sessions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  ephemeral_ble_id TEXT UNIQUE NOT NULL,
  expires_at       TIMESTAMPTZ NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES profiles(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS nearby_sessions_user_id_idx ON nearby_sessions(user_id);
CREATE INDEX IF NOT EXISTS nearby_sessions_ephemeral_idx ON nearby_sessions(ephemeral_ble_id);
CREATE INDEX IF NOT EXISTS nearby_sessions_expires_idx ON nearby_sessions(expires_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- FRIEND REQUESTS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS friend_requests (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status      TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','cancelled')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT no_self_request CHECK (sender_id <> receiver_id),
  CONSTRAINT unique_pending_request UNIQUE NULLS NOT DISTINCT (sender_id, receiver_id)
);

CREATE INDEX IF NOT EXISTS friend_requests_sender_idx ON friend_requests(sender_id);
CREATE INDEX IF NOT EXISTS friend_requests_receiver_idx ON friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS friend_requests_status_idx ON friend_requests(status);

-- ─────────────────────────────────────────────────────────────────────────────
-- FRIENDSHIPS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS friendships (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_b     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT no_self_friendship CHECK (user_a <> user_b)
);

CREATE UNIQUE INDEX IF NOT EXISTS friendships_unique_pair ON friendships(LEAST(user_a, user_b), GREATEST(user_a, user_b));

CREATE INDEX IF NOT EXISTS friendships_user_a_idx ON friendships(user_a);
CREATE INDEX IF NOT EXISTS friendships_user_b_idx ON friendships(user_b);

-- ─────────────────────────────────────────────────────────────────────────────
-- CONVERSATIONS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conversations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  user_b     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT no_self_conversation CHECK (user_a <> user_b)
);

CREATE UNIQUE INDEX IF NOT EXISTS conversations_unique_pair ON conversations(LEAST(user_a, user_b), GREATEST(user_a, user_b));

CREATE INDEX IF NOT EXISTS conversations_user_a_idx ON conversations(user_a);
CREATE INDEX IF NOT EXISTS conversations_user_b_idx ON conversations(user_b);
CREATE INDEX IF NOT EXISTS conversations_updated_idx ON conversations(updated_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- MESSAGES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content         TEXT NOT NULL CHECK (length(content) > 0 AND length(content) <= 4000),
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS messages_conversation_idx ON messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS messages_sender_idx ON messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_unread_idx ON messages(conversation_id, read_at) WHERE read_at IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- BLOCKS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS blocks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id),
  CONSTRAINT unique_block UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS blocks_blocker_idx ON blocks(blocker_id);
CREATE INDEX IF NOT EXISTS blocks_blocked_idx ON blocks(blocked_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- REPORTS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason      TEXT NOT NULL,
  description TEXT CHECK (length(description) <= 1000),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT no_self_report CHECK (reporter_id <> reported_id)
);

CREATE INDEX IF NOT EXISTS reports_reporter_idx ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS reports_reported_idx ON reports(reported_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGERS: updated_at
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE OR REPLACE TRIGGER friend_requests_updated_at
  BEFORE UPDATE ON friend_requests
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE OR REPLACE TRIGGER conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Accept friend request and create friendship atomically
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION accept_friend_request(request_id UUID)
RETURNS VOID AS $$
DECLARE
  v_sender   UUID;
  v_receiver UUID;
  v_status   TEXT;
BEGIN
  -- Get request details
  SELECT sender_id, receiver_id, status
    INTO v_sender, v_receiver, v_status
    FROM friend_requests
   WHERE id = request_id
     AND receiver_id = auth.uid()
   FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found or unauthorized';
  END IF;

  IF v_status <> 'pending' THEN
    RAISE EXCEPTION 'Request is not pending';
  END IF;

  -- Update request status
  UPDATE friend_requests
     SET status = 'accepted', updated_at = NOW()
   WHERE id = request_id;

  -- Create friendship (ordered to satisfy unique constraint)
  INSERT INTO friendships (user_a, user_b)
  VALUES (
    LEAST(v_sender::TEXT, v_receiver::TEXT)::UUID,
    GREATEST(v_sender::TEXT, v_receiver::TEXT)::UUID
  )
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION accept_friend_request(UUID) TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════
-- FUNCTION: Auto-create profile on signup (email/password + Google OAuth)
-- ═══════════════════════════════════════════════════════════════════════════
-- NOTE: Enable Google provider in Supabase Dashboard →
--       Authentication → Providers → Google
--       and add your Client ID + Secret from Google Cloud Console.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_display_name TEXT;
  v_avatar_url   TEXT;
  v_base         TEXT;
  v_username     TEXT;
BEGIN
  -- Pull display name from Google metadata (full_name / name) or fallback to email local part
  v_display_name := left(COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''),
    NULLIF(trim(NEW.raw_user_meta_data->>'name'), ''),
    split_part(COALESCE(NEW.email, ''), '@', 1),
    'User'
  ), 60);

  IF length(v_display_name) < 2 THEN
    v_display_name := 'User';
  END IF;

  -- Pull avatar from Google metadata (avatar_url / picture)
  v_avatar_url := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'avatar_url', ''),
    NULLIF(NEW.raw_user_meta_data->>'picture', '')
  );

  -- Build a base username from the email local part (sanitized, max 14 chars)
  v_base := left(
    regexp_replace(lower(split_part(COALESCE(NEW.email, ''), '@', 1)), '[^a-z0-9_]', '', 'g'),
    14
  );
  IF length(v_base) < 3 THEN
    v_base := 'user';
  END IF;

  -- Append random hex suffix until unique (satisfies unique + format constraints)
  LOOP
    v_username := v_base || '_' || substr(encode(gen_random_bytes(4), 'hex'), 1, 5);
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username);
  END LOOP;

  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (NEW.id, v_username, v_display_name, v_avatar_url)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fire after every new auth.users row (covers email/password AND OAuth)
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP: Expired nearby sessions
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS VOID AS $$
BEGIN
  DELETE FROM nearby_sessions WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE nearby_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ─── profiles ───────────────────────────────────────────────────────────────

-- Anyone authenticated can read public profile fields
CREATE POLICY "profiles_read_public"
  ON profiles FOR SELECT
  TO authenticated
  USING (TRUE);

-- Only owner can update their profile
CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Only owner can insert their profile
CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- ─── nearby_sessions ────────────────────────────────────────────────────────

-- Authenticated users can read active sessions (to resolve ephemeral IDs)
CREATE POLICY "nearby_sessions_read"
  ON nearby_sessions FOR SELECT
  TO authenticated
  USING (expires_at > NOW());

-- Users can only insert/update/delete their own session
CREATE POLICY "nearby_sessions_own"
  ON nearby_sessions FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── friend_requests ────────────────────────────────────────────────────────

-- Only sender and receiver can see a request
CREATE POLICY "friend_requests_read"
  ON friend_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Only authenticated users can insert (as sender)
CREATE POLICY "friend_requests_insert"
  ON friend_requests FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

-- Sender and receiver can update (cancel / accept / reject)
CREATE POLICY "friend_requests_update"
  ON friend_requests FOR UPDATE
  TO authenticated
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- ─── friendships ────────────────────────────────────────────────────────────

-- Both users in a friendship can see it
CREATE POLICY "friendships_read"
  ON friendships FOR SELECT
  TO authenticated
  USING (auth.uid() = user_a OR auth.uid() = user_b);

-- System inserts friendships (via accept_friend_request function)
CREATE POLICY "friendships_insert"
  ON friendships FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_a OR auth.uid() = user_b);

-- Both users can delete friendship
CREATE POLICY "friendships_delete"
  ON friendships FOR DELETE
  TO authenticated
  USING (auth.uid() = user_a OR auth.uid() = user_b);

-- ─── conversations ───────────────────────────────────────────────────────────

-- Both participants can see the conversation
CREATE POLICY "conversations_read"
  ON conversations FOR SELECT
  TO authenticated
  USING (auth.uid() = user_a OR auth.uid() = user_b);

-- Either participant can create a conversation
CREATE POLICY "conversations_insert"
  ON conversations FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_a OR auth.uid() = user_b);

-- Either participant can update (e.g., updated_at)
CREATE POLICY "conversations_update"
  ON conversations FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_a OR auth.uid() = user_b);

-- ─── messages ───────────────────────────────────────────────────────────────

-- Only participants of the conversation can read messages
CREATE POLICY "messages_read"
  ON messages FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
        AND (c.user_a = auth.uid() OR c.user_b = auth.uid())
    )
  );

-- Only sender can insert messages (and they must be a participant)
CREATE POLICY "messages_insert"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
        AND (c.user_a = auth.uid() OR c.user_b = auth.uid())
    )
  );

-- Receiver can mark messages as read
CREATE POLICY "messages_update_read"
  ON messages FOR UPDATE
  TO authenticated
  USING (
    auth.uid() <> sender_id AND
    EXISTS (
      SELECT 1 FROM conversations c
      WHERE c.id = conversation_id
        AND (c.user_a = auth.uid() OR c.user_b = auth.uid())
    )
  );

-- ─── blocks ─────────────────────────────────────────────────────────────────

CREATE POLICY "blocks_read_own"
  ON blocks FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_id);

CREATE POLICY "blocks_insert"
  ON blocks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "blocks_delete"
  ON blocks FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_id);

-- ─── reports ────────────────────────────────────────────────────────────────

CREATE POLICY "reports_read_own"
  ON reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

CREATE POLICY "reports_insert"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- REALTIME: Enable for relevant tables
-- ═══════════════════════════════════════════════════════════════════════════

-- Run these in Supabase Dashboard > Database > Replication
-- Or run via SQL:
ALTER PUBLICATION supabase_realtime ADD TABLE friend_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE nearby_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE friendships;

-- ═══════════════════════════════════════════════════════════════════════════
-- STORAGE: Create avatars bucket
-- ═══════════════════════════════════════════════════════════════════════════

-- Run in Supabase Dashboard > Storage > New Bucket
-- OR via SQL (requires service_role):
/*
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  TRUE,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- RLS for storage
CREATE POLICY "avatar_read_public"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatar_insert_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "avatar_update_own"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "avatar_delete_own"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);
*/
