############################################################################################
# Program Name : Confidence Interval Calculator / Grapher
# Description  : Displays confidence intervals from actual MOS values and calculated 
#                   statistics.  Made from a a matlab version by a video quality researcher
#                   in germany.
############################################################################################

import os
import sys
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy
import scipy.io

# Input Value Files and Fields
MOSFileNameList     = []
MOSFieldNameList    = []
NRParsFileNameList  = []
NRParsFieldNameList = []
NRParsMOSCount      =  0

GraphSaveFileName =    ""
IsVerbose         = False

# Global field values
MetricName = ""
MOSList    = []
NRParsList = []

# Main
#   Plot the confidence interval (CI) of an NR parameter by MOS values
# SYNTAX
#   python ci_calc.py -m iqa_camera.mat ccriq_dataset blur.mat 10_percent
# SEMANTICS
#   Read values and run ci_calc algorithm. Please see ci_calc
#   description or documentation for extra detail on f output graph
#   and output parameters.
#
# Input Parameters:
#   mosFileName     Input mos filename(s)
#   mosFieldName    MOS filename's field name
#   nrParsFileName  Input NR Parameter's filename(s)
#   nrParsFieldName NR Parameter's field name
##
# Output Parameters
#   ideal_ci = the ideal confidence interval
#   practial_ci = the practical confidence interval
#
# Constraints:
#   All datasets are weighted equally.
#   The MOSs must range from 1 to 5. 
#
def Main():
    # sys.argv = [ sys.argv[0], "-m", "iqa_camera.mat", "ccriq_dataset", "blur.mat", "10_percent" ]

    # Parse commandline arguments
    parse_command_arguments(sys.argv)

    read_mos_and_nrpars()

# Main
#   Parse command arguments
# SYNTAX
#   parse_command_arguments([ "-help" ])
# SEMANTICS
#   Parses input filenames and fields.  And, prints any format errors.
#
# Input Parameters:
#   argvList: Command line arguments
##
# Output Parameters
#   MOSFileNameList     Input mos filename(s)
#   MOSFieldNameList    MOS filename's field name
#   NRParsFileNameList  Input NR Parameter's filename(s)
#   NRParsFieldNameList NR Parameter's field name
#
def parse_command_arguments(argvList):
    # Global vars
    global MOSFileNameList
    global MOSFieldNameList
    global NRParsFileNameList
    global NRParsFieldNameList
    global NRParsMOSCount
    global GraphSaveFileName
    global IsVerbose

    # Clear data
    MOSFileNameList     =    []
    MOSFieldNameList    =    []
    NRParsFileNameList  =    []
    NRParsFieldNameList =    []
    NRParsMOSCount      =     0
    GraphSaveFileName   =    ""
    IsVerbose           = False

    # Parse arguments
    if len(argvList)<=1:
        argvList = [ argvList[0] if len(argvList)>0 else "", "-h" ]

    argvListCount = len(argvList)
    index = 1

    while index<argvListCount:
        # Format argument
        argv = (argvList[index] or "").strip().lower()
        if argv.startswith("/"):
            argv = "-"+argv[1:]

        # Read argument
        if (argv=="-m" and index+4<argvListCount):
            MOSFileNameList    .append((argvList[index+1] or "").strip())
            MOSFieldNameList   .append((argvList[index+2] or "").strip())
            NRParsFileNameList .append((argvList[index+3] or "").strip())
            NRParsFieldNameList.append((argvList[index+4] or "").strip())
            NRParsMOSCount += 1
            index += 4
        elif (argv=="-s" and index+1<argvListCount):
            GraphSaveFileName = (argvList[index+1] or "").strip()
        elif (argv=="-h" or argv=="--help"):
            print("Usage:")
            print(" python3 ci_calc.py [options]")
            print("Options:")
            print(" -m    <mosFileName> <mosFieldName> <nrParsFileName> <nrParsFieldName>")
            print(" -s    <graphSaveFileName>")
            print(" -b    Verbose / Program Status")
            print("Misc Options:")
            print(" -h --help       Help")
            print(" -v --version    Version Number")
            print(" -b --verbose    Verbose Messages")
            print("Example:")
            print("")
            print("")
        elif (argv=="-v" or argv=="--version"):
            print("Version 1.0a")
        elif (argv=="-b" or argv=="-?" or argv=="--verbose"):
            IsVerbose = True
        else:
            print("  <Error: Failed to Parse Arguments at Index {0} of {1} with First Value \"{2}\" >".format(index, argvListCount, argvList[index]))

        index += 1

# read_mos_and_nrpars
#   Read MOS and NRPars
# SYNTAX
#   read_mos_and_nrpars();
# SEMANTICS
#   Read MOS and NRPars into global variables.
#
# Input Parameters:
#   MOSFileNameList       MOS filename(is a list)
#   MOSFieldNameList      MOS dataset name
#   NRParsFileNameList    NRPars filename
#   NRParsFieldNameList   NRPars fieldname
#
# Output Parameters
#   MetricName   Metric name, taken from fieldnames
#   MOSList      MOS values from mat file
#   NRParsList   NRPar values from mat file
#
def read_mos_and_nrpars():
    # Global vars
    global MetricName
    global MOSList
    global NRParsList

    # Through mat files
    for index in range(NRParsMOSCount):
        # Attempt to read MOS file
        if not os.path.exists(MOSFileNameList[index]):
            print("  <Failed to find MOS File \"{0}\">".format(MOSFileNameList[index]))
            exit(0)

        data = scipy.io.loadmat(MOSFileNameList[index])

        if not MOSFieldNameList[index] in data.keys():
            print("  <Failed to find MOS Dataset Field \"{0}\">".format(MOSFieldNameList[index]))
            exit(0)

        data = data[MOSFieldNameList[index]]

        if not( type(data      )==np.ndarray and len(data      )>0 \
            and type(data[0]   )==np.ndarray and len(data[0]   )>0 \
            and type(data[0][0])==np.void    and "media" in np.dtype(data[0][0]).names):
            print("  <Failed to find \"media\" Field in MOS Dataset \"{0}\">".format(MOSFieldNameList[index]))
            exit(0)

        dataIndex = np.dtype(data[0][0]).names.index("media")
        data = data[0][0]

        if not(dataIndex<len(data) \
            and type(data[dataIndex]   )==np.ndarray and len(data[dataIndex]   )>0 \
            and type(data[dataIndex][0])==np.ndarray and len(data[dataIndex][0])>0):
            print("  <Failed to find \"media\" Field as a List in MOS Dataset \"{0}\">".format(MOSFieldNameList[index]))
            exit(0)

        for rowIndex in range(len(data[dataIndex][0])):
            row = data[dataIndex][0][rowIndex]
            if not("mos" in np.dtype(row).names):
                print("  <Failed to find MOS column on row \"{0}\">".format(rowIndex))
                exit(0)
            columnIndex = np.dtype(row).names.index("mos")
            if not( type(row[columnIndex]      )==np.ndarray and len(row[columnIndex]   )>0 \
                and type(row[columnIndex][0]   )==np.ndarray and len(row[columnIndex][0])>0 \
                and type(row[columnIndex][0][0]) in (np.int8, np.int16, np.int32, np.int64, np.uint8, np.uint16, np.uint32, np.uint64, np.float32, np.float64)):
                print("  <Failed to find MOS column as a formatted float on row \"{0}\">".format(rowIndex))
                exit(0)
            mos = float(row[columnIndex][0][0])
            MOSList.append(mos)

        # Attempt to read NRPars file
        if not os.path.exists(NRParsFileNameList[index]):
            print("  <Failed to find NRPars File \"{0}\">".format(NRParsFileNameList[index]))
            exit(0)

        data = scipy.io.loadmat(NRParsFileNameList[index])

        if not "NRpars" in data.keys():
            print("  <Failed to find NRPars Dataset Field \"NRPars\">")
            exit(0)

        data = data["NRpars"]

        if not( type(data      )==np.ndarray and len(data      )>0 \
            and type(data[0]   )==np.ndarray and len(data[0]   )>0 \
            and type(data[0][0])==np.void    and "par_name" in np.dtype(data[0][0]).names and "data" in np.dtype(data[0][0]).names):
            print("  <Failed to find \"par_name\" and \"data\" Fields in NRPars Dataset \"{0}\">".format(NRParsFieldNameList[index]))
            exit(0)

        dataIndex1 = np.dtype(data[0][0]).names.index("par_name")
        dataIndex2 = np.dtype(data[0][0]).names.index("data")
        data = data[0][0]

        if not(dataIndex1<len(data) and dataIndex2<len(data) \
            and type(data[dataIndex1])==np.ndarray and len(data[dataIndex1])>0 \
            and type(data[dataIndex2])==np.ndarray and len(data[dataIndex2])>0):
            print("  <Failed to find \"par_name\" and \"data\" Fields as a List in MOS Dataset \"{0}\">".format(MOSFieldNameList[index]))
            exit(0)

        # if not( type(data[dataIndex1][0])==np.ndarray and len(data[dataIndex1][0])>0 \
        #     and type(data[dataIndex2][0])==np.ndarray and len(data[dataIndex2][0])>0:
        #     print("  <Failed to find \"par_name\" and \"data\" Fields as a List in MOS Dataset \"{0}\">".format(MOSFieldNameList[index]))
        #     exit(0)

        # NRParsFieldNameList[index]
        print("msg2 : ({0})".format(type(data[dataIndex1][0])))
        print("msg2 : ({0})".format(len(data[dataIndex1][0])))
        print("msg2 : ({0})".format(len(data[dataIndex1][0][0])))
        print("msg2 : ({0})".format(len(data[dataIndex1][0][1])))
        print("msg2 : ({0})".format(type(data[dataIndex2][0])))
        print("msg2 : ({0})".format(len(data[dataIndex2][0])))
        print("msg2 : ({0})".format(data[dataIndex2][0][0]))


        # for rowIndex in range(len(data[dataIndex][0])):
        #     row = data[dataIndex][0][rowIndex]
        #     if not("mos" in np.dtype(row).names):
        #         print("  <Failed to find MOS column on row \"{0}\">".format(rowIndex))
        #         exit(0)
        #     columnIndex = np.dtype(row).names.index("mos")
        #     if not( type(row[columnIndex]      )==np.ndarray and len(row[columnIndex]   )>0 \
        #         and type(row[columnIndex][0]   )==np.ndarray and len(row[columnIndex][0])>0 \
        #         and type(row[columnIndex][0][0]) in (np.int8, np.int16, np.int32, np.int64, np.uint8, np.uint16, np.uint32, np.uint64, np.float32, np.float64)):
        #         print("  <Failed to find MOS column as a formatted float on row \"{0}\">".format(rowIndex))
        #         exit(0)
        #     mos = float(row[columnIndex][0][0])
        #     MOSList.append(mos)

        # print("msg2 : ({0})".format(type(data[dataIndex][0])))
        # print("msg2 : ({0})".format(len(data[dataIndex][0])))
        # print("msg2 : ({0})".format(type(data[dataIndex][0][0])))
        # print("msg2 : ({0})".format("mos" in np.dtype(data[dataIndex][0][0]).names))
        # print("msg0 : ({0})".format(type(row[columnIndex][0][0])))

        # mosFileName[index]
        # mosFieldName[index]
        # nrParsFileName[index]
        # nrParsFieldName[index]
        # print("msg0 : ({0})".format(data.keys()))
        # print("msg1 : ({0})".format(data["__version__"]))
        # print("msg2 : ({0})".format(len(data["NRpars"])))
        # print("msg3 : ({0})".format(len(data["NRpars"][0])))
        # print("msg4 : ({0})".format(len(data["NRpars"][0][0])))
        # print("msg5 : ({0})".format(len(data["NRpars"][0][0][0][0])))
        # print("msg6 : ({0})".format(len(data["NRpars"][0][0][1][0])))
        # print("msg7 : ({0})".format(len(data["NRpars"][0][0][2][0])))
        # print("msg8 : ({0})".format(len(data["NRpars"][0][0][2][1])))
        # print("msg9 : ({0})".format(len(data["NRpars"][0][0][3][0])))
        # print("msg10: ({0})".format(len(data["NRpars"][0][0][4][0])))

# ci_calc
#   Estimate the confidence interval (CI) of an NR parameter
# SYNTAX
#   (ideal_ci, practical_ci) = ci_calc(metric_name, dataset_mos, 
#       dataset_metrics, fig_path = False, verbose = True);
# SEMANTICS
#   Estimate the confidence interval (CI) of an NR metric or parameter, 
#   by comparing the conclusions reached by the metric with conclusions 
#   reached by a subjective test. Both will use a constant confidence 
#   interval (CI) to make decisions. The subjective CI is based on
#   5-level ACR MOSs. Two recommended CIs are printed to the command window.
#   (1) ideal CI, and (2) practical CI. The classification types are plotted, 
#   which allows the user to choose an alternate CI.
#
#   By analogy, assess the performance of the metric in terms of an ad-hoc
#   test with N people. This analysis assumes that the metric and MOSs are 
#   compared without statistical tests or confidence intervals. 
#
# Input Parameters:
#   metric_name     Character string that contains the metric's name
#   dataset_mos     Cell array. For each dataset (1..num_datasets), a
#                   double array that contains the mean opinion score (MOS)
#                   for each stimuli in the dataset.
#   dataset_metrics Cell array. For each dataset (1..num_datasets), a
#                   double array that contains the metric's value for each
#                   stimuli in the dataset. Order of stimuli must be
#                   identical to dataset_mos.
#   fig_path        figure path for saving
#   verbose         print extra status messages
#
#   The theoretical underpinnings of this algorithm are pending publication
#   of NTIA Report "Confidence Intervals for Subjective Tests and 
#   Objective Metrics" by Margaret H Pinson
#
#   For a preliminary analysis, see Margaret Pinson, "NR metric confidence 
#   interval estimation using classification errors," Video Quality Experts
#   Group (VQEG) meeting, Statistical Analysis Methods (SAM) Group, 
#   Presentation 11, March 2020.  
#   ftp://vqeg.its.bldrdoc.gov/Documents/VQEG_online_Mar20/VQEG_2020_SAM_011_confidence_intervals_for_metrics.pptx
#
# Output Parameters
#   ideal_ci = the ideal confidence interval
#   practial_ci = the practical confidence interval
#   N = the number of people in an ad-hoc test with an equivalent likelihood of
#       false ranking, or zerro (0) if the performance is worse than a 1
#       person ad-hoc test. 
#
#   For positively correlated metrics, false ranking is where a well designed
#   subjective test would conclude that stimuli A is statisticall better 
#   than stimuli B, but the metric value for stimuli B is greater than
#   the metric value for stimuli A. "Less than" is used for negatively
#   correlated metrics. 
#
# Constraints:
#   All datasets are weighted equally.
#   The MOSs must range from 1 to 5. 
#
def ci_calc(metric_name, dataset_mos, dataset_metrics, fig_path = False, verbose = True):
    threshold_level = 0.5 # delta S, where 95% of stimuli MOS can be rank ordered
    false_rank_thresh = 0.01 # disagree rate
    false_diff_thresh = 0.10 # half of the uncertain rate of 20%
    practical_threshold = 0.165 # half of maximum uncertain rate plus disagree rate
    concur_threshold = 0.91 #based on analyses of the VQEG FRTV Phase I ratings
    print('Metric confidence interval analysis for {}'.format(metric_name))

    # calculate range of this parameter
    this_par = []
    pos_corr = []
    for dcnt, mos in dataset_mos.items():
        omos = dataset_metrics[dcnt]
        tmp = np.corrcoef(mos, omos)
        if tmp[0,1] >= 0:
            pos_corr.append(1)
        else:
            pos_corr.append(-1)
        this_par.extend(omos)


    this_par = sorted(this_par)
    pmin = min(this_par)
    pmax = max(this_par)

    if verbose:
        print('Full range {}..{}, '.format(pmin, pmax))
        print('95% of data in {}..{}\n'.format(this_par[int(0.025*len(this_par))], this_par[int(0.975*len(this_par))]))

    if sum(pos_corr) > 0:
        if verbose:
            print('Positively correlated with MOS for most datasets\n\n')
        is_pos_corr = True
    elif sum(pos_corr) == 0:
        if verbose:
            print('Split decision on whether metric is positively or negatively correlated with MOS.\nAssume positive correlation.\n\n')
        is_pos_corr = True
    else:
        if verbose:
            print('Negatively correlated with MOS for most datasets\n\n')
        is_pos_corr = False

    if pmin == pmax:
        print('Warning: parameter has a constant value, aborting.\n')
        ideal_ci = np.NaN
        practical_ci = np.NaN
        return


    # manually loop through all pairs of stimuli
    subj = []
    obj = []
    wt = []
    curr = 1
    for dcnt, mos in dataset_mos.items():
        curr_len = len(mos)
        for mcnt1 in range(0,curr_len):
            for mcnt2 in range(mcnt1+1,curr_len):

                if curr == 479:
                    stop_here = 1
                # subj(curr) is decision whether #1 is better,
                # equivalent, or worse than #2
                diff = mos[mcnt1] - mos[mcnt2]
                if diff > threshold_level:
                    subj.append(1)
                elif diff < -threshold_level:
                    subj.append(-1)
                else:
                    subj.append(0)

                # obj(curr) is distance before thresholding, since the
                # point of this function is to ideal_ci a threshold
                obj.append(dataset_metrics[dcnt][mcnt1] - dataset_metrics[dcnt][mcnt2])

                # note weight
                wt.append( 1 / len(mos) )
                curr += 1

    # flip sign of objective differences, if parameter is
    # negatively correlated to MOS
    if is_pos_corr == False:
        obj = -obj

    # Have all of the data. Now make the plot.
    # round our increment to one significant digits
    # incr = round((pmax-pmin)/100, 1, 'significant');
    incr = (pmax-pmin)/100
    list_want = np.arange(incr,pmax-pmin,incr)

    correct_rank = [0]*len(list_want)
    correct_tie = [0]*len(list_want)
    false_ranking = [0]*len(list_want)
    false_distinction = [0]*len(list_want)
    false_tie = [0]*len(list_want)

    # create data for roughly 60% of the range of parameter values
    # from there, the plot flattens and contains no more info
    for loop in range(0,len(list_want)):
        #print(loop)
        delta = list_want[loop]
        for curr in range(0,len(subj)):
            if (subj[curr] == 1 and obj[curr] >= delta) or (subj[curr] == -1 and obj[curr] <= -delta):
                correct_rank[loop] = correct_rank[loop] + wt[curr]
            elif subj[curr] == 0 and obj[curr] > -delta and obj[curr] < delta:
                correct_tie[loop] = correct_tie[loop] + wt[curr]
            elif (subj[curr] == 1 and obj[curr] <= -delta) or (subj[curr] == -1 and obj[curr] >= delta):
                false_ranking[loop] = false_ranking[loop] + wt[curr]
            elif (subj[curr] != 0 and obj[curr] > -delta and obj[curr] < delta):
                false_tie[loop] = false_tie[loop] + wt[curr]
            else:
                false_distinction[loop] = false_distinction[loop] + wt[curr]

    total_votes = sum(wt)

    correct_rank = [ val/total_votes for val in correct_rank]
    correct_tie = [ val/total_votes for val in correct_tie]
    false_ranking = [ val/total_votes for val in false_ranking]
    false_distinction = [ val/total_votes for val in false_distinction]
    false_tie = [ val/total_votes for val in false_tie]

    # if too much data is false_tie and correct_tie at minimum
    # threshold, don't try. Skip. Rule of thumb: 50% ties. We expect
    # values close to zero, so this should mean most of the metric is a
    # constant value.
    if false_tie[0] + correct_tie[0] > 0.5:
        print('Half of data is correct ties or false ties. Skipping.\n')
        ideal_ci = np.NAN
        practical_ci = np.NAN
        return

    # compute the ideal ci
    ideal_ci = len(list_want)
    for n, (fr, fd) in enumerate(zip(false_ranking,false_distinction)):
        if (fr < false_rank_thresh) and (fd < false_diff_thresh):
            ideal_ci = n
            break


    # compute the practical CI
    practical_ci = len(list_want)
    for n, (fr, fd) in enumerate(zip(false_ranking, false_distinction)):
        if (fr + fd) < practical_threshold:
            practical_ci = n
            break

    equiv_ideal = np.sqrt(correct_rank[ideal_ci]) + 1.2 * correct_tie[ideal_ci]
    equiv_practical = np.sqrt(correct_rank[practical_ci]) + 1.2 * correct_tie[practical_ci]

    # print recommended threshold
    if verbose:
        print('{} Ideal CI      ({}% correct ranking, {}% false ranking, {}% false distinction, {}% false tie, {}% correct tie)'.format(
        list_want[ideal_ci], round(correct_rank[ideal_ci]*100), round(false_ranking[ideal_ci]*100), round(false_distinction[ideal_ci]*100),
            round(false_tie[ideal_ci]*100), round(correct_tie[ideal_ci]*100)))
        if equiv_ideal >= concur_threshold:
            print(' ==> equivalent to a subjective test with 24 subjects')

        print('\n{} Practical CI  ({}% correct ranking, {}% false ranking, {}% false distinction, {}% false tie, {}% correct tie)'.format(
        list_want[practical_ci], round(correct_rank[practical_ci]*100), round(false_ranking[practical_ci]*100), round(false_distinction[practical_ci]*100),
            round(false_tie[practical_ci]*100), round(correct_tie[practical_ci]*100)))
        if equiv_practical >= concur_threshold:
            print(' ==> equivalent to a subjective test with 15 subjects')

    # dataset names
    tmp = " ".join(sorted(dataset_mos.keys()))


    # create plot
    fig, ax = plt.subplots(figsize=(6, 6))
    ax.plot(list_want, [val*100 for val in correct_rank], 'g', label="correct rank")
    ax.plot(list_want, [val*100 for val in false_ranking], 'r', label="false rank")
    ax.plot(list_want, [val*100 for val in false_distinction], 'b--', label="false distinction")
    ax.plot(list_want, [val*100 for val in false_tie], 'y--', label="false tie")
    ax.plot(list_want, [val*100 for val in correct_tie], 'y', label="correct tie")

    ax.plot([list_want[ideal_ci],list_want[ideal_ci]], [0,100], 'k', label="ideal CI")
    ax.plot([list_want[practical_ci],list_want[practical_ci]], [0,100], 'k--', label="practical CI")

    plt.xlabel("Delta Metric")
    plt.ylabel("Probability")
    ax.grid()
    ax.set_title(metric_name)
    ax.axis([0, 2, 0, 100])
    leg = ax.legend()

    if fig_path:
        plt.savefig(fig_path)
    else:
        plt.show()

    # equivelence determination

    correct_rank_zero = 0
    correct_tie_zero = 0
    false_ranking_zero = 0
    false_distinction_zero = 0
    false_tie_zero = 0

    delta = 0
    for curr in range(0,len(subj)):
        if (subj[curr] == 1 and obj[curr] >= delta) or (subj[curr] == -1 and obj[curr] <= -delta):
            correct_rank_zero = correct_rank_zero + wt[curr]
        elif subj[curr] == 0 and obj[curr] > -delta and obj[curr] < delta:
            correct_tie_zero = correct_tie_zero + wt[curr]
        elif (subj[curr] == 1 and obj[curr] <= -delta) or (subj[curr] == -1 and obj[curr] >= delta):
            false_ranking_zero = false_ranking_zero + wt[curr]
        elif (subj[curr] != 0 and obj[curr] > -delta and obj[curr] < delta):
            false_tie_zero = false_tie_zero + wt[curr]
        else:
            false_distinction_zero = false_distinction_zero + wt[curr]

    correct_rank_zero = correct_rank_zero/total_votes
    correct_tie_zero = correct_tie_zero/total_votes
    false_ranking_zero = false_ranking_zero/total_votes
    false_distinction_zero = false_distinction_zero/total_votes
    false_tie_zero = false_tie_zero/total_votes

    print('\nNo CI used ({}% correct ranking, {}% false ranking, {}% false distinction, {}% false tie, {}% correct tie)'.format(
        round(correct_rank_zero*100), round(false_ranking_zero*100), round(false_distinction_zero*100), round(false_tie_zero*100), round(correct_tie_zero*100)))

    if false_ranking_zero <= 0.0325:
        equivalent = 12
        print(' ==> equivalent to a pilot test with {} subjects'.format(equivalent))
    elif false_ranking_zero <= 0.0395:
        equivalent = 9
        print(' ==> equivalent to a pilot test with {} subjects'.format(equivalent))
    elif false_ranking_zero <= 0.056:
        equivalent = 6
        print(' ==> equivalent to a pilot test with {} subjects'.format(equivalent))
    elif false_ranking_zero <= 0.0765:
        equivalent = 3
        print(' ==> equivalent to a {} person ad-hoc test'.format(equivalent))
    elif false_ranking_zero <= 0.0995:
        equivalent = 2
        print(' ==> equivalent to a {} person ad-hoc test'.format(equivalent))
    elif false_ranking_zero <= 0.1285:
        equivalent = 1
        print(' ==> equivalent to a {} person ad-hoc test'.format(equivalent))
    else:
        equivalent = 0

    return list_want[ideal_ci], list_want[practical_ci]

if __name__ == "__main__":
    Main()

#     df = pd.read_csv("p2str01.csv")

#     dataset_mos = {"db01": [2.692307692,
# 3.846153846,
# 4.192307692,
# 4.269230769,
# 4.384615385,
# 1.576923077,
# 2.461538462,
# 3.192307692,
# 4.076923077,
# 1.653846154,
# 1.423076923,
# 2.730769231,
# 3.653846154,
# 4.615384615,
# 1.230769231,
# 3.115384615,
# 3.269230769,
# 3.5,
# 2
# ]}
#     dataset_metrics = {"db01": [2.105,
# 2.784,
# 2.988,
# 4.035,
# 1.666,
# 2.299,
# 3.052,
# 3.578,
# 4.429,
# 2.489,
# 2.286,
# 3.021,
# 3.516,
# 4.405,
# 2.533,
# 2.158,
# 2.169,
# 2.337,
# 2.159
# ]}

#     metric_name = "TEST_METRIC"

#     ideal_ci, practical_ci = ci_calc(metric_name, dataset_mos, dataset_metrics, verbose=True)