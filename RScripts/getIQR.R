source(paste0('${url}', '/molgenis.R?molgenis-token=${molgenisToken}'))
data <- molgenis.get('${entity}', attributes=c("${column}"), num=10000)
values <- data$'${column}'
print(quantile(values, na.rm=T))