<div class="row">
	<div class="col-md-12">
		<h2>Statistics</h2>
		<div id="parentDiv">
  			<!--// Nav tabs -->
  			<ul class="nav nav-tabs" role="tablist">
    			<li role="presentation" class="active"><a href="#descriptiveStatistics" aria-controls="descriptiveStatistics" role="tab" data-toggle="tab">Descriptive statistics</a></li>
  			</ul>
  			<!--// Tab panes -->
  			<div class="tab-content">
   	 			<div role="tabpanel" class="tab-pane active" id="descriptiveStatistics">
    				<div class="row">
    					<div class="col-md-3">
    						<table class="table" id="overview">
    							<tbody>
    								<tr>
    									<th scope="row">Name of dataset</th>
    									<td id="nameOfDataSet"></td>
    								</tr>
    								<tr>
    									<th scope="row">No. of variables</th>
    									<td id="noOfVariables"></td>
    								</tr>
    								<tr>
    									<th scope="row">No. of records</th>
    									<td id="noOfRecords"></td>
    								</tr>
    							</tbody>
    						</table>
    					</div>
    				</div>
    				<div class="row">
    					<div class="col-md-12">
    						<i><small>Note: Normality and Q25 and 75 are calculated over the first 10.000 samples</small></i>
							<table class="table table-striped">
								<thead>
									<th>Id</th>
									<th>Label</th>
									<th>Datatype</th>
									<th>Summary statistic:mean/median/yes/no/counts/unique values</th>
									<th>Value</th>
									<th>Normally distributed (alpha>0.05)</th>
									<th>Shapiro-Wilk normality test</th>
									<th>N Missing (%)</th>
									<th>N Total (%)</th>
									<th>Is the N total <5</th>
								</thead>
								<tbody id="descriptiveStatisticsData">
								</tbody>
							</table>
    					</div>
    				</div>
    				<div class="row">
    					<div class="col-md-12">
    						<a class="export btn btn-primary" type="button"><span class="glyphicon glyphicon-download" aria-hidden="true"></span> Export to CSV</a>
    					</div>
    				</div>
    			</div>
  			</div>	
		</div>
	</div>
<div>
<style>
#overview{	margin-top:3em;
}
#overview table{	border-collapse: collapse;
					border: 1px solid black;
}
#overview th{	border: 1px solid black;
}
#overview td{	border: 1px solid black;
}
</style>
<script>
var url = window.location.href;
var entity = url.split('entity=')[1].split('&')[0];
var data={};
var metaData = {};
var bools = [];
var cats = [];
var boolCatData = {};
var chartId="";
var totalPerBiobank = {};
start(entity);
function fillBiobankSelect(id, biobankTable){
	$.get("/api/v2/"+biobankTable).done(function(biobankTable){
		biobanks = biobankTable.items;
		$.each(biobanks, function(i, biobank){
			$('#selectBiobank').append('<option value = "'+biobank.id+'">'+biobank.abbr+'</option>');
		});
	});
	
}
function start(entity){
	$('#nameOfDataSet').text(entity);
	$(document).ready(
		function(){
			//get the meta data of the table and use this further on
			getMetaData(
				function(idAttribute){
					//get the actual data and process it
					gatherData('/api/v2/'+entity+'?num=10000', 
						function(){
							$('#noOfVariables').text(Object.keys(data).length);
							processData(data, 'regularValue');
						}
					)
				}
			);
		}
	)
}

function mean(list){
	return sum(list)/list.length;
}

function add(num1, num2){
	return num1+num2;
}

function sum(list){
	return list.reduce(add, 0);
}

function median(list){
	var list = list.sort();
	var l = list.length;
	//take the middle number position 0 based
	var middle = l/2 - 0.5;
	if(l%2 === 0){
		return getPointInBetween(list, middle);
	}else{
		return list[middle];	
	}
}

function deviation(datapoint, mean){
	return (datapoint-mean)*(datapoint-mean);
}

function sd(list){
	return Math.sqrt(variance(list));
}

function variance(list){
	var m = mean(list);
	var dev_map = list.map(function(x){
		return deviation(x, m);
	});
	return mean(dev_map);
}
function getPointInBetween(list, actual){
	list = list.sort();
	pos = Math.floor(actual)
	p1 = list[pos];
	p2 = list[Math.ceil(actual)];
	return p1+(p2-p1)*(actual-pos);
}
function createAttrRowInTable(rowClass, attribute, label, type){
	var attributeIdAttr = attribute.replace('#', '');
	$('#descriptiveStatisticsData').append('<tr class="'+rowClass+'"><td class="id-td"><b>'+attribute+'</b></td><td>'+label+'</td><td>'+type+'</td>'+
	'<td id="'+attributeIdAttr+'-meanType"></td><td id="'+attributeIdAttr+'-value"></td><td id="'+
	attributeIdAttr+'-normal"></td><td id="'+attributeIdAttr+'-shapiroWilk"></td><td id="'+attributeIdAttr+
	'-missing"></td><td id="'+attributeIdAttr+'-total"></td><td id="'+attributeIdAttr+'-totalSmallerThan5"></td></tr>');
}
function processBool(values, attribute, total){
	var na = total-values.length;
	var attributeIdAttr = attribute.replace('#', '');
	$('#'+attributeIdAttr+'-meanType').text('N TRUE(%)/N FALSE(%)');
	$('#'+attributeIdAttr+'-normal').text('NA');			
	$('#'+attributeIdAttr+'-missing').text(na+' ('+getPercentage(na,total)+'%)');
	$('#'+attributeIdAttr+'-total').text(total-na+'('+getPercentage(total-na,total)+'%)');
	$('#'+attributeIdAttr+'-shapiroWilk').text('NA');
	$('#'+attributeIdAttr+'-totalSmallerThan5').text(isSmallerThanFive(total-na));
	getValueCountsArr(values, function(counts){
		if(counts.true && counts.false){
			$('#'+attributeIdAttr+'-value').text(counts.true+' ('+getPercentage(counts.true,total)+
			'%)/'+counts.false+' ('+getPercentage(counts.false,total)+'%)');
		}else if(counts.true){
			$('#'+attribute+'-value').text(counts.true+' ('+getPercentage(counts.true,total)+'%)/0 (0%)');
		}else if(counts.false){
			$('#'+attribute+'-value').text('0 (0%)/'+counts.false+' ('+getPercentage(counts.false,total)+'%)');
		}else{
			$('#'+attribute+'-value').text('0 (0%)/0 (0%)');
		}
		
	});
}
function processEnum(values, attribute, total){
	var na = total-values.length;
	var attributeIdAttr = attribute.replace('#', '');
	$('#'+attributeIdAttr+'-normal').text('NA');			
	$('#'+attributeIdAttr+'-missing').text(na+' ('+getPercentage(na,total)+'%)');
	$('#'+attributeIdAttr+'-total').text(total-na+'('+getPercentage(total-na,total)+'%)');
	$('#'+attributeIdAttr+'-shapiroWilk').text('NA');
	$('#'+attributeIdAttr+'-totalSmallerThan5').text(isSmallerThanFive(total-na));
	getValueCountsArr(values, function(counts){
		var options = metaData[attribute].parts;
		$.each(options, 
			function(i, option){
				if(counts[option]===undefined){
					('#'+attributeIdAttr+'-meanType').append(option+' N(%)<br/>');
					$('#'+attributeIdAttr+'-value').append('0 (0%)<br/>');
				}else{
					$('#'+attributeIdAttr+'-meanType').append(option+' N(%)<br/>');
					$('#'+attributeIdAttr+'-value').append(counts[option]+' ('+getPercentage(counts[option],total)+'%)<br/>');
				}
			}
		)
		
	});
}
function processNumber(values, attribute, total){
	var attributeIdAttr = attribute.replace('#', '');
	//test for normality
	checkNormality(attribute, entity, function(normality){
		//get the alpha from the output
		var alpha = parseFloat(normality.split(' ')[1]);
		//put alpha in table
		$('#'+attributeIdAttr+'-shapiroWilk').text('P='+alpha.toFixed(2));
		//if alpha > 0.05 data is normally distributed, show mean and sd 
		if(alpha > 0.05){
			$('#'+attributeIdAttr+'-meanType').text('mean(SD)');
			$('#'+attributeIdAttr+'-normal').text('Yes');
			//append mean, sd and percentages to table
			var na = total-values.length;
			var meanVal = mean(values);
			var sdVal= sd(values);
			$('#'+attributeIdAttr+'-value').text(meanVal.toFixed(2)+'('+sdVal.toFixed(2)+')');
			$('#'+attributeIdAttr+'-missing').text(na+' ('+getPercentage(na,total)+'%)');
			$('#'+attributeIdAttr+'-total').text(total-na+' ('+getPercentage(total-na,total)+'%)');
			$('#'+attributeIdAttr+'-totalSmallerThan5').text(isSmallerThanFive(total-na));
		//alpha < 0.05 data is normally distributed, show median and IQR25 and 75 
		}else{
			$('#'+attributeIdAttr+'-meanType').text('median(IQR 25-75)');
			//get median and IQR
			getIqr2575(attribute, entity, function(IQR){
				//split output on end of lines and spaces, filter out empty strings
				//var IQR = medianIQR.split(/\n| /).filter(Boolean);
				var IQR = IQR.split(/\s+/);
				console.log(IQR);
				var medianOfData = median(values);
				var IQR25 = IQR[7];
				var IQR75 = IQR[9];
				var na = total-values.length;
				//put info in table
				$('#'+attributeIdAttr+'-normal').text('No');
				$('#'+attributeIdAttr+'-value').text(medianOfData+' ('+IQR25+'-'+IQR75+')');
				$('#'+attributeIdAttr+'-missing').text(na+' ('+getPercentage(na,total)+'%)');
				$('#'+attributeIdAttr+'-total').text(total-na+'('+getPercentage(total-na,total)+'%)');
				$('#'+attributeIdAttr+'-totalSmallerThan5').text(isSmallerThanFive(total-na));
			});
		}
	});
}
function getIqr2575(column, entity, callback){
	var website = window.location.protocol+'//'+window.location.host;
	website.replace(/:/g,"%3A");
	website.replace(/\//g,"%3F");
	$.get('/scripts/getIQR/run?url='+website+'&column='+column+'&entity='+entity).done(
		function(iqr){
			callback(iqr);
		}
	)
}
function checkNormality(column, entity, callback){
	var website = window.location.protocol+'//'+window.location.host;
	website.replace(/:/g,"%3A");
	website.replace(/\//g,"%3F");
	$.get('/scripts/normalityCheck/run?url='+website+'&column='+column+'&entity='+entity).done(
		function(normality){
			callback(normality);
		}
	)
}
function calculateUniques(values){
	var counts = {};
	for (var i = 0; i < values.length; i++) {
   		counts[values[i]] = 1 + (counts[values[i]] || 0);
		if(i === values.length -1){
			return Object.keys(counts).length;
		}
	}
}
function processString(attribute, values, total){
	var uniques = calculateUniques(values);
	var na = total-values.length;
	var N = values.length;
	var attributeIdAttr = attribute.replace('#', '');
	$('#'+attributeIdAttr+'-meanType').text('Unique values');
	$('#'+attributeIdAttr+'-normal').text('NA');
	$('#'+attributeIdAttr+'-value').text(uniques+' ('+getPercentage(uniques, total)+'%)');
	$('#'+attributeIdAttr+'-missing').text(na+' ('+getPercentage(na, total)+'%)');
	$('#'+attributeIdAttr+'-total').text(N +' ('+getPercentage(N, total)+'%)');
	$('#'+attributeIdAttr+'-totalSmallerThan5').text(isSmallerThanFive(N));
	$('#'+attributeIdAttr+'-shapiroWilk').text('NA');
}
function processRemaining(attribute){
	var attributeIdAttr = attribute.replace('#', '');
	$('#'+attributeIdAttr+'-meanType').text('NA');
	$('#'+attributeIdAttr+'-normal').text('NA');
	$('#'+attributeIdAttr+'-value').text('NA');
	$('#'+attributeIdAttr+'-missing').text('NA');
	$('#'+attributeIdAttr+'-total').text('NA');
	$('#'+attributeIdAttr+'-totalSmallerThan5').text('NA');
	$('#'+attributeIdAttr+'-shapiroWilk').text('NA');
}
function processData(attrs, className){
	var doneCounter = Object.keys(attrs).length;
	//This function processes the data in the entity
	$.each(attrs,
		function(attribute, values){
			var attributeIdAttr = attribute.replace('#', '');
			var total = $('#noOfRecords').text();
			var meta = metaData[attribute];
			var label = meta.label;
			var type = meta.type;
			if(metaData[attribute].partOf === undefined){
				switch(type){
					//when int or decimal attribute is found, test normality, calculate mean/median + sd/iqr etc. 
					case 'COMPOUND':
						createAttrRowInTable('compound-row', attribute, label, type);
						//here some code that does the same as for each other thing, for each attribute of the compound
						processCompound(attribute, values, meta.parts);
						$('.compound-row').css('background-color', '#d9d9d9');
						doneCounter -= 1;
						if(doneCounter === 0){
							$('tr.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					case 'INT':
					case 'DECIMAL':
						createAttrRowInTable(className, attribute, label, type);
						if(values.length > 2){
							processNumber(values, attribute, total, values);
						}else{
							$('#'+attributeIdAttr+'-meanType').text('NA');
							$('#'+attributeIdAttr+'-normal').text('NA');
							$('#'+attributeIdAttr+'-value').text('NA');
							$('#'+attributeIdAttr+'-missing').text(total-values.length);
							$('#'+attributeIdAttr+'-total').text(values.length);
							$('#'+attributeIdAttr+'-totalSmallerThan5').text('Yes');
							$('#'+attributeIdAttr+'-shapiroWilk').text('NA');
						}
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					//if boolean: calculate true/false percentages
					case 'BOOL':
						bools.push(attribute);
						createAttrRowInTable(className, attribute, label, type);
						processBool(values, attribute, total);
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					//if categorical: calculate percentage for each category
					case 'ENUM':
						createAttrRowInTable(className, attribute, label, type);
						processEnum(values, attribute, total);
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					//if categorical: calculate percentage for each category
					case 'CATEGORICAL':
						cats.push(attribute);
					case 'XREF':
						createAttrRowInTable(className, attribute, label, type);
						//get ref entity from saved meta data
						var ref = meta.ref.href;
						processCategorical(attribute, values, total, ref);
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					//if categorical mref: calculate percentage for each category, can be more than 100% since one attribute can have more than one category each
					case 'CATEGORICAL_MREF':
						createAttrRowInTable(className, attribute, label, type);
						//get ref entity from saved meta data
						var ref = meta.ref.href;
						processCategoricalMref(attribute, values, total, ref);
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					//if string process as string, calculate missing, total, <5 and uniqueness
					case 'STRING':
						createAttrRowInTable(className, attribute, label, type);
						processString(attribute, values, total);
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
						break;
					//if attribute is not processable, put NA in every cell except from name and label
					default:
						createAttrRowInTable(className, attribute, label, type);
						processRemaining(attribute);
						doneCounter -= 1;
						if(doneCounter === 0){
							$('.compound-part .id-td').css('padding-left', '4em');
						}
				}
			}
		}
	)
}
function processCategorical(attribute, values, total, ref){
	//this function processes categorical values
	//put general info in table
	var na = total-values.length;
	var attributeIdAttr = attribute.replace('#', '');
	$('#'+attributeIdAttr+'-normal').text('NA');			
	$('#'+attributeIdAttr+'-missing').text(na+' ('+getPercentage(na, total)+'%)');
	$('#'+attributeIdAttr+'-total').text(total-na+'('+getPercentage(total-na, total)+'%)');
	$('#'+attributeIdAttr+'-shapiroWilk').text('NA');
	//get the ref entity to get all options that can be selected 
	$.get(ref).done(function(refEntity){
		var options = refEntity.items;
		//get also label and id
		var label = refEntity.meta.labelAttribute;
		var id = refEntity.meta.idAttribute;
		//get object that with the counted values for each option, and put the info in the table
		getValueCountsObj(values,id, function(counts){
			$.each(options, function(i, option){
				if(counts[option[id]]=== undefined){
					$('#'+attributeIdAttr+'-meanType').append(option[label]+' N(%)<br/>');
					$('#'+attributeIdAttr+'-value').append('0 (0%)<br/>');
				}else{
					$('#'+attributeIdAttr+'-meanType').append(option[label]+' N(%)<br/>');
					$('#'+attributeIdAttr+'-value').append(counts[option[id]]+' ('+getPercentage(counts[option[id]],total)+'%)<br/>');
				}
			});
		});
	});
	$('#'+attributeIdAttr+'-totalSmallerThan5').text(isSmallerThanFive(total-na));
}
function processCategoricalMref(attribute, values, total, ref){
	var arr = [];
	var countIfDone = total;
	$.each(values,
		function(i, values){
			var countValues = values.length;
			if(values.length === 0){
				countIfDone -= 1;
				if(countIfDone ===0){
					processCategorical(attribute, arr, total, ref);
				}
			}else{
				$.each(values,
					function(i, value){
						arr.push(value);
						countValues -= 1;
						if(countValues === 0){
							countIfDone -= 1;
							if(countIfDone ===0){
								processCategorical(attribute, arr, total, ref);
							}
						}
					}
				)
			}
		}
	)
}
function processCompound(attribute, values, attributes){
	var compoundAttrs = {}
	var doneCounter = attributes.length;
	$.each(attributes, 
		function(i, attribute){
			compoundAttrs[attribute] = data[attribute];
			metaData[attribute].partOf = undefined;
			doneCounter -= 1;
			if(doneCounter === 0){
				processData(compoundAttrs, 'compound-part');
			}
		}
	)
	
}
function isSmallerThanFive(value){
	//this function returns yes if the given value is smaller than 5 and no if not
	if(value < 5){
		return('Yes');
	}else{
		return('No');
	}
}
function getPercentage(value, total){
	//this function calculates the percentage of a value compared to the total, it returns it with two decimals (in string)
	return (value*100/total).toFixed(2);
}
function getValueCountsArr(values, callback){
	//counts occurences of values in an valuesay of values
	//http://stackoverflow.com/questions/11649255/how-to-count-the-number-of-occurences-of-each-item-in-an-valuesay
	// var obj = { };
	var obj = { };
	var checkDone = values.length;
	//for each value in the valuesay if it does not exist, put it in an object with count 0 and always count one
	for (var i = 0, j = values.length; i < j; i++) {
   		obj[values[i]] = (obj[values[i]] || 0) + 1;
   		checkDone -=1;
   		//if the forloop is done, go on with the callback function
   		if(checkDone === 0){
   			callback(obj);
   		}
	}
	return obj;
}
function getValueCountsObj(values, idAttr, callback){
	//counts occurences of values in an valuesay of objects, from which the id should be counted 
	//http://stackoverflow.com/questions/11649255/how-to-count-the-number-of-occurences-of-each-item-in-an-valuesay
	var obj = { };
	var checkDone = values.length;
	//for each object in the valuesay, get the id, if it does not exist, put it in an object with count 0 and always count one
	for (var i = 0, j = values.length; i < j; i++) {
   		obj[values[i][idAttr]] = (obj[values[i][idAttr]] || 0) + 1;
   		checkDone -= 1;
   		//if the forloop is done, go on with the callback function
   		if(checkDone === 0){
   			callback(obj);
   		}
	}
	return obj;
}
function getMetaData(callback){
	//this function gets the meta data of the entity with the rest api
	$.get('/api/v2/'+entity).done(
		function(entityData){
			//get the total of attributes and put that in the table
			var total = entityData.total;
			$('#noOfRecords').text(total);
			//get the attributes from the meta data and id attribute
			var meta = entityData.meta.attributes;
			var idAttribute = entityData.idAttribute;
			var doneCounter = meta.length;
			//put label, type and ref entity (if available, else undefined) of each attribute in an object with as key the id attribute
			$.each(meta, 
				function(i, attribute){
					//if done, call callback, use counter because sometimes the forloop is faster for one attribute than for the other and will run assynch
					if(doneCounter -1 === 0){
						metaData[attribute.name] = {'label':attribute.label, 'type':attribute.fieldType, 'ref': attribute.refEntity, 'parts':attribute.enumOptions}
						if(attribute.fieldType === 'COMPOUND'){
							processMetaIfCompound(attribute, 
								function(){
									callback(idAttribute);
								}
							);
						}else{
							data[attribute.name] = [];
							callback(idAttribute);
						}
					}else{
						metaData[attribute.name] = {'label':attribute.label, 'type':attribute.fieldType, 'ref': attribute.refEntity, 'parts':attribute.enumOptions}
						if(attribute.fieldType === 'COMPOUND'){
							processMetaIfCompound(attribute, function(){
								doneCounter -= 1;
							});
						}else{
							data[attribute.name] = [];
							doneCounter -= 1;
						}
					}
					
				}
			)
		}
	);
}
function saveAttrPart(attrPart, partOf){
	metaData[attrPart.name] = {'label':attrPart.label, 'type':attrPart.fieldType, 'ref': attrPart.refEntity, 'partOf':partOf}
	data[attrPart.name] = [];
	if(attrPart.fieldType === 'COMPOUND'){
		processMetaIfCompound(attrPart, function(){
			});
	}
}
function processMetaIfCompound(attribute, callback){
	var total = attribute.attributes.length;
	metaData[attribute.name]['parts']=[];
	$.each(attribute.attributes, 
		function(i, attrPart){
			metaData[attribute.name].parts.push(attrPart.name);
			saveAttrPart(attrPart, attribute.name);
			total -= 1;
			if(total === 0){
				data[attribute.name] = [];
				callback();
			}
		}
	)
}
function getRowData(row, greenLight, callback){
	//get information from a row and put this per attribute in an object, so not all attributes for one entity as in the rest api output, but data from all entities per attribute
	var trackKeeper = 1;
	$.each(row, 
		function(attribute, value){
			//skip the href
			if(attribute !== '_href'){
				data[attribute].push(value);
				if(trackKeeper === Object.keys(row).length && greenLight){
					callback();
				}else{
					trackKeeper += 1;
				}
			}else{
				trackKeeper += 1;
			}
		}
	)
}
function getRows(content, callback){
	//get a row from the rest api data and call getRowData to get the data of the row, if done, give green light to go on with the callback in the next function 
	doneCount = content.length;
	$.each(content, 
		function(i, row){
			if(doneCount === 1){
				getRowData(row, true, callback);
			}else{
				getRowData(row, false, callback);
				doneCount -=1;
			}
		}
	);
}
function gatherData(href, callback){
	//gather the data of the entity from the rest api, this function is recursive to get all data instead of a maximum of 10.000 items
	$.get(href).done(
		function(data){
			//get the items fo the data
			var dataContent = data.items;
			//get the href of the next 10.000 items
			var next = data.nextHref;
			//if there is no next href (and so there are less than 10.000 items), just process these rows
			if(next === undefined){
				getRows(dataContent, callback);
			//if there is a next href, call this one with the same function and process the lines of these data
			}else{
				gatherData(next);
				getRows(dataContent, callback);
			}
		}
	);
}
	function exportTableToCSV($table, filename) {
	//http://jsfiddle.net/terryyounghk/KPEGU/
	//this function exports a html table ($table, formatted as $("tableselector")) to a csv file with a given name
        //get all html table rows in the table	
		var $rows = $table.find('tr'),
			// Temporary delimiter characters unlikely to be typed by keyboard
			// This is to avoid accidentally splitting the actual contents
			tmpColDelim = String.fromCharCode(11), // vertical tab character
			tmpRowDelim = String.fromCharCode(0), // null character
			// actual delimiter characters for CSV format
			colDelim = '","',
			rowDelim = '"\r\n"',
			// Grab text from table into CSV formatted string, both headers and data
			csv = '"' + $rows.map(function (i, row) {
				//get all children of the row (td and th)
				var $row = $(row),
					$cols = $row.children();
				return $cols.map(function (j, col) {
					//get the text for each column
					var $col = $(col),
						text = $col.text();
					return text.replace(/"/g, '""'); // escape double quotes
				}).get().join(tmpColDelim);
			}).get().join(tmpRowDelim)
				.split(tmpRowDelim).join(rowDelim)
				.split(tmpColDelim).join(colDelim) + '"',
			// Data URI
			csvData = 'data:application/csv;charset=utf-8,' + encodeURIComponent(csv);
		$(this)
			.attr({
			'download': filename,
				'href': csvData,
				'target': '_blank'
		});
	}
    // This must be a hyperlink
    $(".export").on('click', function (event) {
        // CSV
        exportTableToCSV.apply(this, [$('#descriptiveStatistics table'), 'descriptive_statistics_'+entity+'.csv']);
    });
      
	function getArrayData(optionObj, callback){
	<!--//Convert dataformat to format required by google charts-->d
		var chartdata = [['Option', 'Count']];
 		var iteration= 0;
 		console.log(optionObj);
 		$.each(optionObj, function(option, count){
 			chartdata.push([option, count]);
 			iteration += 1;
 			if(iteration === Object.keys(optionObj).length){
 				console.log(chartdata);
 				callback(chartdata);
 			}
 		});
	}
</script>
