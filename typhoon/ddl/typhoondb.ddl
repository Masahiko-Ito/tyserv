database typhoondb {

    data file "smp1.dat"   contains smp1;
    key  file "smp1.pk"    contains smp1.smp1_pkey;
    key  file "smp1.s1"    contains smp1.smp1_skey1;

    record smp1 {
        char id[4 + 1];
        char name[20 + 1];
        char salary[7 + 1];

        primary   key smp1_pkey  { id asc };
        alternate key smp1_skey1 { name asc, id asc };
    }

    data file "smp2.dat"   contains smp2;
    key  file "smp2.pk"    contains smp2.smp2_pkey;
    key  file "smp2.s1"    contains smp2.smp2_skey1;

    record smp2 {
        char id[4 + 1];
        char name[20 + 1];
        char salary[7 + 1];

        primary   key smp2_pkey  { id asc };
        alternate key smp2_skey1 { name asc, id asc };
    }

}
