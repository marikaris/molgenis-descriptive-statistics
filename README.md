# Molgenis Descriptive statistics

These script allow for some descriptive statistics on your data. The script reads the meta 
data and based on that it calculates statistics on your data:
- For strings it tests the uniqueness of the string (100% means all values are unique)
- For ints and decimals it calculates the normality using the shapiro wilk algorithm; 
when normally distributed, it shows the mean and standard deviation of you data; when not 
normally distributed, it shows the median and interquartile range 25 and 75
- For enums, xrefs and categoricals it calculates the usage percentages of each category
- For booleans it calculates true/false percentages
- For categorical mref: calculate percentage for each category, can be more than 100% since one attribute can have more than one category each
- If type is not processable, put NA in every cell except from name and label					
- It groups on compounds

## How to set up descriptive statistics table for Molgenis 
1. Go to your script plugin on your molgenis
2. Add the following R scripts to your script plugin with their parameters:
getIQR.R					url,column,entity
normalityCheck.R			url,column,entity
3. Go to your freemarkertemplate entity 
4. Make a new freemarkertemplate with this name: view-Descriptive statistics-entitiesreport.ftl
5. Paste the code of view-Descriptive statistics-entitiesreport.ftl in the template
6. Click on the settings icon for the dataexplorer (when you are in the data explorer, the little gear wheel right above)
7. Make sure Data - Reports is marked as Yes
8. In the Reports section you type: *fill in id of entity where table should be added to*:Descriptive statistics
If you want to add the table to several entities, then just put a , as seperator between them like:
table1:Descriptive statistics,table2:Descriptive statistics
The id of your table can be found if you navigate to your table in the dataexplorer and then look in the URL. The id is after the ?entity=
9. Now go to your entity and click on the tab Descriptive statistics