<?php

$list = explode("\n", file_get_contents("list.txt"));
echo "DELETE FROM Keyword;\n";
foreach ($list as $word) {
    if (strlen($word) > 3) {
        echo "INSERT INTO Keyword(text) VALUES('$word');\n";
    }
}


