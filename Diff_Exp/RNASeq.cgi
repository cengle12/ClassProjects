#!/usr/local/bin/python3

from pathlib import Path
import pandas as pd
import cgi
import json
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri, Formula
from rpy2.robjects.packages import importr

pandas2ri.activate()
deseq = importr('DESeq2')

to_dataframe = robjects.r('function(x) data.frame(x)')


def main():
    print("Content-Type: application/json\n\n")
    counts_file, design_file, design, control, exp = parse_data(cgi.FieldStorage())
    counts_matrix, design_matrix, gene_dict = check_input(counts_file, design_file, design, control, exp)

    results = run_analysis(counts_matrix, design_matrix, design, control, exp, gene_dict)

    print(json.dumps(results))


def parse_data(data):
    """
    Receives cgi.FieldStorage object and parses arguments from html form assigning them to
    different variables for later analysis.
    :param data: cgi.FieldStorage object containing form elements passed from RNASeq.html page through an ajax request
    :return: string variables corresponding to each input element from html form
    """
    form = data
    counts_file = form.getvalue('raw_counts_csv')
    counts_file = './Resources/'+counts_file  # Adds path to Resources folder
    design_file = form.getvalue('design_file_csv')
    design_file = './Resources/'+design_file
    design = str(form.getvalue('study_design_factor'))
    control = str(form.getvalue('control_group_subfactor'))
    exp = str(form.getvalue('exp_group_subfactor'))

    return counts_file, design_file, design, control, exp


def check_input(counts_file, design_file, design, control, experimental):
    """
    Checks input values parsed from ajax request to see if they are valid and creates matrix objects for passed csv
    files. If input is valid, returns the matrices for RNASeq analysis.
    :param counts_file: .csv filename containing raw RNASeq counts
    :param design_file: .csv filename of study design containing treatment conditions and subgroups
    :param design: study factor being analyzed by RNA Seq analysis
    :param control: control group name present in the design file
    :param experimental: experimental group name present in design file.
    :return: returns pandas matrix objects for both .csv files for analysis in next step.
    """
    # Searches Resources folder to see if .csv files specified exist
    if not Path(counts_file).exists() or not Path(design_file).exists():
        raise Exception('Error: Counts file and/or design file cannot be found in Resources folder')

    counts_matrix = pd.read_csv(counts_file, header=0, index_col=0)  # Pandas matrix instantiation
    counts_copy = counts_matrix.copy()  # copy to make dict of gene names

    counts_matrix.drop(['Gene Name'], axis=1, inplace=True)  # drops gene names in original matrix for analysis

    counts_copy = counts_copy.loc[:,"Gene Name"]
    counts_copy.dropna(axis=0, inplace=True)  # Removes Na values from matrix
    gene_dict = counts_copy.to_dict() # creates dict from batch conditions and gene names

    design_matrix = pd.read_csv(design_file, header=0, index_col=0)

    column_headers = list(counts_matrix.columns)

    design_rows = list(design_matrix.index)

    # Ensures length of experimental batches are equal in both files (no missing information present)
    if len(column_headers) != len(design_rows):
        raise Exception('Amount of batch runs in data and design files inconsistent')

    i = 0
    while i < len(column_headers):
        if column_headers[i] != design_rows[i]:  # Ensures they are in the same order in matrix for analysis
            raise Exception('Batch run order does not align between data and design file')
        i += 1

    # Checks to see if specified study factor is a column in design matrix
    if design not in design_matrix.columns:
        raise Exception('Specified study factor not present in design file')

    # Determines if specified control group is a subgroup within the specified study factor column
    if control not in design_matrix[design].tolist():
        raise Exception('Specified control group not a subgroup within the {} column'.format(design))

    # Same as above but for experimental group
    if experimental not in design_matrix[design].tolist():
        raise Exception('Specified experimental group not a subgroup within the {} column'.format(design))

    return counts_matrix, design_matrix, gene_dict


def run_analysis(counts_matrix, design_matrix, design, control, exp, gene_dict):
    """
    Performs RNASeq analysis using matrices and specified input form elements from html file. Once a DESeq object has
    has been created, the results are pulled from the object and significant up-or-down-regulated genes are passed into
    json structure and finally passed back to html form.

    :param counts_matrix: pandas matrix of RNASeq counts
    :param design_matrix: pandas matrix of study factors
    :param design: user-defined analysis factor
    :param control: user-defined control group
    :param exp: user-defined experimental group
    :return: significant differential expression results in json format
    """

    # Establishes deseq object pulling information from matrices and study design
    dds = deseq.DESeqDataSetFromMatrix(countData=counts_matrix,
                                       colData=design_matrix,
                                       design=Formula("~ "+design))

    dds = deseq.DESeq(dds)  # Begins analysis

    # Removes groups with <10 counts for prefiltering - speeds up subsequent analysis
    dds = robjects.r.subset(dds, robjects.r.rowSums(robjects.r.counts(dds)) >= 10)

    # Sets variable containing vector of factor, control, and exp group information
    contrast = robjects.vectors.StrVector([design, exp, control])

    # Pulls results from object according to specified contrast conditions
    deseq_result = deseq.results(dds, contrast=contrast)

    deseq_result = to_dataframe(deseq_result)  # Results to dataframe format
    deseq_result = robjects.conversion.rpy2py(deseq_result)  # Converted to pandas matrix

    deseq_result.index.name='Gene_id'
    deseq_result['Gene_id'] = deseq_result.index
    deseq_result = deseq_result.reset_index(drop=True)

    sig_results = deseq_result[deseq_result["padj"] < 0.001]  # Subsets to 0.01 significance level

    # Formats results to json structure
    output_results = {"results_count": str(len(sig_results.index)), "gene_names": gene_dict, "matches": list()}
    output_results["matches"].append(sig_results.to_json(orient="index"))

    return output_results


if __name__ == '__main__':
    main()
