# Remove all files in "avi_path" that are not part of current "VCRDCI_3.xlsx" spreadsheet.  Also, print the original and truncated file list to the console.

import os
import time
import json
from json import JSONDecodeError
import pandas as pd


avi_path = "I:\\VCRDCI_matlab_data"
raw_json_path = "D:\\VCRDCI_dataset"


  
    
def main():
    
    #import the spreadsheet
    spreadsheet_name = 'VCRDCI_3.xlsx'
    spreadsheet_path = os.path.join(avi_path, spreadsheet_name)
    category_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Category')
    category_list_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Category_list')
    category_name_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Category_name')
    mos_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'MOS')
    read_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Read')
    format_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Format')
    dataset_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Dataset')
    #create dictionary of excel sheets that we will call a workbook
    workbook_dir = {'Category':category_sheet , 'Category_list':category_list_sheet, 'Category_name':category_name_sheet, \
                    'MOS':mos_sheet,'Read':read_sheet, 'Format':format_sheet, 'Dataset':dataset_sheet} 

    all_files = []
    folders = os.listdir(avi_path)
    for folder in folders:
        sub_path = avi_path + "\\" + folder
        if os.path.isdir(sub_path) == True:
            files = os.listdir(sub_path)
            for file in files:
                file_sub_path = folder + "\\" + file
                all_files.append(file_sub_path)
    print(all_files)
    
    #only need to view mos sheet, iterate through all rows
    for index,row in mos_sheet.iterrows():

        #formulate path of json file containing vmaf rating
        json_file_name = row['file'].replace('.avi', '.json')
        json_path = os.path.join(raw_json_path, json_file_name)
        
        #print(scene_number)
        try:
            print(row['file'])
            
            all_files.remove(row['file'])
        except ValueError as e:
            print(json_path,"extra or missing file")
            print(e)
        
        
    print(all_files)  #print the files that are absent from the matlab dataset. this means the avi file was not opened, not readable or corrupt
                      #check matlab dataset for all vmaf ratings by searching for NaN in the mos sheet. This will highlight any straggling errors 
    
    
if __name__ == '__main__':
    main()
