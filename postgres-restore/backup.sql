--
-- PostgreSQL database dump
--

-- Dumped from database version 14.4
-- Dumped by pg_dump version 14.4

-- Started on 2022-08-31 03:09:29

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 9 (class 2615 OID 16436)
-- Name: dao_subject; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA dao_subject;


ALTER SCHEMA dao_subject OWNER TO gp_site_owner;

--
-- TOC entry 10 (class 2615 OID 32995)
-- Name: dic; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA dic;


ALTER SCHEMA dic OWNER TO gp_site_owner;

--
-- TOC entry 12 (class 2615 OID 32996)
-- Name: doc; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA doc;


ALTER SCHEMA doc OWNER TO gp_site_owner;

--
-- TOC entry 4 (class 2615 OID 32997)
-- Name: enm; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA enm;


ALTER SCHEMA enm OWNER TO gp_site_owner;

--
-- TOC entry 6 (class 2615 OID 32998)
-- Name: reg; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA reg;


ALTER SCHEMA reg OWNER TO gp_site_owner;

--
-- TOC entry 3 (class 2615 OID 32999)
-- Name: rel; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA rel;


ALTER SCHEMA rel OWNER TO gp_site_owner;

--
-- TOC entry 8 (class 2615 OID 33058)
-- Name: sys; Type: SCHEMA; Schema: -; Owner: gp_site_owner
--

CREATE SCHEMA sys;


ALTER SCHEMA sys OWNER TO gp_site_owner;

--
-- TOC entry 867 (class 1247 OID 33066)
-- Name: state_tp; Type: TYPE; Schema: sys; Owner: gp_site_owner
--

CREATE TYPE sys.state_tp AS ENUM (
    'active',
    'draft',
    'deleted'
);


ALTER TYPE sys.state_tp OWNER TO gp_site_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 33008)
-- Name: subject; Type: TABLE; Schema: dic; Owner: gp_site_owner
--

CREATE TABLE dic.subject (
    id integer NOT NULL,
    creation_date timestamp with time zone DEFAULT now(),
    status_id integer DEFAULT 1 NOT NULL,
    username character varying(50),
    password_hash character varying(500),
    password_salt character varying(500),
    password_hash_upd timestamp without time zone,
    email character varying(256),
    phone character varying(16),
    email_confirm_code character varying(50),
    phone_confirm_code character varying(6),
    is_email_confirmed boolean DEFAULT false NOT NULL,
    is_phone_confirmed boolean DEFAULT false NOT NULL,
    last_login_date timestamp with time zone
);


ALTER TABLE dic.subject OWNER TO gp_site_owner;

--
-- TOC entry 221 (class 1259 OID 33001)
-- Name: subject_status; Type: TABLE; Schema: enm; Owner: gp_site_owner
--

CREATE TABLE enm.subject_status (
    id integer NOT NULL,
    title character varying(100) NOT NULL
);


ALTER TABLE enm.subject_status OWNER TO gp_site_owner;

--
-- TOC entry 224 (class 1259 OID 33025)
-- Name: dic_subject_v; Type: VIEW; Schema: dao_subject; Owner: gp_site_owner
--

CREATE VIEW dao_subject.dic_subject_v AS
 SELECT t.id AS "subjectId",
    t.creation_date AS "creationDate",
    t.password_hash_upd AS "passwordHashUpdate",
    t.username,
    t.email,
    t.phone,
    t.is_email_confirmed AS "isEmailConfirmed",
    t.is_phone_confirmed AS "isPhoneConfirmed",
    t.last_login_date AS "lastLogin",
    s.id AS "statusId",
    s.title AS "statusName"
   FROM (dic.subject t
     JOIN enm.subject_status s ON ((s.id = t.status_id)));


ALTER TABLE dao_subject.dic_subject_v OWNER TO gp_site_owner;

--
-- TOC entry 227 (class 1255 OID 33030)
-- Name: fn_get_item_r(integer); Type: FUNCTION; Schema: dao_subject; Owner: gp_site_owner
--

CREATE FUNCTION dao_subject.fn_get_item_r(p_id integer) RETURNS SETOF dao_subject.dic_subject_v
    LANGUAGE sql SECURITY DEFINER
    AS $$
	SELECT * FROM dao_subject.dic_subject_v v
	WHERE v."subjectId" = p_id;
$$;


ALTER FUNCTION dao_subject.fn_get_item_r(p_id integer) OWNER TO gp_site_owner;

--
-- TOC entry 242 (class 1255 OID 32924)
-- Name: fn_is_email_confirmed_b(integer); Type: FUNCTION; Schema: dao_subject; Owner: gp_site_owner
--

CREATE FUNCTION dao_subject.fn_is_email_confirmed_b(p_subject integer) RETURNS boolean
    LANGUAGE sql SECURITY DEFINER
    AS $$
	SELECT t.is_email_confirmed
	FROM dic.subject t
	WHERE t.id = p_subject;
$$;


ALTER FUNCTION dao_subject.fn_is_email_confirmed_b(p_subject integer) OWNER TO gp_site_owner;

--
-- TOC entry 243 (class 1255 OID 32925)
-- Name: fn_is_exists_by_contacts_b(json); Type: FUNCTION; Schema: dao_subject; Owner: gp_site_owner
--

CREATE FUNCTION dao_subject.fn_is_exists_by_contacts_b(p_props json) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE 
	l_email			TEXT := p_props ->> 'email';
	l_phone			TEXT := p_props ->> 'phone';
	l_cnt			int;
BEGIN
	SELECT count(*) INTO l_cnt
	FROM dic.subject s
	WHERE s.email = l_email
		OR s.phone = l_phone;
	
	IF l_cnt > 0 THEN 
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$;


ALTER FUNCTION dao_subject.fn_is_exists_by_contacts_b(p_props json) OWNER TO gp_site_owner;

--
-- TOC entry 239 (class 1255 OID 32921)
-- Name: pr_check_email_confirm_code_b(json); Type: PROCEDURE; Schema: dao_subject; Owner: gp_site_owner
--

CREATE PROCEDURE dao_subject.pr_check_email_confirm_code_b(OUT p_result boolean, IN p_json json)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
	l_code TEXT := p_json ->> code;
	l_is_code_valid boolean;
	l_subject_id int := (p_json ->> 'subjectId')::integer;
BEGIN
	-- Check code
	SELECT INTO l_is_code_valid EXISTS (
		SELECT * FROM dic.subject t
		WHERE t.email_confirm_code = p_json ->> 'code'
			AND t.id = l_subject_id
	);

	-- Update confirmed status
	IF l_is_code_valid IS TRUE THEN
		UPDATE dic.subject t
		SET t.is_email_confirmed  = TRUE
		WHERE t.id = l_subject_id;
	END IF;

	-- Result
	p_result := l_is_code_valid;
END;
$$;


ALTER PROCEDURE dao_subject.pr_check_email_confirm_code_b(OUT p_result boolean, IN p_json json) OWNER TO gp_site_owner;

--
-- TOC entry 240 (class 1255 OID 32922)
-- Name: pr_create_n(json); Type: PROCEDURE; Schema: dao_subject; Owner: gp_site_owner
--

CREATE PROCEDURE dao_subject.pr_create_n(OUT p_result integer, IN p_json json)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
	BEGIN
		INSERT INTO dic.subject (
			username,
			email,
			phone,
			password_hash,
			password_salt
		) VALUES (
			p_json ->> 'username',
			p_json ->> 'email',
			p_json ->> 'phone',
			p_json ->> 'passwordHash',
			p_json ->> 'passwordSalt'
		) RETURNING id INTO p_result;
	END;
$$;


ALTER PROCEDURE dao_subject.pr_create_n(OUT p_result integer, IN p_json json) OWNER TO gp_site_owner;

--
-- TOC entry 244 (class 1255 OID 32926)
-- Name: pr_make_email_confirm_code_s(json); Type: PROCEDURE; Schema: dao_subject; Owner: gp_site_owner
--

CREATE PROCEDURE dao_subject.pr_make_email_confirm_code_s(OUT p_result character varying, IN p_json json)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
	l_subject_id int := (p_json ->> 'subjectId')::integer;
	l_code_in TEXT := p_json ->> 'code';
	l_code_db varchar;
BEGIN
	-- Проверяем, подтвержден ли адрес эл. почты
	SELECT INTO l_code_db FROM dic.subject t
	WHERE t.id = l_subject_id
		-- Забираем код только если эл почта НЕ подтверждена
		AND t.is_email_confirmed IS FALSE;
	
	-- Для новых учеток, кода, естественно, не будет
	IF l_code_db IS NOT NULL THEN
		-- Раз код найден в базе, вернем его
		p_result := l_code_db;
	ELSE
		-- Добавим код, полученный от клиента
		UPDATE dic.subject t
		SET t.email_confirm_code = l_code_in
		WHERE t.id = l_subject_id;
	
		-- И вернем его
		p_result := l_code_in;
	END IF;
END;
$$;


ALTER PROCEDURE dao_subject.pr_make_email_confirm_code_s(OUT p_result character varying, IN p_json json) OWNER TO gp_site_owner;

--
-- TOC entry 241 (class 1255 OID 32927)
-- Name: pr_update_email_s(json); Type: PROCEDURE; Schema: dao_subject; Owner: gp_site_owner
--

CREATE PROCEDURE dao_subject.pr_update_email_s(OUT p_result character varying, IN p_json json)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
	l_subject_id int := (p_json ->> 'subjectId')::integer;
	l_email TEXT := p_json ->> 'email';
	l_code	TEXT := p_json ->> 'code';
BEGIN
	UPDATE dic.subject t
	SET t.email = l_email,
		t.email_confirm_code = l_code,
		t.is_email_confirmed = FALSE
	WHERE t.id = l_subject_id
	RETURNING t.email_confirm_code INTO p_result;
END;
$$;


ALTER PROCEDURE dao_subject.pr_update_email_s(OUT p_result character varying, IN p_json json) OWNER TO gp_site_owner;

--
-- TOC entry 246 (class 1255 OID 33037)
-- Name: create_subject(json); Type: FUNCTION; Schema: dic; Owner: gp_site_owner
--

CREATE FUNCTION dic.create_subject(p_json json) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	l_subject_id int4;
	l_username varchar(30);
	l_phone varchar(16);
	l_email varchar(256);
	l_password_hash varchar(500);
	l_password_salt varchar(500);
BEGIN
	-- Parsing
	BEGIN
		l_username := (p_json ->> 'username');
		l_phone := (p_json ->> 'phone');
		l_email := (p_json ->> 'email');
		l_password_hash := (p_json ->> 'passwordHash');
		l_password_salt := (p_json ->> 'passwordSalt');
	
		EXCEPTION WHEN OTHERS THEN
			RAISE EXCEPTION 'Parsing error: %', SQLERRM;
	END;

	INSERT INTO dic.subject (username, email, phone, password_hash,	password_salt)
	VALUES (l_username, l_email, l_phone, l_password_hash, l_password_salt)
	RETURNING id;

END;
$$;


ALTER FUNCTION dic.create_subject(p_json json) OWNER TO gp_site_owner;

--
-- TOC entry 222 (class 1259 OID 33007)
-- Name: subject_id_seq; Type: SEQUENCE; Schema: dic; Owner: gp_site_owner
--

CREATE SEQUENCE dic.subject_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dic.subject_id_seq OWNER TO gp_site_owner;

--
-- TOC entry 3390 (class 0 OID 0)
-- Dependencies: 222
-- Name: subject_id_seq; Type: SEQUENCE OWNED BY; Schema: dic; Owner: gp_site_owner
--

ALTER SEQUENCE dic.subject_id_seq OWNED BY dic.subject.id;


--
-- TOC entry 220 (class 1259 OID 33000)
-- Name: subject_status_id_seq; Type: SEQUENCE; Schema: enm; Owner: gp_site_owner
--

CREATE SEQUENCE enm.subject_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE enm.subject_status_id_seq OWNER TO gp_site_owner;

--
-- TOC entry 3391 (class 0 OID 0)
-- Dependencies: 220
-- Name: subject_status_id_seq; Type: SEQUENCE OWNED BY; Schema: enm; Owner: gp_site_owner
--

ALTER SEQUENCE enm.subject_status_id_seq OWNED BY enm.subject_status.id;


--
-- TOC entry 3224 (class 2604 OID 33011)
-- Name: subject id; Type: DEFAULT; Schema: dic; Owner: gp_site_owner
--

ALTER TABLE ONLY dic.subject ALTER COLUMN id SET DEFAULT nextval('dic.subject_id_seq'::regclass);


--
-- TOC entry 3223 (class 2604 OID 33004)
-- Name: subject_status id; Type: DEFAULT; Schema: enm; Owner: gp_site_owner
--

ALTER TABLE ONLY enm.subject_status ALTER COLUMN id SET DEFAULT nextval('enm.subject_status_id_seq'::regclass);


--
-- TOC entry 3377 (class 0 OID 33008)
-- Dependencies: 223
-- Data for Name: subject; Type: TABLE DATA; Schema: dic; Owner: gp_site_owner
--

COPY dic.subject (id, creation_date, status_id, username, password_hash, password_salt, password_hash_upd, email, phone, email_confirm_code, phone_confirm_code, is_email_confirmed, is_phone_confirmed, last_login_date) FROM stdin;
\.


--
-- TOC entry 3375 (class 0 OID 33001)
-- Dependencies: 221
-- Data for Name: subject_status; Type: TABLE DATA; Schema: enm; Owner: gp_site_owner
--

COPY enm.subject_status (id, title) FROM stdin;
\.


--
-- TOC entry 3392 (class 0 OID 0)
-- Dependencies: 222
-- Name: subject_id_seq; Type: SEQUENCE SET; Schema: dic; Owner: gp_site_owner
--

SELECT pg_catalog.setval('dic.subject_id_seq', 1, false);


--
-- TOC entry 3393 (class 0 OID 0)
-- Dependencies: 220
-- Name: subject_status_id_seq; Type: SEQUENCE SET; Schema: enm; Owner: gp_site_owner
--

SELECT pg_catalog.setval('enm.subject_status_id_seq', 1, false);


--
-- TOC entry 3232 (class 2606 OID 33019)
-- Name: subject dic_subject_pk; Type: CONSTRAINT; Schema: dic; Owner: gp_site_owner
--

ALTER TABLE ONLY dic.subject
    ADD CONSTRAINT dic_subject_pk PRIMARY KEY (id);


--
-- TOC entry 3230 (class 2606 OID 33006)
-- Name: subject_status enm_subject_status_pk; Type: CONSTRAINT; Schema: enm; Owner: gp_site_owner
--

ALTER TABLE ONLY enm.subject_status
    ADD CONSTRAINT enm_subject_status_pk PRIMARY KEY (id);


--
-- TOC entry 3233 (class 2606 OID 33020)
-- Name: subject dic_subject_fk1; Type: FK CONSTRAINT; Schema: dic; Owner: gp_site_owner
--

ALTER TABLE ONLY dic.subject
    ADD CONSTRAINT dic_subject_fk1 FOREIGN KEY (id) REFERENCES enm.subject_status(id);


--
-- TOC entry 3383 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA dao_subject; Type: ACL; Schema: -; Owner: gp_site_owner
--

GRANT USAGE ON SCHEMA dao_subject TO gp_site_client;


--
-- TOC entry 3384 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION fn_is_email_confirmed_b(p_subject integer); Type: ACL; Schema: dao_subject; Owner: gp_site_owner
--

GRANT ALL ON FUNCTION dao_subject.fn_is_email_confirmed_b(p_subject integer) TO gp_site_client;


--
-- TOC entry 3385 (class 0 OID 0)
-- Dependencies: 243
-- Name: FUNCTION fn_is_exists_by_contacts_b(p_props json); Type: ACL; Schema: dao_subject; Owner: gp_site_owner
--

GRANT ALL ON FUNCTION dao_subject.fn_is_exists_by_contacts_b(p_props json) TO gp_site_client;


--
-- TOC entry 3386 (class 0 OID 0)
-- Dependencies: 239
-- Name: PROCEDURE pr_check_email_confirm_code_b(OUT p_result boolean, IN p_json json); Type: ACL; Schema: dao_subject; Owner: gp_site_owner
--

GRANT ALL ON PROCEDURE dao_subject.pr_check_email_confirm_code_b(OUT p_result boolean, IN p_json json) TO gp_site_client;


--
-- TOC entry 3387 (class 0 OID 0)
-- Dependencies: 240
-- Name: PROCEDURE pr_create_n(OUT p_result integer, IN p_json json); Type: ACL; Schema: dao_subject; Owner: gp_site_owner
--

GRANT ALL ON PROCEDURE dao_subject.pr_create_n(OUT p_result integer, IN p_json json) TO gp_site_client;


--
-- TOC entry 3388 (class 0 OID 0)
-- Dependencies: 244
-- Name: PROCEDURE pr_make_email_confirm_code_s(OUT p_result character varying, IN p_json json); Type: ACL; Schema: dao_subject; Owner: gp_site_owner
--

GRANT ALL ON PROCEDURE dao_subject.pr_make_email_confirm_code_s(OUT p_result character varying, IN p_json json) TO gp_site_client;


--
-- TOC entry 3389 (class 0 OID 0)
-- Dependencies: 241
-- Name: PROCEDURE pr_update_email_s(OUT p_result character varying, IN p_json json); Type: ACL; Schema: dao_subject; Owner: gp_site_owner
--

GRANT ALL ON PROCEDURE dao_subject.pr_update_email_s(OUT p_result character varying, IN p_json json) TO gp_site_client;


-- Completed on 2022-08-31 03:09:32

--
-- PostgreSQL database dump complete
--

