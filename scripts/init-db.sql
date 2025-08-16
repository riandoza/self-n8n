-- n8n Database Initialization Script
-- Optimizations for PostgreSQL performance

-- Set optimal PostgreSQL settings for n8n
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activity_query_size = 2048;
ALTER SYSTEM SET track_io_timing = on;
ALTER SYSTEM SET checkpoint_timeout = '15min';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- Create indexes for better performance
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set up connection pooling parameters
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';

-- Optimize for n8n workload
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET seq_page_cost = 1.0;

SELECT pg_reload_conf();

-- Create dedicated n8n user with limited privileges (security)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'n8n_readonly') THEN
        CREATE ROLE n8n_readonly;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE n8n TO n8n_readonly;
GRANT USAGE ON SCHEMA public TO n8n_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_readonly;