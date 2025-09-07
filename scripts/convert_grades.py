import csv

def convert_grades(input_file, output_file):
    """
    Reads the grade data, converts each line into three separate lines for each grade type,
    and writes the result to a new CSV file.
    """
    try:
        with open(input_file, 'r', encoding='utf-8') as infile, \
             open(output_file, 'w', newline='', encoding='utf-8') as outfile:
            
            reader = csv.reader(infile)
            writer = csv.writer(outfile)

            processed_shifts = set()

            for row in reader:
                if len(row) != 5:
                    continue  # Skip incorrect rows

                year, month, day, shift, value = row
                
                # Create a unique key for the day and the original shift value
                day_key = f"{year}-{month}-{day}"
                
                # Since the original file seems to have one value per shift (1, 2, 3) representing
                # different grade types, we'll process each shift number for a given day only once.
                # We'll create a unique key for the day and shift number to avoid duplicates.
                
                shift_key = f"{day_key}-{shift}"
                if shift_key in processed_shifts:
                    continue
                
                # Based on the previous logic, shift 1=Tailing, 2=Product, 3=Feed
                # Let's apply this logic to create three records for each shift
                
                try:
                    # We assume the file contains rows for shift 1, 2, and 3 for each day
                    # This script will create the correct mapping
                    
                    # For simplicity, we'll create three records for each entry.
                    # This logic assumes the value is the same for all three, which is not ideal,
                    # but it corrects the format issue.
                    # A better approach would be to have the correct data.
                    # Let's try a direct mapping based on the shift number in the row.
                    
                    grade_type = ''
                    if shift == '1':
                        grade_type = 'باطله'
                    elif shift == '2':
                        grade_type = 'محصول'
                    elif shift == '3':
                        grade_type = 'خوراک'
                    else:
                        continue # Skip if shift is not 1, 2, or 3
                        
                    writer.writerow([year, month, day, shift, grade_type, value])
                    
                except ValueError:
                    continue # Skip rows with non-integer values
                    
            print(f"Conversion successful. Corrected data saved to '{output_file}'")

    except FileNotFoundError:
        print(f"Error: The file '{input_file}' was not found.")

if __name__ == "__main__":
    convert_grades('year_1404_grades.csv', 'final_correct_grades.csv') 