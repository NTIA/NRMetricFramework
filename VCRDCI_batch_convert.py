#!/usr/bin/env python3

#VCRDCI batch convert is a single threaded
#automated conversion tool for the VCRDCI dataset written in python

#this script will take all videos in all folders located in "path"
#and convert them by calling ffmpeg with a system command.

#this script was run on windows, which requires the double \\
#when specifying the path.
#The converted videos are placed into a location called "dump_path"

#the script will check for errors using ffprobe,
#then convert the files to AVI for matlab uptake
#and will place the uncompressed files in the "avi_file_path"

#to properly run, the machine calling this script must have access to ffmpeg in the path,
#or must be running this script from the same path as ffmpeg.exe
#the python module FFprobe is used in the error checking algorithm

import time
import json
from json import JSONDecodeError
import os
from ffprobe import FFProbe
from ffprobe.exceptions import FFProbeError


path = "C:\\Users\\rgrosso\\Documents\\Media\\VCRDCI_source_video" #path to source video

dump_path = "D:\\VCRDCI_dataset" #path to dump the distorted/fullHD files

avi_file_path_1 = 'D:\\VCRDCI_matlab_data' #path to drive hosting uncompressed dataset
avi_file_path_2 = 'E:\VCRDCI_matlab_data' #path to drive hosting uncompressed dataset
avi_file_path_3 = 'I:\\VCRDCI_matlab_data' #path to drive hosting uncompressed dataset

res_list = ['1920x1080', '1280x720', \              #list of resolutions used in the VCRDCI dataset. 
            '960x540', '768x432', '640x360', \      #resolutions can be added or removed when generating further data
            '512x288', '384x216', '320x180']        

crf_list =  ['0', '18', '19', '20', '22', \         #list of constant rate factors used in the VCRDCI dataset
            '25', '27', '30', '35', '40']           #CRF valuse can be added or removed when generating further data

encoder_list = ['h.264', 'h.265', 'av1']            #list of encoders used in VCRDCI dataset

def dump_file(crf, res, encoding, file_fields):

    file_num = file_fields[1][:3]  #seperate the file number from file_fields list
    
    if encoding == 'h.264':        #options associated with h.264 encoding
        encoding_field = '0'
        ffmpeg_setting = 'libx264'
        if crf == '0':
            options = '-profile:v high444 '
        else:
            options = ''           
    elif encoding == 'h.265':     #options associated with h.265 encoding
        encoding_field = '1'
        ffmpeg_setting = 'libx265'
        options = ''
    elif encoding == 'av1':       #options associated with av1 encoding
        encoding_field = '2'
        ffmpeg_setting = 'libaom-av1'
        options = '-cpu-used 8 -threads 8 '
    else:
        encoding_field = '3'      #catch all directing the encoder to h.264 (not used)
        ffmpeg_setting = 'libx264'
        options = ''

    
    if crf == '0':                #converting the CRF number to naming convention
        crf_field = '0'
    elif crf == '18':
        crf_field = '1'
    elif crf == '19':
        crf_field = '2'
    elif crf == '20':
        crf_field = '3'
    elif crf == '22':
        crf_field = '4'
    elif crf == '25':
        crf_field = '5'
    elif crf == '27':
        crf_field = '6'
    elif crf == '30':
        crf_field = '7'
    elif crf == '35':
        crf_field = '8'
    elif crf == '40':
        crf_field = '9'

    if res == '1920x1080':   #converting resoltuion to naming convention
        res_field = '0'
    elif res == '1280x720':
        res_field = '1'
    elif res == '960x540':
        res_field = '2'
    elif res == '768x432':
        res_field = '3'
    elif res == '640x360':
        res_field = '4'
    elif res == '512x288':
        res_field = '5'
    elif res == '384x216':
        res_field = '6'
    elif res == '320x180':
        res_field = '7'

    
    dump_file_string = file_fields[0] + "_" \
                       + file_num + encoding_field + res_field + crf_field \
                       + "_" + file_fields[2] \
                       + "_" + file_fields[3] \
                       + "_" + encoding \
                       + "_" + res \
                       + "_Q" + crf                      #formulating the file string from the options
    
    return dump_file_string, ffmpeg_setting, options     #return dump file string, ffmpeg settings and ffpmeg options



def scene_matrix(folder):
        
    files = os.listdir(path + "\\" + folder)  #list all files in the directory "folder" in the path
    
    for file in files:                        #iterate through all items in "files" list
        if '.mp4' in file:                    #check if "file" is an mp4
            
            file_name = file.replace('.mp4','')   #extract the file name without ".mp4"
            file_fields = file_name.split('_')    #create a list of the file fields seperated by an underscore
            
            
            if os.path.exists(dump_path + "\\" + file_name) == False:          #check for the container directory in dump_path
                
                os.mkdir(dump_path + "\\" + file_name)                         #create the container directory if absent
            
            if os.path.isfile(dump_path + "\\" + file_name + "\\" + file) == False:        #check for the source file in the container folder
                
                command = 'copy \"' + path +"\\"+ folder + "\\" +file + "\" \"" + dump_path +"\\"+ file_name + "\\" + file +"\""
                
                os.system(command)   #copy the original source file to the container folder
                
            
            for res in res_list:      #iterate through all resolutions
                for crf in crf_list:  #iterate through all CRF values
                    for encoding in encoder_list:  #iterate through encoder list
                        dump_file_name, ffmpeg_setting, options = dump_file(crf, res, encoding, file_fields)   #forumulate distorted file in accordance with VCRDCI naming convention
                        command = "ffmpeg -i \"" + path + "\\" + folder + "\\" + file \                        #formulate the command string
                                  + "\" -c:v " + ffmpeg_setting + " -pix_fmt yuv420p " + options \
                                  + "-crf " + crf + " -vf scale=" + res + " -c:a copy \"" \
                                  + dump_path + "\\" + file_name + "\\" + dump_file_name + ".mp4\""
                        
                        file_exists = os.path.isfile(dump_path + "\\" + file_name + "\\" + dump_file_name + ".mp4")    #check if the dump file exists
                        
                        if file_exists == False:
                            os.system(command)    #send the command to the os
                            
    

def fullHD_dump_file(file_fields):

    encoding = file_fields[4]     #get the encoding value from file_fields

    if encoding == 'h.264':       #set ffmpeg settings based on h.264
       
        ffmpeg_setting = 'libx264'
        options = ''
    elif encoding == 'h.265':     #set ffmpeg settings based on h.265
        
        ffmpeg_setting = 'libx265' 
        options = ''
    elif encoding == 'av1':       #set ffmpeg settings based on av1
        
        ffmpeg_setting = 'libaom-av1'
        options = '-cpu-used 8 -threads 8 '
    else:                        #catchall ffmpeg settings based on h.264
        
        ffmpeg_setting = 'libx264'
        options = ''

    return ffmpeg_setting, options   #return settings and options


def fullHD_convert(sub_path):

       
    files = os.listdir(sub_path)     #list all files in sub_path
    
    for file in files:              #iterate through all files in "files" list
        if '.mp4' in file and 'fullHD' not in file and 'Original' not in file:     #select distorted videos
            file_name = file.replace('.mp4','')                                    #extract the file name without .mp4 tag
            
            file_fields = file_name.split('_')                                     #extract file fields variable
            
        
            ffmpeg_setting, options = fullHD_dump_file(file_fields)                #formulate ffmpeg settings
            command = "ffmpeg -i \"" + sub_path + "\\" + file \                    #formulate ffmpeg command string
                      + "\" -c:v " + ffmpeg_setting + " -pix_fmt yuv420p " + options \
                      + "-crf 0 -vf scale=1920x1080 -c:a copy \"" \
                      + sub_path + "\\" + file_name + "_fullHD.mp4\""
            file_exists = os.path.isfile(sub_path + "\\" + file_name + "_fullHD.mp4")    #logical variable to check if converted file exists
            if  file_exists == False:                                                    #check logical variable
                 os.system(command)       #send command string to os


def error_check(check_path,sub_path,folder):
    #get original file frames
    files = os.listdir(sub_path)  #list files in sub_path
    min_file_size = 2000          #min file size 2 kB, anything smaller is likely encoded incorrectly
    original_file = folder + '.mp4'  #source file string formulated from the folder string
    
    command = check_path + '\\' + folder + '\\' + original_file  #formulate original file path string
    
    metadata=FFProbe(command)  #get metadata of original file

    for stream in metadata.streams:   #iterate through streams in original file
        if stream.is_video():         #select streams that are video
             print('Original Stream contains {} frames. '.format(stream.frames()) + folder)  #print number of frames in original video
             original_file_frames = stream.frames()                                          #set the variable to compare other encodings against
             
    for file in files:                              #iterate through files in sub_path
        if '.mp4' in file and 'Original' not in file:    #select all .mp4 videos for error checking
                      
           #check for file size
           if os.path.getsize(sub_path + "\\" + file) >=  min_file_size:  #if the file size is greater than min_file_size
               pass                                                       #do nothing
           else:
               os.remove(sub_path + "\\" + file)                            #remove the file
               print(file)                                                  #print the deleted file

           #ffprobe error check
           command = sub_path + '\\' + file                  #formulate file path
           
           metadata=FFProbe(command)                         #probe the file
           
           if len(metadata.streams) == 0:                    #if no meta data comes up, delete the file
               print(file + '   bad copy, deleting')
               os.remove(sub_path + "\\" + file)
           for stream in metadata.streams:                   #iterate through streams and check for equal number of frames
               try:
                   if stream.is_video():
                       
                       if stream.frames() < original_file_frames:
                           print(file + '   bad copy, deleting')
                           os.remove(sub_path + "\\" + file)       #delete the bad file
               except FFProbeError as e:                            #catch other FFprobe errors and delete the file if any errors
                   print(e)
                   os.remove(sub_path + "\\" + file)      
                   

           
            
def convert_avi(avi_dump_path,sub_path):
    

    if os.path.isdir(avi_dump_path) == False:        #check if the dump path exists
        os.mkdir(avi_dump_path)                      #create the avi_dump path
        
    files = os.listdir(sub_path)                     #list files in sub_path
    
    for file in files:                               #iterate through all files
        if '.mp4' in file and 'fullHD' in file and 'Original' not in file:        #select fullHD files to convert
            file_name = file.replace('.mp4','')                                   #remove .mp4 tag
            
            #matlab wants uyvy422 encoded avi
            command = "ffmpeg -i \"" + sub_path + "\\" + file \                   #formulate .avi encoding command
                      + "\" -c:v rawvideo -pix_fmt uyvy422 -vtag uyvy " \
                      + "-c:a copy \"" \
                      + avi_dump_path + "\\" + file_name + ".avi\""
            file_exists = os.path.isfile(avi_dump_path + "\\" + file_name + ".avi")  #check if .avi exists
            if  file_exists == False:                                                #check logical variable
                try:                                                                 #try block
                    os.system(command)                                               #send command variable to os
                    
                except Exception as e:                                               #handle all exceptions
                    print(e)
    

def error_check_avi(check_path,sub_path,folder):
       
    min_file_size = 2000                  #set minimum file size to 2kb
    files = os.listdir(sub_path)          #list all files in sub_path
        
    for file in files:                    #iterate through all files
        
            
        if '.avi' in file and 'Original' not in file:        #select .avi files
           file_name = file.replace('.avi','')
           
           #check for file size
           if os.path.getsize(sub_path + "\\" + file) >=  min_file_size:   #check file size
               pass                                                        #do nothing if the file is acceptable
           else:
               os.remove(sub_path + "\\" + file)                           #delete if its a bad encoding
               print(file)
    

                            
def json_check(check_path,sub_path,folder):       
    files = os.listdir(sub_path)     #list all files in sub_path
    matrix_list = []                 #create empty list
    for encoder in encoder_list:     #iterate through encoder list
        for res in res_list:         #iterate through resolution list
            for crf in crf_list:     #iterate through crf list
            
                file_res = str(encoder)+"_"+str(res) + "_Q" + str(crf)        #create entry in matrix that is unique to each encoder, resolution, crf value
                matrix_list.append(file_res)                                  #add this unique string to the matrix
    #print(matrix_list)                                                       #debugging command, uncomment to see matrix_list variable
    absent_json_list = []                                                     #create empty list
    
    for file in files:                                                        #iterate through files
        if 'fullHD.mp4' in file:                                              #select mp4s with the fullHD tag
            file_name = file.replace('.mp4','')                               #remove the .mp4 tag
            file_fields = file_name.split("_")                                #split the file fields
            file_res = str(file_fields[4]) + "_" + str(file_fields[5]) + "_" + str(file_fields[6])     #formulate the files appropriate file_res string
            
            json_exists = os.path.isfile(sub_path+'\\'+file_name+'.json')      #check for the associated json file
            
            if json_exists == True:                                            #check for assocaited json file
                try:
                    f = open(sub_path+'\\'+file_name+'.json','r')              #open the json file
                    data = json.load(f)                                        #load json data
                    raw_vmaf = data['aggregate']['VMAF_score']                 #get the mean vmaf score
                    
                except JSONDecodeError as e:                                   #handle errors
                    f.close()                                                  #close the json file
                    os.remove(sub_path+'\\'+file_name+'.json')                 #delete the json file
                    print(e, "deleting:", file_name+'.json')
                    absent_json_list.append(file)                              #add the file to the absent json list
            
                
            else:
                absent_json_list.append(file)                               #if the json file does not exist, add it to the absentee list       
            
            
            try:
                matrix_list.remove(file_res)                                 #remove file from the absent encoding list, showing there was an encoding but a bad or absent json file
            except ValueError as e:                                          #handle errors. if there is no file in the list it usually means there was an extra file
                print(file_res,"extra or missing file")
                print(e)
                time.sleep(0.5)
            
                
               
    for item in absent_json_list:                                           #iterate through the absent json list and print the absent json files
        print("absent json:",item)
    for item in matrix_list:                                                #iterate through matrix list and print the absent matrix encodings
        print("absent encoding:",item)

        
def main_loop():
    #the main loop will perform the following functions:
    #create the distorted scene matrix with all combinations of encoder, CRF and resolutions
    #re scale the distorted videos to 1920x1080 with the respective encoder
    #error check the distorted videos and re-scaled versions, will delete videos that have errors
    #error check can only handle files that are readable
    #        if there are files that are corrupted but still present on the file system, 
    #        the script will handle the exception but will be found later when the JSON is absent
    #create .avi uncompressed files in the appropriate drive
    #error check the .avi files by looking at size, metadata for .avi files do not show up in FFprobe
    #check for absent or corrupt jsons
    
    
    


    
    #create distorted version
    folders = os.listdir(path) # lists the folders in the path
    
    for folder in folders:  #cycle through folders
        if os.path.isdir(path + "\\" + folder) == True:  #check the item in "folder" is a directory
            scene_matrix(folder)                         #call the distortion function
            

    #convert distorted version back to 1920x1080
    folders = os.listdir(dump_path)                      #list all the folders in dump_path
    for folder in folders:                               #iterate through folders in dump_path
        sub_path = dump_path + "\\" + folder             #create sub_path string
        
        if os.path.isdir(sub_path) == True:              #check the sub_path exists
           fullHD_convert(sub_path)               #call the fullHD_convert function
           

        
    #check for errors in the distortion/upconvert process
    folders = os.listdir(dump_path)                      #list all the folders in dump_path
    
    for folder in folders:                               #iterate through folders in dump_path
        sub_path = dump_path + "\\" + folder
                                                         
        if os.path.isdir(sub_path) == True:              #check if sub_path exists
            error_check(dump_path,sub_path,folder)       #call error check function

                
    # create avi
 
    if os.path.isdir(dump_path):                         #check dump_path exists
        folders = os.listdir(dump_path)                  #list folders in dump_path
        
        for folder in folders:                           #iterate through folders
            
            sub_path = dump_path + "\\" + folder         #formulate sub_path
                        
            if os.path.isdir(sub_path) == True:         #if sub_path exists
                file_fields = folder.split('_')         #split up folder name
                
                file_num = int(file_fields[1])                   #convert the scene number to an integer
                if file_num <= 45000:                            #select scenes with identifying number less than or equal to 045000
                    current_avi_path = avi_file_path_1           #set appropriate avi drive
                elif file_num > 45000 and file_num <= 100000:    #select scenes with identifying number between 46000 and 100000
                    current_avi_path = avi_file_path_2           #set appropriate avi drive
                elif file_num > 100000:                          #select scenes with identifying number greater than 100000
                    current_avi_path = avi_file_path_3           #set appropriate avi drive
                else:
                    current_avi_path = avi_file_path_1
                    
                avi_dump_path = current_avi_path + '\\' + folder  #set avi dump path
                
                convert_avi(avi_dump_path,sub_path)  #call the avi_conversion function

    #check for errors in avi path
    avi_path_list = [avi_file_path_1,avi_file_path_2,avi_file_path_3]    #list of all avi paths
    for avi_file_path in avi_path_list:                                  #iterate through all avi paths
        
        folders = os.listdir(avi_file_path)                              #list the folders in the current path
    
        for folder in folders:                                           #iterate through folders
            
            sub_path = avi_file_path + "\\" + folder                    #fomulate sub_path
            
            if os.path.isdir(sub_path) == True:                         #check if sub_path exists
                
                error_check_avi(avi_file_path,sub_path,folder)          #call the error check avi function


    #check fo absent or corrupt jsons
    folders = os.listdir(dump_path)                                  #list all folders in dump path  
                                                                     #note: .json files need to be located in respective folders in dump_path
    for folder in folders:                                           #iterate through folders
        sub_path = dump_path + "\\" + folder                       #formulate sub_path
        print("Checking:", sub_path, " for jsons")                   #print statement
        if os.path.isdir(sub_path) == True:                          #check of sub_path exists
            
            json_check(remote_path,sub_path,folder)                  #call the json_check function


        
        
    
def main():
    while 1:                    #loop over all functions until the process is killed by the user
        try:
            main_loop()         #enter main loop
        except OSError as e:    #handle any OS errors
            print(e)
        print('end loop')
        time.sleep(10)
        
    
if __name__ == '__main__':
    main()
