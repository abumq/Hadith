php ~/Projects/muflihun.com/tools/sqlite-query-builder/release.php --version-file=/Users/mkhan/Dropbox/Apps/iOS/Hadith/Hadith/Database/version.json --master-db=/Users/mkhan/Dropbox/Apps/iOS/Hadith/Hadith/Database/db-master.db --database=riyaad --collection-id=10 --name="Riyaad-us Saliheen" --details="Full extract of Riyaad-us Saliheen (English) as of 21/06/2016" --upload
php ~/Projects/muflihun.com/tools/sqlite-query-builder/release.php --version-file=/Users/mkhan/Dropbox/Apps/iOS/Hadith/Hadith/Database/version.json --master-db=/Users/mkhan/Dropbox/Apps/iOS/Hadith/Hadith/Database/db-master.db --database=riyaad-arabic --collection-id=10 --name="Riyaad-us Saliheen (Arabic)" --details="Full extract of Riyaad-us Saliheen (Arabic) as of 21/06/2016" --upload
echo
echo
echo "scp ~/Projects/Hadith/Hadith/Database/db-master.db livemuflihun:~/public_html/resources/data/hadith.app && scp ~/Projects/Hadith/Hadith/Database/version.json livemuflihun:~/public_html/resources/data/hadith.app"
