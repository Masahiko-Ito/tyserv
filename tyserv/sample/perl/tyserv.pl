use strict;
#
# 機能:更新モードでのトランザクション開始
# 引数:socket_handle, user_name, password
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_start_tran($handle, "user", "hogehoge");
#
sub ty_start_tran(){
    my ($handle, $user, $passwd) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "start_tran\t$user\t$passwd\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:更新モードでのトランザクション開始(但しロールバックジャーナル取得無し)
# 引数:socket_handle, user_name, password
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_start_tran_nj($handle, "user", "hogehoge");
#
sub ty_start_tran_nj(){
    my ($handle, $user, $passwd) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "start_tran_nj\t$user\t$passwd\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:参照モードでのトランザクション開始
# 引数:socket_handle, user_name, password
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_start_tranm($handle, "user", "hogehoge");
#
sub ty_start_tranm(){
    my ($handle, $user, $passwd) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "start_tranm\t$user\t$passwd\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:トランザクション終了(トランザクションの確定)
# 引数:socket_handle
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_end_tran($handle);
#
sub ty_end_tran(){
    my ($handle) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "end_tran\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:トランザクション終了(ロールバック実行)
# 引数:socket_handle
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_abort_tran($handle);
#
sub ty_abort_tran(){
    my ($handle) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "abort_tran\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:コミット実行
# 引数:socket_handle
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_commit($handle);
#
sub ty_commit(){
    my ($handle) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "commit\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:ロールバック実行
# 引数:socket_handle
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_rollback($handle);
#
sub ty_rollback(){
    my ($handle) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "rollback\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:レコード検索
# 引数:socket_handle, table_name, key_name, condition, arrayref_to_key_value
# 戻値:status1, status2, hash_record
# 例  :($status1, $status2, %rec) = ty_get($handle, "table", "pkey", "eq", ["Masahiko", "Ito"]);
#
#    o condition に許されるのは "==", "eq", "EQ", ">", "gt", "GT", ">=", "=>", "ge", "GE"
#
#    o arrayref_to_key_value の指定例1
#      $ref_key = ["Masahiko", "Ito"];
#    o arrayref_to_key_value の指定例2
#      @name = ("Masahiko", "Ito");
#      $ref_key = \@name;
#
sub ty_get(){
    my ($handle, $table, $key, $cond, $ref_key) = @_;
    my ($response, $sts1, $sts2, $data);
    my ($i, %record, @keyvarpair, $rkey, $rval);

    printf($handle "get\t%-s\t%-s\t%-s", $table, $key, $cond);
    foreach $i (@{$ref_key}){
        printf($handle "\t%-s", $i);
    }
    printf($handle "\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2, $data) = split(/\t/, $response, 3);
    @keyvarpair = split(/\t/, $data);
    foreach $i (@keyvarpair){
        ($rkey, $rval) = split(/=/, $i, 2);
        $record{$rkey} = $rval;
    }
    
    return ($sts1, $sts2, %record);
}
#
# 機能:次レコード検索
# 引数:socket_handle, table_name, key_name
# 戻値:status1, status2, hash_record
# 例  :($status1, $status2, %rec) = ty_getnext($handle, "table", "pkey");
#
sub ty_getnext(){
    my ($handle, $table, $key) = @_;
    my ($response, $sts1, $sts2, $data);
    my ($i, %record, @keyvarpair, $rkey, $rval);

    printf($handle "getnext\t%-s\t%-s\n", $table, $key);
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2, $data) = split(/\t/, $response, 3);
    @keyvarpair = split(/\t/, $data);
    foreach $i (@keyvarpair){
        ($rkey, $rval) = split(/=/, $i, 2);
        $record{$rkey} = $rval;
    }
    
    return ($sts1, $sts2, %record);
}
#
# 機能:レコード挿入
# 引数:socket_handle, table_name, hashref_to_record
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_put($handle, "table", ["first_name", "Ito", "last_name", "Masahiko"]);
#
#    o hashref_to_record の指定例1
#      $ref_record = ["first_name", "Ito", "last_name", "Masahiko"];
#    o hashref_to_record の指定例2
#      $rec{first_name} = "Ito";
#      $rec{last_name} = "Masahiko";
#      $ref_record = \%rec;
#
sub ty_put(){
    my ($handle, $table, $ref_record) = @_;
    my ($response, $sts1, $sts2);
    my ($i);

    printf($handle "put\t%-s", $table);
    foreach $i (keys(%{$ref_record})){
        printf($handle "\t%-s=%-s", $i, ${$ref_record}{$i});
    }
    printf($handle "\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:レコード更新
# 引数:socket_handle, table_name, arrayref_to_pkey_value hashref_to_record
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_update($handle, "table", ["Masahiko", "Ito"], ["salary", "1000000"]);
#
#    o arrayref_to_pkey_value の指定例1
#      $ref_key = ["Masahiko", "Ito"];
#    o arrayref_to_pkey_value の指定例2
#      @name = ("Masahiko", "Ito");
#      $ref_key = \@name;
#
#    o hashref_to_record の指定例1
#      $ref_record = ["salary", "1000000"];
#    o hashref_to_record の指定例2
#      $rec{salary} = "1000000";
#      $ref_record = \%rec;
#
sub ty_update(){
    my ($handle, $table, $ref_pkey, $ref_record) = @_;
    my ($response, $sts1, $sts2);
    my ($i);

    printf($handle "update\t%-s", $table);
    foreach $i (@{$ref_pkey}){
        printf($handle "\t%-s", $i);
    }
    foreach $i (keys(%{$ref_record})){
        printf($handle "\t%-s=%-s", $i, ${$ref_record}{$i});
    }
    printf($handle "\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:レコード削除
# 引数:socket_handle, table_name, arrayref_to_pkey_value
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_delete($handle, "table", ["Masahiko", "Ito"]);
#
#    o arrayref_to_pkey_value の指定例1
#      $ref_key = ["Masahiko", "Ito"];
#    o arrayref_to_pkey_value の指定例2
#      @name = ("Masahiko", "Ito");
#      $ref_key = \@name;
#
sub ty_delete(){
    my ($handle, $table, $ref_pkey) = @_;
    my ($response, $sts1, $sts2);
    my ($i);

    printf($handle "delete\t%-s", $table);
    foreach $i (@{$ref_pkey}){
        printf($handle "\t%-s", $i);
    }
    printf($handle "\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:シャットダウン
# 引数:socket_handle, user_name, password
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_shutdown($handle, "user", "hogehoge");
#
sub ty_shutdown(){
    my ($handle, $user, $passwd) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "shutdown\t$user\t$passwd\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#
# 機能:リカバリジャーナルスワップ
# 引数:socket_handle, user_name, password
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_swaprvj($handle, "user", "hogehoge");
#
sub ty_swaprvj(){
    my ($handle, $user, $passwd) = @_;
    my ($response, $sts1, $sts2);

    printf($handle "swaprvj\t$user\t$passwd\n");
    $response = <$handle>;
    chop $response;
    ($sts1, $sts2) = split(/\t/, $response, 2);
    
    return ($sts1, $sts2);
}
#----------------------------------------------------------------------
#
# 機能:複数トランザクションの一括開始
# 引数:port, socket_handle, user_name, password, mode, ...
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_start_trans($port1, $handle1, "user1", "hogehoge1", ""
#                                            $port2, $handle2, "user2", "hogehoge2", "");
# mode : start_tran   に対応 : "",   "update",   "io",    "w",   "a",   "read_write"
#        start_tran_njに対応 : "nj", "updatenj", "ionj",  "wnj", "anj", "read_writenj"
#        start_tranm  に対応 : "m",  "read",     "input", "r",   "r",   "read_only"
#
sub ty_start_trans(){
    my (@parm) = @_;
    my ($port, %handle, %user, %passwd, %mode);
    my ($response, $sts1, $sts2, $i, $handle_tmp);

    $i = 0;
    while ($parm[$i] ne ""){
        $handle{$parm[$i]} = $parm[$i + 1];
        $user{$parm[$i]} = $parm[$i + 2];
        $passwd{$parm[$i]} = $parm[$i + 3];
        $mode{$parm[$i]} = $parm[$i + 4];
        $i += 5;
    }

    foreach $port (sort keys %handle){
        $handle_tmp = $handle{$port};
        if ($mode{$port} eq "" ||
            $mode{$port} eq "update" || $mode{$port} eq "UPDATE" ||
            $mode{$port} eq "io" || $mode{$port} eq "IO" ||
            $mode{$port} eq "w" || $mode{$port} eq "W" ||
            $mode{$port} eq "a" || $mode{$port} eq "A" ||
            $mode{$port} eq "read_write" || $mode{$port} eq "READ_WRITE"){
            printf($handle_tmp "start_tran\t$user{$port}\t$passwd{$port}\n");
        }elsif ($mode{$port} eq "nj" || $mode{$port} eq "NJ" ||
                $mode{$port} eq "updatenj" || $mode{$port} eq "UPDATENJ" ||
                $mode{$port} eq "ionj" || $mode{$port} eq "IONJ" ||
                $mode{$port} eq "wnj" || $mode{$port} eq "WNJ" ||
                $mode{$port} eq "anj" || $mode{$port} eq "ANJ" ||
                $mode{$port} eq "read_writenj" || $mode{$port} eq "READ_WRITENJ"){
            printf($handle_tmp "start_tran_nj\t$user{$port}\t$passwd{$port}\n");
        }elsif ($mode{$port} eq "m" || $mode{$port} eq "M" ||
                $mode{$port} eq "read" || $mode{$port} eq "READ" ||
                $mode{$port} eq "input" || $mode{$port} eq "INPUT" ||
                $mode{$port} eq "r" || $mode{$port} eq "R" ||
                $mode{$port} eq "r" || $mode{$port} eq "R" ||
                $mode{$port} eq "read_only" || $mode{$port} eq "READ_ONLY"){
            printf($handle_tmp "start_tranm\t$user{$port}\t$passwd{$port}\n");
        }else{
            ($sts1, $sts2) = ("NG", "UNKNOWN TRANSACTION MODE($mode{$port})");
            return ($sts1, $sts2);
        }
        $response = <$handle_tmp>;
        chop $response;
        ($sts1, $sts2) = split(/\t/, $response, 2);
        if ($sts1 eq "NG"){
            return ($sts1, $sts2);
        }
    }
    
    return ($sts1, $sts2);
}
#
# 機能:複数トランザクション一括終了(トランザクションの確定)
# 引数:port, socket_handle, user_name, password, mode, ...
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_end_trans($port1, $handle1, "user1", "hogehoge1", ""
#                                          $port2, $handle2, "user2", "hogehoge2", "");
#
sub ty_end_trans(){
    my (@parm) = @_;
    my ($port, %handle, %user, %passwd, %mode);
    my ($response, $sts1, $sts2, $i, $handle_tmp);

    $i = 0;
    while ($parm[$i] ne ""){
        $handle{$parm[$i]} = $parm[$i + 1];
        $user{$parm[$i]} = $parm[$i + 2];
        $passwd{$parm[$i]} = $parm[$i + 3];
        $mode{$parm[$i]} = $parm[$i + 4];
        $i += 5;
    }

    foreach $port (sort keys %handle){
        $handle_tmp = $handle{$port};
        printf($handle_tmp "end_tran\n");
        $response = <$handle_tmp>;
        chop $response;
        ($sts1, $sts2) = split(/\t/, $response, 2);
        if ($sts1 eq "NG"){
            return ($sts1, $sts2);
        }
    }

    return ($sts1, $sts2);
}
#
# 機能:複数トランザクション一括終了(ロールバック実行)
# 引数:port, socket_handle, user_name, password, mode, ...
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_abort_trans($port1, $handle1, "user1", "hogehoge1", ""
#                                            $port2, $handle2, "user2", "hogehoge2", "");
#
sub ty_abort_trans(){
    my (@parm) = @_;
    my ($port, %handle, %user, %passwd, %mode);
    my ($response, $sts1, $sts2, $i, $handle_tmp);

    $i = 0;
    while ($parm[$i] ne ""){
        $handle{$parm[$i]} = $parm[$i + 1];
        $user{$parm[$i]} = $parm[$i + 2];
        $passwd{$parm[$i]} = $parm[$i + 3];
        $mode{$parm[$i]} = $parm[$i + 4];
        $i += 5;
    }

    foreach $port (sort keys %handle){
        $handle_tmp = $handle{$port};
        printf($handle_tmp "abort_tran\n");
        $response = <$handle_tmp>;
        chop $response;
        ($sts1, $sts2) = split(/\t/, $response, 2);
        if ($sts1 eq "NG"){
            return ($sts1, $sts2);
        }
    }

    return ($sts1, $sts2);
}
#
# 機能:複数コミット一括実行
# 引数:port, socket_handle, user_name, password, mode, ...
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_commits($port1, $handle1, "user1", "hogehoge1", ""
#                                        $port2, $handle2, "user2", "hogehoge2", "");
#
sub ty_commits(){
    my (@parm) = @_;
    my ($port, %handle, %user, %passwd, %mode);
    my ($response, $sts1, $sts2, $i, $handle_tmp);

    $i = 0;
    while ($parm[$i] ne ""){
        $handle{$parm[$i]} = $parm[$i + 1];
        $user{$parm[$i]} = $parm[$i + 2];
        $passwd{$parm[$i]} = $parm[$i + 3];
        $mode{$parm[$i]} = $parm[$i + 4];
        $i += 5;
    }

    foreach $port (sort keys %handle){
        $handle_tmp = $handle{$port};
        printf($handle_tmp "commit\n");
        $response = <$handle_tmp>;
        chop $response;
        ($sts1, $sts2) = split(/\t/, $response, 2);
        if ($sts1 eq "NG"){
            return ($sts1, $sts2);
        }
    }

    return ($sts1, $sts2);
}
#
# 機能:複数ロールバック一括実行
# 引数:port, socket_handle, user_name, password, mode, ...
# 戻値:status1, status2
# 例  :($status1, $status2) = ty_rollbacks($port1, $handle1, "user1", "hogehoge1", ""
#                                          $port2, $handle2, "user2", "hogehoge2", "");
#
sub ty_rollbacks(){
    my (@parm) = @_;
    my ($port, %handle, %user, %passwd, %mode);
    my ($response, $sts1, $sts2, $i, $handle_tmp);

    $i = 0;
    while ($parm[$i] ne ""){
        $handle{$parm[$i]} = $parm[$i + 1];
        $user{$parm[$i]} = $parm[$i + 2];
        $passwd{$parm[$i]} = $parm[$i + 3];
        $mode{$parm[$i]} = $parm[$i + 4];
        $i += 5;
    }

    foreach $port (sort keys %handle){
        $handle_tmp = $handle{$port};
        printf($handle_tmp "rollback\n");
        $response = <$handle_tmp>;
        chop $response;
        ($sts1, $sts2) = split(/\t/, $response, 2);
        if ($sts1 eq "NG"){
            return ($sts1, $sts2);
        }
    }

    return ($sts1, $sts2);
}
#----------------------------------------------------------------------

1;
