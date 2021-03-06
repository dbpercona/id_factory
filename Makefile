MYSQLOPTS=-uroot -ppassword test

id_factory.sql:  id_factory.cpp.sql
	cpp -E -P -C -nostdinc id_factory.cpp.sql -o id_factory.sql

test_install: id_factory.sql
	mysql $(MYSQLOPTS) -e 'drop table if exists id_factory' 2> /dev/null
	mysql $(MYSQLOPTS) -e 'drop function if exists id_factory_next' 2> /dev/null
	-mysql $(MYSQLOPTS) < id_factory.sql 2> /tmp/id_factory_make.err
	! grep -Ev '^Warning' /tmp/id_factory_make.err
	rm -f /tmp/id_factory_make.err


test_basic: test_install
	- mysql $(MYSQLOPTS) -e "select id_factory_next(''); select id_factory_next(''); select id_factory_next('')" 2> /tmp/id_factory_make.err
	! grep -Ev '^Warning' /tmp/id_factory_make.err
	rm -f /tmp/id_factory_make.err


