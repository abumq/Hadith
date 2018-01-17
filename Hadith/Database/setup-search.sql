CREATE TABLE "Keyword" (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`text`	VARCHAR(100) NOT NULL
);
CREATE UNIQUE INDEX `keyword_basic_idx` ON `Keyword` (`text` );