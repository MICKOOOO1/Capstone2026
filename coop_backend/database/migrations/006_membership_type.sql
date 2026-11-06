ALTER TABLE members
  ADD COLUMN membership_type ENUM('regular', 'associate') NULL DEFAULT NULL
  AFTER address;
