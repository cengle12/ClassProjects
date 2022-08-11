

# AS.410.671.82.SU22 – Final Project
# Date: 16AUG2022
# Author: Conner Engle

# Information and data used for this project can be found at: www.ncbi.nlm.nih.gov/sites/GDSbrowser?acc=GDS3032

# Title   :	
#	 - Quercetin effect on intestinal cell differentiation in vitro: time course
# Summary :	
#	- Analysis of post-confluent Caco-2 colon cancer cells up to 10 days after treatment with ascorbate-
#	  stabilized quercetin, a polyphenol antioxidant compound. Caco-2 cells differentiate after reaching
#	  confluency. Results provide insight into quercetin's role in cell-proliferation and -differentiation.
#
# Organism:	
#	- Homo sapiens

# Platform:	 
#	- GPL571: [HG-U133A_2] Affymetrix Human Genome U133A 2.0 Array

# Citation:	
#	- 	Dihal AA, Tilburgs C, van Erk MJ, Rietjens IM et al. Pathway and single gene analyses of inhibited Caco-2 
#     differentiation by ascorbate-stabilized quercetin suggest enhancement of cellular processes associated 
#     with development of colon cancer. 
# -   Mol Nutr Food Res 2007 
# -   Aug;51(8):1031-45. 
# -   PMID: 17639512

library(GEOquery)
library(gplots)
library(impute)
library(outliers)
library(MASS)
library(multtest)

##########
# PART I - Loading/Formatting Data and Annotation
##########

# Working directory set to location with data and annotation files
setwd('/Users/Conner/Desktop')

# Loading GEO data object and formatting columns based on treatment factor
geo <- getGEO("GDS3032")
geo.dat <- Table(geo)

control.cols <- 3:6
exp.cols <- 7:10
for (i in control.cols)  { colnames(geo.dat)[i] <- paste(colnames(geo.dat[i]), "control", sep = "_") }
for (i in exp.cols)  { colnames(geo.dat)[i] <- paste(colnames(geo.dat[i]), "quercetin", sep = "_") }
dat <- data.matrix(geo.dat[, (3:ncol(geo.dat))])

# Loading annotation file into dataframe for reference
ann.dat <- read.delim('GPL571.annot', header = TRUE, row.names = 1, skip = 27, sep = "\t")
ann.dat  <- ann.dat[1:nrow(geo.dat), ]
genes <- data.frame(Description = ann.dat$Gene.title, Symbol = ann.dat$Gene.symbol)
rownames(genes) <- rownames(ann.dat)

# set dat matrix rows as probe names from annotation file
row.names(dat) <- row.names(ann.dat)

dim(dat)

# After formatting we can see that the dataset has 8 samples and 22,277 probes. Now we are ready to analyze the data


##########
# PART II - Data Visualizations and Descriptive Statistics
##########

# Standard dev and row means across samples
d.sd    <- apply(dat, 1, sd, na.rm = TRUE)
d.rmeans <- rowMeans(dat, na.rm = TRUE)

# Histogram of std dev
hist(
  	d.sd, 
  	col  = "Green",
  	xlab = "Standard Deviation expression value for GDS3032 samples",
  	ylab = "Frequency",
  	main = paste("Histogram of standard deviation expression values for",nrow(dat),"genes)
  	)

# Histogram of row means
hist(
  	d.rmeans, 
  	col  = "Red",
  	xlab = "Mean expression value for GDS3032 samples",
  	ylab = "Frequency",
  	main = paste("Histogram of mean expression values for",nrow(dat),"genes")
  	)


##########
# PART III - Outlier Detection & Missing Value Imputation
##########

# Correlation matrix of data
dat.cor <- cor(dat, method = "pearson", use = "pairwise.complete.obs")

layout(matrix(c(1,1,1,1,1,1,1,1,2,2), 5, 2, byrow = TRUE))
par(oma=c(5,7,1,1))
cx <- rev(colorpanel(25,"yellow","black","blue"))
leg <- seq(min(dat.cor,na.rm=T),max(dat.cor,na.rm=T),length=10)
image(dat.cor,main="Correlation plot GDS3032 data",axes=F,col=cx)
axis(1,at=seq(0,1,length=ncol(dat.cor)),label=dimnames(dat.cor)[[2]],cex.axis=0.9,las=2)
axis(2,at=seq(0,1,length=ncol(dat.cor)),label=dimnames(dat.cor)[[2]],cex.axis=0.9,las=2)

image(as.matrix(leg),col=cx,axes=F)
tmp <- round(leg,2)
axis(1,at=seq(0,1,length=length(leg)),labels=tmp,cex.axis=1)

# PCA Plot of Samples
dat.pca <- prcomp(t(dat))
dat.loads <- dat.pca$x[,1:2]
plot(dat.loads[,1],dat.loads[,2],main="Sample PCA plot",xlab="p1",ylab="p2",col='red',cex=1,pch=15)
text(dat.loads,label=dimnames(dat)[[2]],pos=1,cex=0.5)


# Correlation plot of gene averages for control and quercetin by timepoints (5 vs. 10 days)
cor.m <- apply(dat.cor, 1, mean)

plot(
  	c(1,length(cor.m)), 
  	range(cor.m), 
  	type = "n", 
  	xlab = "",
  	ylab = "Average correlation",
  	main = "Avg correlation for control/quercetin samples by timepoint",
  	axes = FALSE
  	)

points(
  	cor.m,
  	col = c(rep("Blue", ncol(dat)/4), rep("Green", ncol(dat)/4), rep("Orange", ncol(dat)/4), rep("Red", ncol(dat)/4)),
  	pch = c(rep(16, ncol(dat)/4), rep(17, ncol(dat)/4), rep(18, ncol(dat)/4), rep(19, ncol(dat)/4))
  	)

axis(2)
axis(1, at=c(1:length(cor.m)), labels = colnames(dat), las = 2, cex.lab = 0.3, cex.axis = 0.5)
grid(nx = 16, col = "grey")

legend(
  	"bottomright",cex=0.8, 
  	c("Control - 5 days", "Control - 10 days", "Quercetin - 5 days", "Quercetin - 10 days"), 
  	pch = c(16:19), col = c("Blue", "Green", "Orange", "Red"), bg = "white"
  	)

# CV vs. mean plot
dat.mean <- apply(log2(dat),2,mean)
dat.sd <- sqrt(apply(log2(dat),2,var))
dat.cv <- dat.sd/dat.mean

plot(dat.mean,dat.cv,main="GDS3032 GEO Dataset\nSample CV vs. Mean",xlab="Mean",ylab="CV",col='blue',cex=1.5,type="n")
points(dat.mean,dat.cv,bg="lightblue",col=1,pch=21)
text(dat.mean,dat.cv,label=dimnames(dat)[[2]],pos=1,cex=0.5)

# Although the data shows wide variation across different factors, groups of the same factors are fairly similar. GSM174949
# and GSM174950 show the largest amount of discrepancy within groups but it is difficult to tell whether an outlier exists
# without more samples across the same factors. No samples will be removed as an outlier.


# Missing value imputation
colSums(is.na(dat))

# No missing values so no imputation necessary
# dat.knn <- impute.knn(dat.kng1,6)


##########
# PART IV - Gene Filtering
##########

# First remove genes with very little expression (essentially zero)
dat.filt <- subset(dat, log2(rowMeans(dat)) > 0)
num.removed <- nrow(dat) - nrow(dat.filt)

num.removed
# Output:
# 90 
# 
# Aka 90 low variation genes removed

dat.lg <- log2(dat.filt)
lg.mean <- apply(dat.lg, 1, mean) 
lg.var <- apply(dat.lg,1,var)
lg.cv <- lg.var/lg.mean

# CV vs mean plot for filtered genes across control and quercetin samples
plot(
 	lg.mean, 
 	lg.cv, 
 	xlab = "log2(RowMeans)",
 	ylab = "log2(CV)", ylim=c(-50,50),
 	main = "Plot of Row Mean v. Row Variance for control and quercetin samples across filtered genes",
 	col  = c(rep("Blue", ncol(dat)/2), rep("Green", ncol(dat)/2)),
 	pch  = c(rep(17, ncol(dat)/2), rep(19, ncol(dat)/2))
 	)
 
 
# Filter again removing genes with mean expression less than 3 on log2 scale
dat.filt2 <- subset(dat.lg, rowMeans(dat.filt) > 3)
num.removed.2 <- nrow(dat.lg) - nrow(dat.filt2)

num.removed.2
# Output:
# 6479 
# 
# Aka 6479 genes removed

lg.mean2 <- apply(dat.filt2, 1, mean) 
lg.var2 <- apply(dat.filt2,1,var)
lg.cv2 <- lg.var2/lg.mean2

# CV vs mean plot for second set of filtered genes
plot(
  	lg.mean2, 
  	lg.cv2,
  	xlim = c(-2, 15), ylim = c(-50, 50),
  	xlab = "log2(RowMeans)",
  	ylab = "log2(CV)",
  	main = "Second Filtered Plot of Row Mean v. Row Variance for control and quercetin samples",
  	col  = c(rep("Blue", ncol(dat)/2), rep("Green", ncol(dat)/2)),
  	pch  = c(rep(17, ncol(dat)/2), rep(19, ncol(dat)/2))
  	)
legend("bottomright", c("control", "quercetin"), pch = c(17, 19), col = c("Blue", "Green"))
abline(v = 3, col = 2, lwd = 2)

genes <- subset(genes, rownames(genes) %in% rownames(dat.filt2))
dat.2 <- dat.filt2

##########
# PART V - Feature Selection
##########

# Determine raw P values for each gene
con <- colnames(dat.2)[1:4]
quer <- colnames(dat.2)[5:8]

t.test.all.genes <- function(x,s1,s2) {
  x1 <- x[s1]
  x2 <- x[s2]
  x1 <- as.numeric(x1)
  x2 <- as.numeric(x2)
  t.out <- t.test(x1,x2, alternative="two.sided",var.equal=T)
  out <- as.numeric(t.out$p.value)
  return(out)
  }

pv <- apply(dat.2,1,t.test.all.genes,s1=con,s2=quer)

> sum(pv < 0.05)
# Output:
# 2119

> sum(pv < 0.01)
# Output:
# 657

# Adjusting p-value cutoff to bonferroni corrected value
bonf <- 0.05/length(pv)
bonf
# Output:
# 2.398542e-06

sum(pv < bonf)
# Output:
# 3
# Only three genes meet bonferroni adjusted cutoff!

# Table for comparison of top 15 p-values 
holm.pv <- p.adjust(pv, method = "holm")
raw.pv  <- sort(pv)
holm.pv <- sort(holm.pv)
p1     <- as.matrix(raw.pv)
p2     <- as.matrix(holm.pv)
tot.p  <- cbind(p1, p2)
colnames(tot.p) <- c('Raw P-Value', 'Adjusted P-Value')

write.matrix(head(tot.p,15),file="SelectionPVals_Top15.csv")

sum(holm.pv < 0.05)
# Output:
# 3
# Consistent with Bonferroni corrected cutoff

sum(holm.pv < 0.01)
# Output:
# 0

# Plot of raw P-values
plot(
  	raw.pv, type = "b", pch = 1, col = "lightblue",
  	xlab = "Genes",
  	ylab = "P-values",
  	main = "Raw P-values for All Genes in GDS3032\n"
)
abline(h=0.05,col='red')

# Plot of raw vs adjusted P-values
matplot(
  	tot.p, type = "b", pch = 1, col = 1:2,
  	xlab = "Genes",
  	ylab = "P-values",
  	main = "Raw vs. Adjusted P-values for All Genes in GDS3032\n"
  	)
abline(h=0.05,col='red')   # Shows how conservative bonferroni adjustment is

# Histogram distribution of raw and adjusted p-values for GDS3032 genes
hist(
  	pv, 
  	col  = "lightblue",
  	xlab = "P-Value",
  	ylab = "Frequency",
  	main = "Histogram of t-test p-values for GDS3032 genes"
  	)
hist(
  	holm.pv, 
  	col  = "darkgreen",
  	add  = TRUE 
  	)
legend("bottomright", legend = colnames(tot.p), pch = 16, col = c("lightblue", "green"),bg='white')

# Log2 Fold Change
control.vals  <- dat.2[, 1:4]
con.m    <- apply(control.vals, 1, mean, na.rm = TRUE)
quer.vals <- dat.2[, 5:8]
quer.m   <- apply(quer.vals, 1, mean, na.rm = TRUE)
fold.change <- con.m - quer.m

# Find genes with 2-fold change and create dataframe to store
fold.2 <- lapply(as.list(fold.change), function(x){ if (abs(x) > log2(2)) TRUE else FALSE })
fold.dat   <- as.data.frame(do.call(rbind, fold.2))
names(fold.dat) <- c("2.fold")

# Breakdown of 2-fold change
table(fold.dat$2.fold)
# Output:
# FALSE  TRUE 
# 17718  3128 

# Histogram distribution of log2 fold change
hist(
  	fold.change, 
  	col  = "lavender",
  	xlab = "Log2 Fold Change",
  	ylab = "Frequency",
  	main = paste("Histogram of Fold Change values for GDS3032 genes")
  	)
abline(v = log2(2), col = 2, lwd = 2)
abline(v = -log2(2), col = 2, lwd = 2)

# Volcano Plot
p.transformed <- (-1 * log10(pv))
 
plot(
  	range(p.transformed),
  	range(fold.change),
  	type = "n", xlab = "-1 * log10(P-Value)", ylab = "Fold Change",
  	main = "Volcano Plot Illistrating  Control vs. Quercetin Differences"
  	)
points(
  	p.transformed, fold.change,
  	col = 1, bg = 1, pch = 21
  	)
points(
  	p.transformed[(p.transformed > -log10(0.05) & fold.change > log2(2))],
  	fold.change[(p.transformed > -log10(0.05) & fold.change > log2(2))],
  	col = 1, bg = 2, pch = 21
  	)
points(
  	p.transformed[(p.transformed > -log10(0.05) & fold.change < -log2(2))],
  	fold.change[(p.transformed > -log10(0.05) & fold.change < -log2(2))],
  	col = 1, bg = 3, pch = 21
  	)
abline(v = -log10(0.05))
abline(h = -log2(2))
abline(h = log2(2))

# Insert p cutoff and fold-change cutoff into gene annotation dataframe
p.cutoff <- lapply(as.list(pv), function(f){ if (f < 0.05) TRUE else FALSE })
p.col <- as.data.frame(do.call(rbind, p.cutoff), rname = row.names(dat.2))
colnames(p.col) <- c('PVal.Met')
genes$PVal.Met <- p.col$PVal.Met

genes$Fold.Met <- fold.dat$Fold.Test

# Isolate Genes that meet both criteria
cutoff.genes <- subset(genes, (PVal.Met & Fold.Met) == TRUE)
write.table(cutoff.genes, file = "Cutoff_Genes.csv", sep = ",", col.names = NA, qmethod = "double")

# Ordering data by p-value and converting back from log2 values
ord <- order(pv)[1:length(pv)]
dat.3 <- 2^dat.2[ord, ]

top.genes <- data.frame(
  					index = ord,
  					exp   = 2^dat.2[ord, ],
  					pval  = pv[ord]
  				)
top.p <- top.genes$pval[top.genes$pval < 0.05]

# Histogram of top gene p-values
hist(
  	top.p,
  	col  = "lightblue",
  	xlab = "P-Value",
  	ylab = "Frequency",
  	main = "Histogram of T-Test P-Values values for ranked genes GDS3032"
  	)
abline(v = 0.05, col = 2, lwd = 2)

# Top and bottom 5 ranked genes from subset
top.5    <- head(dat.3, n = 5L)

# Output:
#         GSM174945_control GSM174946_control GSM174949_control GSM174950_control GSM174819_quercetin GSM174944_quercetin GSM174947_quercetin GSM174948_quercetin
# 206199_a          4.54794           9.16003           5.45883           6.04873           93.005800           89.448200           89.982900           95.619300
# 220726_at         7.23891           7.63533           9.01140           7.31185            0.417399            0.270324            0.571531            0.450969
# 203108_at         158.58600         133.69600         142.63000         123.92300          543.428000          560.836000          458.816000          464.183000
# 218162_at         133.69600         164.54100         158.99800         152.86000           53.758900           59.972800           66.027000           61.102300
# 212444_at         178.66200         197.53500         168.75600         146.18300          637.492000          607.951000          507.303000          531.807000

bottom.5 <- tail(dat.3.info, n = 5L)

# Output:
#           GSM174945_control GSM174946_control GSM174949_control GSM174950_control GSM174819_quercetin GSM174944_quercetin GSM174947_quercetin GSM174948_quercetin
# 221091_at           8.23675           9.52495           10.8211           2.87859             11.7485             8.65834             2.83046             8.48339
# 201965_s_at         133.75200          99.57240          171.5570         127.68500            131.0810           101.75900           128.50600           170.22300
# 203387_s_at         308.05900         381.61800          166.1550         144.44100            413.0110           406.01500           135.19700           124.49200
# 210645_s_at         789.87900         731.44800          813.3510         669.77600            767.9700           799.61200           832.88700           615.35300
# 215421_at           5.01988           8.58506           13.1882           1.47508             13.6813             1.44688             3.43275            12.33490


##########
# PART VI - Dimensionality Reduction
##########




