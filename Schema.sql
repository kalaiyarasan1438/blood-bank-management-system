CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE blood_group (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(5) NOT NULL UNIQUE
);

CREATE TABLE blood_compatibility (
    donor_group_id BIGINT NOT NULL,
    recipient_group_id BIGINT NOT NULL,
    PRIMARY KEY (donor_group_id, recipient_group_id),
    CONSTRAINT fk_compatibility_donor_group
        FOREIGN KEY (donor_group_id) REFERENCES blood_group(id),
    CONSTRAINT fk_compatibility_recipient_group
        FOREIGN KEY (recipient_group_id) REFERENCES blood_group(id)
);

CREATE TABLE donors (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    blood_group_id BIGINT NOT NULL,
    dob DATE,
    weight_kg NUMERIC(5,2),
    last_donation_date DATE,
    CONSTRAINT fk_donors_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_donors_blood_group
        FOREIGN KEY (blood_group_id) REFERENCES blood_group(id)
);

CREATE TABLE hospitals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    license_no VARCHAR(100) NOT NULL UNIQUE,
    approval_status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_hospitals_user
        FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE donations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    donor_id BIGINT NOT NULL,
    donation_date DATE NOT NULL,
    volume_ml INTEGER,
    screening_status VARCHAR(20) NOT NULL,
    failure_reason VARCHAR(500),
    CONSTRAINT fk_donations_donor
        FOREIGN KEY (donor_id) REFERENCES donors(id)
);

CREATE INDEX idx_donations_donor_date
ON donations (donor_id, donation_date);

CREATE TABLE blood_inventory (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    unit_number VARCHAR(50) NOT NULL UNIQUE,
    blood_group_id BIGINT NOT NULL,
    donation_id BIGINT NOT NULL UNIQUE,
    collection_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_inventory_blood_group
        FOREIGN KEY (blood_group_id) REFERENCES blood_group(id),
    CONSTRAINT fk_inventory_donation
        FOREIGN KEY (donation_id) REFERENCES donations(id),
    CONSTRAINT chk_blood_inventory_expiry
        CHECK (expiry_date > collection_date)
);

CREATE INDEX idx_blood_inventory_group_status_expiry
ON blood_inventory (blood_group_id, status, expiry_date);

CREATE TABLE blood_requests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_no VARCHAR(50) NOT NULL UNIQUE,
    hospital_id BIGINT NOT NULL,
    blood_group_id BIGINT NOT NULL,
    units INTEGER NOT NULL,
    priority VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    required_by TIMESTAMP,
    idempotency_key VARCHAR(100),
    CONSTRAINT fk_requests_hospital
        FOREIGN KEY (hospital_id) REFERENCES hospitals(id),
    CONSTRAINT fk_requests_blood_group
        FOREIGN KEY (blood_group_id) REFERENCES blood_group(id),
    CONSTRAINT chk_blood_requests_units
        CHECK (units BETWEEN 1 AND 10),
    CONSTRAINT uq_blood_requests_hospital_idempotency
        UNIQUE (hospital_id, idempotency_key)
);

CREATE INDEX idx_blood_requests_status_priority_required
ON blood_requests (status, priority, required_by);

CREATE TABLE blood_issue (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_id BIGINT NOT NULL,
    inventory_id BIGINT NOT NULL UNIQUE,
    issued_by BIGINT NOT NULL,
    issued_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_issue_request
        FOREIGN KEY (request_id) REFERENCES blood_requests(id),
    CONSTRAINT fk_issue_inventory
        FOREIGN KEY (inventory_id) REFERENCES blood_inventory(id),
    CONSTRAINT fk_issue_issued_by
        FOREIGN KEY (issued_by) REFERENCES users(id)
);

CREATE TABLE notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT,
    details TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_log_user
        FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE outbox_event (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(50) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    payload TEXT NOT NULL,
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);