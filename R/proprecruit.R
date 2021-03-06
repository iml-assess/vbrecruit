#' Proportion of a cohort recruiting each year
#'
#' Using a Von Bertalanffy growth function and parameters you supply, this determines the proportion
#' of a cohort's numbers and biomass that are at or above different size classes each year
#' @param birth.year four digit year of birth
#' @param final.year four digit final year of the growth projection (birth year + average max age is good)
#' @param Linf VB maximum length (cm)
#' @param k VB k
#' @param t0 VB t-zero
#' @param cv coefficient of variation on length for an age
#' @keywords VonBertalanffy growth recruit age
#' @export
#' @examples
#' cohort.props.f(birth.year=2011, final.year = 2030, Linf = 42, k = 0.086, t0 = -1.57, cv = 0.089)
#' vb.growth.f(age.vector=1:40,Linf=42,k=0.086,t0=-1.57,cv=0.1)
cohort.props.f= function(birth.year, final.year, Linf, k, t0, cv){
  years= 1:(final.year-birth.year)
  lengths=ceiling(Linf+Linf*cv*3):1 #need to reverse length vector to make diff work properly.
  props.gte.len= matrix(nrow=length(lengths),ncol=length(years))
  for (i in years){
    len= Linf*(1-exp(-k*(i-t0)))
    props.gte.len[,i]= 1-pnorm(lengths,len,len*cv)
  }

  # this part does the same calculation but for biomass. I have disabled it though because it involves
  # extra assumptions that I think are against the simplicity of such a method for abundance. If you want
  # to enable it, think about it first.

  # props.gte.len= as.data.frame(props.gte.len)
  # names(props.gte.len)=c(paste("Y",(birth.year+1):final.year,sep=""))
  # row.names(props.gte.len)=paste(lengths,"cm",sep="")
  # #computes the proportion of individuals in each size class noting that they are from largest to smallest size
  # props.eq.len= apply(props.gte.len,2,diff)
  # weight= (exp(lw.a)*lengths^lw.b)[-1]
  # # multiply the proportion in each length class by the nominal weight of individuals in that length class.
  # bmass.len= props.eq.len*weight
  #
  #
  # bmass.sum= apply(bmass.len,2,sum) # compute the total biomass for a year
  # props.bmass.len= t(t(bmass.len)/bmass.sum)
  # props.bms.gte.len= apply(props.bmass.len,2,cumsum)
  #
  # # The output is reversed again so it goes from smallest to largest size
  #outp= list(abundance.props= props.gte.len[lengths,][-length(lengths),], biomass.props= props.bms.gte.len[lengths[-1],])
  outp= list(abundance.props= props.gte.len[lengths,][-length(lengths),])
  outp
}



#' Von Bertalanffy growth
#'
#' Using a Von Bertalanffy growth function and parameters you supply, show the trajectory for the supplied age vector
#' @param age.vector ages
#' @param Linf VB maximum length (cm)
#' @param k VB k
#' @param t0 VB t-zero
#' @param cv coefficient of variation on length for an age
#' @keywords VonBertalanffy growth recruit age
#' @export
#' @examples
#' vb.growth.f(age.vector=1:40,Linf=42,k=0.086,t0=-1.57,cv=0.1)
#' cohort.props.f(birth.year=2011, final.year = 2030, Linf = 42, k = 0.086, t0 = -1.57, cv = 0.089)
vb.growth.f= function(age.vector,Linf,k,t0,cv){
  Amax= max(age.vector) #maximum age
  A=age.vector
  L= Linf*(1-exp(-k*(age.vector-t0)))
  stdev= cv*L
  CI.low= L-1.96*stdev
  CI.high= L+1.96*stdev
  vb.growth= data.frame(Age=A,Length=L,Length.CI.low= CI.low, Length.CI.high=CI.high)
  vb.growth
}



#' Von Bertalanffy growth solved for mean age given a length
#'
#' Using a Von Bertalanffy growth function and parameters you supply, show the mean age given a specified length
#' @param length.vector ages
#' @param Linf VB maximum length (cm)
#' @param k VB k
#' @param t0 VB t-zero
#' @keywords VonBertalanffy growth recruit age
#' @export
VB.growth.for.age.f= function(length.vector,k,Linf,t0){
  age.vector= (1/-k) * log(1-length.vector/Linf)+t0
  VB.age= data.frame(length=length.vector, age=age.vector)
  VB.age
}


#' The proportion of a cohort of at or above difference sizes cumulative distribution
#'
#' Using a Von Bertalanffy growth function and parameters you supply, this determines the proportion
#' of a cohort's numbers and biomass that are at or above different size classes each year and plots them. A helper
#' function not usually called directly. It is called by the overall vbrecruit function.
#' @param proj.object a projection object produced by vbgrowth.f
#' @param birth.year four digit year of birth
#' @param final.year four digit final year of the growth projection (birth year + average max age is a good)
#' @param lengths.of.interest (often the length at recruitment to the fishery or a valuable size
#' @param Linf VB maximum length (cm)
#' @param k VB k
#' @param t0 VB t-zero
#' @param cv coefficient of variation on length for an age
#' @keywords VonBertalanffy growth recruit age
#' @export
#' @examples
#' vbrecruit.f(birth.year=2011, final.year = 2050, Linf = 42, k = 0.086, t0 = -1.57, cv = 0.089,
#'    lengths.of.interest=c(22,25,27,30))
#' cohort.props.f(birth.year=2011, final.year = 2030, Linf = 42, k = 0.086, t0 = -1.57, cv = 0.089)
#' vb.growth.f(age.vector=1:40,Linf=42,k=0.086,t0=-1.57,cv=0.089)
plotcdfa.f= function(proj.object,lengths.of.interest,birth.year,final.year,k,Linf,t0, cv){
  abund= proj.object$abundance.props
  years= (birth.year+1):final.year
  plot(years,abund[lengths.of.interest[1],],lwd=2,type="n",xlab="",ylab="",las=1,cex.axis=.85,ylim=c(0,1))
  for (i in lengths.of.interest){
    lines(years,abund[i,],lwd=2)
    y50= VB.growth.for.age.f(i,k=k,Linf=Linf,t0=t0)[2]+birth.year
    #y50= propinterp.f(recruiting.matrix=abund, birth.year=birth.year, final.year=final.year,len=i)
#    text(y50,0.65,paste(i,"cm"),cex=0.6)
    points(y50,0.5,pch=21,cex=1.7,bg="white")
    text(y50,.5,i,cex=0.5)
    lines(c(y50,y50),c(-.5,0.5),col="grey",lty=1)
  }
  legend("topleft",legend=paste("birth year=",birth.year,sep=""),bty="n",cex=0.6,xjust=0)
}


#' Proportion of a cohort recruiting each year, plots, wrapper function
#'
#' Using a Von Bertalanffy growth function and parameters you supply, this determines the proportion
#' of a cohort's numbers and biomass that are at or above different size classes each year
#' @param birth.year four digit year of birth
#' @param final.year four digit final year of the growth projection (birth year + average max age is a good)
#' @param Linf VB maximum length (cm)
#' @param k VB k
#' @param t0 VB t-zero
#' @param cv coefficient of variation on length for an age
#' @param lengths.of.interest (often the length at recruitment to the fishery or a valuable size
#' @keywords VonBertalanffy growth recruit age
#' @export
#' @examples
#' cohort.props.f(birth.year=2011, final.year = 2030, Linf = 42, k = 0.086, t0 = -1.57, cv = 0.089)
#' vb.growth.f(age.vector=1:40,Linf=42,k=0.086,t0=-1.57,cv=0.089)
#' recruit=vbrecruit.f(birth.year=2011, final.year = 2035, Linf = 42, k = 0.086, t0 = -1.57, cv = 0.089,
#'    lengths.of.interest=c(25,22,27,30,35))
vbrecruit.f= function(birth.year, final.year, Linf, k, t0, cv, lengths.of.interest){
  props= cohort.props.f(birth.year=birth.year, final.year=final.year, Linf=Linf, k=k, t0=t0, cv=cv)
  ages= 0:(final.year-birth.year)
  growth= vb.growth.f(age.vector=ages,Linf=Linf,k=k,t0=t0,cv=cv)
  old.pars=par()
  par(mfcol=c(2, 1),mar=c(3, 3, 1, 3),omi=c(.01, 1.5, .01, 1.5))
  plot(growth$Age,growth$Length,xlab="Age", ylab="Length (cm)",type="n",ylim=c(0,max(growth$Length.CI.high)+1.01),cex.axis=.85)
    mtext("Age (years)",side=1,line=2)
    mtext("Length (cm)",side=2,line=2.5)
    legend("bottomright",legend=c(paste("Linf=",Linf),paste("k=",k),paste("t0=",t0),paste("cv=",cv)),bty="n",cex=0.6)
  polygon(x=c(growth$Age, rev(growth$Age)), y=c(growth$Length.CI.low,rev(growth$Length.CI.high)), col = "grey", border = NA)
  lines(growth$Age,growth$Length,lwd=2)
  props$vbcurve= growth
  plotcdfa.f(props,lengths.of.interest=lengths.of.interest,birth.year=birth.year,final.year=final.year,
    k=k, Linf=Linf, t0=t0, cv=cv)
  mtext("Year",side=1,line=2)
  mtext("Prop abundance > size",side=2,line=2.5)
  par=old.pars
  props$years= birth.year:final.year
  props$lengths= 1:nrow(props$abundance.props)
  props
}
