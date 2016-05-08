#! /usr/bin/perl
while ($line = <STDIN>){
    chop($line);
    if ($line =~ /^struct /){
        ($dummy1, $tmp, $dummy2) = split(/ /, $line);
        ($recname, $keyname) = split(/_/, $tmp);
    }
    if ($line =~ /^ *char /){
        ($dummy1, $dummy2, $tmp) = split(/ .. /, $line);
        ($item, $tmp) = split(/\[/, $tmp);
        ($size, $dummy1) = split(/\]/, $tmp);
        printf("%-s\t%-s\t%-s\t%-s\n", $recname, $keyname, $item, $size);
    }
}
