

#######################################
# attach all elements in an environment   
attach_environment <- function( res , envir ){
	CC <- length(res)
	for (cc in 1:CC){
		assign( names(res)[cc] , res[[cc]] , envir=envir )		
	}
}

.attach.environment <- attach_environment
		