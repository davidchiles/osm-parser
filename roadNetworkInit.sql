--
--
-- This SQL script creates the DB model used to store information extracted during a .osm file parsing.
--
-- 
-- SELECT InitSpatialMetaData();
-- INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, ref_sys_name, proj4text) VALUES (4326, 'epsg', 4326,'WGS 84', '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs');
CREATE TABLE "main"."nodes" (
	"id" INTEGER PRIMARY KEY  NOT NULL , 
	"latitude" DOUBLE NOT NULL , 
	"longitude" DOUBLE NOT NULL,
	"user" TEXT,
	"uid" INTEGER,
	"timestamp" TEXT,
	"version" TEXT,
	"changeset" INTEGER
	"action" TEXT CHECK ( type IN ("delete", "update"))
);

CREATE TABLE "main"."nodes_tags" (
	node_id INTEGER REFERENCES nodes ( id ),
	"key" TEXT, 
	"value" TEXT,
	UNIQUE ( node_id, key, value )
	);
CREATE TABLE "main"."ways" (
	"id" INTEGER PRIMARY KEY NOT NULL,
	"user" TEXT,
	"uid" INTEGER,
	"timestamp" TEXT,
	"version" TEXT,
	"changeset" INTEGER
	"action" TEXT CHECK ( type IN ("delete", "update"))
);

CREATE TABLE "main"."ways_tags" (
	"way_id" INTEGER REFERENCES ways ( id ),
    "key" TEXT,
    "value" TEXT,
    UNIQUE ( way_id, key, value )
);

CREATE TABLE "main"."ways_nodes" (
	"way_id" INTEGER REFERENCES ways ( id ),
    "local_order" INTEGER,
    "node_id" INTEGER REFERENCES nodes ( id ),
    UNIQUE ( way_id, local_order, node_id )
);


CREATE TABLE "main"."relations" (
	"id" INTEGER NOT NULL
	"user" TEXT,
	"uid" INTEGER,
	"timestamp" TEXT,
	"version" TEXT,
	"changeset" INTEGER
	"action" TEXT CHECK ( type IN ("delete", "update"))
);
CREATE TABLE "main"."relations_members" (
	relation_id INTEGER REFERENCES relations ( id )
	"type" TEXT CHECK ( type IN ("node", "way", "relation")), 
	"ref" INTEGER NOT NULL , 
	"role" TEXT,
	"local_order" INTEGER
);
CREATE TABLE "main"."relations_tags" (
	relation_id INTEGER NOT NULL REFERENCES relations ( id ), 
	"key" TEXT, 
	"value" TEXT
);

create index way_nodes_way_id ON way_nodes ( way_id );
create index way_nodes_node_id ON way_nodes ( node_id );
-- SELECT AddGeometryColumn('ways', 'geom', 4326, 'LINESTRING', 2);
-- CREATE TABLE roadsDefinitions ("ref" VARCHAR[10], "name" VARCHAR[100], "course" VARCHAR[2], "section" VARCHAR[2]);
CREATE TABLE ways_info ("ref" VARCHAR[10], "name" VARCHAR[100]);
