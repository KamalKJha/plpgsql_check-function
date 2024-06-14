CREATE TABLE procedure_errors (
    procedure_name TEXT,
    error_message TEXT,
    error_time TIMESTAMPTZ DEFAULT NOW()
);


DO $$
DECLARE
    procedure RECORD;
    procedure_name TEXT;
    sql_statement TEXT;
BEGIN
    -- Loop through each procedure in the database
    FOR procedure IN
        SELECT proname
        FROM pg_proc
        JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid
        WHERE pg_namespace.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        procedure_name := procedure.proname;
        sql_statement := 'SELECT ' || procedure_name || '();';
        
        BEGIN
            -- Attempt to execute the procedure
            EXECUTE sql_statement;
        EXCEPTION
            WHEN OTHERS THEN
                -- Log any errors to the procedure_errors table
                INSERT INTO procedure_errors (procedure_name, error_message)
                VALUES (procedure_name, SQLERRM);
        END;
    END LOOP;
END $$;
