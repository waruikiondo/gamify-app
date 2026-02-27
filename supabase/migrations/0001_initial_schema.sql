-- ==============================================================================
-- PHASE 1: GAMIFY INITIAL DATABASE SCHEMA & RLS POLICIES
-- ==============================================================================

-- Enable the UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. USERS TABLE (Public extension of auth.users)
-- ------------------------------------------------------------------------------
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    rank TEXT DEFAULT 'Novice',
    primary_goal TEXT,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to automatically create a public user record when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ------------------------------------------------------------------------------
-- 2. SKILL AREAS TABLE (ACS Areas / Skill Tree nodes)
-- ------------------------------------------------------------------------------
CREATE TABLE public.skill_areas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ------------------------------------------------------------------------------
-- 3. LEVELS TABLE (Chapters / Progression Nodes)
-- ------------------------------------------------------------------------------
CREATE TABLE public.levels (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    level_order INT NOT NULL UNIQUE,
    passing_percentage INT DEFAULT 80,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ------------------------------------------------------------------------------
-- 4. QUESTIONS TABLE (Gates)
-- ------------------------------------------------------------------------------
CREATE TABLE public.questions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    level_id UUID REFERENCES public.levels(id) ON DELETE CASCADE,
    skill_area_id UUID REFERENCES public.skill_areas(id) ON DELETE SET NULL,
    question_text TEXT NOT NULL,
    answer_options JSONB NOT NULL, -- Stored as JSON array
    correct_answer TEXT NOT NULL,
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ------------------------------------------------------------------------------
-- 5. USER LEVEL PROGRESS TABLE (Tracks unlocks and scores)
-- ------------------------------------------------------------------------------
CREATE TABLE public.user_level_progress (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    level_id UUID REFERENCES public.levels(id) ON DELETE CASCADE,
    unlocked BOOLEAN DEFAULT FALSE,
    completed BOOLEAN DEFAULT FALSE,
    score NUMERIC DEFAULT 0,
    highest_score_percentage NUMERIC DEFAULT 0,
    last_attempted_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, level_id) -- Ensures one progress record per user per level
);


-- ------------------------------------------------------------------------------
-- 6. EXAM RESULTS TABLE (Phase 3 Mock Exams)
-- ------------------------------------------------------------------------------
CREATE TABLE public.exam_results (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    score INT NOT NULL,
    total_questions INT NOT NULL,
    passed BOOLEAN DEFAULT FALSE,
    time_taken_seconds INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skill_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_level_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;

-- USERS: Users can read and update their own profile. Everyone can read to see leaderboards.
CREATE POLICY "Users can view all profiles for leaderboards" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- SKILL AREAS, LEVELS, QUESTIONS: Anyone authenticated can read. Only admins can modify.
CREATE POLICY "Authenticated users can view skill areas" ON public.skill_areas FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can view levels" ON public.levels FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can view questions" ON public.questions FOR SELECT USING (auth.role() = 'authenticated');

-- USER LEVEL PROGRESS: Users can only see and update their own progress.
CREATE POLICY "Users can view own progress" ON public.user_level_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON public.user_level_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON public.user_level_progress FOR UPDATE USING (auth.uid() = user_id);

-- EXAM RESULTS: Users can only see and insert their own exam results.
CREATE POLICY "Users can view own exam results" ON public.exam_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own exam results" ON public.exam_results FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ==============================================================================
-- RPC: GET USER SKILL MASTERY (Placeholder logic for Phase 2)
-- ==============================================================================
CREATE OR REPLACE FUNCTION get_user_skill_mastery(user_uuid UUID)
RETURNS TABLE (
    skill_area_id UUID,
    title TEXT,
    mastery_percentage NUMERIC
) AS $$
BEGIN
    -- NOTE: This is a placeholder calculation. 
    -- It currently returns 0 for all skills to satisfy the UI requirement.
    -- Once question-level tracking is added, this query will be updated to calculate real averages.
    RETURN QUERY
    SELECT 
        sa.id AS skill_area_id,
        sa.title,
        COALESCE(0.0, 0.0) AS mastery_percentage
    FROM public.skill_areas sa;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;