# This script was run on a linux computer with netflix vmaf suite installed at the home folder.
#    Converts mp4 files of differing formats to yuv.  Python's interface to ffprobe 
#    was installed to check for files that failed to convert correctly.

import os
import time
from subprocess import CalledProcessError
from ffprobe import FFProbe
from ffprobe.exceptions import FFProbeError

path = "/media/rgrosso/Aegis_DT/ffmpeg_test_cuts"
vmaf_path = "~/vmaf"
error_check_folder = None                               # Example folder: "VCRDCI_128000_4k.from.SVT_Dnc.Prty_h.264_Original_Highest"

def original_yuv_convert(sub_path,file):
       
    if '.mp4' in file and 'Original' in file:            #select only the source video
        file_name = file.replace('.mp4','.yuv')          #formulate source yuv string
        yuv_exists = os.path.isfile(sub_path+file_name)  #test if the source yuv exists
        
        print(file_name)
              
        command = "ffmpeg -i " + sub_path + file \      #formulate command for original yuv
                  + "  -pix_fmt yuv420p -c:a copy " \
                  + sub_path + file_name
                  
        if yuv_exists == False:                         #check original yuv logical 
            os.system(command)                          #execute command 
             

 
def yuv_convert(sub_path,file,folder):
       
    if '.mp4' in file and 'fullHD' in file:                         #select upconverted files
        file_name = file.replace('.mp4','')                         #remove .mp4 tag
        yuv_exists = os.path.isfile(sub_path+file_name+".yuv")      #check if the yuv file exists for this encoding
        json_exists = os.path.isfile(sub_path+file_name+".json")    #check if the .json exists for this encoding
        print(file_name)
               
        #only use when dealing with errors in the .yuv files    
        if yuv_exists == True:                                      #check if yuv logical is true
        	os.remove(sub_path+file_name+".yuv")                #remove the yuv, generate each yuv when needed
        	yuv_exists = False
        
        #original yuv check	
        original_file = folder + '.mp4'                             #check if the mp4 encoding for the source video is present
        original_file_yuv = folder + ".yuv"                         #check if the yuv for the source video is included

        if os.path.isfile(sub_path+"/"+original_file_yuv) == False and json_exists == False:       #check if original yuv is present, if not create it
        	print('original YUV converting')
        	
        	original_yuv_convert(sub_path, original_file) #call the function to create the source yuv
        
        
        	
        command = "ffmpeg -i " + sub_path + file \            #formulate yuv conversion command string
                  + "  -pix_fmt yuv420p -c:a copy " \
                  + sub_path + file_name + ".yuv"
                  
                  
                  
        if yuv_exists == False and json_exists == False:      #check that the json is absent and the yuv does not exist
            os.system(command)                                #send the command to the os for execution
             
            
                                  
def vmaf_convert(sub_path,file,folder):
    
    
    if ('.yuv' in file or '.mp4' in file) and 'fullHD' in file:                               #select files that could be converted
        
        if '.yuv' in file:                                                                    #test if file is yuv
            file_name = file.replace('.yuv','')
        elif '.mp4' in file:
            file_name = file.replace('.mp4','')                                               #test if file is mp4
        distorted_exists = os.path.isfile(sub_path+file_name+".yuv")                          #check for yuv encoding of distorted file
        original_file = sub_path + folder + '.yuv'                                            #source file path
        original_exists = os.path.isfile(original_file)                                       #check for yuv encoding of source video
        json_exists = os.path.isfile(sub_path+file_name+".json")                              #check for json file 
        
        command = "cd '" + vmaf_path + "'; \
                   PYTHONPATH=python '" + vmaf_path + "/python/vmaf/script/run_vmaf.py' \
                   yuv420p 1920 1080 '" + original_file + "' '" + sub_path + file_name \
                   + ".yuv' --out-fmt json --out-file '" + sub_path + file_name + ".json'"    #formulate command string to call vmaf according to vmaf github
        
        if distorted_exists == True and original_exists == True and json_exists == False:     #check if the file needs rating
            try:
                os.system(command)                                                            #send the command to the os for execution
            except as e:                print(e)
                os.remove(sub_path+file_name+".yuv")                                          #handle errors, delete yuv file
            print(command)
            time.sleep(1)
        	
            	
def delete_yuv(sub_path,file):
    
    if 'fullHD.mp4' in file or 'fullHD.yuv' in file:                #select files for deletion
        
        file_name = file                                            #set new variable (for some reason it errors without this step
        file_name = file_name.replace('.mp4','')                    #remove file type tag
        file_name = file_name.replace('.yuv','')                    #remove file type tag
        
        
        json_exists = os.path.isfile(sub_path+file_name+".json")    #check if an associated json file exists
        yuv_exists = os.path.isfile(sub_path+file_name+".yuv")      #check if yuv exists
        
        if json_exists == True and yuv_exists == True:              #logical check to make sure the yuv can be deleted
            print(sub_path+file)
            os.remove(sub_path+file_name+".yuv")                    #remove the yuv file

def error_check(sub_path,folder):

     files = os.listdir(sub_path)                                     #list all items in sub_path
     original_file = folder + '.mp4'                                  #fomrulate original file string
     command = path + "/" + folder + "/" + original_file              #formulate command string
     
     metadata = FFProbe(command)                                      #extract metadata
     
     for stream in metadata.streams:                                  #iterate through streams in file
        if stream.is_video():                                         #if the stream is a video stream
             print('Original Stream contains {} frames. '.format(stream.frames()) + folder)
             original_file_frames = stream.frames()                   #set the original stream frame count
             
     for file in files:                                               #iterate through files
         if '.mp4' in file and 'Original' not in file:                #select source files
             min_file_size = 2000                                     #set min file size 2kB
           

             #ffprobe error check
             command = sub_path + '/' + file                          #formulate command string
           
             metadata=FFProbe(command)                                #probe metadata
             if os.path.getsize(command) < min_file_size:             #compare file size
                 print(file + '   bad copy, deleting')
                 os.remove(command)                                   #delete file
                 
             if len(metadata.streams) == 0:                           #if there are no streams, file is bad
                     print(file + '   bad copy, deleting')
                     os.remove(command)                               #delete file
                     
             for stream in metadata.streams:                          #iterate through streams
                 try:
                     if stream.is_video():                            #if the stream is a video
                         #print(file + ' Stream contains {} frames.'.format(stream.frames()))
                         if stream.frames() < original_file_frames:   #compare number of frames
                             print(file + '   bad copy, deleting')
                             os.remove(command)                       #remove file if less frames than original
                 except FFProbeError as e:                            #catch exceptions
                     print(e)
                     os.remove(command)                               #delete file if it throws an error

def main():
    
    folders = os.listdir(path)                         #list all items in "path"
    
    for folder in folders:                             #iterate through all items in "folders"
        
        sub_path = path + "/" + folder + "/"           #create sub_path string
               
        if os.path.isdir(sub_path) == True:            #check if sub_path exists
            files = os.listdir(sub_path)               #list all files in sub_path
            file_list = files                          #set new variable for list of files
            for file in file_list:                     #iterate through file_list
                yuv_convert(sub_path,file,folder)      #call yuv_convert function
                
                vmaf_convert(sub_path,file,folder)     #call the vmaf rate function
                
                	
                delete_yuv(sub_path,file)              #call the function to delete associated yuv files, does not delete source yuv
        else:
           print('bad directory path')
        
        
    #error check all the folders 
    for folder in folders:                             #iterate through all items in "folders"
       sub_path = path + "/" + folder                  #formulate sub path
       if os.path.isdir(sub_path):                     #check if sub path exists
           error_check(sub_path,folder)                #call error check function
    
    
    #error check one folder
    if not error_check_folder is None:
        sub_path = path + "/" + error_check_folder
        if os.path.isdir(sub_path):
            error_check(sub_path, folder)
         
if __name__ == "__main__":
    while True:   #continuously loop until killed
        main()    #call main function
    

