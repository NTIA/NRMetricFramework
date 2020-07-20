import os
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

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
    df = pd.read_csv("p2str01.csv")

    dataset_mos = {"db01": [2.692307692,
3.846153846,
4.192307692,
4.269230769,
4.384615385,
1.576923077,
2.461538462,
3.192307692,
4.076923077,
1.653846154,
1.423076923,
2.730769231,
3.653846154,
4.615384615,
1.230769231,
3.115384615,
3.269230769,
3.5,
2
]}
    dataset_metrics = {"db01": [2.105,
2.784,
2.988,
4.035,
1.666,
2.299,
3.052,
3.578,
4.429,
2.489,
2.286,
3.021,
3.516,
4.405,
2.533,
2.158,
2.169,
2.337,
2.159
]}

    metric_name = "TEST_METRIC"

    ideal_ci, practical_ci = ci_calc(metric_name, dataset_mos, dataset_metrics, verbose=True)