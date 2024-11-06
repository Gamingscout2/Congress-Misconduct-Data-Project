import re

# A python file designed specifically to read the contents
# of con-crim.txt, which is a .txt representation of the
#.yaml file that can be found at https://github.com/govtrack/misconduct
# and output an SQL script in a .txt format to make
# an SQL or MySQL compatible database to easily
# use the information and sort through it
# Authored by Preston Parsons at Rochester Institute of Technology
# on November 5, 2024
#https://sirobivan.org/index.html

# Function to parse txt file
def txt_to_sql_insert(input_file, output_file):
    # Variable to hold each entry's data
    entries = []
    current_entry = {}
    inside_consequence = False

    # Read and process the file line by line
    with open(input_file, 'r', encoding='utf-8') as file:  # UTF-8 encoding had to be used as I encountered a character that was either corrupt or
                                                        # pointed to a null value
                                                            # using standard encoding
        for line in file:
            # Detect new entry
            if re.match(r'^\s*-\s*person:', line):
                if current_entry:
                    entries.append(current_entry)
                current_entry = {'consequences': []}
                current_entry['person'] = int(line.split(':')[1].strip())

            # Check for key-value pairs at the main level
            elif re.match(r'^\s+\w+:', line):
                    key, value = line.strip().split(':', 1)
                    current_entry[key] = value.strip()


            # Detect beginning of consequence list
            elif re.match(r'^\s+-\s+date:', line):
                inside_consequence = True
                consequence = {}
                key, value = line.strip().split(':', 1)
                consequence['date'] = value.strip()
                current_entry['consequences'].join(consequence)

            # Process subsequent keys in the consequence list
            elif inside_consequence and re.match(r'^\s+(\w+):', line):
                key, value = line.strip().split(':', 1)
                current_entry['consequences'][-1][key] = value.strip()

            # Detect tags
            elif line.strip().startswith("tags:"):
                tags = line.split(':', 1)[1].strip().split()
                current_entry['tags'] = tags

    # Append the last entry
    if current_entry:
        entries.append(current_entry)

    # Open the output file to write the SQL script
    with open(output_file, 'w') as output:
        # Write the CREATE TABLE statement
        output.write("""
        --Created using misconduct_to_sql.py by PRESTON PARSONS
        --https://sirobivan.org/index.html
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
            consequences LONGTEXT,
            tags LONGTEXT
        );

        -- Insert data into the table
        INSERT INTO misconduct (person, name, allegation, description, consequences, tags) VALUES
        """)

        # Generate insert statements
        insert_statements = []
        for entry in entries:
            # Escape single quotes for SQL
            name = entry.get('name', '').replace("'", "''")
            allegation = entry.get('allegation', '').replace("'", "''")
            text = entry.get('text', '').replace("'", "''")
            consequences = '; '.join(
                [f"{c.get('date', '')}: {c.get('body', '')} - {c.get('action', '')} ({c.get('link', '')})" for c in
                 entry.get('consequences', [])]
            ).replace("'", "''")
            tags = ', '.join(entry.get('tags', [])).replace("'", "''")

            # Create the SQL insert statement for each record
            insert_statement = (
                f"({entry.get('person')}, "
                f"'{name}', "
                f"'{allegation}', "
                f"'{text}', "
                f"'{consequences}', "
                f"'{tags}')"
            )
            insert_statements.append(insert_statement)

        # Write all insert statements joined by commas and end with a semicolon
        output.write(",\n".join(insert_statements) + ";")


# Specify the input and output files
input_file = 'C:/Users/ppars/PycharmProjects/Congress_Crimes/con-crim.txt'  # Replace with your actual .txt file path
output_file = 'output_insert_statements.txt'  # Output file for SQL statements

# Generate the SQL script
txt_to_sql_insert(input_file, output_file)
print(f"SQL INSERT statements written to {output_file}")


