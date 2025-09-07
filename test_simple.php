<?php
echo "PHP is working!";
echo "<br>";
echo "Current time: " . date('Y-m-d H:i:s');
echo "<br>";
echo "Current directory: " . getcwd();
echo "<br>";
echo "Files in directory:";
echo "<pre>";
print_r(scandir('.'));
echo "</pre>";
?> 