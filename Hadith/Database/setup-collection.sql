CREATE TABLE "Book" (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`collection_id`	INTEGER NOT NULL,
	`volume`	INTEGER,
	`number`	INTEGER NOT NULL,
	`name`	TEXT NOT NULL,
	`arabic_name`	TEXT,
	`total_hadiths`	INTEGER NOT NULL DEFAULT 0
)

CREATE TABLE "Hadith" (
	`id`	INTEGER PRIMARY KEY AUTOINCREMENT,
	`language_id`	INTEGER NOT NULL,
	`collection_id`	INTEGER NOT NULL,
	`volume`	INTEGER,
	`book`	INTEGER,
	`number`	VARCHAR(10) NOT NULL,
	`text`	TEXT NOT NULL,
	`grade`	INTEGER NOT NULL,
	`tags`	VARCHAR(255),
	`ref_tags`	VARCHAR(255),
	`refs`	VARCHAR(255),
	`links`	TEXT
)
CREATE INDEX `book_basic_idx` ON `Book` (`id` ,`collection_id` ,`volume` ,`number` );
CREATE UNIQUE INDEX `book_uniq_idx` ON `Book` (`collection_id` ,`volume` ,`number` );
CREATE INDEX `hadith_basic_idx` ON `Hadith` (`grade` ,`tags` ,`ref_tags` );
CREATE UNIQUE INDEX `hadith_uniq_idx` ON `Hadith` (`language_id` ,`collection_id` ,`volume` ,`book` ,`number` )