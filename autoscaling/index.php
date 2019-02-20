<?php

$sum = 0;
$n = 10000000;
$sign = 1;

for ($i = 0; $i < $n; $i++) {
    $sum += $sign / (2 * $i + 1);
    $sign = -$sign;
}

echo 'π ~= ' . (4 * $sum) . "\n";
