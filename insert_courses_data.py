#!/usr/bin/env python3
"""
Script to insert courses and packages data into PostgreSQL database
Usage: python insert_courses_data.py
"""

import psycopg2
from psycopg2 import sql

# Database connection parameters
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'chalak_db',
    'user': 'chalak',
    'password': 'chalak123'
}

# Courses data
COURSES = [
    ('a1111111-1111-1111-1111-111111111111', 'Scooter', 'SCT', 'Learn to ride a scooter safely and confidently', 30, 6500, True),
    ('a2222222-2222-2222-2222-222222222222', 'Motorbike', 'MTB', 'Comprehensive motorbike riding training', 30, 7500, True),
    ('a3333333-3333-3333-3333-333333333333', 'Car', 'CAR', 'Complete car driving course with road test preparation', 45, 15000, True),
    ('a4444444-4444-4444-4444-444444444444', 'Heavy Vehicle', 'HVY', 'Heavy vehicle and truck driving license preparation', 60, 25000, True),
]

# Packages data
PACKAGES = [
    # Scooter Packages
    ('b1111111-1111-1111-1111-111111111111', 'Scooter - Half Hour', 'SCT-30MIN', 'Half hour scooter practice session', 0, 400, 0, True),
    ('b1111111-1111-1111-1111-111111111112', 'Scooter - 1 Hour', 'SCT-1HR', 'One hour scooter practice session', 0, 700, 0, True),
    ('b1111111-1111-1111-1111-111111111113', 'Scooter - Daily', 'SCT-DAY', 'One day scooter practice (2 hours)', 1, 1200, 0, True),
    ('b1111111-1111-1111-1111-111111111114', 'Scooter - Weekly', 'SCT-WEEK', 'One week scooter practice (6 working days)', 7, 3500, 10, True),
    ('b1111111-1111-1111-1111-111111111115', 'Scooter - Monthly', 'SCT-MONTH', '26 working days complete scooter course', 26, 6500, 15, True),

    # Motorbike Packages
    ('b2222222-2222-2222-2222-222222222221', 'Motorbike - Half Hour', 'MTB-30MIN', 'Half hour motorbike practice session', 0, 450, 0, True),
    ('b2222222-2222-2222-2222-222222222222', 'Motorbike - 1 Hour', 'MTB-1HR', 'One hour motorbike practice session', 0, 800, 0, True),
    ('b2222222-2222-2222-2222-222222222223', 'Motorbike - Daily', 'MTB-DAY', 'One day motorbike practice (2 hours)', 1, 1400, 0, True),
    ('b2222222-2222-2222-2222-222222222224', 'Motorbike - Weekly', 'MTB-WEEK', 'One week motorbike practice (6 working days)', 7, 4000, 10, True),
    ('b2222222-2222-2222-2222-222222222225', 'Motorbike - Monthly', 'MTB-MONTH', '26 working days complete motorbike course', 26, 7500, 15, True),

    # Car Packages
    ('b3333333-3333-3333-3333-333333333331', 'Car - Half Hour', 'CAR-30MIN', 'Half hour car driving practice', 0, 600, 0, True),
    ('b3333333-3333-3333-3333-333333333332', 'Car - 1 Hour', 'CAR-1HR', 'One hour car driving practice', 0, 1100, 0, True),
    ('b3333333-3333-3333-3333-333333333333', 'Car - Daily', 'CAR-DAY', 'One day car driving practice (2 hours)', 1, 2000, 0, True),
    ('b3333333-3333-3333-3333-333333333334', 'Car - Weekly', 'CAR-WEEK', 'One week car driving practice (6 working days)', 7, 6000, 10, True),
    ('b3333333-3333-3333-3333-333333333335', 'Car - Monthly Basic', 'CAR-MONTH-B', '26 working days basic car course', 26, 12000, 15, True),
    ('b3333333-3333-3333-3333-333333333336', 'Car - Monthly Complete', 'CAR-MONTH-C', '45 days complete car course with test prep', 45, 15000, 20, True),

    # Heavy Vehicle Packages
    ('b4444444-4444-4444-4444-444444444441', 'Heavy Vehicle - Daily', 'HVY-DAY', 'One day heavy vehicle practice', 1, 2500, 0, True),
    ('b4444444-4444-4444-4444-444444444442', 'Heavy Vehicle - Weekly', 'HVY-WEEK', 'One week heavy vehicle practice', 7, 8000, 10, True),
    ('b4444444-4444-4444-4444-444444444443', 'Heavy Vehicle - Monthly', 'HVY-MONTH', '30 days heavy vehicle course', 30, 18000, 15, True),
    ('b4444444-4444-4444-4444-444444444444', 'Heavy Vehicle - Complete', 'HVY-FULL', '60 days complete heavy vehicle license course', 60, 25000, 20, True),
]

# Package-Course mappings
PACKAGE_COURSES = [
    # Scooter packages
    ('b1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111'),
    ('b1111111-1111-1111-1111-111111111112', 'a1111111-1111-1111-1111-111111111111'),
    ('b1111111-1111-1111-1111-111111111113', 'a1111111-1111-1111-1111-111111111111'),
    ('b1111111-1111-1111-1111-111111111114', 'a1111111-1111-1111-1111-111111111111'),
    ('b1111111-1111-1111-1111-111111111115', 'a1111111-1111-1111-1111-111111111111'),

    # Motorbike packages
    ('b2222222-2222-2222-2222-222222222221', 'a2222222-2222-2222-2222-222222222222'),
    ('b2222222-2222-2222-2222-222222222222', 'a2222222-2222-2222-2222-222222222222'),
    ('b2222222-2222-2222-2222-222222222223', 'a2222222-2222-2222-2222-222222222222'),
    ('b2222222-2222-2222-2222-222222222224', 'a2222222-2222-2222-2222-222222222222'),
    ('b2222222-2222-2222-2222-222222222225', 'a2222222-2222-2222-2222-222222222222'),

    # Car packages
    ('b3333333-3333-3333-3333-333333333331', 'a3333333-3333-3333-3333-333333333333'),
    ('b3333333-3333-3333-3333-333333333332', 'a3333333-3333-3333-3333-333333333333'),
    ('b3333333-3333-3333-3333-333333333333', 'a3333333-3333-3333-3333-333333333333'),
    ('b3333333-3333-3333-3333-333333333334', 'a3333333-3333-3333-3333-333333333333'),
    ('b3333333-3333-3333-3333-333333333335', 'a3333333-3333-3333-3333-333333333333'),
    ('b3333333-3333-3333-3333-333333333336', 'a3333333-3333-3333-3333-333333333333'),

    # Heavy Vehicle packages
    ('b4444444-4444-4444-4444-444444444441', 'a4444444-4444-4444-4444-444444444444'),
    ('b4444444-4444-4444-4444-444444444442', 'a4444444-4444-4444-4444-444444444444'),
    ('b4444444-4444-4444-4444-444444444443', 'a4444444-4444-4444-4444-444444444444'),
    ('b4444444-4444-4444-4444-444444444444', 'a4444444-4444-4444-4444-444444444444'),
]

def main():
    try:
        # Connect to the database
        print("Connecting to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()

        # Insert courses
        print("\nInserting courses...")
        courses_inserted = 0
        for course in COURSES:
            try:
                cursor.execute("""
                    INSERT INTO courses (id, name, code, description, duration, fee, is_active)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (code) DO NOTHING
                """, course)
                if cursor.rowcount > 0:
                    courses_inserted += 1
                    print(f"  ✓ Inserted: {course[1]}")
                else:
                    print(f"  - Skipped (exists): {course[1]}")
            except Exception as e:
                print(f"  ✗ Error inserting {course[1]}: {e}")

        # Insert packages
        print("\nInserting packages...")
        packages_inserted = 0
        for package in PACKAGES:
            try:
                cursor.execute("""
                    INSERT INTO packages (id, name, code, description, duration, price, discount_percentage, is_active)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (code) DO NOTHING
                """, package)
                if cursor.rowcount > 0:
                    packages_inserted += 1
                    print(f"  ✓ Inserted: {package[1]}")
                else:
                    print(f"  - Skipped (exists): {package[1]}")
            except Exception as e:
                print(f"  ✗ Error inserting {package[1]}: {e}")

        # Insert package-course mappings
        print("\nLinking packages to courses...")
        mappings_inserted = 0
        for mapping in PACKAGE_COURSES:
            try:
                cursor.execute("""
                    INSERT INTO package_courses (package_id, course_id)
                    VALUES (%s, %s)
                    ON CONFLICT (package_id, course_id) DO NOTHING
                """, mapping)
                if cursor.rowcount > 0:
                    mappings_inserted += 1
            except Exception as e:
                print(f"  ✗ Error inserting mapping: {e}")
        print(f"  ✓ Created {mappings_inserted} package-course links")

        # Commit the transaction
        conn.commit()

        # Display summary
        cursor.execute("SELECT COUNT(*) FROM courses WHERE deleted_at IS NULL")
        total_courses = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM packages WHERE deleted_at IS NULL")
        total_packages = cursor.fetchone()[0]

        print("\n" + "="*50)
        print("✅ Data insertion completed!")
        print("="*50)
        print(f"Courses in database: {total_courses}")
        print(f"Packages in database: {total_packages}")
        print(f"New courses added: {courses_inserted}")
        print(f"New packages added: {packages_inserted}")
        print("="*50)

        # Close connection
        cursor.close()
        conn.close()

    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())
