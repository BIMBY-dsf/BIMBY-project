
-- Create Users table
CREATE TABLE Members (
    user_id VARCHAR(100) PRIMARY KEY,
    user_login VARCHAR(50) NOT NULL,
    user_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    is_active VARCHAR(1)
);

-- Create TaxonDictionary table
CREATE TABLE TaxonDictionary (
    taxon_id VARCHAR(50) PRIMARY KEY,
    scientific_name VARCHAR(50) NOT NULL,
    common_name VARCHAR(50),
    iconic_taxon_name VARCHAR(50)
);


-- Create QualityGrades table
CREATE TABLE QualityGrades (
    grade_id INT PRIMARY KEY AUTO_INCREMENT,
    grade_name VARCHAR(50) NOT NULL
);

-- Create ButterflyObservations table
CREATE TABLE ButterflyObservations (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    taxon_id VARCHAR(100),
    place_guess VARCHAR(64),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    positional_accuracy VARCHAR(50),
    place_state_name VARCHAR(100),
    geoprivacy VARCHAR(50),
    coordinates_obscured VARCHAR(25),
    positioning_method VARCHAR(50),
    positioning_device VARCHAR(50),
    iconic_taxon_name VARCHAR(50),
    observed_on_string VARCHAR(50),
    observed_on DATE,
    time_observed_at VARCHAR(50),
    time_zone VARCHAR(50),
    created_at VARCHAR(50),
    updated_at VARCHAR(50),
    quality_grade_id VARCHAR(100),
    license VARCHAR(100),
    url VARCHAR(255),
    image_url VARCHAR(255),
    sound_url VARCHAR(255),
    description VARCHAR(512),
    num_identification_agreements INT,
    num_identification_disagreements INT,
    captive_cultivated VARCHAR(25),
    species_guess VARCHAR(100),
    dsf_butterfly_activity VARCHAR(50),
    dsf_cloud_cover VARCHAR(50),
    dsf_temperature VARCHAR(50),
    dsf_transect_personal VARCHAR(50),
    dsf_transect_set VARCHAR(50),
    cc_plant_id1 VARCHAR(100),
    cc_plant_id2 VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES Members(user_id),
    FOREIGN KEY (taxon_id) REFERENCES TaxonDictionary(taxon_id),
    FOREIGN KEY (quality_grade_id) REFERENCES QualityGrades(grade_id)
);

-- Create PlantObservations table
CREATE TABLE PlantObservations (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100),
    taxon_id VARCHAR(100),
   place_guess VARCHAR(64),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    positional_accuracy VARCHAR(10),
    place_state_name VARCHAR(100),
    geoprivacy VARCHAR(50),
    coordinates_obscured VARCHAR(25),
    positioning_method VARCHAR(50),
    positioning_device VARCHAR(50),
    iconic_taxon_name VARCHAR(50),
    observed_on DATE,
    time_observed_at VARCHAR(50),
    time_zone VARCHAR(50),
    created_at VARCHAR(50),
    updated_at VARCHAR(50),
    quality_grade_id VARCHAR(100),
    license VARCHAR(100),
    url VARCHAR(255),
    image_url VARCHAR(255),
    sound_url VARCHAR(255),
    description VARCHAR(512),
    num_identification_agreements INT,
    num_identification_disagreements INT,
    captive_cultivated VARCHAR(25),
    species_guess VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Members(user_id),
    FOREIGN KEY (taxon_id) REFERENCES TaxonDictionary(taxon_id),
    FOREIGN KEY (quality_grade_id) REFERENCES QualityGrades(grade_id)
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
    user_login AS user_login,
    user_name AS user_name,
    MIN(observed_on) AS start_date,
    'Y' AS is_active
FROM databaseimport
GROUP BY user_id;

-- Step 2: Populate validation tables

INSERT INTO QualityGrades (grade_name)
SELECT DISTINCT quality_grade FROM databaseimport WHERE quality_grade IS NOT NULL;

INSERT INTO TaxonDictionary (taxon_id, scientific_name, common_name, iconic_taxon_name)
SELECT DISTINCT 
    taxon_id,
    scientific_name,
    common_name,
    iconic_taxon_name
FROM databaseimport
WHERE taxon_id IS NOT NULL;

-- Step 4: Insert Plant Observations (non-butterfly records)

INSERT INTO PlantObservations (
    id, user_id, taxon_id, place_guess, latitude,longitude, positional_accuracy, place_state_name, geoprivacy,
    coordinates_obscured, positioning_method, positioning_device, observed_on, time_observed_at,
    time_zone, created_at, updated_at, quality_grade_id, license, url,
    image_url, sound_url, description, num_identification_agreements,
    num_identification_disagreements, captive_cultivated, species_guess
)
SELECT 
    d.id,
    m.user_id,
    t.taxon_id,
    d.place_guess,
    d.latitude ,
    d.longitude,
    d.positional_accuracy,
    d.place_state_name,
    d.geoprivacy,
    d.coordinates_obscured,
    d.positioning_method,
    d.positioning_device,
    d.observed_on,
    d.time_observed_at,
    d.time_zone,
    d.created_at,
    d.updated_at,
    qg.grade_id,
    d.license,
    d.url,
    d.image_url,
    d.sound_url,
    d.description,
    d.num_identification_agreements,
    d.num_identification_disagreements,
    d.captive_cultivated,
    d.species_guess
FROM databaseimport d
LEFT JOIN Members m ON d.user_id = m.user_id
LEFT JOIN TaxonDictionary t ON d.taxon_id = t.taxon_id
LEFT JOIN QualityGrades qg ON d.quality_grade = qg.grade_name
where d.iconic_taxon_name = 'Plantae'
;

-- Step 5: Insert Butterfly Observations
 truncate ButterflyObservations
 INSERT INTO ButterflyObservations (
    id, user_id, taxon_id, place_guess,latitude ,longitude, 
    positional_accuracy,place_state_name,geoprivacy,coordinates_obscured,
    positioning_method,positioning_device, observed_on, time_observed_at,
    time_zone, created_at, updated_at, quality_grade_id, license, url,
    image_url, sound_url, description, num_identification_agreements,
    num_identification_disagreements, captive_cultivated, species_guess,
    dsf_butterfly_activity, dsf_cloud_cover, dsf_temperature,
    dsf_transect_personal, dsf_transect_set,cc_plant_id1, cc_plant_id2
)
SELECT 
    d.id,
    d.user_id,
    d.taxon_id,
    d.place_guess,
    d.latitude ,
    d.longitude,
    d.positional_accuracy,
    d.place_state_name,
    d.geoprivacy,
    d.coordinates_obscured,
    d.positioning_method,
    d.positioning_device,
    d.observed_on,
    d.time_observed_at,
    d.time_zone,
    d.created_at,
    d.updated_at,
    qg.grade_id,
    d.license,
    d.url,
    d.image_url,
    d.sound_url,
    d.description,
    d.num_identification_agreements,
    d.num_identification_disagreements,
    d.captive_cultivated,
    d.species_guess,
    d.`field:dsf butterfly activity`,
    d.`field:dsf cloud cover`,
    d.`field:dsf temperature at time of observation`,
    d.`field:dsf transect: personal`,
    d.`field:dsf transect: set`,
    CASE WHEN `field:dsf plant association (1st)` LIKE '%observations/%' THEN
            CASE 
                WHEN RIGHT(`field:dsf plant association (1st)`, 9) REGEXP '^[0-9]{9}$' 
                THEN RIGHT(`field:dsf plant association (1st)`, 9)
                ELSE NULL
            END
        ELSE
            NULL
    end,
    null /*replace this null with the second plant association field when data is imported correctly..." CASE WHEN `field:dsf plant association (2nd)` LIKE '%observations/%' THEN
            CASE 
                WHEN RIGHT(`field:dsf plant association (2nd)`, 9) REGEXP '^[0-9]{9}$' 
                THEN RIGHT(`field:dsf plant association (2nd)`, 9)
                ELSE NULL
            END
        ELSE
            NULL
    end,*/
FROM databaseimport d
LEFT JOIN QualityGrades qg ON d.quality_grade = qg.grade_name
;


-- Step 6: Insert into plant-butterfly associations.
truncate ButterflyPlantAssociations
INSERT INTO ButterflyPlantAssociations (butterfly_id, plant_id, association_type)
SELECT 
    bo.id,
    po.id,
    '1st'
FROM ButterflyObservations bo
JOIN PlantObservations po ON bo.cc_plant_id1 = po.id
WHERE bo.cc_plant_id1 IS NOT NULL;

/* Add in once the data exists in the database
INSERT INTO ButterflyPlantAssociations (butterfly_id, plant_id, association_type)
SELECT 
    bo.id,
    po.id,
    '2nd'
FROM ButterflyObservations bo
JOIN databaseimport d ON bo.id = b.id
JOIN PlantObservations po ON d.`field:dsf plant association (2nd)` = po.id
WHERE d.`field:dsf plant association (2nd)` IS NOT NULL;
*/
