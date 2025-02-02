#' Convenience function to plot power across a range of sample sizes.
#' @param design_result Output from the ANOVA_design function
#' @param alpha_level Alpha level used to determine statistical significance
#' @param min_n Minimum sample size in power curve.
#' @param max_n Maximum sample size in power curve.
#' @param desired_power Desired power (e.g., 80, 90). N per group will be highlighted to achieve this desired power in the plot. Defaults to 90.
#' @param plot Should power plot be printed automatically (defaults to TRUE)
#' @param emm Set to FALSE to not perform analysis of estimated marginal means
#' @param emm_model Set model type ("multivariate", or "univariate") for estimated marginal means
#' @param contrast_type Select the type of comparison for the estimated marginal means
#' @param emm_comp Set the comparisons for estimated marginal means comparisons. This is a factor name (a), combination of factor names (a+b), or for simple effects a | sign is needed (a|b)
#' @return Returns plot with power curves for the ANOVA, and a dataframe with the summary data.
#' 

#' \describe{
#'   \item{\code{"plot_ANOVA"}}{Plot of power curves from ANOVA results.}
#'   \item{\code{"plot_MANOVA"}}{Plot of power curves from MANOVA results. Returns NULL if no within-subject factors.}
#'   \item{\code{"plot_emm"}}{Plot of power curves from MANOVA results. Returns NULL if emm = FALSE.}
#'   \item{\code{"power_df"}}{The tabulated ANOVA power results.}
#'   \item{\code{"power_df_manova"}}{The tabulated MANOVA power results. Returns NULL if no within-subject factors.}
#'   \item{\code{"power_df_emm"}}{The tabulated Estimated Marginal Means power results. Returns NULL if emm = FALSE.}
#'   \item{\code{"effect_sizes"}}{Effect sizes (partial eta-squared) from ANOVA results.}
#'   \item{\code{"effect_sizes_manova"}}{Effect sizes (Pillai's Trace) from MANOVA results. Returns NULL if no within-subject factors.}
#'   \item{\code{"effect_sizes_emm"}}{ Effect sizes (cohen's f) estimated marginal means results. Returns NULL if emm = FALSE.}
#'   \item{\code{"n_for_power"}}{Sample sizes for each effect to achieve desired power for ANOVA.}
#'   \item{\code{"n_for_power_manova"}}{Sample sizes for each effect to achieve desired power for MANOVA results. Returns NULL if no within-subject factors.}
#'   \item{\code{"n_for_power_emm"}}{Sample sizes for each effect to achieve desired power for estimated marginal means results. Returns NULL if emm = FALSE.}
#'   
#' }
#' 
#' @examples
#' design_result <- ANOVA_design(design = "3b",
#'                              n = 20,
#'                              mu = c(0,0,0.3),
#'                              sd = 1,
#'                              labelnames = c("condition",
#'                              "cheerful", "neutral", "sad"))
#'
#' plot_power(design_result, min_n = 50, max_n = 70, desired_power = 90)
#' @section References:
#' too be added
#' @importFrom stats pnorm pt qnorm qt as.formula median qf power.t.test pf sd power
#' @importFrom reshape2 melt
#' @importFrom MASS mvrnorm
#' @importFrom afex aov_car
#' @importFrom graphics pairs
#' @importFrom magrittr '%>%'
#' @importFrom dplyr select mutate everything
#' @import emmeans
#' @import ggplot2
#' @export

plot_power <- function(design_result, 
                       alpha_level = Superpower_options("alpha_level"),
                       min_n = 7, max_n = 100,
                       desired_power = 90,
                       plot = TRUE,
                       emm = Superpower_options("emm"),
                       emm_model = Superpower_options("emm_model"),
                       contrast_type = Superpower_options("contrast_type"),
                       emm_comp){
  
  #Need this to avoid "undefined" global error or no visible binding from occuring
  cohen_f <- partial_eta_squared <- non_centrality <- pairs_results_df <- NULL
  #New checks for emmeans input
  if (missing(emm)) {
    emm = FALSE
  }
  
  if (missing(emm_model)) {
    emm_model = "multivariate"
  }
  
  #Follow if statements limit the possible input for emmeans specifications
  if (emm == TRUE) {
    if (is.element(emm_model, c("univariate", "multivariate")) == FALSE ) {
      stop("emm_model must be set to \"univariate\" or \"multivariate\". ")
    }
    if (is.element(contrast_type, 
                  c("pairwise", 
                    "revpairwise",
                    "eff",
                    "consec",
                    "poly",
                    "del.eff",
                    "trt.vs.ctrl",
                    "trt.vs.ctrl1",
                    "trt.vs.ctrlk",
                    "mean_chg"
                  )) == FALSE ) {
      stop("contrast_type must be of an accepted format. 
           The tukey & dunnett options currently not supported in ANOVA_exact. 
           See help(\"contrast-methods\") for details on the exact methods")
    }
  }
  
  design = design_result$design
  mu = design_result$mu
  sd <- design_result$sd
  r <- design_result$r
  labelnames <- design_result$labelnames
  n <- design_result$n
  if (length(n) != 1 ) {
    warning("Unequal n designs can only be passed to ANOVA_power")
  }
  frml1 <- design_result$frml1
  frml2 <- design_result$frml2


  if (missing(alpha_level)) {
    alpha_level <- 0.05
  }

  if (alpha_level >= 1 | alpha_level <= 0  ) {
    stop("alpha_level must be less than 1 and greater than zero")
  }

  #Errors with very small sample size; issue with mvrnorm function from MASS package
  if (design_result$n < prod(as.numeric(unlist(regmatches(design_result$design,
                                       gregexpr("[[:digit:]]+", design_result$design)))))
  ) {
    stop("plot_power must have an ANOVA_design object with n > the product of the factors; please increase the n in ANOVA_design function.")
  }

  #Check to ensure there is a within subject factor -- if none --> no MANOVA
  run_manova <- grepl("w", design_result$design)





  #Do one ANOVA to get number of power columns
  if (emm == FALSE) {
  exact_result <- ANOVA_exact(design_result, alpha_level = alpha_level,
                              verbose = FALSE)
  } else {
    #Call emmeans with specifcations given in the function
    #Limited to specs and model
    if (missing(emm_comp)) {
      emm_comp = as.character(frml2)[2]
    }
    exact_result <- ANOVA_exact(design_result, alpha_level = alpha_level,
                                emm = TRUE,
                                contrast_type = contrast_type,
                                emm_model = emm_model,
                                emm_comp = emm_comp,
                                verbose = FALSE)
  }

  length_power <- length(exact_result$main_results$power)

  power_df <- as.data.frame(matrix(0, ncol = length_power + 1,
                                   nrow = max_n + 1 - min_n))
  power_df[,1] <- c((min_n):max_n)

  colnames(power_df) <- c("n", row.names(exact_result$main_results))

  if (run_manova == TRUE) {

    length_power_manova <- length(exact_result$manova_results$power)
  
    power_df_manova <- as.data.frame(matrix(0, ncol = length_power_manova + 1,
                                            nrow = max_n + 1 - min_n))
    power_df_manova[, 1] <- c((min_n):max_n)
  
    colnames(power_df_manova) <- c("n", row.names(exact_result$manova_results))

  }
  
  if (emm == TRUE) {

    length_power_emm <- length(exact_result$emm_results$power)
    
    power_df_emm <- as.data.frame(matrix(0, ncol = length_power_emm + 1,
                                     nrow = max_n + 1 - min_n))
    power_df_emm[,1] <- c((min_n):max_n)
    
    colnames(power_df_emm) <- c("n", as.character(exact_result$emm_results$contrast))
    
  } 
  
  for (i in 1:(max_n + 1 - min_n)) {

    design_result <- ANOVA_design(design = design,
                                  n = i + min_n - 1,
                                  mu = mu,
                                  sd = sd,
                                  r = r,
                                  labelnames = labelnames,
                                  plot = FALSE)
    
    if (emm == FALSE) {
      exact_result <- ANOVA_exact(design_result, alpha_level = alpha_level,
                                  verbose = FALSE)
      power_df[i, 2:(1 + length_power)] <- exact_result$main_results$power
      
      if (run_manova == TRUE) {
         power_df_manova[i, 2:(1 + length_power_manova)] <- exact_result$manova_results$power
      }
      
    } else {
      #Call emmeans with specifcations given in the function
      #Limited to specs and model
      if (missing(emm_comp)) {
        emm_comp = as.character(frml2)[2]
      }
      exact_result <- ANOVA_exact(design_result, alpha_level = alpha_level,
                                  emm = TRUE,
                                  contrast_type = contrast_type,
                                  emm_model = emm_model,
                                  emm_comp = emm_comp,
                                  verbose = FALSE)
      power_df_emm[i, 2:(1 + length_power_emm)] <- exact_result$emm_results$power
    }
  }

  plot_data <- suppressMessages(melt(power_df, id = c('n')))
  plot_data$variable <- as.factor(plot_data$variable)

  #create data frame for annotation for desired power
  n_for_power <- as.data.frame(matrix(0, ncol = 4, nrow = length(row.names(exact_result$main_results)))) #three rows, for N, power, and variable label
  colnames(n_for_power) <- c("n", "power", "variable", "label") # add columns names
  n_for_power$variable <- as.factor(c(row.names(exact_result$main_results))) #add variable label names

  # Create a dataframe with columns for each effect and rows for the N and power for that N
  for (i in 1:length_power) {
    n_for_power[i,1] <- tryCatch(findInterval(desired_power, power_df[,(1 + i)]), error=function(e){max_n-min_n}) + min_n #use findinterval to find the first value in the vector before desired power. Add 1 (we want to achieve the power, not stop just short) then add min_n (because the vector starts at min_n, not 0)
    if(n_for_power[i,1] > max_n){n_for_power[i,1] <- max_n} # catches cases that do not reach desired power. Then just plot max_n
    if(n_for_power[i,1] == max_n){n_for_power[i,1] <- (min_n+max_n)/2} # We will plot that max power is not reached at midpoint of max n
    n_for_power[i,2] <- power_df[n_for_power[i,1]-min_n+1,(i+1)] #store exact power at N for which we pass desired power (for plot)
    if(n_for_power[i,2] < desired_power){n_for_power[i,4] <- "Desired Power Not Reached"}
    if(n_for_power[i,2] >= desired_power){n_for_power[i,4] <- n_for_power[i,1]}
    if(n_for_power[i,2] < desired_power){n_for_power[i,2] <- 5}
  }
  
  p1 <- ggplot(data = plot_data, aes(x = n, y = value)) +
    geom_line(size = 1.5) +
    scale_x_continuous(limits = c(min_n, max_n)) +
    scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10)) +
    theme_bw() +
    labs(x = "Sample size per condition", y = "Power") +
    geom_line(y = desired_power, colour="red", alpha = 0.3, size = 1) + 
    geom_label(data = n_for_power, aes(x = n, y = power, label = label)) +
    facet_grid(variable ~ .)

  if (run_manova == TRUE) {
    plot_data_manova <- suppressMessages(melt(power_df_manova, id = c('n')))

    #create data frame for annotation for desired power for manova
    n_for_power_manova <- as.data.frame(matrix(0, ncol = 3, nrow = length(row.names(exact_result$manova_results)))) #three rows, for N, power, and variable label
    colnames(n_for_power_manova) <- c("n", "power", "variable") # add columns names
    n_for_power_manova$variable <- as.factor(c(row.names(exact_result$manova_results))) #add variable label names
   
    # Create a dataframe with columns for each effect and rows for the N and power for that N
    for (i in 1:length_power_manova) {
      n_for_power_manova[i,1] <- tryCatch(findInterval(desired_power, power_df_manova[,(1 + i)]), error=function(e){max_n-min_n}) + min_n #use findinterval to find the first value in the vector before desired power. Add 1 (we want to achieve the power, not stop just short) then add min_n (because the vector starts at min_n, not 0)
      if(n_for_power_manova[i,1] > max_n){n_for_power_manova[i,1] <- max_n} # catches cases that do not reach desired power. Then just plot max_n
      if(n_for_power_manova[i,1] == max_n){n_for_power_manova[i,1] <- (min_n+max_n)/2} # We will plot that max power is not reached at midpoint of max n
      n_for_power_manova[i,2] <- power_df_manova[n_for_power_manova[i,1]-min_n+1,(i+1)] #store exact power at N for which we pass desired power (for plot)
      if(n_for_power_manova[i,2] < desired_power){n_for_power_manova[i,4] <- "Desired Power Not Reached"}
      if(n_for_power_manova[i,2] >= desired_power){n_for_power_manova[i,4] <- n_for_power_manova[i,1]}
      if(n_for_power_manova[i,2] < desired_power){n_for_power_manova[i,2] <- 5}
    }

    p2 <- ggplot(data = plot_data_manova,
                 aes(x = n, y = value)) +
      geom_line(size = 1.5) +
      scale_x_continuous(limits = c(min_n, max_n)) +
      scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10)) +
      geom_line(y = desired_power, colour="red", alpha = 0.3, size = 1) + 
      geom_label(data = n_for_power_manova, aes(x = n, y = power, label = n)) +
      theme_bw() +
      labs(x = "Sample size per condition", y = "Power") +
      facet_grid(variable ~ .)
  }
  
  if (emm == TRUE) {
    plot_data_emm <- suppressMessages(melt(power_df_emm, id = c('n')))
    
    #create data frame for annotation for desired power for emmeans
    n_for_power_emm <- as.data.frame(matrix(0, ncol = 3, nrow = length(levels(exact_result$emmeans$contrasts@grid$contrast)))) #three rows, for N, power, and variable label
    colnames(n_for_power_emm) <- c("n", "power", "variable") # add columns names
    n_for_power_emm$variable <- as.factor(levels(exact_result$emmeans$contrasts@grid$contrast)) #add variable label names
    i<-1
    # Create a dataframe with columns for each effect and rows for the N and power for that N
    for (i in 1:length_power_emm) {
      n_for_power_emm[i,1] <- tryCatch(findInterval(desired_power, power_df_emm[,(1 + i)]), error=function(e){max_n-min_n}) + min_n #use findinterval to find the first value in the vector before desired power. Add 1 (we want to achieve the power, not stop just short) then add min_n (because the vector starts at min_n, not 0)
      if(n_for_power_emm[i,1] > max_n){n_for_power_emm[i,1] <- max_n} # catches cases that do not reach desired power. Then just plot max_n
      if(n_for_power_emm[i,1] == max_n){n_for_power_emm[i,1] <- (min_n+max_n)/2} # We will plot that max power is not reached at midpoint of max n
      n_for_power_emm[i,2] <- power_df_emm[n_for_power_emm[i,1]-min_n+1,(i+1)] #store exact power at N for which we pass desired power (for plot)
      if(n_for_power_emm[i,2] < desired_power){n_for_power_emm[i,4] <- "Desired Power Not Reached"}
      if(n_for_power_emm[i,2] >= desired_power){n_for_power_emm[i,4] <- n_for_power_emm[i,1]}
      if(n_for_power_emm[i,2] < desired_power){n_for_power_emm[i,2] <- 5}
    }

    p3 <- ggplot(data = plot_data_emm,
                 aes(x = n, y = value)) +
      geom_line(size = 1.5) +
      scale_x_continuous(limits = c(min_n, max_n)) +
      scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10)) +
      geom_line(y = desired_power, colour="red", alpha = 0.3, size = 1) + 
      geom_label(data = n_for_power_emm, aes(x = n, y = power, label = n)) +
      theme_bw() +
      labs(x = "Sample size per condition", y = "Power") +
      facet_grid(variable ~ .)
  }

  if (plot == TRUE) {
    print(p1)
  }

  if (run_manova == FALSE) {
    p2 = NULL
    power_df_manova = NULL
    effect_sizes_manova = NULL
    n_for_power_manova = NULL
  }
  
  if (emm == FALSE) {
    p3 = NULL
    power_df_emm = NULL
    effect_sizes_emm = NULL
    n_for_power_emm = NULL
  }

  #Save effect sizes
  effect_sizes <- exact_result$main_results[,2:3]

  if (run_manova == TRUE) {
  effect_sizes_manova <- exact_result$manova_results[,2:3]
  }
  
  if (emm == TRUE) {
  effect_sizes_emm <- exact_result$emm_results %>%
    select(everything(),-non_centrality,-power)
}
  invisible(list(plot_ANOVA = p1,
                 plot_MANOVA = p2,
                 plot_emm = p3,
                 power_df = power_df,
                 power_df_manova = power_df_manova,
                 power_df_emm = power_df_emm,
                 effect_sizes = effect_sizes,
                 effect_sizes_manova = effect_sizes_manova,
                 effect_sizes_emm = effect_sizes_emm,
                 n_for_power = n_for_power,
                 n_for_power_manova = n_for_power_manova,
                 n_for_power_emm = n_for_power_emm))
}
