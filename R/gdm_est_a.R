


###########################################
# estimation of a
# Q matrix [1:I , 1:TD , 1:K]
# thetaDes [TP,TD]
# n.ik [ TP , I , K+1 , G ]
# N.ik [ TP , I , G ]
# probs [I , K+1 , TP ]

gdm_est_a <- function(probs, n.ik, N.ik, I, K, G,a,a.constraint,TD,
				Qmatrix,thetaDes,TP, max.increment ,
				b , msteps , convM , centerslopes, decrease.increments=TRUE )
{
	iter <- 1
	parchange <- 1
	a00 <- a
	eps <- 1E-10

	maxa <- max.increment + 0 * a
	while( ( iter <= msteps ) & ( parchange > convM )  ){
		a0 <- a
		probs <-  gdm_calc_prob( a=a, b=b, thetaDes=thetaDes, Qmatrix=Qmatrix, I=I, K=K, TP=TP, TD=TD ) 
		# 1st derivative	
		d2.b <- d1.b <- array( 0 , dim=c(I , TD ) )
		for (td in 1:TD){
			for (gg in 1:G){
				for (kk in 2:(K+1)){		
					QM <- matrix( Qmatrix[  , td , kk-1 ]  , nrow=TP , ncol=I , byrow=TRUE )
					v1 <- colSums( n.ik[,,kk,gg] * QM * thetaDes[ , td ] )
					v2 <- N.ik[,,gg] * QM * thetaDes[,td] *  t( probs[,kk,] )
					v2 <- colSums(v2)
					d1.b[  , td] <- d1.b[,td] + v1 - v2
				}
			}
		}
		# 2nd derivative
		for (td in 1:TD){
			for (ii in 1:I){
				v1 <- l0 <- 0
				for (gg in 1:G){
					for (kk in 2:(K+1) ){		# kk <- 2
						v1 <- v1 + N.ik[,ii,gg] * as.vector( ( Qmatrix[ii,td,kk-1] * 
							thetaDes[ , td ] )^2 * t( probs[ii,kk,] ) )
						l0 <- l0 + as.vector ( Qmatrix[ii,td,kk-1] * thetaDes[ , td ]  * t( probs[ii,kk,] ) )			
					}															
				}				
				d2.b[ii,td] <- sum(v1) - sum( l0^2 * N.ik[,ii,gg] )
			}
		}
		increment <-  d1.b / abs( d2.b + eps )
		increment[ is.na(increment) ] <- 0		
		increment <- ifelse(abs(increment)> max.increment, 
						   sign(increment)*max.increment , increment )							   					  				
		a[,,1] <- a[,,1] + increment	
		se.a <- sqrt( 1 / abs( d2.b + eps ) )
		if (K>1){ 
			for (kk in 2:K){ 
				a[,,kk] <- a[,,1] }	 
		}	
		if ( ! is.null( a.constraint) ){
			a[ a.constraint[,1:3,drop=FALSE] ] <- a.constraint[,4,drop=FALSE]
			se.a[ a.constraint[,1:3,drop=FALSE] ] <- 0			
			increment[ a.constraint[,1:2,drop=FALSE] ] <- 0			
		}		
		if (centerslopes){
			if (TD>1){
				m11 <- t( colSums( a[,,1] ) / colSums( Qmatrix ) )	
				a[,,1] <- a[,,1] / m11[ rep(1,I) , ]
			}
			if (TD==1){
				m11 <- t( colSums( a ) / colSums( Qmatrix ) )	
				a <- a / m11[ rep(1,I) , ]
			}						
		}
		parchange <- max( abs(a-a0) )
		iter <- iter + 1
	}	# end iter
	#------------
	max.increment.a <- max(abs(a-a00)) / 1.005
	if (decrease.increments){ 
		max.increment.a <- max.increment.a / 1.01	
	}	
	#-- OUTPUT
	res <- list( a = a , se.a = se.a , max.increment.a = max.increment.a)
	return(res)
}		


.gdm.est.a <- gdm_est_a