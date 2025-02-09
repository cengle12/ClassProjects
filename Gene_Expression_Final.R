

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
  	main = paste("Histogram of standard deviation expression values for",nrow(dat),"genes")
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
cutoff.genes.2 <- merge(cutoff.genes, fold.change,by = 'row.names', all.x=TRUE)
cut.3 <- cbind(cutoff.genes.2, pv.df[row.names(cutoff.genes),])
row.names(cut.3) <- cut.3$Row.names
cut.3 <- cut.3[,-1]
col.names(cut.3) <- c('Description','Symbol','PVal.Met','Fold.Met','Fold.Change','P.Val')					    
genes.out <- cut.3[order(cut.3$P.Val),]
genes.out.fold <- cut.3[order(cut.3$Fold.Change),]						    

# Ordered by significance					    
write.table(genes.out, file = "Cutoff_Genes.csv", sep = ",", col.names = NA, qmethod = "double")
top.5.sig <- head(genes.out)		# Top and bottom 5 by significance level				    
bottom.5.sig <- tail(genes.out)					    

# Ordered by fold change					    
write.table(genes.out.fold, file = "Cutoff_Genes_Fold.csv", sep = ",", col.names = NA, qmethod = "double")
top.5.fold <- head(genes.out.fold)	# Top and bottom 5 by fold					    
bottom.5.fold <- tail(genes.out.fold)
					    

# Subset of data used going forward
dat.3 <- dat.2[row.names(genes.out),]

top.genes <- data.frame(
  					index = row.names(genes.out),
  					exp   = 2^dat.3[row.names(genes.out), ],
  					pval  = pv[row.names(genes.out)]
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

##########
# PART VI - Dimensionality Reduction
##########

# Principle Component Analysis
pca <- prcomp(t(dat.3))
pca.loads <- pca$x[, 1:3]

# PC1 vs. PC2                                            
plot(
  	range(pca.loads[, 1]), 
  	range(pca.loads[, 2]), 
  	type = "n",
  	xlab = "Principal Component 1",
  	ylab = "Principal Component 2",
  	main = "PCA Plot for GDS3032 data\n PC1 vs. PC2"
  	)
points(
  	pca.loads[, 1][1:4], 
  	pca.loads[, 2][1:4],
  	col = "Blue", pch = 15
  	)
points(
  	pca.loads[, 1][5:8], 
  	pca.loads[, 2][5:8],
  	col = "Red", pch = 19
  	)
legend(
  	"bottomright", 
  	c("control", "quercetin"), 
  	col = c("Blue", "Red"), pch = c(15,19)
  	)                                            
                                            
# PC2 vs. PC3
plot(
  	range(pca.loads[, 2]), 
  	range(pca.loads[, 3]), 
  	type = "n",
  	xlab = "Principal Component 2",
  	ylab = "Principal Component 3",
  	main = "PCA Plot for GDS3032 data\n PC2 vs. PC3"
  	)
points(
  	pca.loads[, 2][1:4], 
  	pca.loads[, 3][1:4],
  	col = "Blue", pch = 15
  	)
points(
  	pca.loads[, 2][5:8], 
  	pca.loads[, 3][5:8],
  	col = "Red", pch = 19
  	)
legend(
  	"bottomleft", 
  	c("control", "quercetin"), 
  	col = c("Blue", "Red"), pch = c(15,19)
  	)                                             
                                            
# PC1 vs PC3                                            
plot(
  	range(pca.loads[, 1]), 
  	range(pca.loads[, 3]), 
  	type = "n",
  	xlab = "Principal Component 1",
  	ylab = "Principal Component 3",
  	main = "PCA Plot for GDS3032 data\n PC1 vs. PC3"
  	)
points(
  	pca.loads[, 1][1:4], 
  	pca.loads[, 3][1:4],
  	col = "Blue", pch = 15
  	)
points(
  	pca.loads[, 1][5:8], 
  	pca.loads[, 3][5:8],
  	col = "Red", pch = 19
  	)
legend(
  	"bottomright", 
  	c("control", "quercetin"), 
  	col = c("Blue", "Red"), pch = c(15,19)
  	)                                              
                                            
pca.var <- round(pca$sdev^2 / sum(pca$sdev^2) * 100, 2)
sum(pca.var[1:2])  # 74.3% of variability in the data explained by first two eigenvalues
                                            
plot(
	c(1:length(pca.var)), 
	pca.var, 
	type = "b", 
	xlab = "Components",
	ylab = "Percent Variance", 
	bg = "Blue", pch = 21
	)
title("Scree Plot Illistrating %-Variability Explained By Each Eigenvalue\n control/quercetin - GDS3032 Dataset")                                            
                                            
# Nonlinear - Weighted Laplacian Graph
temp <- t(dat.3)
temp <- scale(temp, center = T, scale = T)
                                            
k.speClust2 <- function (X, qnt=NULL) {
  dist2full <- function(dis) {
    n <- attr(dis, "Size")
        full <- matrix(0, n, n)
        full[lower.tri(full)] <- dis
        full + t(full)
  }
  dat.dis <- dist(t(X),"euc")^2
  if(!is.null(qnt)) {eps <- as.numeric(quantile(dat.dis,qnt))}
  if(is.null(qnt)) {eps <- min(dat.dis[dat.dis!=0])}
  kernal <- exp(-1 * dat.dis/(eps))
  K1 <- dist2full(kernal)
  diag(K1) <- 0
  D = matrix(0,ncol=ncol(K1),nrow=ncol(K1))
  tmpe <- apply(K1,1,sum)
  tmpe[tmpe>0] <- 1/sqrt(tmpe[tmpe>0])
  tmpe[tmpe<0] <- 0
  diag(D) <- tmpe
  L <- D%*% K1 %*% D
  X <- svd(L)$u
  Y <- X / sqrt(apply(X^2,1,sum))
}                                            
phi <- k.speClust2(t(temp),qnt=NULL)

plot(
  	range(phi[, 1]), range(phi[, 2]),
  	xlab = "Phi 1", ylab = "Phi 2",
  	main = "Weighted Graph Laplacian Plot for GDS3032 Dataset\ncontrol vs quercetin"
  	)
points(
  	phi[, 1][1:4],
  	phi[, 2][1:4], 
  	col = "Red", pch = 16, cex = 1.5
  	)
points(
  	phi[, 1][5:8], 
  	phi[, 2][5:8], 
  	col = "Blue", pch = 16, cex = 1.5
  	)
legend("bottomright", c("control", "quercetin"), col = c("Red", "Blue"), fill = c("Red", "Blue"))                                            
                                            
##########
# PART VII - Clustering
##########                                            

# Manhattan distance for clustering (more conservative distance measure) with median agglomeration
clust.dist <- dist(t(dat.3), method = "manhattan")
clust.dat <- hclust(clust.dist, method = "median")					    
                                            
# Plotting dendrogram
plot(
	clust.dat,
	labels = colnames(dat.3),  
	xlab   = "Median Clustered Samples",
	ylab   = "Manhattan Distance",
	main   = "Hierarchical Clustering Dendrogram\nRanked Intestinal Cell Differentiation Classification"
	)					    

# Heatmap of top 100 genes					    
hm.rg <- c("#FF0000","#CC0000","#990000","#660000","#330000","#000000","#000000","#0A3300","#146600","#1F9900","#29CC00","#33FF00")                                            

heatmap(
 	dat.3[1:100, ],
 	col  = hm.rg,
 	xlab = "Samples",
 	ylab = "Top Ranked Genes",
 	main = "Heatmap for the top 100 genes GDS3032 Dataset",cexCol=0.4
 	)

					    
##########
# PART VIII - Classification
########## 					    

# Linear Discriminant Analysis
# This was first performed by factor and subfactor but there was not enough within group variablity between factors
# Therefore LDA used only by primary factor or control vs quercetin				    
					    
pre.lda <- t(dat.3)
training <- as.data.frame(rbind(pre.lda[c(1, 3, 5, 7), ]))					    
test <- as.data.frame(rbind(pre.lda[c(2, 4, 6, 8), ]))
					    
te.names <- rownames(test)					    
#te.names[c(1, 3)] <- paste("5d", te.names[c(1, 3)], sep = "_")
#te.names[c(2, 4)] <- paste("10d", te.names[c(2, 4)], sep = "_")					    
test.names <- factor(gsub('GSM[[:digit:]]+_', '', te.names))				#_[[:alpha:]]+
					    
train.names <- rownames(training)					    
#train.names[c(1, 3)] <- paste("5d", train.names[c(1, 3)], sep = "_")					    
#train.names[c(2, 4)] <- paste("10d", train.names[c(2, 4)], sep = "_")					    
training.names <- factor(gsub('GSM[[:digit:]]+_', '', train.names))	# _[[:alpha:]]+				    

# Used only first 5,000 genes due to system constraints					    
dat.lda <- lda(training.names ~ ., data = training[, c(1:5000)])					    
dat.pred <- predict(dat.lda, data = test[, c(1:5000)])					    
table(dat.pred$class, test.names)

# Output:
#            control quercetin
#  control         2         1
#  quercetin       0         1

# GSM174947_quercetin incorrectly classified as control
					    
					    
plot(
	dat.pred$x,
	bg=as.numeric(factor(training.names)),
	pch=21,
	col=1,
	ylab="Discriminant function",
	axes=F,
	xlab="Score",
	main="Discriminant function for GDS3032 dataset"
)
axis(1,at=c(1:4),train.names,las=2,cex.axis=0.4)
axis(2)					    
					    
					    
# Gene names & GO
top.5.sig
					    
# Output:					    
#                                                          Description  Symbol PVal.Met Fold.Met Fold.Change        P.Val
# 206199_at carcinoembryonic antigen related cell adhesion molecule 7 CEACAM7     TRUE     TRUE   -3.916812 1.767013e-06
# 220726_at                                                                       TRUE     TRUE    4.233547 1.981332e-06
# 203108_at       G protein-coupled receptor class C group 5 member A  GPRC5A     TRUE     TRUE   -1.859084 2.268419e-06
# 218162_at                                       olfactomedin like 3  OLFML3     TRUE     TRUE    1.340310 5.646760e-06
# 212444_at       G protein-coupled receptor class C group 5 member A  GPRC5A     TRUE     TRUE   -1.727014 6.907572e-06
# 207790_at                          leucine rich repeat containing 1   LRRC1     TRUE     TRUE   -1.660251 1.888056e-05				    

top.5.fold					    

# Output:					    
#                                                            Description  Symbol PVal.Met Fold.Met Fold.Change        P.Val
# 210517_s_at                             A-kinase anchoring protein 12  AKAP12     TRUE     TRUE   -4.251244 1.167626e-02
# 208338_at                                   purinergic receptor P2X 3   P2RX3     TRUE     TRUE   -4.071281 3.742866e-04
# 204259_at                                   matrix metallopeptidase 7    MMP7     TRUE     TRUE   -3.981677 5.993508e-03
# 206199_at   carcinoembryonic antigen related cell adhesion molecule 7 CEACAM7     TRUE     TRUE   -3.916812 1.767013e-06
# 221393_at         trace amine associated receptor 3 (gene/pseudogene)   TAAR3     TRUE     TRUE   -3.608596 1.331667e-02
# 200907_s_at                 palladin, cytoskeletal associated protein   PALLD     TRUE     TRUE   -3.594829 3.498722e-04					    
					    
bottom.5.fold			    
					    
# Output:
#                                                     Description Symbol PVal.Met Fold.Met Fold.Change        P.Val
# 217068_at                                                                  TRUE     TRUE    3.442838 3.847880e-04
# 217623_at                           myosin light chain kinase 3  MYLK3     TRUE     TRUE    3.478276 2.809966e-05
# 206795_at        coagulation factor II thrombin receptor like 2  F2RL2     TRUE     TRUE    3.572501 1.414994e-03
# 214218_s_at X inactive specific transcript (non-protein coding)   XIST     TRUE     TRUE    3.750045 3.588891e-04
# 220726_at                                                                  TRUE     TRUE    4.233547 1.981332e-06
# 216625_at                                                                  TRUE     TRUE    4.243770 4.700057e-04					    
					    
					    
					    					    
