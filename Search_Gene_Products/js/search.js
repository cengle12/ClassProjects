// this function executes our search via an AJAX call
function runSearch( term ) {
    // hide and clear the previous results, if any
    $('#results').hide();
    $('tbody').empty();

    // transforms all the form parameters into a string we can send to the server
    var frmStr = $('#gene_search').serialize();

    $.ajax({
        url: './search_product.cgi',
        dataType: 'json',
        data: frmStr,
        success: function(data, textStatus, jqXHR) {
            processJSON(data);
        },
        error: function(jqXHR, textStatus, errorThrown){
            alert("Failed to perform gene search! textStatus: (" + textStatus +
                  ") and errorThrown: (" + errorThrown + ")");
        }
    });
}


// this processes a passed JSON structure representing gene matches and draws it
//  to the result table
function processJSON( data ) {
    // set the span that lists the match count
    $('#match_count').text( data.match_count );

    // this will be used to keep track of row identifiers
    var next_row_num = 1;

    // iterate over each match and add a row to the result table for each
    $.each( data.matches, function(i, item) {
        var this_row_id = 'result_row_' + next_row_num++;

        // create a row and append it to the body of the table
        $('<tr/>', { "id" : this_row_id } ).appendTo('tbody');

        // add the locus column
        $('<td/>', { "text" : item.locus_id } ).appendTo('#' + this_row_id);

        // add the product column
        $('<td/>', { "text" : item.product } ).appendTo('#' + this_row_id);

    });

    // now show the result section that was previously hidden
    $('#results').show();
}

function setText(element){
    var value = $(element).text();

    $("#txt_search").val(value);
    $("#searchResult").empty();
}

// run our javascript once the page is ready

$(document).ready( function() {
    $("#gene_search").keyup(function(){
        var search = $('#gene_search').serialize();
        if(search != ""){
            $.ajax({
                url: './search_product.cgi',
                data: search,
                dataType: 'json',
                success:function(response) {
                    $('#match_count').text(response.match_count);
                    var results = [];
                    $.each(response.matches, function (i, item) {
                        results.push(item);
                    })
                    $("#searchResult").empty();
                    for (var i = 0; i < 5; i++) {
                        var locus_id = results[i]['locus_id'];
                        var product = results[i]['product'];
                        $("#searchResult").append("<li value='" + locus_id + "'>" + product + "</li>");
                        $('#searchResult li').bind("click", function () {
                            setText(this);
                        })
                    }

                }
            });
        }
        $("#searchResult").empty();

    });

});

$(document).ready( function() {
    // define what should happen when a user clicks submit on our search form
    $('#submit').click(function () {
        runSearch();
        $("#searchResult").empty();
        return false;  // prevents 'normal' form submission
    });
});
