use strict;
#
# ��ǽ:�����⡼�ɤǤΥȥ�󥶥�����󳫻�
# ����:socket_handle, user_name, password
# ����:status1, status2
# ��  :($status1, $status2) = ty_start_tran($handle, "user", "hogehoge");
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
# ��ǽ:�����⡼�ɤǤΥȥ�󥶥�����󳫻�(â������Хå����㡼�ʥ����̵��)
# ����:socket_handle, user_name, password
# ����:status1, status2
# ��  :($status1, $status2) = ty_start_tran_nj($handle, "user", "hogehoge");
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
# ��ǽ:���ȥ⡼�ɤǤΥȥ�󥶥�����󳫻�
# ����:socket_handle, user_name, password
# ����:status1, status2
# ��  :($status1, $status2) = ty_start_tranm($handle, "user", "hogehoge");
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
# ��ǽ:�ȥ�󥶥������λ(�ȥ�󥶥������γ���)
# ����:socket_handle
# ����:status1, status2
# ��  :($status1, $status2) = ty_end_tran($handle);
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
# ��ǽ:�ȥ�󥶥������λ(����Хå��¹�)
# ����:socket_handle
# ����:status1, status2
# ��  :($status1, $status2) = ty_abort_tran($handle);
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
# ��ǽ:���ߥåȼ¹�
# ����:socket_handle
# ����:status1, status2
# ��  :($status1, $status2) = ty_commit($handle);
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
# ��ǽ:����Хå��¹�
# ����:socket_handle
# ����:status1, status2
# ��  :($status1, $status2) = ty_rollback($handle);
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
# ��ǽ:�쥳���ɸ���
# ����:socket_handle, table_name, key_name, condition, arrayref_to_key_value
# ����:status1, status2, hash_record
# ��  :($status1, $status2, %rec) = ty_get($handle, "table", "pkey", "eq", ["Masahiko", "Ito"]);
#
#    o condition �˵������Τ� "==", "eq", "EQ", ">", "gt", "GT", ">=", "=>", "ge", "GE"
#
#    o arrayref_to_key_value �λ�����1
#      $ref_key = ["Masahiko", "Ito"];
#    o arrayref_to_key_value �λ�����2
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
# ��ǽ:���쥳���ɸ���
# ����:socket_handle, table_name, key_name
# ����:status1, status2, hash_record
# ��  :($status1, $status2, %rec) = ty_getnext($handle, "table", "pkey");
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
# ��ǽ:�쥳��������
# ����:socket_handle, table_name, hashref_to_record
# ����:status1, status2
# ��  :($status1, $status2) = ty_put($handle, "table", ["first_name", "Ito", "last_name", "Masahiko"]);
#
#    o hashref_to_record �λ�����1
#      $ref_record = ["first_name", "Ito", "last_name", "Masahiko"];
#    o hashref_to_record �λ�����2
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
# ��ǽ:�쥳���ɹ���
# ����:socket_handle, table_name, arrayref_to_pkey_value hashref_to_record
# ����:status1, status2
# ��  :($status1, $status2) = ty_update($handle, "table", ["Masahiko", "Ito"], ["salary", "1000000"]);
#
#    o arrayref_to_pkey_value �λ�����1
#      $ref_key = ["Masahiko", "Ito"];
#    o arrayref_to_pkey_value �λ�����2
#      @name = ("Masahiko", "Ito");
#      $ref_key = \@name;
#
#    o hashref_to_record �λ�����1
#      $ref_record = ["salary", "1000000"];
#    o hashref_to_record �λ�����2
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
# ��ǽ:�쥳���ɺ��
# ����:socket_handle, table_name, arrayref_to_pkey_value
# ����:status1, status2
# ��  :($status1, $status2) = ty_delete($handle, "table", ["Masahiko", "Ito"]);
#
#    o arrayref_to_pkey_value �λ�����1
#      $ref_key = ["Masahiko", "Ito"];
#    o arrayref_to_pkey_value �λ�����2
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

1;
