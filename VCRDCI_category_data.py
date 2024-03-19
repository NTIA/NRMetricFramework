# Script was run on windows.  Update spreadsheet with correct categories.
#    Currently set to "VCRDCI_1.xlsx" spreadsheet.
#    Also, print the original and truncated file list to the console.

import os
import time
import json
from json import JSONDecodeError
import pandas as pd


avi_path = "D:\\VCRDCI_matlab_data"         #replace the path in this line with any other two uncomressed dataset paths "E:\\VCRDCI_matlab_data""I:\\VCRDCI_matlab_data"


   
        
def main_loop():
    pass    
    
def main():
    #import the spreadsheet
    spreadsheet_name = 'VCRDCI_1.xlsx' #Replace the file in this line with 'VCRDCI_2.xlsx''VCRDCI_3.xlsx' when accessing drive E or I of the uncompressed dataset
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

    #first open the database register
    rain_snow = []                #create empty list
    public_safety = []            #create empty list
    entertainment = []            #create empty list
    natural_scenes = []           #create empty list
    confounding = []              #create empty list
    database_register  = 'VCRDCI_Database_register_r3.xlsx'    #databse register name
    database_register_path = 'F:\\'                            #databse register path
    register_path = os.path.join(database_register_path, database_register)   #formulate path string
    register_sheet = pd.read_excel(register_path,sheet_name = 'Video-Image Register')   #read the video-image register sheet
    for index,row in register_sheet.iterrows():                                         #iterate through rows of the spreadsheet
        if register_sheet.at[index,'Attributes'] == 'Public Safety':                    #insert identification number into attribute list
            public_safety.append(str(register_sheet.at[index,'Identification #']).zfill(6))
        elif register_sheet.at[index,'Attributes'] == 'Rain/Snow':
            rain_snow.append(str(register_sheet.at[index,'Identification #']).zfill(6))
        elif register_sheet.at[index,'Attributes'] == 'Natural Scenes':
            natural_scenes.append(str(register_sheet.at[index,'Identification #']).zfill(6))
        elif register_sheet.at[index,'Attributes'] == 'Entertainment':
            entertainment.append(str(register_sheet.at[index,'Identification #']).zfill(6))
        elif register_sheet.at[index,'Attributes'] == 'Abstract':
            confounding.append(str(register_sheet.at[index,'Identification #']).zfill(6))
    print(public_safety, rain_snow, entertainment, natural_scenes, confounding)         #print each of the lists
            
    for index,row in category_sheet.iterrows():                                         #iterate through all rows in category sheet
        file = category_sheet.at[index,'file']                                          #select file column
        file_path = file.split('\\')                                                    #split file path
        if len(file_path)<2:
            continue

        file_fields = file_path[1].split('_')                                           #split file fields
        if len(file_fields)<7:
            continue

        folder_fields = file_path[0].split('_')                                         #extract scene number
        if len(file_path)<2:
            continue
        scene_number = folder_fields[1]

        #category 1
        if file_fields[6] == 'Q0':
            category_sheet.at[index,'Category1'] = 'original'
        else:
            category_sheet.at[index,'Category1'] = 'compressed'
            
        

        #category 2 is chosen by matlab during import_dataset.m
        #category 3
        if file_fields[4] == 'av1':
            category_sheet.at[index,'Category3'] = 'av1'
        elif file_fields[4] == 'h.264':
            category_sheet.at[index,'Category3'] = 'avc'
        elif file_fields[4] == 'h.265':
            category_sheet.at[index,'Category3'] = 'hevc'

        #category 4 is the resolution that it is viewed, which is all upconverted to 1920x1080
        category_sheet.at[index,'Category4'] = 'FHD'

        #category 5 is encoding resolution
        category_sheet.at[index,'Category5'] = file_fields[5]

        #category 6 is the quality factor
        category_sheet.at[index,'Category6'] = file_fields[6]

        #category 7 is the scene number
        category_sheet.at[index,'Category7'] = scene_number

        #category 8 is scene content
        if scene_number in rain_snow:
            category_sheet.at[index,'Category8'] = 'rain/snow'
        elif scene_number in public_safety:
            category_sheet.at[index,'Category8'] = 'public safety'
        elif scene_number in entertainment:
            category_sheet.at[index,'Category8'] = 'entertainment'
        elif scene_number in natural_scenes:
            category_sheet.at[index,'Category8'] = 'natural'
        elif scene_number in confounding:
            category_sheet.at[index,'Category8'] = 'abstract'
        
        print(file_fields, category_sheet.at[index,'Category1'],
              category_sheet.at[index,'Category2'],
              category_sheet.at[index,'Category3'],
              category_sheet.at[index,'Category4'],
              category_sheet.at[index,'Category5'],
              category_sheet.at[index,'Category6'],
              category_sheet.at[index,'Category7'],
              category_sheet.at[index,'Category8'])
        
        
    #use same spreadsheet
    writer = pd.ExcelWriter(spreadsheet_path, engine='xlsxwriter')
    for sheet_label in workbook_dir.keys():
        workbook_dir[sheet_label].to_excel(writer,sheet_name=sheet_label,index=False)
    writer.save()

if __name__ == '__main__':
    main()
