source(paste0('${url}', '/molgenis.R?molgenis-token=${molgenisToken}'))
data <- molgenis.get('${entity}', attributes=c("${column}"), num=10000)
print(shapiro.test(data$"${column}")$p.value)