
-- Create Users table
CREATE TABLE Members (
    user_id VARCHAR(100) PRIMARY KEY,
    user_login VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create TaxonDictionary table
CREATE TABLE TaxonDictionary (
    taxon_id VARCHAR(100) PRIMARY KEY,
    scientific_name VARCHAR(255) NOT NULL,
    common_name VARCHAR(255),
    iconic_taxon_name VARCHAR(255),
    taxon_family_name VARCHAR(255)
);

-- Create Locations table
CREATE TABLE Locations (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    place_guess VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    positional_accuracy VARCHAR(100),
    place_state_name VARCHAR(255),
    geoprivacy VARCHAR(50),
    coordinates_obscured BOOLEAN,
    positioning_method VARCHAR(100),
    positioning_device VARCHAR(100)
);

-- Create QualityGrades table
CREATE TABLE QualityGrades (
    grade_id INT PRIMARY KEY AUTO_INCREMENT,
    grade_name VARCHAR(50) NOT NULL
);

-- Create ButterflyObservations table
CREATE TABLE ButterflyObservations (
    id VARCHAR(100) PRIMARY KEY,
    uuid VARCHAR(36) UNIQUE NOT NULL,
    user_id VARCHAR(100),
    taxon_id VARCHAR(100),
    iconic_taxon_name VARCHAR(25)
    location_id VARCHAR(100),
    observed_on_string VARCHAR(50),
    observed_on DATE,
    time_observed_at TIME,
    time_zone VARCHAR(50),
    created_at DATETIME,
    updated_at DATETIME,
    quality_grade_id VARCHAR(100),
    license_id VARCHAR(100),
    url VARCHAR(255),
    image_url VARCHAR(255),
    sound_url VARCHAR(255),
    description TEXT,
    num_identification_agreements INT,
    num_identification_disagreements INT,
    captive_cultivated BOOLEAN,
    species_guess VARCHAR(255),
    dsf_butterfly_activity VARCHAR(255),
    dsf_cloud_cover VARCHAR(50),
    dsf_temperature DECIMAL(5, 2),
    dsf_transect_personal VARCHAR(255),
    dsf_transect_set VARCHAR(255),
    cc_plant_id1 VARCHAR(100),
    cc_plant_id2 VARCHAR(100),
    feeding_on VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Members(user_id),
    FOREIGN KEY (taxon_id) REFERENCES TaxonDictionary(taxon_id),
    FOREIGN KEY (location_id) REFERENCES Locations(location_id),
    FOREIGN KEY (quality_grade_id) REFERENCES QualityGrades(grade_id),
    FOREIGN KEY (license_id) REFERENCES Licenses(license_id)
);

-- Create PlantObservations table
CREATE TABLE PlantObservations (
    id VARCHAR(100) PRIMARY KEY,
    uuid VARCHAR(36) UNIQUE NOT NULL,
    user_id VARCHAR(100),
    taxon_id VARCHAR(100),
    location_id VARCHAR(100),
    observed_on DATE,
    time_observed_at TIME,
    time_zone VARCHAR(50),
    created_at DATETIME,
    updated_at DATETIME,
    quality_grade_id VARCHAR(100),
    license VARCHAR(100),
    url VARCHAR(255),
    image_url VARCHAR(255),
    sound_url VARCHAR(255),
    description TEXT,
    num_identification_agreements INT,
    num_identification_disagreements INT,
    captive_cultivated BOOLEAN,
    species_guess VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Members(user_id),
    FOREIGN KEY (taxon_id) REFERENCES TaxonDictionary(taxon_id),
    FOREIGN KEY (location_id) REFERENCES Locations(location_id),
    FOREIGN KEY (quality_grade_id) REFERENCES QualityGrades(grade_id),
    FOREIGN KEY (license_id) REFERENCES Licenses(license_id)

);

-- Create ButterflyPlantAssociations table
CREATE TABLE ButterflyPlantAssociations (
    butterfly_id VARCHAR(100),
    plant_id VARCHAR(100),
    association_type ENUM('1st', '2nd'),
    PRIMARY KEY (butterfly_id, plant_id, association_type),
    FOREIGN KEY (butterfly_id) REFERENCES ButterflyObservations(id),
    FOREIGN KEY (plant_id) REFERENCES PlantObservations(id)
);

-- Create ObservationHistory table to track changes
CREATE TABLE ObservationHistory (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    observation_id VARCHAR(100),
    observation_type ENUM('butterfly', 'plant'),
    field_name VARCHAR(50),
    old_value TEXT,
    new_value TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (observation_id) REFERENCES ButterflyObservations(id),
    FOREIGN KEY (observation_id) REFERENCES PlantObservations(id)
);

-- Create trigger to track changes in ButterflyObservations
DELIMITER //
CREATE TRIGGER butterfly_observation_history
AFTER UPDATE ON ButterflyObservations
FOR EACH ROW
BEGIN
    IF OLD.quality_grade_id != NEW.quality_grade_id THEN
        INSERT INTO ObservationHistory (observation_id, observation_type, field_name, old_value, new_value)
        VALUES (NEW.id, 'butterfly', 'quality_grade_id', OLD.quality_grade_id, NEW.quality_grade_id);
    END IF;
    
    IF OLD.taxon_id != NEW.taxon_id THEN
        INSERT INTO ObservationHistory (observation_id, observation_type, field_name, old_value, new_value)
        VALUES (NEW.id, 'butterfly', 'taxon_id', OLD.taxon_id, NEW.taxon_id);
    END IF;
END //
DELIMITER ;

-- Create trigger to track changes in PlantObservations
DELIMITER //
CREATE TRIGGER plant_observation_history
AFTER UPDATE ON PlantObservations
FOR EACH ROW
BEGIN
    IF OLD.quality_grade_id != NEW.quality_grade_id THEN
        INSERT INTO ObservationHistory (observation_id, observation_type, field_name, old_value, new_value)
        VALUES (NEW.id, 'plant', 'quality_grade_id', OLD.quality_grade_id, NEW.quality_grade_id);
    END IF;
    
    IF OLD.taxon_id != NEW.taxon_id THEN
        INSERT INTO ObservationHistory (observation_id, observation_type, field_name, old_value, new_value)
        VALUES (NEW.id, 'plant', 'taxon_id', OLD.taxon_id, NEW.taxon_id);
    END IF;
END //
DELIMITER ;

-- Step 1: Populate Users table with initial membership data
INSERT INTO members (user_id, user_login, user_name, start_date, is_active)
SELECT 
    user_id,
    MAX(user_login) AS user_login,
    MAX(user_name) AS user_name,
    MIN(observed_on) AS start_date,
    TRUE AS is_active
FROM bimby2024
GROUP BY user_id;

-- Step 2: Populate validation tables
INSERT INTO QualityGrades (grade_name)
SELECT DISTINCT quality_grade FROM bimby2024 WHERE quality_grade IS NOT NULL;

--Populate butterfly taxon
INSERT INTO TaxonDictionary (taxon_id, scientific_name, common_name, iconic_taxon_name, taxon_family_name)
SELECT DISTINCT 
    taxon_id,
    scientific_name,
    common_name,
    iconic_taxon_name,
    taxon_family_name
FROM bimby2024
WHERE taxon_id IS NOT NULL;

--Populate plant taxon
INSERT INTO TaxonDictionary (taxon_id, scientific_name, common_name, iconic_taxon_name, taxon_family_name)
SELECT DISTINCT 
    taxon_id,
    scientific_name,
    common_name,
    iconic_taxon_name,
    taxon_family_name
FROM plants2024
WHERE taxon_id IS NOT NULL;


-- Step 3: Populate Locations table
INSERT INTO Locations (
    place_guess, latitude, longitude, positional_accuracy, 
    place_state_name, geoprivacy, coordinates_obscured,
    positioning_method, positioning_device
)
SELECT DISTINCT 
    place_guess,
    latitude,
    longitude,
    positional_accuracy,
    place_state_name,
    geoprivacy,
    coordinates_obscured,
    positioning_method,
    positioning_device
FROM bimby2024
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Step 4: Insert Plant Observations (non-butterfly records)
INSERT INTO PlantObservations (
    id, uuid, user_id, taxon_id, location_id, observed_on, time_observed_at,
    time_zone, created_at, updated_at, quality_grade_id, license_id, url,
    image_url, sound_url, description, num_identification_agreements,
    num_identification_disagreements, captive_cultivated, species_guess
)
SELECT 
    p.id,
    p.uuid,
    u.user_id,
    t.taxon_id,
    l.location_id,
    p.observed_on,
    p.time_observed_at,
    p.time_zone,
    p.created_at,
    p.updated_at,
    qg.grade_id,
    p.license,
    p.url,
    p.image_url,
    p.sound_url,
    p.description,
    p.num_identification_agreements,
    p.num_identification_disagreements,
    p.captive_cultivated,
    p.species_guess
FROM plants2024 p
LEFT JOIN Users u ON b.user_id = u.user_id
LEFT JOIN TaxonDictionary t ON b.taxon_id = t.taxon_id
LEFT JOIN Locations l ON b.latitude = l.latitude 
    AND b.longitude = l.longitude
    AND b.place_guess = l.place_guess
LEFT JOIN QualityGrades qg ON b.quality_grade = qg.grade_name
LEFT JOIN Licenses lic ON b.license = lic.license_name


-- Step 5: Insert Butterfly Observations
 
 INSERT INTO ButterflyObservations (
    id, uuid, user_id, taxon_id, location_id, observed_on, time_observed_at,
    time_zone, created_at, updated_at, quality_grade_id, license_id, url,
    image_url, sound_url, description, num_identification_agreements,
    num_identification_disagreements, captive_cultivated, species_guess,
    dsf_butterfly_activity, dsf_cloud_cover, dsf_temperature,
    dsf_transect_personal, dsf_transect_set, feeding_on
)
SELECT 
    b.id,
    b.uuid,
    u.user_id,
    t.taxon_id,
    l.location_id,
    b.observed_on,
    b.time_observed_at,
    b.time_zone,
    b.created_at,
    b.updated_at,
    qg.grade_id,
    b.license,
    b.url,
    b.image_url,
    b.sound_url,
    b.description,
    b.num_identification_agreements,
    b.num_identification_disagreements,
    b.captive_cultivated,
    b.species_guess,
    b.`field:dsf butterfly activity`,
    b.`field:dsf cloud cover`,
    b.`field:dsf temperature at time of observation`,
    b.`field:dsf transect: personal`,
    b.`field:dsf transect: set`,
    b.`field:feeding on`
FROM bimby2024 b
LEFT JOIN Users u ON b.user_id = u.user_id
LEFT JOIN TaxonDictionary t ON b.taxon_id = t.taxon_id
LEFT JOIN Locations l ON b.latitude = l.latitude 
    AND b.longitude = l.longitude
    AND b.place_guess = l.place_guess
LEFT JOIN QualityGrades qg ON b.quality_grade = qg.grade_name
;


-- Step 6: Insert into plant-butterfly associations. Needs data to be set up correctly and its not yet
/*
INSERT INTO ButterflyPlantAssociations (butterfly_id, plant_id, association_type)
SELECT 
    bo.id,
    po.id,
    '1st'
FROM ButterflyObservations bo
JOIN bimby2024 b ON bo.id = b.id
JOIN PlantObservations po ON p.`field:dsf plant association (1st)` = po.id
WHERE b.`field:dsf plant association (1st)` IS NOT NULL;

INSERT INTO ButterflyPlantAssociations (butterfly_id, plant_id, association_type)
SELECT 
    bo.id,
    po.id,
    '2nd'
FROM ButterflyObservations bo
JOIN bimby2024 b ON bo.id = b.id
JOIN PlantObservations po ON b.`field:dsf plant association (2nd)` = po.id
WHERE b.`field:dsf plant association (2nd)` IS NOT NULL;
*/
