#! /usr/bin/perl
@rec = <STDIN>;
foreach $i (@rec){
    chop($i);
}
printf("/*\n");
printf(" * !! DO NOT EDIT THIS SOURCE. THIS IS GENERATED AUTOMATICALY !!\n");
printf(" */\n");
printf("#if defined(__TYSERV_PART1__)\n");
foreach $i (@rec){
    printf("int  %-s_get(), %-s_put(), %-s_update(), %-s_delete(), %-s_getnext();\n",
            $i, $i, $i, $i, $i);
}
printf("#endif\n");
printf("\n");
printf("#if defined(__TYSERV_PART2__)\n");
foreach $i (@rec){
    printf("    {\"%-s\", %-s_get, %-s_put, %-s_update, %-s_delete, %-s_getnext},\n",
            $i, $i, $i, $i, $i, $i);
}
printf("#endif\n");
