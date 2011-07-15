library(ggplot2)
args <- commandArgs(trailingOnly = T)
corpus <- read.csv(args[1])
fit <- cmdscale(corpus, k=2)
data <- as.data.frame(fit)
data$Category <- gsub("\\d+ ", "", rownames(data))
data$URLID <- gsub("(\\d+)?.*", "\\1", rownames(fit))

Category <- gsub("\\d+ ", "", rownames(fit))

png(args[2], width=500, height=500, res=100)

ggplot(data) +
    geom_point(data=subset(data, URLID != ""),
        aes(x=V1, y=V2, size=1.5, color=factor(Category))) +
    geom_point(data=subset(data, URLID == ""),
        aes(x=V1, y=V2, size=7, shape=c(1), color=factor(Category))) +
    scale_x_continuous("", breaks=NA) +
    scale_y_continuous("", breaks=NA) +
    opts(axis.text.x = theme_blank(), axis.title.x=theme_blank(),
        axis.text.y = theme_blank(), axis.title.y=theme_blank(),
        legend.position = "none") +
    facet_wrap(~ Category)


#plot(x, y, pch=19, xaxt='n', yaxt='n', ann=FALSE)
#plot(x, y, type="n")
#text(x, y, labels=row.names(corpus), cex=1.5)

