
# this script will open an NRMetricFramework-dev dataset spreadsheet and input the raw json files
# into the dataset and save the excel file with the same name.

import os
import time
import json
from json import JSONDecodeError
import pandas as pd


avi_path = "I:\\VCRDCI_matlab_data"
raw_json_path = "D:\\VCRDCI_dataset"

   
    
def main():
    
    #import the spreadsheet
    spreadsheet_name = 'VCRDCI_3.xlsx'     #can be VCRDCI_1.xlsx or VCRDCI_2.xlsx
    spreadsheet_path = os.path.join(avi_path, spreadsheet_name)                                         #formulate path to spreadsheet in question
    category_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Category')                            #each sheet in a workbook is imported as a separate variable
    category_list_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Category_list')                  #import Category_list
    category_name_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Category_name')                  #import Category_name
    mos_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'MOS')                                      #import MOS
    read_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Read')                                    #import read
    format_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Format')                                #import format
    dataset_sheet = pd.read_excel(spreadsheet_path,sheet_name = 'Dataset')                              #import dataset
    #create dictionary of excel sheets that we will call a workbook
    workbook_dir = {'Category':category_sheet , 'Category_list':category_list_sheet, 'Category_name':category_name_sheet, \  #create a dictionary of the sheets in the workbook
                    'MOS':mos_sheet,'Read':read_sheet, 'Format':format_sheet, 'Dataset':dataset_sheet} 

    #only need to change mos sheet, iterate through all rows
    for index,row in mos_sheet.iterrows():

        #formulate path of json file containing vmaf rating
        json_file_name = row['file'].replace('.avi', '.json')
        json_path = os.path.join(raw_json_path, json_file_name)
        
        #check if the file exists, and if it does, open it, read it and insert the vmaf rating into the mos spreadsheet structure
        if os.path.isfile(json_path) == True:
            try:
                f = open(json_path)
                data = json.load(f)
                raw_vmaf = data['aggregate']['VMAF_score']
                #mos_sheet.at[index,'raw_mos'] = raw_vmaf
                # f(x) = k*x + b            #formula to calculate scaling of MOS values to ACR
                # x = 0, f(x) = 1
                # k = f(x)/ x + b/x
                # x = 100, f(x) = 5
                # k = 5/100 + 1/100 = 4/100
                mos_sheet.at[index,'mos'] = (raw_vmaf * (4/100)) + 1
                mos_sheet.at[index,'raw_mos'] = raw_vmaf
                
            except JSONDecodeError as e:
                print(e,index,json_file_name)
                mos_sheet.at[index,'mos'] = 'NaN'
                mos_sheet.at[index,'raw_mos'] = 'NaN'
                
        else:
            # if the file doesnt exist, put a NaN in the mos sheet structure
            mos_sheet.at[index,'raw_mos'] = 'NaN'
            mos_sheet.at[index,'mos'] = 'NaN'

    #use same spreadsheet        
          
    writer = pd.ExcelWriter(spreadsheet_path, engine='xlsxwriter')                    #instance of ExcelWriter
    for sheet_label in workbook_dir.keys():                                           #iterate through all sheets in the workbook
        workbook_dir[sheet_label].to_excel(writer,sheet_name=sheet_label,index=False)
    writer.save()                                                                     #save the file
if __name__ == '__main__':
    main()
