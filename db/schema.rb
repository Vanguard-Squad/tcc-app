# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_03_140000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "city"
    t.bigint "company_id"
    t.string "complement"
    t.string "country"
    t.datetime "created_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "neighborhood"
    t.integer "number"
    t.string "street"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["company_id"], name: "index_addresses_on_company_id"
  end

  create_table "archives", force: :cascade do |t|
    t.string "archive_type"
    t.datetime "created_at", null: false
    t.binary "file"
    t.string "name"
    t.string "service_path"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_archives_on_user_id"
  end

  create_table "checkins", force: :cascade do |t|
    t.datetime "boarded_college"
    t.datetime "boarded_initial"
    t.datetime "created_at", null: false
    t.datetime "date"
    t.datetime "disembarked_college"
    t.datetime "disembarked_final"
    t.boolean "status"
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["student_id"], name: "index_checkins_on_student_id"
    t.index ["vehicle_id"], name: "index_checkins_on_vehicle_id"
  end

  create_table "colleges", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_active"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_colleges_on_address_id"
  end

  create_table "companies", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.string "cnpj"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["address_id"], name: "index_companies_on_address_id"
    t.index ["cnpj"], name: "index_companies_on_cnpj", unique: true
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.bigint "student_id", null: false
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["reviewed_by_id"], name: "index_contracts_on_reviewed_by_id"
    t.index ["student_id"], name: "index_contracts_on_student_id", unique: true
  end

  create_table "drivers", force: :cascade do |t|
    t.date "birthdate"
    t.datetime "created_at", null: false
    t.string "drive_license"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["drive_license"], name: "index_drivers_on_drive_license", unique: true
    t.index ["user_id"], name: "index_drivers_on_user_id"
  end

  create_table "logs", force: :cascade do |t|
    t.string "action"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_logs_on_auditable"
    t.index ["company_id", "created_at"], name: "index_logs_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_logs_on_company_id"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "routes", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_routes_on_company_id"
  end

  create_table "stops", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.boolean "await_return"
    t.datetime "created_at", null: false
    t.bigint "route_id", null: false
    t.integer "step"
    t.integer "total_student_number"
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_stops_on_address_id"
    t.index ["route_id"], name: "index_stops_on_route_id"
  end

  create_table "students", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.date "birthdate"
    t.bigint "college_id", null: false
    t.string "cpf"
    t.datetime "created_at", null: false
    t.string "gender"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["address_id"], name: "index_students_on_address_id"
    t.index ["college_id"], name: "index_students_on_college_id"
    t.index ["cpf"], name: "index_students_on_cpf", unique: true
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.bigint "driver_id", null: false
    t.datetime "finished_at"
    t.float "latitude"
    t.float "longitude"
    t.datetime "position_at"
    t.datetime "started_at", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["driver_id"], name: "index_trips_on_driver_id"
    t.index ["vehicle_id"], name: "index_trips_on_active_vehicle", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "is_active", default: true
    t.boolean "must_change_password", default: false, null: false
    t.string "name"
    t.string "password_digest"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vehicle_drivers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "driver_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.string "week_day"
    t.index ["driver_id"], name: "index_vehicle_drivers_on_driver_id"
    t.index ["vehicle_id"], name: "index_vehicle_drivers_on_vehicle_id"
  end

  create_table "vehicle_students", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_return"
    t.bigint "student_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["student_id"], name: "index_vehicle_students_on_student_id"
    t.index ["vehicle_id"], name: "index_vehicle_students_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true
    t.string "license_plate"
    t.bigint "route_id"
    t.integer "seats"
    t.integer "seats_busy", default: 0
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_vehicles_on_company_id"
    t.index ["license_plate"], name: "index_vehicles_on_license_plate", unique: true
    t.index ["route_id"], name: "index_vehicles_on_route_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "companies"
  add_foreign_key "archives", "users"
  add_foreign_key "checkins", "students"
  add_foreign_key "checkins", "vehicles"
  add_foreign_key "colleges", "addresses"
  add_foreign_key "companies", "addresses"
  add_foreign_key "companies", "users"
  add_foreign_key "contracts", "students"
  add_foreign_key "contracts", "users", column: "reviewed_by_id"
  add_foreign_key "drivers", "users"
  add_foreign_key "logs", "companies"
  add_foreign_key "logs", "users"
  add_foreign_key "routes", "companies"
  add_foreign_key "stops", "addresses"
  add_foreign_key "stops", "routes"
  add_foreign_key "students", "addresses"
  add_foreign_key "students", "colleges"
  add_foreign_key "students", "users"
  add_foreign_key "trips", "drivers"
  add_foreign_key "trips", "vehicles"
  add_foreign_key "vehicle_drivers", "drivers"
  add_foreign_key "vehicle_drivers", "vehicles"
  add_foreign_key "vehicle_students", "students"
  add_foreign_key "vehicle_students", "vehicles"
  add_foreign_key "vehicles", "companies"
  add_foreign_key "vehicles", "routes"
end
