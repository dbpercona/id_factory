-- shared id_factory that supports Galera clusters
-- id_factory table
CREATE TABLE `id_factory` (
  namespace CHAR(255) NOT NULL,
  node TINYINT UNSIGNED NOT NULL,
  id BIGINT UNSIGNED NOT NULL,
  node_bits TINYINT NOT NULL,
  PRIMARY KEY (namespace, node)
) ENGINE=InnoDB;
-- id_factory function
delimiter //
CREATE FUNCTION id_factory_next(pnamespace CHAR(255)) RETURNS BIGINT(20) UNSIGNED
BEGIN
  DECLARE last_id BIGINT UNSIGNED; -- last_id assigned
  DECLARE nbits TINYINT UNSIGNED; -- stored node bits
  DECLARE nzero TINYINT UNSIGNED; -- zero based node
  DECLARE nmask TINYINT UNSIGNED; -- node mask for testing
  DECLARE nloop TINYINT UNSIGNED; -- loop increment
  -- make sure 2 is not to large
  IF 2 > 8 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'id_factory NODE_BITS size too large (maximum 8)';
  END IF;
  SET nzero = @@auto_increment_offset - 1;
  -- test nzero to insure that it fits
  SET nmask = 0;
  IF 2 > 0 THEN
    SET nloop = 2;
    buildmask: LOOP
      SET nmask = nmask << 1 | 1;
      SET nloop = nloop - 1;
      IF nloop = 0 THEN
        LEAVE buildmask;
      END IF;
    END LOOP buildmask;
  END IF;
  IF nzero > (nzero & nmask) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'auto_increment_offset too large for defined NODE_BITS in id_factory';
  END IF;
  -- use 'default' as namespace if none specified
  IF LENGTH(pnamespace) = 0 THEN
    SET pnamespace='default';
  END IF;
  -- insert or update
  INSERT INTO `id_factory`
    (id,namespace,node,node_bits)
  VALUES
    (1,pnamespace,nzero,2)
  ON DUPLICATE KEY UPDATE
    id=(id+1);
  -- select them back
  SELECT id,node_bits
  FROM `id_factory`
  WHERE `namespace`=pnamespace
  AND node=nzero
  INTO last_id,nbits;
  RETURN last_id << nbits | nzero;
END
//
delimiter ;
