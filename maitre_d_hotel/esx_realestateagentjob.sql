INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_maitrehotel','Maitre d Hotel',1)
;

INSERT INTO `jobs` (name, label) VALUES
	('maitrehotel','Maitre d Hotel')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('maitrehotel',0,'location','Location',10,'{}','{}'),
	('maitrehotel',1,'vendeur','Vendeur',25,'{}','{}'),
	('maitrehotel',2,'gestion','Gestion',40,'{}','{}'),
	('maitrehotel',3,'boss','Patron',0,'{}','{}')
;

