CREATE SCHEMA IF NOT EXISTS "core";

-- udf
CREATE OR REPLACE FUNCTION core.set_updated_at()
RETURNS trigger AS $$
BEGIN
  IF row(NEW.*) IS DISTINCT FROM row(OLD.*) THEN
    NEW.updated_at := CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- company
CREATE TYPE core.enum_company_tier AS ENUM ('1', '2', '3');

CREATE TABLE core.company (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(20),
  about VARCHAR(100),
  tier core.enum_company_tier,
  cool_off_period_days INT,
  is_blocked BOOLEAN
);

-- application
CREATE TYPE core.enum_application_status AS ENUM ('applied', 'shortlisted', 'assessment', 'phone_screen', 'interview', 'hr', 'offered', 'accepted', 'rejected', 'ghosted');

CREATE TABLE core.application (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_portal_job_id VARCHAR(10),
  company_id UUID REFERENCES core.company(id) ON DELETE SET NULL,
  
  role VARCHAR(20) NOT NULL,
  status core.enum_application_status NOT NULL,
  
  rounds_count NUMERIC(2,0) CHECK(rounds_count>=0),
  is_referred BOOLEAN DEFAULT false,
  expected_ctc_lpa NUMERIC(5,2) CHECK(expected_ctc_lpa>=8),
  
  applied_at DATE DEFAULT CURRENT_DATE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_set_updated_at
BEFORE UPDATE ON core.application
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

SELECT unnest(enum_range(NULL::core.enum_application_status)) AS status;

-- SELECT *
-- FROM pg_type t
-- JOIN pg_enum e ON t.oid = e.enumtypid
-- JOIN pg_namespace n ON n.oid = t.typnamespace
-- WHERE t.typname = 'enum_application_status'
--   AND n.nspname = 'core'
-- ORDER BY e.enumsortorder;

-- application_link
CREATE TABLE core.application_link (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_application_id UUID REFERENCES core.application(id) ON DELETE CASCADE,
  link VARCHAR(100),
  text VARCHAR(20)
);

-- application_stage
CREATE TYPE core.enum_interview_feedback AS ENUM (
  'waiting',
  'strong_yes',
  'lean_yes',
  'neutral',
  'hold',
  'lean_no',
  'strong_no',
  'eliminated',
  'red_flag'
);

CREATE TABLE core.application_stage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_application_id UUID REFERENCES core.application(id) ON DELETE RESTRICT,
  stage_number NUMERIC(2,0) CHECK(sequence_number>=0),
  stage_title VARCHAR(20) NOT NULL,
  stage_details TEXT,
  duration_minutes NUMERIC(3,0) NOT NULL,
  feedback core.enum_interview_feedback NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_set_updated_at_application_stage
BEFORE UPDATE ON core.application_stage
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

SELECT unnest(enum_range(NULL::core.enum_interview_feedback)) AS feedback;

-- SELECT *
-- FROM pg_type t
-- JOIN pg_enum e ON t.oid = e.enumtypid
-- JOIN pg_namespace n ON n.oid = t.typnamespace
-- WHERE t.typname = 'enum_interview_feedback'
--   AND n.nspname = 'core'
-- ORDER BY e.enumsortorder;
