USE `spacelife`;

ALTER TABLE `users`
  ADD COLUMN `last_hotel` VARCHAR(255) NULL
;

INSERT INTO `addon_account` (name, label, shared) VALUES
  ('hotel_black_money','Argent Sale Hotel',0)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
  ('hotel','Hotel',0)
;

INSERT INTO `datastore` (name, label, shared) VALUES
  ('hotel','Hotel',0)
;

CREATE TABLE `owned_hotels` (

  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `price` double NOT NULL,
  `rented` int(11) NOT NULL,
  `owner` varchar(60) NOT NULL,

  PRIMARY KEY (`id`)
);

CREATE TABLE `hotels` (

  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `entering` varchar(255) DEFAULT NULL,
  `exit` varchar(255) DEFAULT NULL,
  `inside` varchar(255) DEFAULT NULL,
  `outside` varchar(255) DEFAULT NULL,
  `ipls` varchar(255) DEFAULT '[]',
  `gateway` varchar(255) DEFAULT NULL,
  `is_single` int(11) DEFAULT NULL,
  `is_room` int(11) DEFAULT NULL,
  `is_gateway` int(11) DEFAULT NULL,
  `room_menu` varchar(255) DEFAULT NULL,
  `price` int(11) NOT NULL,

  PRIMARY KEY (`id`)
);

INSERT INTO `hotels` VALUES
  ;

