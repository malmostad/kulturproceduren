CREATE TABLE "age_groups" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "age" integer, "quantity" integer, "group_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "booking_requirements" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "requirement" text, "occasion_id" integer, "group_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "culture_administrators" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "mobil_nr" varchar(255), "email" varchar(255), "created_at" datetime, "updated_at" datetime);
CREATE TABLE "districts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "elit_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "events" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "from_age" integer, "to_age" integer, "description" text, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "groups" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "elit_id" integer, "school_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "notification_requests" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "send_mail" boolean, "send_sms" boolean, "group_id" integer, "occasion_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "occasions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "date" date, "seats" integer, "address" text, "description" text, "event_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "schools" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "elit_id" integer, "district_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "tickets" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "state" integer, "group_id" integer, "event_id" integer, "occasion_id" integer, "district_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20090430090955');

INSERT INTO schema_migrations (version) VALUES ('20090430094356');

INSERT INTO schema_migrations (version) VALUES ('20090430094357');

INSERT INTO schema_migrations (version) VALUES ('20090430094358');

INSERT INTO schema_migrations (version) VALUES ('20090430094359');

INSERT INTO schema_migrations (version) VALUES ('20090430094400');

INSERT INTO schema_migrations (version) VALUES ('20090430094402');

INSERT INTO schema_migrations (version) VALUES ('20090430094403');

INSERT INTO schema_migrations (version) VALUES ('20090430094404');

INSERT INTO schema_migrations (version) VALUES ('20090430094405');

INSERT INTO schema_migrations (version) VALUES ('20090430094406');