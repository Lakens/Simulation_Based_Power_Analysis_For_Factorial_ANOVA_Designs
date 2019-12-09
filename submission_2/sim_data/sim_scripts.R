#Simulations storage
nsims = 100000
Superpower_options(verbose = FALSE)
manuscript_seed = 2019
set.seed(manuscript_seed)

library(Superpower)
#First simulation
design_result <- ANOVA_design(design = "2b", n = 80, mu = c(1, 0), sd = 2, labelnames = c("condition", "cheerful", "sad"))



#To save time compiling this manuscript, simulations are run and the result is stored
power_result <- ANOVA_power(design_result, alpha_level = 0.05, p_adjust = "none", nsims = nsims, verbose = FALSE)
saveRDS(power_result, file = "submission_2/sim_data/power_result.rds")

#sim_3 chunk
design_result_1 <- ANOVA_design(design = "3b", n = 80, mu = c(1, 0.5, 0), sd = 2, labelnames = c("condition", "cheerful", "neutral", "sad"))
set.seed(manuscript_seed)
power_result_1 <- ANOVA_power(design_result_1, alpha_level = 0.05, p_adjust = "none", nsims = nsims, verbose = FALSE)
saveRDS(power_result_1, file = "submission_2/sim_data/power_result_1.rds")

design_result_2 <- ANOVA_design(design = "3b", n = 80, mu = c(1, 1, 0), sd = 2, labelnames = c("condition", "cheerful", "neutral", "sad"))
set.seed(manuscript_seed)
power_result_2 <- ANOVA_power(design_result_2, alpha_level = 0.05, p_adjust = "none", nsims = nsims, verbose = FALSE)
saveRDS(power_result_2, file = "submission_2/sim_data/power_result_2.rds")

#sim_4 chuck
#To save time compiling this manuscript, simulations are run and the result is stored
design_result_within_1 <- ANOVA_design(design = "3w", n = 80, mu = c(1, 0.5, 0), sd = 2, r = 0.5, labelnames = c("condition", "cheerful", "neutral", "sad"))
set.seed(manuscript_seed)
power_result_within_1 <- ANOVA_power(design_result_within_1, alpha_level = 0.05, p_adjust = "none", nsims = nsims, verbose = FALSE)
saveRDS(power_result_within_1, file = "submission_2/sim_data/power_result_within_1.rds")

#mean_plot chunk
#To save time compiling this manuscript, simulations are run and the result is stored
design_result_cross_80 <- ANOVA_design(design = "2b*2b", n = 80, mu = c(1, 0, 0, 1), sd = 2, labelnames = c("condition", "cheerful", "sad", "voice", "human", "robot"))
set.seed(manuscript_seed)
power_result_cross_80 <- ANOVA_power(design_result_cross_80, alpha_level = 0.05, p_adjust = "none", nsims = nsims, verbose = FALSE)
saveRDS(power_result_cross_80, file = "submission_2/sim_data/power_result_cross_80.rds")



#To save time compiling this manuscript, simulations are run and the result is stored
design_result_cross_40 <- ANOVA_design(design = "2b*2b", n = 40, mu = c(1, 0, 0, 1), sd = 2, labelnames = c("condition", "cheerful", "sad", "voice", "human", "robot"), plot = FALSE)
set.seed(manuscript_seed)
power_result_cross_40 <- ANOVA_power(design_result_cross_40, alpha_level = 0.05, p_adjust = "none", nsims = nsims, verbose = FALSE)
saveRDS(power_result_cross_40, file = "submission_2/sim_data/power_result_cross_40.rds")

#sim-interaction-2 chunk
#To save time compiling this manuscript, simulations are run and the result is stored
design_result_ordinal <- ANOVA_design(design = "2b*2b", n = 160, mu = c(1, 0, 0, 0), sd = 2, labelnames = c("condition", "cheerful", "sad", "voice", "human", "robot"))
set.seed(manuscript_seed)
power_result_ordinal <- ANOVA_power(design_result_ordinal, alpha_level = 0.05, p_adjust = "none", nsims = nsims)
saveRDS(power_result_ordinal, file = "submission_2/sim_data/power_result_ordinal.rds")

#sim-holm chunk
#To save time compiling this manuscript, simulations are run and the result is stored
design_result_holm_correction <- ANOVA_design(design = "2b*2b", n = 40, mu = c(1, 0, 0, 1), sd = 2, labelnames = c("condition", "cheerful", "sad", "voice", "human", "robot"))
set.seed(manuscript_seed)
power_result_holm_correction <- ANOVA_power(design_result_holm_correction, alpha_level = 0.05, p_adjust = "holm", nsims = nsims, verbose = FALSE)
saveRDS(power_result_holm_correction, file = "power_result_holm_correction.rds")

#Sphericity chunk
design_result_s1 <- ANOVA_design("4w",
                                 n = 29,
                                 r = c(.05,.15,.25,.55, .65, .9
                                 ),
                                 sd = 1,
                                 mu= c(0,0,0,0))


#In order to simulate violations we MUST use ANOVA_power
power_result_s1 <- ANOVA_power(design_result_s1, alpha_level = 0.05, nsims = nsims, verbose = FALSE)
saveRDS("submission_2/sim_data", file = "power_result_s1.rds")
