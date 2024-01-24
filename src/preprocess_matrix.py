import csv
import jsonlines

DATA_DIR_PATH = "/n/data2/hms/dbmi/beamlab/cindy/nch_rop/data/processed/"

# convert raw windowed data into dictionary
"""
data_dict structure:
{(ENC_ID, WINDOW): {'HR': {'values': [90, 90, ..., 90], 'times': ["Datetime", ..., "Datetime"]},
                    'RR': {'values': [89.6, 90.1, ..., 89.7], 'times': ["Datetime", ..., "Datetime"]},
                     ..., 
                    'SpO2': {'values': [89.3, ..., 89.4], 'times': ["Datetime", ..., "Datetime"]}
                    },
 (ENC_ID, WINDOW): {..}
}
"""
data_dict = {}
# iterate line by line through windows CSV: ENC_ID, WINDOW, TIME, SUBLABEL, VALUE
with open(DATA_DIR_PATH + "enc_24h_windows.csv", 'r') as file:
    reader = csv.DictReader(file)
    for i, row in enumerate(reader):
        key = (int(row['ENC_ID']), int(row['WINDOW']))
        # renaming for convenience
        if row['SUBLABEL'] == 'SpO₂':
            sublabel = "SpO2"
        elif row['SUBLABEL'] == 'Pulse (SpO₂)':
            sublabel = "Pulse"
        else:
            sublabel = row['SUBLABEL']
        value = float(row['VALUE'])
        time = row['TIME']

        if key not in data_dict:
            data_dict[key] = {}

        if sublabel not in data_dict[key]:
            data_dict[key][sublabel] = {'values': [], 'times': []}
        # appending to dictionary values/times from row
        data_dict[key][sublabel]['values'].append(value)
        data_dict[key][sublabel]['times'].append(time)

"""
Saving values and times data to separate JSONL files
Example of values:
{"ENC_ID": 572839292, 
 "WINDOW": 1, 
 "HR": [158.0, 158.0, ..., 158.0], 
 "RR": [43.0, 43.0, ..., 40.0], 
 ...,
 "SpO2": [[95.2, 95.1, ..., 94.9]
}
{"ENC_ID": ....}
"""
values_file_path = DATA_DIR_PATH + 'enc24hw_values.jsonl'
times_file_path = DATA_DIR_PATH + 'enc24hw_times.jsonl'

# writing values to one file
with jsonlines.open(values_file_path, mode='w') as writer:
    for key, sublabels in data_dict.items():
        enc_id, window = key
        values_record = {'ENC_ID': enc_id, 'WINDOW': window}
        for sublabel, data in sublabels.items():
            values_record[sublabel] = data['values']
        writer.write(values_record)

# writing times to another file
with jsonlines.open(times_file_path, mode='w') as writer:
    for key, sublabels in data_dict.items():
        enc_id, window = key
        times_record = {'ENC_ID': enc_id, 'WINDOW': window}
        for sublabel, data in sublabels.items():
            times_record[sublabel + '_times'] = data['times']
        writer.write(times_record)

"""
Saving files from data_dict to csv format standardized to 86,400 size; did separate for values/times
Example of values:
[[ENC_ID,WINDOW,SUBLABEL,VALUE0,VALUE1, ..., VALUE86400], ...]
"""
max_size = 86400
# saving for values
output_file_path = DATA_DIR_PATH + 'enc24hw_values.csv'
with open(output_file_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)

    # headers
    writer.writerow(['ENC_ID', 'WINDOW', 'SUBLABEL'] + ['VALUE' + str(i) for i in range(max_size)])

    for (enc_id, window), window_data in data_dict.items():
        print(enc_id, window)
        for sublabel, data in window_data.items():
            horiz = data['values']
            horiz += [0] * (max_size - len(horiz))
            row = [enc_id, window, sublabel] + horiz[:max_size]
            writer.writerow(row)
# saving for times
output_file_path = DATA_DIR_PATH + 'enc24hw_times.csv'
with open(output_file_path, mode='w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)

    # headers
    writer.writerow(['ENC_ID', 'WINDOW', 'SUBLABEL'] + ['TIME' + str(i) for i in range(max_size)])

    for (enc_id, window), window_data in data_dict.items():
        print(enc_id, window)
        for sublabel, data in window_data.items():
            horiz = data['times']
            horiz += [0] * (max_size - len(horiz))
            row = [enc_id, window, sublabel] + horiz[:max_size]
            writer.writerow(row)
