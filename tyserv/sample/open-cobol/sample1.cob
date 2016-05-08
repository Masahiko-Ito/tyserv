      *
      * ����ץ�ơ��֥�(smp1)��ȥ�󥶥������ǡ���
      * �ΰ�ư��ʬ�˱����ƹ�����ɽ������ץ����Ǥ�
      *
      * �ȥ�󥶥������ǡ����ϸ���Ĺ��CSV�����Ǥ�
      *
       IDENTIFICATION   DIVISION.
       PROGRAM-ID.      sample1.
       ENVIRONMENT      DIVISION.
       CONFIGURATION    SECTION.
       INPUT-OUTPUT     SECTION.
       FILE-CONTROL.
      *------------------------------------------
      * �ȥ�󥶥������ǡ���
      *------------------------------------------
          SELECT TRANDAT ASSIGN TO "smp1_tran.dat"
             ORGANIZATION LINE SEQUENTIAL.
       DATA             DIVISION.
       FILE             SECTION.
      *------------------------------------------
      * �ȥ�󥶥������ǡ���
      *------------------------------------------
       FD  TRANDAT.
       01  TRC.
      * I:���� D:��� U:���� G:����(ɽ��)
      * R:ROLLBACK C:COMMIT M:��å�����
          02 IDO-KUBUN  PIC X(1).
          02 FILLER     PIC X(1).
          02 ID-PK      PIC X(4).
          02 FILLER     PIC X(1).
          02 NAME       PIC X(20).
          02 FILLER     PIC X(1).
          02 SALARY     PIC 9(7).
       01  TRC2.
      * I:���� D:��� U:���� G:����(ɽ��)
      * R:ROLLBACK C:COMMIT M:��å�����
          02 FILLER     PIC X(1).
          02 MESG       PIC X(34).
      *------------------------------------------
      * ����ΰ����
      *------------------------------------------
       WORKING-STORAGE  SECTION.
      *------------------------------------------
      * ������
      *------------------------------------------
       01 C-PGMNAME     PIC X(7) VALUE 'sample1'.
       01 C-NULL        PIC X(1) VALUE LOW-VALUE.
       01 C-TAB         PIC X(1) VALUE X'09'.
      *------------------------------------------
      * ������
      *------------------------------------------
       01 END-SW        PIC X(3) VALUE 'OFF'.
      *
      * sock_* �ط����󥿡��ե���������
      *
       01 HOST.
          02 FILLER     PIC X(9) VALUE 'localhost'.
          02 FILLER     PIC X(1) VALUE LOW-VALUE.
       01 PORT.
          02 FILLER     PIC X(5) VALUE '20000'.
          02 FILLER     PIC X(1) VALUE LOW-VALUE.
      *01 FD-SOCK       PIC S9(10) BINARY VALUE ZERO.
       01 FD-SOCK.
          02 FILLER     PIC X(5) VALUE SPACE.
          02 FILLER     PIC X(1) VALUE LOW-VALUE.
       01 SEND-DATA.
          02 FILLER     PIC X(1024) VALUE SPACE.
          02 FILLER     PIC X(1) VALUE LOW-VALUE.
       01 RECV-DATA.
          02 FILLER     PIC X(1024) VALUE SPACE.
          02 FILLER     PIC X(1) VALUE LOW-VALUE.
      *
      * get_* �ط����󥿡��ե���������
      *
       01 STAT1         PIC X(2) VALUE SPACE.
       01 STAT2         PIC X(1024) VALUE SPACE.
       01 G-ID-PK       PIC X(4).
       01 G-NAME        PIC X(20).
       01 G-SALARY      PIC 9(7).
      *------------------------------------------
      * ��������
      *------------------------------------------
       PROCEDURE        DIVISION.
      *
       MAIN-EN.
      *------------------------------------------
      * �����ץ����
      *------------------------------------------
         PERFORM SUB-OPEN-EN THRU SUB-OPEN-EX.
      *------------------------------------------
      * ���������
      *------------------------------------------
         PERFORM SUB-INIT-EN THRU SUB-INIT-EX.
      *------------------------------------------
      * �����
      *------------------------------------------
         PERFORM SUB-MAIN-EN THRU SUB-MAIN-EX
            UNTIL (END-SW = 'ON').
      *------------------------------------------
      * ��λ����
      *------------------------------------------
         PERFORM SUB-END-EN THRU SUB-END-EX.
      *------------------------------------------
      * ����������
      *------------------------------------------
         PERFORM SUB-CLOSE-EN THRU SUB-CLOSE-EX.
       MAIN-EX.
         STOP RUN.
      *------------------------------------------
      * ������λ
      *------------------------------------------
      *
      *
      *
      *------------------------------------------
      * �����ץ����
      *------------------------------------------
       SUB-OPEN-EN.
      *
      * �����åȥ����ץ�
      *
         CALL 'sock_open' USING HOST PORT FD-SOCK.
      *
      * �ȥ�󥶥������ǡ���
      *
         OPEN    INPUT    TRANDAT.
       SUB-OPEN-EX.
         EXIT.
      *------------------------------------------
      * ���������
      *------------------------------------------
       SUB-INIT-EN.
         DISPLAY C-PGMNAME
                 ' : START'.
      *
      * �����⡼�ɥȥ�󥶥�����󳫻�
      *
         INITIALIZE SEND-DATA RECV-DATA.
         STRING 'start_tran' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'user' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'user' DELIMITED BY SIZE
                C-NULL DELIMITED BY SIZE
                INTO SEND-DATA.
         CALL 'sock_send_recv' USING FD-SOCK SEND-DATA RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : ABEND ' STAT1 ' ' STAT2
            PERFORM SUB-ABEND-EN THRU SUB-ABEND-EX
         END-IF.
      *
      * �ȥ�󥶥�������ɤ߹���
      *
         PERFORM SUB-RDTRAN-EN THRU SUB-RDTRAN-EX.
       SUB-INIT-EX.
         EXIT.
      *------------------------------------------
      * �����
      *------------------------------------------
       SUB-MAIN-EN.
      *
         EVALUATE TRUE
         WHEN (IDO-KUBUN = 'I')
      * I:����
            PERFORM SUB-INSERT-EN THRU SUB-INSERT-EX
         WHEN (IDO-KUBUN = 'D')
      * D:���
            PERFORM SUB-DELETE-EN THRU SUB-DELETE-EX
         WHEN (IDO-KUBUN = 'U')
      * U:����
            PERFORM SUB-UPDATE-EN THRU SUB-UPDATE-EX
         WHEN (IDO-KUBUN = 'G')
      * G:����(ɽ��)
            PERFORM SUB-GET-EN THRU SUB-GET-EX
         WHEN (IDO-KUBUN = 'R')
      * R:ROLLBACK
            PERFORM SUB-ROLLBACK-EN THRU SUB-ROLLBACK-EX
         WHEN (IDO-KUBUN = 'C')
      * C:COMMIT
            PERFORM SUB-COMMIT-EN THRU SUB-COMMIT-EX
         WHEN (IDO-KUBUN = 'M')
      * M:��å�����
            PERFORM SUB-MESG-EN THRU SUB-MESG-EX
         WHEN (IDO-KUBUN = '#')
      * #:�����ȹ�
            CONTINUE
         WHEN OTHER
            DISPLAY C-PGMNAME
                    ' : TRANSACTION ERROR, SKIPPED=('
                    TRC ')'
         END-EVALUATE.
      *
      * �ȥ�󥶥�������ɤ߹���
      *
         PERFORM SUB-RDTRAN-EN THRU SUB-RDTRAN-EX.
       SUB-MAIN-EX.
         EXIT.
      *------------------------------------------
      * ��λ����
      *------------------------------------------
       SUB-END-EN.
      *
      * �ȥ�󥶥���������ｪλ
      *
         INITIALIZE RECV-DATA.
         CALL 'sock_send_recv' USING FD-SOCK 'end_tran' RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : ABEND ' STAT1 ' ' STAT2
            PERFORM SUB-ABEND-EN THRU SUB-ABEND-EX
         END-IF.
      *
         DISPLAY C-PGMNAME
                 ' : END  '.
       SUB-END-EX.
         EXIT.
      *------------------------------------------
      * ����������
      *------------------------------------------
       SUB-CLOSE-EN.
      *
      * �ȥ�󥶥������ǡ���
      *
         CLOSE   TRANDAT.
      *
      * �����å�
      *
         CALL 'sock_close' USING FD-SOCK.
       SUB-CLOSE-EX.
         EXIT.
      *
      *
      *
      *------------------------------------------
      * �۾ｪλ
      *------------------------------------------
       SUB-ABEND-EN.
          PERFORM SUB-CLOSE-EN THRU SUB-CLOSE-EX.
          STOP RUN.
       SUB-ABEND-EX.
         EXIT.
      *------------------------------------------
      * �ȥ�󥶥�������ɤ߹���
      *------------------------------------------
       SUB-RDTRAN-EN.
          READ TRANDAT AT END
             MOVE 'ON' TO END-SW
          END-READ.
       SUB-RDTRAN-EX.
         EXIT.
      *------------------------------------------
      * I:����
      *------------------------------------------
       SUB-INSERT-EN.
      *
      * ����
      *
         INITIALIZE SEND-DATA RECV-DATA.
         STRING 'put' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'smp1' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'id=' DELIMITED BY SIZE
                ID-PK DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'name=' DELIMITED BY SIZE
                NAME DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'salary=' DELIMITED BY SIZE
                SALARY DELIMITED BY SIZE
                C-NULL DELIMITED BY SIZE
                INTO SEND-DATA.
         CALL 'sock_send_recv' USING FD-SOCK SEND-DATA RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : INSERT ERROR ' STAT1 ' ' STAT2
                    ' ' TRC
         END-IF.
       SUB-INSERT-EX.
         EXIT.
      *------------------------------------------
      * D:���
      *------------------------------------------
       SUB-DELETE-EN.
      *
      * ���
      *
         INITIALIZE SEND-DATA RECV-DATA.
         STRING 'delete' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'smp1' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                ID-PK DELIMITED BY SIZE
                C-NULL DELIMITED BY SIZE
                INTO SEND-DATA.
         CALL 'sock_send_recv' USING FD-SOCK SEND-DATA RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : DELETE ERROR ' STAT1 ' ' STAT2
                    ' ' TRC
         END-IF.
       SUB-DELETE-EX.
         EXIT.
      *------------------------------------------
      * U:����
      *------------------------------------------
       SUB-UPDATE-EN.
      *
      * ����
      *
         INITIALIZE SEND-DATA RECV-DATA.
         STRING 'update' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'smp1' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                ID-PK DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'name=' DELIMITED BY SIZE
                NAME DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'salary=' DELIMITED BY SIZE
                SALARY DELIMITED BY SIZE
                C-NULL DELIMITED BY SIZE
                INTO SEND-DATA.
         CALL 'sock_send_recv' USING FD-SOCK SEND-DATA RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : UPDATE ERROR ' STAT1 ' ' STAT2
                    ' ' TRC
         END-IF.
       SUB-UPDATE-EX.
         EXIT.
      *------------------------------------------
      * G:����(ɽ��)
      *------------------------------------------
       SUB-GET-EN.
      *
      * ����
      *
         INITIALIZE SEND-DATA RECV-DATA.
         STRING 'get' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'smp1' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'pkey' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                'eq' DELIMITED BY SIZE
                C-TAB DELIMITED BY SIZE
                ID-PK DELIMITED BY SIZE
                C-NULL DELIMITED BY SIZE
                INTO SEND-DATA.
         CALL 'sock_send_recv' USING FD-SOCK SEND-DATA RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : GET ERROR ' STAT1 ' ' STAT2
                    ' ' TRC
         ELSE
      *
      * ɽ��
      *
            INITIALIZE G-ID-PK G-NAME G-SALARY
      *
            CALL 'get_value' USING RECV-DATA 'id' G-ID-PK
            CALL 'get_value' USING RECV-DATA 'name' G-NAME
            CALL 'get_value' USING RECV-DATA 'salary' G-SALARY
      *
            DISPLAY C-PGMNAME ' : '
                    'ID=(' G-ID-PK ') '
                    'NAME=(' G-NAME ') '
                    'SALARY=(' G-SALARY ') '
         END-IF.
       SUB-GET-EX.
         EXIT.
      *------------------------------------------
      * R:ROLLBACK
      *------------------------------------------
       SUB-ROLLBACK-EN.
      *
      * ����Хå�
      *
         INITIALIZE RECV-DATA.
         CALL 'sock_send_recv' USING FD-SOCK 'rollback' RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : ROLLBACK ERROR ' STAT1 ' ' STAT2
                    ' ' TRC
         END-IF.
       SUB-ROLLBACK-EX.
         EXIT.
      *------------------------------------------
      * C:COMMIT
      *------------------------------------------
       SUB-COMMIT-EN.
      *
      * ���ߥå�
      *
         INITIALIZE RECV-DATA.
         CALL 'sock_send_recv' USING FD-SOCK 'commit' RECV-DATA.
      *
      * ���ơ����������å�
      *
         INITIALIZE STAT1 STAT2.
         CALL 'get_status' USING RECV-DATA STAT1 STAT2.
         IF (STAT1 = 'NG')
            DISPLAY C-PGMNAME
                    ' : COMMIT ERROR ' STAT1 ' ' STAT2
                    ' ' TRC
         END-IF.
       SUB-COMMIT-EX.
         EXIT.
      *------------------------------------------
      * M:��å�����
      *------------------------------------------
       SUB-MESG-EN.
         DISPLAY C-PGMNAME
                 ' : ' MESG.
       SUB-MESG-EX.
         EXIT.
