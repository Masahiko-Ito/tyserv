#! /usr/bin/perl
use strict;
use IO::Socket;
require 'tyserv.pl';
my ($host, $port, $handle, $sts1, $sts2, @key, %rec);
my ($user, $passwd);
#
$user = "manager";
$passwd = "manager";
#
if (@ARGV != 2){
    printf("usage: $0 host port\n");
    exit 1;
}
($host, $port) = @ARGV;
#
# create a tcp connection to the specified host and port
#
$handle = IO::Socket::INET->new(Proto     => "tcp",
                                PeerAddr  => $host,
                                PeerPort  => $port);
if ($handle == 0){
    printf("can't connect to port $port on $host: $! \n");
    exit 1;
}
$handle->autoflush(1);              # so output gets there right away
print "\n[Connected to $host:$port]\n";
#
# start transaction
#
print "\n[START TRANSACTION]\n";

($sts1, $sts2) = &ty_start_tran($handle, $user, $passwd);
printf("start_tran %-2.2s, %-s\n", $sts1, $sts2);
#
# delete all record
#
($sts1, $sts2) = &ty_delete($handle, "smp1", ["0001"]);
($sts1, $sts2) = &ty_delete($handle, "smp1", ["0002"]);
($sts1, $sts2) = &ty_delete($handle, "smp1", ["0003"]);
($sts1, $sts2) = &ty_delete($handle, "smp1", ["0004"]);
($sts1, $sts2) = &ty_delete($handle, "smp1", ["0005"]);
#
# insert record
#
print "\n[START INSERT]\n";

%rec = ();
$rec{id} = "0001";
$rec{name} = "Masao Sato";
$rec{salary} = "0500000";
($sts1, $sts2) = &ty_put($handle, "smp1", \%rec);
printf("insert %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0002";
$rec{name} = "Katsumi Kinoshita";
$rec{salary} = "0490000";
($sts1, $sts2) = &ty_put($handle, "smp1", \%rec);
printf("insert %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0003";
$rec{name} = "Kiyoshi Sakamoto";
$rec{salary} = "0510000";
($sts1, $sts2) = &ty_put($handle, "smp1", \%rec);
printf("insert %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0004";
$rec{name} = "Masaharu Sawada";
$rec{salary} = "0470000";
($sts1, $sts2) = &ty_put($handle, "smp1", \%rec);
printf("insert %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0005";
$rec{name} = "Masahiko Ito";
$rec{salary} = "0300000";
($sts1, $sts2) = &ty_put($handle, "smp1", \%rec);
printf("insert %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
# get record (check inserted)
#
print "\n[CHECK INSERTED RECORD]\n";

%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0001"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
# commit transaction
#
print "\n[START COMMIT]\n";

($sts1, $sts2) = &ty_commit($handle);
printf("commit %-2.2s, %-s\n", $sts1, $sts2);
#
# update record
#
print "\n[START UPDATE]\n";

%rec = ();
$rec{id} = "0001";
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", [$rec{id}]);
$rec{salary} *= 10;
($sts1, $sts2) = &ty_update($handle, "smp1", [$rec{id}], \%rec);
printf("update %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0002";
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", [$rec{id}]);
$rec{salary} *= 10;
($sts1, $sts2) = &ty_update($handle, "smp1", [$rec{id}], \%rec);
printf("update %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0003";
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", [$rec{id}]);
$rec{salary} *= 10;
($sts1, $sts2) = &ty_update($handle, "smp1", [$rec{id}], \%rec);
printf("update %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0004";
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", [$rec{id}]);
$rec{salary} *= 10;
($sts1, $sts2) = &ty_update($handle, "smp1", [$rec{id}], \%rec);
printf("update %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
%rec = ();
$rec{id} = "0005";
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", [$rec{id}]);
$rec{salary} *= 10;
($sts1, $sts2) = &ty_update($handle, "smp1", [$rec{id}], \%rec);
printf("update %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, $rec{id});
#
# get record (check updated)
#
print "\n[CHECK UPDATED RECORD]\n";

%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0001"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
# rollback transaction
#
print "\n[START ROLLBACK]\n";

($sts1, $sts2) = &ty_rollback($handle);
printf("rollback %-2.2s, %-s\n", $sts1, $sts2);
#
# get record (check rollback)
#
print "\n[CHECK ROLLBACKED TO COMMITED POINT]\n";

%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0001"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_getnext($handle, "smp1", "pkey");
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
# delete record
#
print "\n[START DELETE]\n";

($sts1, $sts2) = &ty_delete($handle, "smp1", ["0002"]);
printf("delete %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, "0002");
#
($sts1, $sts2) = &ty_delete($handle, "smp1", ["0004"]);
printf("delete %-2.2s, %-s, id=%-4.4s\n", $sts1, $sts2, "0004");
#
# get record (check deleted)
#
print "\n[CHECK DELETED RECORD]\n";

%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0001"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0002"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0003"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0004"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0005"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
#
# abort transaction
#
print "\n[ABORT TRANSACTION]\n";

($sts1, $sts2) = &ty_abort_tran($handle);
printf("abort_tran %-2.2s, %-s\n", $sts1, $sts2);
#
# create a tcp connection to the specified host and port
#
print "\n[RE CONNECT SERVER]\n";

$handle = IO::Socket::INET->new(Proto     => "tcp",
                                PeerAddr  => $host,
                                PeerPort  => $port);
if ($handle == 0){
    printf("can't connect to port $port on $host: $! \n");
    exit 1;
}
$handle->autoflush(1);              # so output gets there right away
print "\n[Connected to $host:$port]\n";
#
# start transaction
#
print "\n[START TRANSACTION]\n";

($sts1, $sts2) = &ty_start_tran($handle, $user, $passwd);
printf("start_tran %-2.2s, %-s\n", $sts1, $sts2);
#
# get record (check aborted)
#
print "\n[CHECK ABORTED(ROLLBACKED TO COMMITED POINT) TRANSACTION]\n";

%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0001"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0002"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0003"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0004"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
%rec = ();
($sts1, $sts2, %rec) = &ty_get($handle, "smp1", "pkey", "eq", ["0005"]);
printf("|%-2.2s|%-4.4s|%-20.20s|%7d|\n", $sts1, $rec{id}, $rec{name}, $rec{salary});
#
# end transaction
#
print "\n[END TRANSACTION]\n";

($sts1, $sts2) = &ty_end_tran($handle);
printf("end_tran %-2.2s, %-s\n", $sts1, $sts2);

