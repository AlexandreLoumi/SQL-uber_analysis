CREATE INDEX IF NOT EXISTS idx_cancellations_driver_trip
ON cancellations(cancelled_by, trip_id);

CREATE INDEX IF NOT EXISTS idx_trips_driver
ON trips(driver_id);

CREATE INDEX IF NOT EXISTS idx_trips_requested_at
ON trips(requested_at);

CREATE INDEX IF NOT EXISTS idx_payments_trip
ON payments(trip_id);

CREATE INDEX IF NOT EXISTS idx_reviews_trip
ON reviews(trip_id);

SELECT name
FROM sqlite_master
WHERE type = 'index';