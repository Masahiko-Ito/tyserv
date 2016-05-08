#! /usr/bin/perl
$i = 0;
while ($line = <STDIN>){
    chop($line);
    ($rec[$i], $key[$i], $item[$i], $size[$i]) = split(/\t/, $line);
    $i++;
}

@src = <<__EOF__;
/*
 * !! DO NOT EDIT THIS SOURCE. THIS IS GENERATED AUTOMATICALY !!
 *
 * tyhpoon database server program by M.Ito
 * Ver. 1.0    2002.07.01
 */
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <errno.h>
#include <signal.h>

#include <ctype.h>
#include <typhoon.h>

/* DataBase definition */
#include "__DB__.h"

extern FILE *Fp_rvj;
extern FILE *Fp_rbj;
extern int  Rvj_sw;
extern int  Rbj_sw;
extern char In_buf[];
extern char In_buf_rvj[];
extern char Out_buf[];
extern char Out_buf_rbj[];
extern char *KeyName;
extern char *Condition;
extern char *KeyValue;
extern char *ItemName;
extern char *ItemValue;

/*
__EOF__
print @src;

printf(" * %-s access functions\n", $rec[0]);
printf(" */\n");
printf("int %-s_get(buf)\n", $rec[0]);
printf("    char *buf;\n");
printf("{\n");
printf("    int  sts, key_id;\n");
printf("    void *p_key;\n");
printf("    struct %-s       %-s;\n", $rec[0], $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    struct %-s_%-s  %-s_%-s;\n", 
                   $rec[$i], $key[$i], $rec[$i], $key[$i]);
        }else{
            if ($key[$i] ne $old_key){
                $old_key = $key[$i];
                printf("    struct %-s_%-s  %-s_%-s;\n",
                       $rec[$i], $key[$i], $rec[$i], $key[$i]);
            }
        }
    }
}
printf("\n");
printf("    get_key_cond(buf);\n");

$old_key = "";
for ($i = 0; $rec[$i]; $i++){

    $upper_rec = $rec[$i];
    $upper_rec =~ tr/a-z/A-Z/;
    $upper_key = $key[$i];
    $upper_key =~ tr/a-z/A-Z/;
    $upper_item = $item[$i];
    $upper_item =~ tr/a-z/A-Z/;

    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    if (strcmp(\"%-s\", KeyName) == 0){\n", $key[$i]);
            printf("        get_keyvalue(buf);\n");
            printf("        strncpy(%-s_%-s.%-s, %-s, sizeof %-s_%-s.%-s);\n",
                   $rec[$i], $key[$i], $item[$i], "KeyValue",
                   $rec[$i], $key[$i], $item[$i]);
        }else{
            if ($key[$i] eq $old_key){
                printf("        get_keyvalue(buf);\n");
                printf("        strncpy(%-s_%-s.%-s, %-s, sizeof %-s_%-s.%-s);\n",
                       $rec[$i], $key[$i], $item[$i], "KeyValue",
                       $rec[$i], $key[$i], $item[$i]);
            }else{
                $upper_old_key = $old_key;
                $upper_old_key =~ tr/a-z/A-Z/;
                printf("        key_id = %-s_%-s;\n", $upper_rec, $upper_old_key);
                printf("        p_key = &%-s_%-s;\n", $rec[$i], $old_key);

                $old_key = $key[$i];
                printf("    }else if (strcmp(\"%-s\", KeyName) == 0){\n", $key[$i]);
                printf("        get_keyvalue(buf);\n");
                printf("        strncpy(%-s_%-s.%-s, %-s, sizeof %-s_%-s.%-s);\n",
                       $rec[$i], $key[$i], $item[$i], "KeyValue",
                       $rec[$i], $key[$i], $item[$i]);
            }
        }
    }
}
$upper_old_key = $old_key;
$upper_old_key =~ tr/a-z/A-Z/;
printf("        key_id = %-s_%-s;\n", $upper_rec, $upper_old_key);
printf("        p_key = &%-s_%-s;\n", $rec[0], $old_key);

@src = <<__EOF__;
    }else{
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "UNKNOWN KEY");
        return -1;
    }

    sts = d_keyfind(key_id, p_key);
    if (strcmp("==", Condition) == 0 ||
        strcmp("=" , Condition) == 0 ||
        strcmp("EQ", Condition) == 0 ||
        strcmp("eq", Condition) == 0){
    }else if (strcmp(">" , Condition) == 0 ||
              strcmp("GT", Condition) == 0 ||
              strcmp("gt", Condition) == 0){
        sts = d_keynext(key_id);
    }else if (strcmp(">=", Condition) == 0 ||
              strcmp("=>", Condition) == 0 ||
              strcmp("GE", Condition) == 0 ||
              strcmp("ge", Condition) == 0){
        if (sts == S_NOTFOUND){
            sts = d_keynext(key_id);
        }
    }else{
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "UNKNOWN CONDITION");
        return -1;
    }

/*
 * read current record
 */
    if (sts == S_OKAY){
__EOF__
print @src;

printf("        sts = d_recread(&%-s);\n", $rec[0]);

@src = <<__EOF__;
    }

    switch (sts){
    case S_OKAY:
        sprintf(Out_buf, "%-s\\t%-s", "OK", "FOUND");
__EOF__
print @src;

for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] eq ""){
        if ($key[$i + 1] ne ""){
            printf("        sprintf(Out_buf, \"%-s\\t%-s=%-s\\n\", Out_buf, \"%-s\", %-s.%-s);\n", 
                   "%-s", "%-s", "%-s", $item[$i], $rec[$i], $item[$i]);
        }else{
            printf("        sprintf(Out_buf, \"%-s\\t%-s=%-s\", Out_buf, \"%-s\", %-s.%-s);\n", 
                   "%-s", "%-s", "%-s", $item[$i], $rec[$i], $item[$i]);
        }
    }
}

@src = <<__EOF__;
        break;
    case S_NOTFOUND:
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "NOTFOUND");
        break;
    default:
        sprintf(Out_buf, "%-s\\tSTATUS=%-d\\n", "NG", db_status);
        break;
    }

    return 0;
}

__EOF__
print @src;

printf("int %-s_put(buf)\n", $rec[0]);
printf("    char *buf;\n");
printf("{\n");
printf("    int  sts, key_id;\n");
printf("    void *p_key;\n");
printf("    struct %-s       %-s;\n", $rec[0], $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    struct %-s_%-s  %-s_%-s;\n", 
                   $rec[$i], $key[$i], $rec[$i], $key[$i]);
        }else{
            if ($key[$i] ne $old_key){
                $old_key = $key[$i];
                printf("    struct %-s_%-s  %-s_%-s;\n",
                       $rec[$i], $key[$i], $rec[$i], $key[$i]);
            }
        }
    }
}
printf("\n");
printf("    bzero((char *)&%-s, sizeof %-s);\n", $rec[0],  $rec[0]);
printf("    while (get_item_value(buf) == 0){\n");
$old_item = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] eq ""){
        if ($old_item eq ""){
            $old_item = $item[$i];
            printf("        if (strcmp(\"%-s\", ItemName) == 0){\n", $item[$i]);
            printf("            strncpy(%-s.%-s, ItemValue, sizeof %-s.%-s);\n", 
                   $rec[$i], $item[$i], $rec[$i], $item[$i]);
        }else{
            printf("        }else if (strcmp(\"%-s\", ItemName) == 0){\n", $item[$i]);
            printf("            strncpy(%-s.%-s, ItemValue, sizeof %-s.%-s);\n", 
                   $rec[$i], $item[$i], $rec[$i], $item[$i]);
        }
    }
}

@src = <<__EOF__;
        }else{
            sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "UNKNOWN ITEM");
            return -1;
        }
    }

__EOF__
print @src;

printf("    sprintf(Out_buf_rbj, \"delete\\t%-s", $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("\\t%-s", "%-s");
        }else{
            if ($key[$i] eq $old_key){
                printf("\\t%-s", "%-s");
            }
        }
    }
}
printf("\\n\"");

$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf(", %-s.%-s", $rec[$i], $item[$i]);
        }else{
            if ($key[$i] eq $old_key){
                printf(", %-s.%-s", $rec[$i], $item[$i]);
            }
        }
    }
}
printf(");\n");
printf("\n");

$upper_rec = $rec[0];
$upper_rec =~ tr/a-z/A-Z/;
printf("    switch (sts = d_fillnew(%-s, &%-s)){\n", $upper_rec, $rec[0]);

@src = <<__EOF__;
    case S_OKAY:
        if (Rvj_sw == 1){
#if 0
            fprintf(Fp_rvj, "%-s", In_buf_rvj);
#else
            fputs(In_buf_rvj, Fp_rvj);
#endif
        }
        if (Rbj_sw == 1){
#if 0
            fprintf(Fp_rbj, "%-s", Out_buf_rbj);
#else
            fputs(Out_buf_rbj, Fp_rbj);
#endif
        }
        sprintf(Out_buf, "%-s\\t%-s\\n", "OK", "INSERTED");
        break;
    case S_DUPLICATE:
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "DUPLICATE");
        break;
    default:
        sprintf(Out_buf, "%-s\\tSTATUS=%-d\\n", "NG", db_status);
        break;
    }

    return 0;
}

__EOF__
print @src;

printf("int %-s_update(buf)\n", $rec[0]);
printf("    char *buf;\n");
printf("{\n");
printf("    int  sts, key_id;\n");
printf("    void *p_key;\n");
printf("    struct %-s       %-s;\n", $rec[0], $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    struct %-s_%-s  %-s_%-s;\n", 
                   $rec[$i], $key[$i], $rec[$i], $key[$i]);
        }else{
            if ($key[$i] ne $old_key){
                $old_key = $key[$i];
                printf("    struct %-s_%-s  %-s_%-s;\n",
                       $rec[$i], $key[$i], $rec[$i], $key[$i]);
            }
        }
    }
}
printf("\n");
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    get_keyvalue(buf);\n");
            printf("    strncpy(%-s_%-s.%-s, KeyValue, sizeof %-s_%-s.%-s);\n",
                   $rec[$i], $key[$i], $item[$i], $rec[$i], $key[$i], $item[$i]);
        }else{
            if ($key[$i] eq $old_key){
                printf("    get_keyvalue(buf);\n");
                printf("    strncpy(%-s_%-s.%-s, KeyValue, sizeof %-s_%-s.%-s);\n",
                       $rec[$i], $key[$i], $item[$i], $rec[$i], $key[$i], $item[$i]);
            }
        }
    }
}
$upper_rec = $rec[0];
$upper_rec =~ tr/a-z/A-Z/;
$upper_key = $old_key;
$upper_key =~ tr/a-z/A-Z/;
printf("    key_id = %-s_%-s;\n", $upper_rec, $upper_key);
printf("    p_key = &%-s_%-s;\n", $rec[0], $old_key);

printf("\n");
printf("    sprintf(Out_buf_rbj, \"update\\t%-s", $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("\\t%-s", "%-s");
        }else{
            if ($key[$i] eq $old_key){
                printf("\\t%-s", "%-s");
            }
        }
    }
}
printf("\"");
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf(", %-s_%-s.%-s", $rec[$i], $key[$i], $item[$i]);
        }else{
            if ($key[$i] eq $old_key){
                printf(", %-s_%-s.%-s", $rec[$i], $key[$i], $item[$i]);
            }
        }
    }
}
printf(");\n");

@src = <<__EOF__;

/*
 * seek to record
 */
    sts = d_keyfind(key_id, p_key);
/*
 * read current record
 */
    if (sts == S_OKAY){
__EOF__
print @src;

printf("        sts = d_recread(&%-s);\n", $rec[0]);

@src = <<__EOF__;
    }

    switch (sts){
    case S_OKAY:
        while (get_item_value(buf) == 0){
__EOF__
print @src;

$old_item = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] eq ""){
        if ($old_item eq ""){
            $old_item = $item[$i];
            printf("            if (strcmp(\"%-s\", ItemName) == 0){\n", $item[$i]);
            printf("                sprintf(Out_buf_rbj, \"%-s\\t%-s=%-s\", Out_buf_rbj, ItemName, %-s.%-s);\n", "%-s", "%-s", "%-s", $rec[$i], $item[$i]);
            printf("                strncpy(%-s.%-s, ItemValue, sizeof %-s.%-s);\n", $rec[$i], $item[$i], $rec[$i], $item[$i]);
        }else{
            printf("            }else if (strcmp(\"%-s\", ItemName) == 0){\n", $item[$i]);
            printf("                sprintf(Out_buf_rbj, \"%-s\\t%-s=%-s\", Out_buf_rbj, ItemName, %-s.%-s);\n", "%-s", "%-s", "%-s", $rec[$i], $item[$i]);
            printf("                strncpy(%-s.%-s, ItemValue, sizeof %-s.%-s);\n", $rec[$i], $item[$i], $rec[$i], $item[$i]);
        }
    }
}

@src = <<__EOF__;
            }else{
                sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "UNKNOWN ITEM");
                return -1;
            }
        }
        sprintf(Out_buf_rbj, "%-s\\n", Out_buf_rbj);

__EOF__
print @src;

printf("        switch (sts = d_recwrite(&%-s)){\n", $rec[0]);

@src = <<__EOF__;
        case S_OKAY:
            if (Rvj_sw == 1){
#if 0
                fprintf(Fp_rvj, "%-s", In_buf_rvj);
#else
                fputs(In_buf_rvj, Fp_rvj);
#endif
            }
            if (Rbj_sw == 1){
#if 0
                fprintf(Fp_rbj, "%-s", Out_buf_rbj);
#else
                fputs(Out_buf_rbj, Fp_rbj);
#endif
            }
            sprintf(Out_buf, "%-s\\t%-s\\n", "OK", "UPDATED");
            break;
        default:
            sprintf(Out_buf, "%-s\\tSTATUS=%-d\\n", "NG", db_status);
            break;
        }
        break;
    case S_NOTFOUND:
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "NOTFOUND");
        break;
    default:
        sprintf(Out_buf, "%-s\\tSTATUS=%-d\\n", "NG", db_status);
        break;
    }

    return 0;
}

__EOF__
print @src;

printf("int %-s_delete(buf)\n", $rec[0]);
printf("    char *buf;\n");
printf("{\n");
printf("    int  sts, key_id;\n");
printf("    void *p_key;\n");
printf("    struct %-s       %-s;\n", $rec[0], $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    struct %-s_%-s  %-s_%-s;\n", 
                   $rec[$i], $key[$i], $rec[$i], $key[$i]);
        }else{
            if ($key[$i] ne $old_key){
                $old_key = $key[$i];
                printf("    struct %-s_%-s  %-s_%-s;\n",
                       $rec[$i], $key[$i], $rec[$i], $key[$i]);
            }
        }
    }
}
printf("\n");
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    get_keyvalue(buf);\n");
            printf("    strncpy(%-s_%-s.%-s, KeyValue, sizeof %-s_%-s.%-s);\n",
                   $rec[$i], $key[$i], $item[$i], $rec[$i], $key[$i], $item[$i]);
        }else{
            if ($key[$i] eq $old_key){
                printf("    get_keyvalue(buf);\n");
                printf("    strncpy(%-s_%-s.%-s, KeyValue, sizeof %-s_%-s.%-s);\n",
                       $rec[$i], $key[$i], $item[$i], $rec[$i], $key[$i], $item[$i]);
            }
        }
    }
}
$upper_rec = $rec[0];
$upper_rec =~ tr/a-z/A-Z/;
$upper_key = $old_key;
$upper_key =~ tr/a-z/A-Z/;
printf("    key_id = %-s_%-s;\n", $upper_rec, $upper_key);
printf("    p_key = &%-s_%-s;\n", $rec[0], $old_key);

@src = <<__EOF__;

/*
 * seek to record
 */
    sts = d_keyfind(key_id, p_key);
/*
 * read current record
 */
    if (sts == S_OKAY){
__EOF__
print @src;

printf("        sts = d_recread(&%-s);\n", $rec[0]);
printf("        sprintf(Out_buf_rbj, \"put\\t%-s\");\n", $rec[0]);

$old_item = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] eq ""){
        if ($old_item eq ""){
            $old_item = $item[$i];
            printf("        sprintf(Out_buf_rbj, \"%-s\\t%-s=%-s\", Out_buf_rbj, \"%-s\", %-s.%-s);\n", "%-s", "%-s", "%-s", $item[$i], $rec[$i], $item[$i]);
        }else{
            printf("        sprintf(Out_buf_rbj, \"%-s\\t%-s=%-s\", Out_buf_rbj, \"%-s\", %-s.%-s);\n", "%-s", "%-s", "%-s", $item[$i], $rec[$i], $item[$i]);
        }
    }
}
printf("        sprintf(Out_buf_rbj, \"%-s\\n\", Out_buf_rbj);\n", "%-s");

@src = <<__EOF__;
        sts = d_delete();
    }

    switch (sts){
    case S_OKAY:
        if (Rvj_sw == 1){
#if 0
            fprintf(Fp_rvj, "%-s", In_buf_rvj);
#else
            fputs(In_buf_rvj, Fp_rvj);
#endif
        }
        if (Rbj_sw == 1){
#if 0
            fprintf(Fp_rbj, "%-s", Out_buf_rbj);
#else
            fputs(Out_buf_rbj, Fp_rbj);
#endif
        }
        sprintf(Out_buf, "%-s\\t%-s\\n", "OK", "DELETED");
        break;
    case S_NOTFOUND:
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "NOTFOUND");
        break;
    default:
        sprintf(Out_buf, "%-s\\tSTATUS=%-d\\n", "NG", db_status);
        break;
    }

    return 0;
}

__EOF__
print @src;
#
#
#
printf("int %-s_getnext(buf)\n", $rec[0]);
printf("    char *buf;\n");
printf("{\n");
printf("    int  sts, key_id;\n");
printf("    void *p_key;\n");
printf("    struct %-s       %-s;\n", $rec[0], $rec[0]);
$old_key = "";
for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    struct %-s_%-s  %-s_%-s;\n", 
                   $rec[$i], $key[$i], $rec[$i], $key[$i]);
        }else{
            if ($key[$i] ne $old_key){
                $old_key = $key[$i];
                printf("    struct %-s_%-s  %-s_%-s;\n",
                       $rec[$i], $key[$i], $rec[$i], $key[$i]);
            }
        }
    }
}
printf("\n");
printf("    get_key_cond(buf);\n");

$old_key = "";
for ($i = 0; $rec[$i]; $i++){

    $upper_rec = $rec[$i];
    $upper_rec =~ tr/a-z/A-Z/;
    $upper_key = $key[$i];
    $upper_key =~ tr/a-z/A-Z/;
    $upper_item = $item[$i];
    $upper_item =~ tr/a-z/A-Z/;

    if ($key[$i] ne ""){
        if ($old_key eq ""){
            $old_key = $key[$i];
            printf("    if (strcmp(\"%-s\", KeyName) == 0){\n", $key[$i]);
        }else{
            if ($key[$i] eq $old_key){
            }else{
                $upper_old_key = $old_key;
                $upper_old_key =~ tr/a-z/A-Z/;
                printf("        key_id = %-s_%-s;\n", $upper_rec, $upper_old_key);

                $old_key = $key[$i];
                printf("    }else if (strcmp(\"%-s\", KeyName) == 0){\n", $key[$i]);
            }
        }
    }
}
$upper_old_key = $old_key;
$upper_old_key =~ tr/a-z/A-Z/;
printf("        key_id = %-s_%-s;\n", $upper_rec, $upper_old_key);

@src = <<__EOF__;
    }else{
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "UNKNOWN KEY");
        return -1;
    }

    sts = d_keynext(key_id);
/*
 * read current record
 */
    if (sts == S_OKAY){
__EOF__
print @src;

printf("        sts = d_recread(&%-s);\n", $rec[0]);

@src = <<__EOF__;
    }

    switch (sts){
    case S_OKAY:
        sprintf(Out_buf, "%-s\\t%-s", "OK", "FOUND");
__EOF__
print @src;

for ($i = 0; $rec[$i]; $i++){
    if ($key[$i] eq ""){
        if ($key[$i + 1] ne ""){
            printf("        sprintf(Out_buf, \"%-s\\t%-s=%-s\\n\", Out_buf, \"%-s\", %-s.%-s);\n", 
                   "%-s", "%-s", "%-s", $item[$i], $rec[$i], $item[$i]);
        }else{
            printf("        sprintf(Out_buf, \"%-s\\t%-s=%-s\", Out_buf, \"%-s\", %-s.%-s);\n", 
                   "%-s", "%-s", "%-s", $item[$i], $rec[$i], $item[$i]);
        }
    }
}

@src = <<__EOF__;
        break;
    case S_NOTFOUND:
        sprintf(Out_buf, "%-s\\t%-s\\n", "NG", "NOTFOUND");
        break;
    default:
        sprintf(Out_buf, "%-s\\tSTATUS=%-d\\n", "NG", db_status);
        break;
    }

    return 0;
}

__EOF__
print @src;
