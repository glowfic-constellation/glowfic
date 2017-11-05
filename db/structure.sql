--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE audits (
    id integer NOT NULL,
    auditable_id integer,
    auditable_type character varying,
    associated_id integer,
    associated_type character varying,
    user_id integer,
    user_type character varying,
    username character varying,
    action character varying,
    audited_changes text,
    version integer DEFAULT 0,
    comment character varying,
    remote_address character varying,
    created_at timestamp without time zone,
    request_uuid character varying
);


--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE audits_id_seq OWNED BY audits.id;


--
-- Name: board_authors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE board_authors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    board_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cameo boolean DEFAULT false
);


--
-- Name: board_authors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE board_authors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_authors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE board_authors_id_seq OWNED BY board_authors.id;


--
-- Name: board_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE board_sections (
    id integer NOT NULL,
    board_id integer NOT NULL,
    name character varying NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    section_order integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: board_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE board_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE board_sections_id_seq OWNED BY board_sections.id;


--
-- Name: board_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE board_views (
    id integer NOT NULL,
    board_id integer NOT NULL,
    user_id integer NOT NULL,
    ignored boolean DEFAULT false,
    notify_message boolean DEFAULT false,
    notify_email boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    read_at timestamp without time zone
);


--
-- Name: board_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE board_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: board_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE board_views_id_seq OWNED BY board_views.id;


--
-- Name: boards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE boards (
    id integer NOT NULL,
    name citext NOT NULL,
    creator_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    pinned boolean DEFAULT false
);


--
-- Name: boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE boards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE boards_id_seq OWNED BY boards.id;


--
-- Name: character_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE character_aliases (
    id integer NOT NULL,
    character_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: character_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE character_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE character_aliases_id_seq OWNED BY character_aliases.id;


--
-- Name: character_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE character_groups (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: character_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE character_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE character_groups_id_seq OWNED BY character_groups.id;


--
-- Name: character_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE character_tags (
    id integer NOT NULL,
    character_id integer NOT NULL,
    tag_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: character_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE character_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE character_tags_id_seq OWNED BY character_tags.id;


--
-- Name: characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE characters (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name citext NOT NULL,
    template_name character varying,
    screenname character varying,
    template_id integer,
    default_icon_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    pb character varying,
    character_group_id integer,
    description text
);


--
-- Name: characters_galleries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE characters_galleries (
    id integer NOT NULL,
    character_id integer NOT NULL,
    gallery_id integer NOT NULL,
    section_order integer DEFAULT 0 NOT NULL,
    added_by_group boolean DEFAULT false
);


--
-- Name: characters_galleries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE characters_galleries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: characters_galleries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE characters_galleries_id_seq OWNED BY characters_galleries.id;


--
-- Name: characters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE characters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: characters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE characters_id_seq OWNED BY characters.id;


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE favorites (
    id integer NOT NULL,
    user_id integer NOT NULL,
    favorite_id integer NOT NULL,
    favorite_type character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: favorites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE favorites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favorites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE favorites_id_seq OWNED BY favorites.id;


--
-- Name: flat_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE flat_posts (
    id integer NOT NULL,
    post_id integer NOT NULL,
    content text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: flat_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flat_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flat_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flat_posts_id_seq OWNED BY flat_posts.id;


--
-- Name: galleries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE galleries (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: galleries_icons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE galleries_icons (
    id integer NOT NULL,
    icon_id integer,
    gallery_id integer
);


--
-- Name: galleries_icons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE galleries_icons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: galleries_icons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE galleries_icons_id_seq OWNED BY galleries_icons.id;


--
-- Name: galleries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE galleries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: galleries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE galleries_id_seq OWNED BY galleries.id;


--
-- Name: gallery_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gallery_tags (
    id integer NOT NULL,
    gallery_id integer NOT NULL,
    tag_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: gallery_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gallery_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gallery_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gallery_tags_id_seq OWNED BY gallery_tags.id;


--
-- Name: icons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE icons (
    id integer NOT NULL,
    user_id integer NOT NULL,
    url character varying NOT NULL,
    keyword character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    credit character varying,
    has_gallery boolean DEFAULT false,
    s3_key character varying
);


--
-- Name: icons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE icons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: icons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE icons_id_seq OWNED BY icons.id;


--
-- Name: index_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE index_posts (
    id integer NOT NULL,
    post_id integer NOT NULL,
    index_id integer NOT NULL,
    index_section_id integer,
    description text,
    section_order integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: index_posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE index_posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: index_posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE index_posts_id_seq OWNED BY index_posts.id;


--
-- Name: index_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE index_sections (
    id integer NOT NULL,
    index_id integer NOT NULL,
    name citext NOT NULL,
    description text,
    section_order integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: index_sections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE index_sections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: index_sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE index_sections_id_seq OWNED BY index_sections.id;


--
-- Name: indexes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE indexes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name citext NOT NULL,
    description text,
    privacy integer DEFAULT 0 NOT NULL,
    open_to_anyone boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: indexes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE indexes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: indexes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE indexes_id_seq OWNED BY indexes.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE messages (
    id integer NOT NULL,
    sender_id integer NOT NULL,
    recipient_id integer NOT NULL,
    parent_id integer,
    thread_id integer,
    subject character varying,
    message text,
    unread boolean DEFAULT true,
    visible_inbox boolean DEFAULT true,
    visible_outbox boolean DEFAULT true,
    marked_inbox boolean DEFAULT false,
    marked_outbox boolean DEFAULT false,
    read_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE messages_id_seq OWNED BY messages.id;


--
-- Name: password_resets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE password_resets (
    id integer NOT NULL,
    user_id integer NOT NULL,
    auth_token character varying NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: password_resets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE password_resets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: password_resets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE password_resets_id_seq OWNED BY password_resets.id;


--
-- Name: post_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE post_tags (
    id integer NOT NULL,
    post_id integer NOT NULL,
    tag_id integer NOT NULL,
    suggested boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: post_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE post_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE post_tags_id_seq OWNED BY post_tags.id;


--
-- Name: post_viewers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE post_viewers (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: post_viewers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE post_viewers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_viewers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE post_viewers_id_seq OWNED BY post_viewers.id;


--
-- Name: post_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE post_views (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    ignored boolean DEFAULT false,
    notify_message boolean DEFAULT false,
    notify_email boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    read_at timestamp without time zone,
    warnings_hidden boolean DEFAULT false
);


--
-- Name: post_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE post_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE post_views_id_seq OWNED BY post_views.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE posts (
    id integer NOT NULL,
    board_id integer NOT NULL,
    user_id integer NOT NULL,
    subject character varying NOT NULL,
    content text,
    character_id integer,
    icon_id integer,
    privacy integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    status integer DEFAULT 0,
    section_id integer,
    section_order integer,
    description character varying,
    last_user_id integer,
    last_reply_id integer,
    edited_at timestamp without time zone,
    tagged_at timestamp without time zone,
    authors_locked boolean DEFAULT false,
    character_alias_id integer
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: replies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE replies (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    content text,
    character_id integer,
    icon_id integer,
    thread_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    character_alias_id integer
);


--
-- Name: replies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE replies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: replies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE replies_id_seq OWNED BY replies.id;


--
-- Name: reply_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE reply_drafts (
    id integer NOT NULL,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    content text,
    character_id integer,
    icon_id integer,
    thread_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    character_alias_id integer
);


--
-- Name: reply_drafts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reply_drafts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reply_drafts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reply_drafts_id_seq OWNED BY reply_drafts.id;


--
-- Name: report_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE report_views (
    id integer NOT NULL,
    user_id integer NOT NULL,
    read_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: report_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_views_id_seq OWNED BY report_views.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tag_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tag_tags (
    id integer NOT NULL,
    tagged_id integer NOT NULL,
    tag_id integer NOT NULL,
    suggested boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: tag_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tag_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tag_tags_id_seq OWNED BY tag_tags.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tags (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name citext NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    type character varying,
    description text
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE templates (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name citext,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text
);


--
-- Name: templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE templates_id_seq OWNED BY templates.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    username citext NOT NULL,
    crypted character varying NOT NULL,
    avatar_id integer,
    active_character_id integer,
    per_page integer DEFAULT 25,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    timezone character varying,
    email citext,
    email_notifications boolean,
    icon_picker_grouping boolean DEFAULT true,
    moiety character varying,
    layout character varying,
    moiety_name character varying,
    default_view character varying,
    default_editor character varying DEFAULT 'rtf'::character varying,
    time_display character varying DEFAULT '%b %d, %Y %l:%M %p'::character varying,
    salt_uuid character varying,
    unread_opened boolean DEFAULT false,
    hide_hiatused_tags_owed boolean DEFAULT false,
    hide_warnings boolean DEFAULT false,
    visible_unread boolean DEFAULT false,
    show_user_in_switcher boolean DEFAULT true,
    ignore_unread_daily_report boolean DEFAULT false,
    favorite_notifications boolean DEFAULT true,
    default_character_split character varying DEFAULT 'template'::character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits ALTER COLUMN id SET DEFAULT nextval('audits_id_seq'::regclass);


--
-- Name: board_authors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_authors ALTER COLUMN id SET DEFAULT nextval('board_authors_id_seq'::regclass);


--
-- Name: board_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_sections ALTER COLUMN id SET DEFAULT nextval('board_sections_id_seq'::regclass);


--
-- Name: board_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_views ALTER COLUMN id SET DEFAULT nextval('board_views_id_seq'::regclass);


--
-- Name: boards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY boards ALTER COLUMN id SET DEFAULT nextval('boards_id_seq'::regclass);


--
-- Name: character_aliases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY character_aliases ALTER COLUMN id SET DEFAULT nextval('character_aliases_id_seq'::regclass);


--
-- Name: character_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY character_groups ALTER COLUMN id SET DEFAULT nextval('character_groups_id_seq'::regclass);


--
-- Name: character_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY character_tags ALTER COLUMN id SET DEFAULT nextval('character_tags_id_seq'::regclass);


--
-- Name: characters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY characters ALTER COLUMN id SET DEFAULT nextval('characters_id_seq'::regclass);


--
-- Name: characters_galleries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY characters_galleries ALTER COLUMN id SET DEFAULT nextval('characters_galleries_id_seq'::regclass);


--
-- Name: favorites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorites ALTER COLUMN id SET DEFAULT nextval('favorites_id_seq'::regclass);


--
-- Name: flat_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flat_posts ALTER COLUMN id SET DEFAULT nextval('flat_posts_id_seq'::regclass);


--
-- Name: galleries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY galleries ALTER COLUMN id SET DEFAULT nextval('galleries_id_seq'::regclass);


--
-- Name: galleries_icons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY galleries_icons ALTER COLUMN id SET DEFAULT nextval('galleries_icons_id_seq'::regclass);


--
-- Name: gallery_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gallery_tags ALTER COLUMN id SET DEFAULT nextval('gallery_tags_id_seq'::regclass);


--
-- Name: icons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY icons ALTER COLUMN id SET DEFAULT nextval('icons_id_seq'::regclass);


--
-- Name: index_posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY index_posts ALTER COLUMN id SET DEFAULT nextval('index_posts_id_seq'::regclass);


--
-- Name: index_sections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY index_sections ALTER COLUMN id SET DEFAULT nextval('index_sections_id_seq'::regclass);


--
-- Name: indexes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY indexes ALTER COLUMN id SET DEFAULT nextval('indexes_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages ALTER COLUMN id SET DEFAULT nextval('messages_id_seq'::regclass);


--
-- Name: password_resets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY password_resets ALTER COLUMN id SET DEFAULT nextval('password_resets_id_seq'::regclass);


--
-- Name: post_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_tags ALTER COLUMN id SET DEFAULT nextval('post_tags_id_seq'::regclass);


--
-- Name: post_viewers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_viewers ALTER COLUMN id SET DEFAULT nextval('post_viewers_id_seq'::regclass);


--
-- Name: post_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_views ALTER COLUMN id SET DEFAULT nextval('post_views_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: replies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY replies ALTER COLUMN id SET DEFAULT nextval('replies_id_seq'::regclass);


--
-- Name: reply_drafts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reply_drafts ALTER COLUMN id SET DEFAULT nextval('reply_drafts_id_seq'::regclass);


--
-- Name: report_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_views ALTER COLUMN id SET DEFAULT nextval('report_views_id_seq'::regclass);


--
-- Name: tag_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tag_tags ALTER COLUMN id SET DEFAULT nextval('tag_tags_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY templates ALTER COLUMN id SET DEFAULT nextval('templates_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: board_authors board_authors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_authors
    ADD CONSTRAINT board_authors_pkey PRIMARY KEY (id);


--
-- Name: board_sections board_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_sections
    ADD CONSTRAINT board_sections_pkey PRIMARY KEY (id);


--
-- Name: board_views board_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY board_views
    ADD CONSTRAINT board_views_pkey PRIMARY KEY (id);


--
-- Name: boards boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: character_aliases character_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY character_aliases
    ADD CONSTRAINT character_aliases_pkey PRIMARY KEY (id);


--
-- Name: character_groups character_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY character_groups
    ADD CONSTRAINT character_groups_pkey PRIMARY KEY (id);


--
-- Name: character_tags character_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY character_tags
    ADD CONSTRAINT character_tags_pkey PRIMARY KEY (id);


--
-- Name: characters_galleries characters_galleries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY characters_galleries
    ADD CONSTRAINT characters_galleries_pkey PRIMARY KEY (id);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: flat_posts flat_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY flat_posts
    ADD CONSTRAINT flat_posts_pkey PRIMARY KEY (id);


--
-- Name: galleries_icons galleries_icons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY galleries_icons
    ADD CONSTRAINT galleries_icons_pkey PRIMARY KEY (id);


--
-- Name: galleries galleries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY galleries
    ADD CONSTRAINT galleries_pkey PRIMARY KEY (id);


--
-- Name: gallery_tags gallery_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gallery_tags
    ADD CONSTRAINT gallery_tags_pkey PRIMARY KEY (id);


--
-- Name: icons icons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY icons
    ADD CONSTRAINT icons_pkey PRIMARY KEY (id);


--
-- Name: index_posts index_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY index_posts
    ADD CONSTRAINT index_posts_pkey PRIMARY KEY (id);


--
-- Name: index_sections index_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY index_sections
    ADD CONSTRAINT index_sections_pkey PRIMARY KEY (id);


--
-- Name: indexes indexes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY indexes
    ADD CONSTRAINT indexes_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id);


--
-- Name: post_tags post_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_tags
    ADD CONSTRAINT post_tags_pkey PRIMARY KEY (id);


--
-- Name: post_viewers post_viewers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_viewers
    ADD CONSTRAINT post_viewers_pkey PRIMARY KEY (id);


--
-- Name: post_views post_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY post_views
    ADD CONSTRAINT post_views_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: replies replies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY replies
    ADD CONSTRAINT replies_pkey PRIMARY KEY (id);


--
-- Name: reply_drafts reply_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reply_drafts
    ADD CONSTRAINT reply_drafts_pkey PRIMARY KEY (id);


--
-- Name: report_views report_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_views
    ADD CONSTRAINT report_views_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tag_tags tag_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tag_tags
    ADD CONSTRAINT tag_tags_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: associated_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX associated_index ON audits USING btree (associated_id, associated_type);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditable_index ON audits USING btree (auditable_id, auditable_type);


--
-- Name: idx_fts_post_content; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fts_post_content ON posts USING gin (to_tsvector('english'::regconfig, COALESCE(content, ''::text)));


--
-- Name: idx_fts_post_subject; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fts_post_subject ON posts USING gin (to_tsvector('english'::regconfig, COALESCE((subject)::text, ''::text)));


--
-- Name: idx_fts_reply_content; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fts_reply_content ON replies USING gin (to_tsvector('english'::regconfig, COALESCE(content, ''::text)));


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_created_at ON audits USING btree (created_at);


--
-- Name: index_audits_on_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_request_uuid ON audits USING btree (request_uuid);


--
-- Name: index_board_authors_on_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_authors_on_board_id ON board_authors USING btree (board_id);


--
-- Name: index_board_authors_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_board_authors_on_user_id ON board_authors USING btree (user_id);


--
-- Name: index_board_views_on_user_id_and_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_board_views_on_user_id_and_board_id ON board_views USING btree (user_id, board_id);


--
-- Name: index_character_aliases_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_aliases_on_character_id ON character_aliases USING btree (character_id);


--
-- Name: index_character_tags_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_tags_on_character_id ON character_tags USING btree (character_id);


--
-- Name: index_character_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_tags_on_tag_id ON character_tags USING btree (tag_id);


--
-- Name: index_characters_galleries_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_galleries_on_character_id ON characters_galleries USING btree (character_id);


--
-- Name: index_characters_galleries_on_gallery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_galleries_on_gallery_id ON characters_galleries USING btree (gallery_id);


--
-- Name: index_characters_on_character_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_character_group_id ON characters USING btree (character_group_id);


--
-- Name: index_characters_on_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_template_id ON characters USING btree (template_id);


--
-- Name: index_characters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_user_id ON characters USING btree (user_id);


--
-- Name: index_favorites_on_favorite_id_and_favorite_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorites_on_favorite_id_and_favorite_type ON favorites USING btree (favorite_id, favorite_type);


--
-- Name: index_favorites_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorites_on_user_id ON favorites USING btree (user_id);


--
-- Name: index_flat_posts_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flat_posts_on_post_id ON flat_posts USING btree (post_id);


--
-- Name: index_galleries_icons_on_gallery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_galleries_icons_on_gallery_id ON galleries_icons USING btree (gallery_id);


--
-- Name: index_galleries_icons_on_icon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_galleries_icons_on_icon_id ON galleries_icons USING btree (icon_id);


--
-- Name: index_galleries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_galleries_on_user_id ON galleries USING btree (user_id);


--
-- Name: index_gallery_tags_on_gallery_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gallery_tags_on_gallery_id ON gallery_tags USING btree (gallery_id);


--
-- Name: index_gallery_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gallery_tags_on_tag_id ON gallery_tags USING btree (tag_id);


--
-- Name: index_icons_on_has_gallery; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_icons_on_has_gallery ON icons USING btree (has_gallery);


--
-- Name: index_icons_on_keyword; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_icons_on_keyword ON icons USING btree (keyword);


--
-- Name: index_icons_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_icons_on_url ON icons USING btree (url);


--
-- Name: index_icons_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_icons_on_user_id ON icons USING btree (user_id);


--
-- Name: index_index_posts_on_index_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_index_posts_on_index_id ON index_posts USING btree (index_id);


--
-- Name: index_index_posts_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_index_posts_on_post_id ON index_posts USING btree (post_id);


--
-- Name: index_index_sections_on_index_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_index_sections_on_index_id ON index_sections USING btree (index_id);


--
-- Name: index_indexes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_indexes_on_user_id ON indexes USING btree (user_id);


--
-- Name: index_messages_on_recipient_id_and_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_recipient_id_and_unread ON messages USING btree (recipient_id, unread);


--
-- Name: index_messages_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_sender_id ON messages USING btree (sender_id);


--
-- Name: index_messages_on_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_thread_id ON messages USING btree (thread_id);


--
-- Name: index_password_resets_on_auth_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_password_resets_on_auth_token ON password_resets USING btree (auth_token);


--
-- Name: index_password_resets_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_password_resets_on_user_id_and_created_at ON password_resets USING btree (user_id, created_at);


--
-- Name: index_post_tags_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_tags_on_post_id ON post_tags USING btree (post_id);


--
-- Name: index_post_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_tags_on_tag_id ON post_tags USING btree (tag_id);


--
-- Name: index_post_viewers_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_viewers_on_post_id ON post_viewers USING btree (post_id);


--
-- Name: index_post_views_on_user_id_and_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_post_views_on_user_id_and_post_id ON post_views USING btree (user_id, post_id);


--
-- Name: index_posts_on_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_board_id ON posts USING btree (board_id);


--
-- Name: index_posts_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_character_id ON posts USING btree (character_id);


--
-- Name: index_posts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_created_at ON posts USING btree (created_at);


--
-- Name: index_posts_on_icon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_icon_id ON posts USING btree (icon_id);


--
-- Name: index_posts_on_tagged_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_tagged_at ON posts USING btree (tagged_at);


--
-- Name: index_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id ON posts USING btree (user_id);


--
-- Name: index_replies_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replies_on_character_id ON replies USING btree (character_id);


--
-- Name: index_replies_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replies_on_created_at ON replies USING btree (created_at);


--
-- Name: index_replies_on_icon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replies_on_icon_id ON replies USING btree (icon_id);


--
-- Name: index_replies_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replies_on_post_id ON replies USING btree (post_id);


--
-- Name: index_replies_on_thread_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replies_on_thread_id ON replies USING btree (thread_id);


--
-- Name: index_replies_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_replies_on_user_id ON replies USING btree (user_id);


--
-- Name: index_reply_drafts_on_post_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reply_drafts_on_post_id_and_user_id ON reply_drafts USING btree (post_id, user_id);


--
-- Name: index_report_views_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_views_on_user_id ON report_views USING btree (user_id);


--
-- Name: index_tag_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tag_tags_on_tag_id ON tag_tags USING btree (tag_id);


--
-- Name: index_tag_tags_on_tagged_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tag_tags_on_tagged_id ON tag_tags USING btree (tagged_id);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_name ON tags USING btree (name);


--
-- Name: index_tags_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_type ON tags USING btree (type);


--
-- Name: index_templates_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_templates_on_user_id ON templates USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON users USING btree (username);


--
-- Name: user_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_index ON audits USING btree (user_id, user_type);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20150413062555'),
('20150413233206'),
('20150414195302'),
('20150414195307'),
('20150414200044'),
('20150414211752'),
('20150415221435'),
('20150415221456'),
('20150417214406'),
('20150624201245'),
('20150704060600'),
('20151125201254'),
('20151127033352'),
('20151127181237'),
('20151127183038'),
('20151127210938'),
('20151130050434'),
('20151215041641'),
('20160108230631'),
('20160218041741'),
('20160218041751'),
('20160222042730'),
('20160223065123'),
('20160303032220'),
('20160306053517'),
('20160318021845'),
('20160322032647'),
('20160326210104'),
('20160410024710'),
('20160410060405'),
('20160410170309'),
('20160412035353'),
('20160416031844'),
('20160429033350'),
('20160604181644'),
('20160615094301'),
('20160627210836'),
('20160702213101'),
('20160704224416'),
('20160716055457'),
('20160719012330'),
('20160723172304'),
('20160731040017'),
('20160813025151'),
('20160827161416'),
('20160925032329'),
('20161008224853'),
('20161024185615'),
('20161107014948'),
('20161110055637'),
('20161126195558'),
('20161129195022'),
('20161218194918'),
('20170103184309'),
('20170109000120'),
('20170210013443'),
('20170221171959'),
('20170331133925'),
('20170413195840'),
('20170501214439'),
('20170505173455'),
('20170513052413'),
('20170519123223'),
('20170612015922'),
('20170617180015'),
('20170619010707'),
('20170814042150'),
('20170819222420'),
('20170821210336'),
('20170826211901'),
('20170828144608'),
('20170907180029'),
('20170911235423'),
('20170914191425'),
('20171001035221'),
('20171027225408'),
('20171104140915');


