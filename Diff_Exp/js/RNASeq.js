// Executes search via an AJAX call
function runRNASeq() {
    // hide and clear the previous results, if any
    $('tbody').empty();

    // transforms all the form parameters into a string sent to the server
     var inputs = $('#Input_Section').serialize();

    // alert(inputs);

    $.ajax({
        url: './RNASeq.cgi',
        dataType: 'json',
        data: inputs,
        success: function(data, textStatus, jqXHR) {
            $('#Request_Sent').hide();
            $('#Processing').show();
            processJSON(data);
        },
        error: function(jqXHR, textStatus, errorThrown){
            $('#Request_Sent').hide();
            alert(jqXHR.responseText);
            alert("Failed to perform RNASeq analysis! textStatus: (" + textStatus +
                  ") and errorThrown: (" + errorThrown + ")");
        },
    });
}

// this processes a passed JSON structure representing expression differences and draws it
//  to the result table
function processJSON( data ) {

    var matches = JSON.parse(data.matches);

    // set the span that lists the match count
    $('#results_count').text( data.results_count );

    // this will be used to keep track of row identifiers
    var next_row_num = 1;
    // iterate over each expression difference and add a row to the result table for each
    $.each( matches, function(i, item) {
        var this_row_id = 'result_row_' + next_row_num++;

        // create a row and append it to the body of the table
        $('<tr/>', { "id" : this_row_id } ).appendTo('tbody');

        // add the gene id column
        $('<td/>', { "text" : item.Gene_id } ).appendTo('#' + this_row_id);

        // add the gene name column
        $('<td/>', { "text" : data.gene_names[item.Gene_id] } ).appendTo('#' + this_row_id);

        // add the Base Mean column
        $('<td/>', { "text" : item.baseMean } ).appendTo('#' + this_row_id);

        // add the log2FoldChange column
        $('<td/>', { "text" : item.log2FoldChange } ).appendTo('#' + this_row_id);

        // add the Standard Error column
        $('<td/>', { "text" : item.lfcSE } ).appendTo('#' + this_row_id);

        // add the adjusted p-value column
        $('<td/>', { "text" : item.padj } ).appendTo('#' + this_row_id);

    });

    // show results section and hide submission text
    $('#Processing').hide();
    $('#results').show();
}


$(document).ready( function() {
    $('#results').hide(); // initially hides results section
    $('#Request_Sent').hide(); // hides submit response
    $('#Processing').hide();
    $('#submit').click( function () {
        $('#Request_Sent').show();
        $('#control').text($('#control_group').val());
        $('#exp').text($('#exp_group').val());
        runRNASeq(); // run program on click of submit button
        $('#AnalysisResult').empty();
        return false;  // prevents 'normal' form submission
    });
});
