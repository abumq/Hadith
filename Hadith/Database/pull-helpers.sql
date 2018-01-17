## Book (by collection ID)
SELECT concat('INSERT INTO Book (collection_id, volume, number, name, total_hadiths) VALUES(', collection_id, ',', volume, ',', book, ',\'', replace(book_name, '\'', '\'\''), '\',', 0, ');') 
FROM `HadithBookInfo` where collection_id = 10 AND status = 1

## Update total hadiths
SELECT concat('UPDATE Book SET total_hadiths = ', (SELECT count(*) FROM `Hadith` WHERE collection_id = HBI.collection_id AND book = HBI.book AND database_id = 1 AND status = 1), ' WHERE collection_id = ', collection_id, ' AND number = ', book, ';') 
FROM `HadithBookInfo` HBI where collection_id = 10 AND status = 1

## Update total hadiths MASTER
SELECT concat('UPDATE Collection SET total_hadiths = ', (SELECT count(*) FROM `Hadith` WHERE collection_id = HBI.collection_id AND database_id = 1 AND status = 1), ' WHERE collection_id = ', collection_id) 
FROM `HadithBookInfo` HBI where collection_id = 10 AND status = 1 LIMIT 1;

# Hadith
SELECT concat('INSERT INTO Hadith (language_id, collection_id, volume, book, number, text, grade, tags, ref_tags, refs, links) VALUES(', database_id, ',', collection_id, ',', volume, ',', book, ',\'', hadith, '\',\'', replace(text, '\'', '\'\''), '\',\'', grade_flag, '\',\'', replace(COALESCE(`tags`, ""), '\'', '\'\''), '\',\'', replace(COALESCE(`ref_tags`, ""), '\'', '\'\''), '\',\'', replace(COALESCE(`references`, ""), '\'', '\'\''), '\',\'', replace(COALESCE(`links`, ""), '\'', '\'\''), '\');') 
FROM `Hadith` where collection_id = 10 AND status = 1 and database_id = 1 order by database_id, volume, book, hadith LIMIT 0, 500;

# Remove anything starting from concat
## sed '/^concat/ d' import.sql > export.sql && mv export.sql import.sql

# SCP
## scp db-bukhari.db livemuflihun:~/public_html/resources/data/hadith.app

# Run script against sqlite database
## sqlite3 file.db < file.sql 
