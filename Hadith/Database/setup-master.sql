CREATE TABLE "Collection" (
	`id`	INTEGER,
	`identifier`	TEXT,
	`name`	TEXT NOT NULL,
	`arabic_name`	TEXT,
	`medium_name`	TEXT NOT NULL,
	`short_name`	TEXT NOT NULL,
	`has_books`	INTEGER NOT NULL,
	`has_volumes`	INTEGER NOT NULL,
	`total_hadiths`	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY(id,identifier)
);
CREATE TABLE "Language" (
	`id`	INTEGER NOT NULL,
	`identifier`	INTEGER NOT NULL,
	`name`	TEXT NOT NULL,
	`collection_id`	INTEGER NOT NULL,
	`direction`	INTEGER NOT NULL DEFAULT 1,
	`font_size`	INTEGER NOT NULL DEFAULT 16,
	PRIMARY KEY(id)
);
CREATE UNIQUE INDEX `uniq_collection_idx` ON `Collection` (`id` ,`identifier` );
CREATE UNIQUE INDEX `uniq_languuage_idx` ON `Language` (`identifier` ,`collection_id` );