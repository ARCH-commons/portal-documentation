-- portal-schema.sql
-- create metadata database for portal API
-- Parameters:
--    @devSiteAdmin - the portal development/test site admin user
--    @devSitePwd - the dev site admin password
--    @rstudioNodeUrl - the initial RStudio Node URL (include port number)
--
-- NOTE:  This script was run in HeidiSQL to take advantage of bind parameters for sensitive variables


-- Script Variables
SET @bchSiteId='bc6ae506-ce94-450c-a7b5-db4fe99d6549';
SET @phsSiteId='4560486b-6ad4-410c-87cb-eaadac97bff8';
SET @hmsSiteId='37a99160-bbf2-4da1-a8ef-dd02c15f523b';
SET @devSiteId='51b8d7f6-f435-49f5-81b5-d4fe3f486d8e';

SET @devSiteAdmin = 'dev_siteadmin';
SET @rstudioNodeUsername = 'ec2-user';

USE `:dbName`;

SET foreign_key_checks = 0;

-- DDL (OAuth server)
drop table IF EXISTS UserTokens;
drop table IF EXISTS UserRoles;
drop table IF EXISTS Users;
CREATE TABLE IF NOT EXISTS Users(username VARCHAR(255), passwd VARCHAR(255), PRIMARY KEY (username));
CREATE TABLE IF NOT EXISTS UserRoles(username VARCHAR(255), userRoles VARCHAR(255));
CREATE TABLE IF NOT EXISTS UserTokens(username VARCHAR(255), token VARCHAR(500), expirationDate DATETIME, PRIMARY KEY(token));

-- DDL (API metadata)
drop table if exists document_status;
drop table if exists document_type;
drop table if exists lds_file;
drop table if exists node;
drop table if exists request;
drop table if exists request_status;
drop table if exists site;
drop table if exists space;
drop table if exists study;
drop table if exists study_status;
drop table if exists study_users_access;
drop table if exists user_auth;
drop table if exists user_site;

create table document_status (
  id bigint not null,
  description varchar(255),
  name varchar(255),
  primary key (id)
);

create table document_type (
  id bigint not null,
  description varchar(255),
  name varchar(255),
  primary key (id)
);

create table lds_file (
  uuid varchar(255) not null,
  creation_date datetime(6),
  description varchar(255),
  name varchar(255),
  sync bigint,
  site_uuid varchar(255) not null,
  study_uuid varchar(255) not null,
  primary key (uuid)
);

create table node (
  url varchar(255) not null,
  ssh_key varchar(255),
  node_memory INT,
  name varchar(255),
  num_studies INT,
  ssh_port BIGINT,
  username varchar(255),
  primary key (url)
);

create table request (
  uuid varchar(255) not null,
  change_state_Date datetime(6),
  creation_Date datetime(6),
  email varchar(255),
  institution varchar(255),
  name varchar(255),
  username varchar(255),
  is_data_steward boolean not null default false,
  request_status bigint,
  request_site varchar(255),
  primary key (uuid)
);

create table request_status (
  id bigint not null,
  description varchar(255),
  name varchar(255),
  primary key (id)
);

create table site (
  uuid varchar(255) not null,
  active bigint,
  code varchar(255) unique,
  creation_date datetime(6),
  description varchar(255),
  i2b2_url varchar(255),
  name varchar(255),
  short_name varchar(255) unique,
  primary key (uuid)
);

create table space (
  uuid varchar(255) not null,
  creation_date datetime(6),
  json longtext,
  url varchar(255),
  study_uuid varchar(255) not null,
  primary key (uuid),
  unique (study_uuid)
);

create table study (
  uuid varchar(255) not null,
  change_status_date datetime(6),
  creation_date datetime(6),
  department varchar(255),
  description varchar(255),
  email varchar(255),
  full_name varchar(255),
  institution varchar(255),
  name varchar(255),
  researcher_username varchar(255),
  title varchar(255),
  study_node varchar(255),
  study_site varchar(255),
  study_status bigint,
  primary key (uuid)
);

create table study_status (
  id bigint not null,
  description varchar(255),
  name varchar(255),
  primary key (id)
);

create table study_users_access (
  uuid varchar(255) not null,
  access_level varchar(255),
  researcher_username varchar(255),
  study_uuid varchar(255),
  primary key (uuid)
);

create table user_auth (
  username varchar(255) not null,
  auth_method varchar(255) not null,
  primary key (username)
);

create table user_site (
  uuid varchar(255) not null,
  creation_date datetime(6),
  username varchar(255),
  site_uuid varchar(255) not null,
  primary key (uuid)
);

alter table lds_file
  add constraint fk_lds_file_1
foreign key (site_uuid)
references site(uuid)
  on update cascade;


alter table lds_file
  add constraint fk_lds_file_2
foreign key (study_uuid)
references study(uuid)
  on update cascade;

alter table request
  add constraint fk_request_1
foreign key (request_status)
references request_status(id)
  on update cascade;

alter table request
  add constraint fk_request_2
foreign key (request_site)
references site(uuid)
  on update cascade;

alter table space
  add constraint fk_space_1
foreign key (study_uuid)
references study(uuid)
  on update cascade;


alter table study
  add constraint fk_study_1
foreign key (study_node)
references node(url)
  on update cascade;

alter table study
  add constraint fk_study_2
foreign key (study_site)
references site(uuid)
  on update cascade;

alter table study
  add constraint fk_study_3
foreign key (study_status)
references study_status(id)
  on update cascade;

alter table study_users_access
  add constraint fk_study_users_access_1
foreign key (study_uuid)
references study(uuid)
  on update cascade;

alter table user_site
  add constraint fk_user_site_1
foreign key (site_uuid)
references site(uuid)
  on update cascade;

SET foreign_key_checks = 1;


-- *** DATA ***
-- install site admin users (all users (except dev/test site) SHOULD authenticate via PM cell so 'password' field will be ignored)
-- nevertheless, if the local password is ever used it is obtained by creating a hash, e.g.
-- echo -n "password" | openssl dgst -sha1 -binary | openssl base64
--
INSERT INTO Users(username, passwd) values (@devSiteAdmin, ':devSitePwd');
INSERT INTO UserRoles(username, userRoles) values (@devSiteAdmin, 'SITE_ADMIN');
INSERT INTO user_auth(username, auth_method) values(@devSiteAdmin, 'PM');

-- Insert test users
# INSERT INTO Users(username, passwd) values ('test_siteadmin', '/iSCssLoOhJ0xd5CCtOQJhrJFH8=');
# INSERT INTO UserRoles(username, userRoles) values ('test_siteadmin', 'SITE_ADMIN');
#
# INSERT INTO Users(username, passwd) values ('test_site_uploader', '/iSCssLoOhJ0xd5CCtOQJhrJFH8=');
# INSERT INTO UserRoles(username, userRoles) values ('test_site_uploader', 'SITE_UPLOADER');
#
# INSERT INTO Users(username, passwd) values ('researcher', '/iSCssLoOhJ0xd5CCtOQJhrJFH8=');
# INSERT INTO UserRoles(username, userRoles) values ('researcher', 'EXTERNAL_USER');
#
# INSERT INTO Users(username, passwd) values ('admin', '/iSCssLoOhJ0xd5CCtOQJhrJFH8=');
# INSERT INTO UserRoles(username, userRoles) values ('admin', 'GLOBAL_ADMIN');
# -- Insert 'ARCH_RESEARCHER' test user (PM CELL)
# INSERT INTO UserRoles(username, userRoles) values ('arch_researcher', 'EXTERNAL_USER');

-- Document Types
INSERT INTO document_type (id, name, description) values(0,'IRB', 'Institutional review board');
INSERT INTO document_type (id, name, description) values(1,'DSA', 'Data sharing agreement');
INSERT INTO document_type (id, name, description) values(2,'NDA', 'Non-disclosure agreement');
INSERT INTO document_type (id, name, description) values(3,'Other', 'Other');

-- Document Status
INSERT INTO document_status (id, name, description) values (0, 'Accepted', 'Accepted');
INSERT INTO document_status (id, name, description) values (1, 'In Review', 'In Review');
INSERT INTO document_status (id, name, description) values (2, 'Rejected', 'Rejected');

-- Request Status
INSERT INTO request_status (id, name, description) values (0, 'Accepted', 'Accepted');
INSERT INTO request_status (id, name, description) values (1, 'In Review', 'In Review');
INSERT INTO request_status (id, name, description) values (2, 'Rejected', 'Rejected');

-- Study Status
INSERT INTO study_status (id, name, description) values (0, 'Approved', 'Approved');
INSERT INTO study_status (id, name, description) values (1, 'In Review', 'In Review');
INSERT INTO study_status (id, name, description) values (2, 'Rejected', 'Rejected');

-- Sites
INSERT INTO site(uuid, name, description, i2b2_url, short_name, code, active) values (@bchSiteId, 'BCH', 'Boston Childrens Hospital', 'https://www.i2b2.org/webclient/', 'BCH','A',1);
INSERT INTO site(uuid, name, description, i2b2_url, short_name, code, active) values (@hmsSiteId, 'HMS', 'Harvard Medical School', 'https://www.i2b2.org/webclient/','HMS', 'B',1);
INSERT INTO site(uuid, name, description, i2b2_url, short_name, code, active) values (@phsSiteId, 'Partners', 'Partners Healthcare', 'https://www.i2b2.org/webclient/','Partners', 'C', 1);
INSERT INTO site(uuid, name, description, i2b2_url, short_name, code, active) values (@devSiteId, 'Development/Test Site', 'Development and Testing Site', 'https://www.i2b2.org/webclient/','DEV', 'M', 1);

-- User Sites : To HMS
INSERT INTO user_site(uuid, site_uuid, username) values ('3a1dfc0b-2899-483e-8d57-59829df4d0b7', @devSiteId, @devSiteAdmin);

-- Insert VALID Nodes  (will need to be changed)
INSERT INTO node(url, name, ssh_port, username, ssh_key, node_memory, num_studies) values (':rstudioNodeUrl', 'ARCH RStudio Server Node 1', 22, @rstudioNodeUsername, '/var/arch/.ssh/id_rsa', :rstudioNodeMemory, 0);

-- Studies
# INSERT INTO study(uuid, name, description, researcher_username, study_status, study_node, study_site) values ('91271e86-1847-11e6-b6ba-3e1d05defe78', 'First study', 'Pulmonary hypertension study', 'researcher',0,@rstudioNodeUrl, '91d62170-1847-11e6-b6ba-3e1d05defe78');

-- Studies access
# INSERT INTO study_users_access(uuid, study_uuid, researcher_username, access_level) values ('c19a7812-d661-492b-9396-8e5936239c01','91271e86-1847-11e6-b6ba-3e1d05defe78','researcher','A');

