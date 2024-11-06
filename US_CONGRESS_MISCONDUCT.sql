import re
from datetime import datetime


# A python file designed specifically to read the contents
# of con-crim.txt, which is a .txt representation of the
#.yaml file that can be found at https://github.com/govtrack/misconduct
# and output an SQL script in a .txt format to make
# an SQL or MySQL compatible database to easily
# use the information and sort through it
# Authored by Preston Parsons at Rochester Institute of Technology
# on November 5, 2024
#https://sirobivan.org/index.html


def txt_to_sql_insert(input_file, output_file):
    entries = []
    current_entry = {}
    inside_consequence = False

    with open(input_file, 'r', encoding='utf-8') as file:
        lines = file.readlines()
        i = 0
        while i < len(lines):
            line = lines[i]

            # Detect start of a new entry
            if re.match(r'^\s*-\s*person:', line):
                if current_entry:
                    entries.append(current_entry)
                current_entry = {'consequences': ""}
                current_entry['person'] = int(line.split(':')[1].strip())

            # Key-value pairs at the main level
            elif re.match(r'^\s+\w+:', line):
                key, value = line.strip().split(':', 1)
                value = value.strip()

                # Check for multiline value
                while i + 1 < len(lines) and not re.match(r'^\s+\w+:', lines[i + 1]) and not re.match(
                        r'^\s*-\s*person:', lines[i + 1]):
                    i += 1
                    value += ' ' + lines[i].strip()

                try:
                    current_entry[key] = value
                except Exception as e:
                    print(f"Error setting key '{key}' with value '{value}': {e}")

            # Detect start of a consequence entry with date parsing
            elif re.match(r'^\s+-\s+date:', line):
                inside_consequence = True
                consequence_details = []
                key, value = line.strip().split(':', 1)
                date = value.strip()

                # Detect date format and normalize it to only store the date numbers
                try:
                    # Check if only a year
                    if re.match(r'^\d{4}$', date):
                        parsed_date = f"{date}-01-01"  # Default to January 1st for year
                    # Check if month and year
                    elif re.match(r'^\d{4}-\d{2}$', date):
                        parsed_date = f"{date}-01"  # Default to the 1st of the month
                    # Assume full date format if more parts are provided
                    else:
                        parsed_date = datetime.strptime(date, '%Y-%m-%d').date()

                    print("PARSED" + parsed_date)

                    # Extract the date portion after '- date:'
                    numerical_date = parsed_date.split(':')[1].strip()  # Everything after '- date:'
                    print('NUMER' + numerical_date)

                    # Store the numerical date (YYYY-MM-DD) in the consequence details
                    consequence_details.append(numerical_date)  # Only store YYYY-MM-DD format

                except ValueError:
                    print(f"Invalid date format for date '{date}' in line: {line.strip()}")

            # Continue processing keys within a consequence entry
            elif inside_consequence and re.match(r'^\s+(\w+):', line):
                key, value = line.strip().split(':', 1)
                consequence_details.append(f"{key.capitalize()}: {value.strip()}")

            # End of a consequence entry
            elif inside_consequence and line.strip() == "":
                current_entry['consequences'] += "; ".join(consequence_details) + " | "
                inside_consequence = False

            i += 1

    if current_entry:
        entries.append(current_entry)

    # Write the SQL insert statements
    with open(output_file, 'w') as output:
        output.write("""
        -- Created using misconduct_to_sql.py by PRESTON PARSONS
        -- https://sirobivan.org/index.html
        -- Create the DATABASE
        DROP DATABASE IF EXISTS usCongress;
        CREATE DATABASE usCongress;
        USE usCongress;
        -- Create the table structure
        CREATE TABLE misconduct (
            id INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
            person INT,
            name VARCHAR(25),
            allegation LONGTEXT,
            description LONGTEXT,
            date TEXT,
            tags LONGTEXT
        );

        -- Insert data into the table
        INSERT INTO misconduct (person, name, allegation, description, date, tags) VALUES
        """)

        insert_statements = []
        for entry in entries:
            name = entry.get('name', '').replace("'", "''")
            allegation = entry.get('allegation', '').replace("'", "''")
            text = entry.get('text', '').replace("'", "''")
            consequences = entry['consequences'].strip(" | ").replace("'", "''")
            tags = ', '.join(entry.get('tags', [])).replace("'", "''")
            date = entry.get('date', '').replace("'", "''")
            # Ensure the date is in the format YYYY-MM-DD (in case no date field exists, skip it)
            if date:
                # Normalize date to YYYY-MM-DD format
                try:
                    normalized_date = datetime.strptime(date, '%Y-%m-%d').date()
                    date = str(normalized_date)  # Convert back to string in YYYY-MM-DD format
                except ValueError:
                    print(f"Invalid date format for date '{date}'")

            insert_statement = (
                f"({entry.get('person')}, "
                f"'{name}', "
                f"'{allegation}', "
                f"'{text}', "
                f"'{consequences}', "
                f"'{tags}')"
            )
            insert_statements.append(insert_statement)

        output.write(",\n".join(insert_statements) + ";")


# Specify the input and output files
input_file = 'C:/Users/ppars/PycharmProjects/Congress_Crimes/con-crim.txt'  # Replace with your .txt file path
output_file = 'output_sql_script.txt'  # Output file for SQL statements

# Generate the SQL script
txt_to_sql_insert(input_file, output_file)
print(f"SQL INSERT statements written to {output_file}")
